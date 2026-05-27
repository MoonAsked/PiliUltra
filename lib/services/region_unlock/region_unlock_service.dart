import 'dart:async';

import 'package:PiliPlus/models/region_unlock/region_area.dart';
import 'package:PiliPlus/models/region_unlock/region_playurl_context.dart';
import 'package:PiliPlus/models/region_unlock/region_season_context.dart';
import 'package:PiliPlus/models/region_unlock/region_server.dart';
import 'package:PiliPlus/models/region_unlock/region_unlock_result.dart';
import 'package:PiliPlus/models/video/play/url.dart';
import 'package:PiliPlus/services/region_unlock/area_cache.dart';
import 'package:PiliPlus/services/region_unlock/normalizer/playurl_normalizer.dart';
import 'package:PiliPlus/services/region_unlock/normalizer/season_normalizer.dart';
import 'package:PiliPlus/services/region_unlock/normalizer/thailand_playurl_normalizer.dart';
import 'package:PiliPlus/services/region_unlock/region_unlock_api.dart';
import 'package:PiliPlus/services/region_unlock/region_unlock_config.dart';
import 'package:PiliPlus/services/region_unlock/sensitive_mask.dart';
import 'package:PiliPlus/services/region_unlock/server_manager.dart';
import 'package:PiliPlus/models_new/pgc/pgc_info_model/result.dart';
import 'package:dio/dio.dart';

/// 区域解锁核心服务（门面）
/// 负责编排fallback流程：
/// 开关检查 → 服务器排序 → 缓存查询 → 逐区域尝试 → 响应标准化 → Model映射 → 缓存更新
abstract final class RegionUnlockService {
  /// PGC播放URL fallback
  /// 在VideoHttp.videoUrl的PGC失败分支中调用
  static Future<RegionUnlockResult<PlayUrlModel>> playUrlFallback(
    RegionPlayUrlContext context, {
    CancelToken? cancelToken,
  }) async {
    // 1. 开关前置检查
    if (!RegionUnlockConfig.instance.enableRegionUnlock) {
      return const RegionUnlockFailure(
        RegionUnlockError(
            kind: RegionUnlockErrorKind.notConfigured,
            message: '功能未启用'),
      );
    }

    // 2. 获取候选服务器列表
    final candidates = ServerManager.getCandidates(context);
    if (candidates.isEmpty) {
      return const RegionUnlockFailure(
        RegionUnlockError(
            kind: RegionUnlockErrorKind.notConfigured,
            message: '未配置可用代理服务器'),
      );
    }

    // 3. 逐区域尝试
    final errors = <RegionArea, String>{};
    for (final server in candidates) {
      try {
        // 3a. 获取该区域的access_key
        final accessKey =
            server.accessKey ?? RegionUnlockConfig.instance.getAccessKey(server.area);
        if (accessKey.isEmpty) {
          errors[server.area] = '未配置${server.area.label}区域access_key';
          continue;
        }

        // 3b. 构建请求参数并发送
        final rawJson = await RegionUnlockApi.requestPlayUrl(
          area: server.area,
          serverUrl: server.baseUrl,
          context: context,
          accessKey: accessKey,
          cancelToken: cancelToken,
        );

        // 3c. 响应验证
        final code = rawJson['code'] as int?;
        if (code != 0) {
          final msg = rawJson['message']?.toString() ?? '代理返回错误($code)';
          errors[server.area] = msg;
          ServerManager.recordFailure(server);
          // 鉴权失败特殊处理
          if (code == -101 || code == -111) {
            errors[server.area] = '${server.area.label}区域账号已过期，请重新登录';
          }
          continue;
        }

        // 3d. 响应标准化
        final normalizedJson = server.area.isThailand
            ? ThailandPlayUrlNormalizer.normalize(rawJson)
            : PlayUrlNormalizer.normalize(rawJson);

        // 3e. PlayUrlModel映射
        final playUrlModel = PlayUrlModel.fromJson(normalizedJson);
        if (playUrlModel.dash?.video == null ||
            playUrlModel.dash!.video!.isEmpty) {
          errors[server.area] = 'DASH视频流为空';
          continue;
        }

        // 3f. 缓存成功区域
        final cacheKey = _buildCacheKey(context, server);
        AreaCache.cacheArea(cacheKey, server.area);
        ServerManager.recordSuccess(server);

        SensitiveMask.logInfo(
            'playurl fallback成功: area=${server.area.name}');
        return RegionUnlockSuccess(playUrlModel, server.area);
      } on TimeoutException {
        errors[server.area] = '连接超时';
        ServerManager.recordFailure(server);
      } on DioException catch (e) {
        errors[server.area] = _parseDioError(e);
        ServerManager.recordFailure(server);
      } on RegionUnlockException catch (e) {
        errors[server.area] = e.message;
      } catch (e) {
        errors[server.area] = '解析失败: ${e.toString().substring(0, (e.toString().length).clamp(0, 50))}';
      }
    }

    // 4. 所有区域均失败
    SensitiveMask.logFallbackErrors(errors);
    return RegionUnlockFailure(RegionUnlockError(
      kind: RegionUnlockErrorKind.allAreaFailed,
      message: '所有区域fallback均失败',
      allErrors: errors,
    ));
  }

  /// Season详情fallback
  static Future<RegionUnlockResult<PgcInfoModel>> seasonFallback(
    RegionSeasonContext context, {
    CancelToken? cancelToken,
  }) async {
    // 1. 开关前置检查
    if (!RegionUnlockConfig.instance.enableRegionUnlock) {
      return const RegionUnlockFailure(
        RegionUnlockError(
            kind: RegionUnlockErrorKind.notConfigured,
            message: '功能未启用'),
      );
    }

    // 2. 获取候选服务器列表
    final candidates = ServerManager.getCandidatesForSeason(
      context.seasonId,
      context.epId,
      context.accountId,
    );
    if (candidates.isEmpty) {
      return const RegionUnlockFailure(
        RegionUnlockError(
            kind: RegionUnlockErrorKind.notConfigured,
            message: '未配置可用代理服务器'),
      );
    }

    // 3. 逐区域尝试
    final errors = <RegionArea, String>{};
    for (final server in candidates) {
      try {
        final accessKey =
            server.accessKey ?? RegionUnlockConfig.instance.getAccessKey(server.area);
        if (accessKey.isEmpty) {
          errors[server.area] = '未配置${server.area.label}区域access_key';
          continue;
        }

        final rawJson = await RegionUnlockApi.requestSeason(
          area: server.area,
          serverUrl: server.baseUrl,
          context: context,
          accessKey: accessKey,
          cancelToken: cancelToken,
        );

        final code = rawJson['code'] as int?;
        if (code != 0) {
          final msg = rawJson['message']?.toString() ?? '代理返回错误($code)';
          errors[server.area] = msg;
          ServerManager.recordFailure(server);
          if (code == -101 || code == -111) {
            errors[server.area] = '${server.area.label}区域账号已过期，请重新登录';
          }
          continue;
        }

        // 响应标准化
        final normalizedJson = SeasonNormalizer.normalize(
          rawJson,
          area: server.area,
        );

        // PgcInfoModel映射
        final pgcInfoModel = PgcInfoModel.fromJson(normalizedJson);

        // 缓存成功区域
        final id = context.seasonId != null && context.seasonId != 0
            ? 's${context.seasonId}'
            : '${context.epId ?? ''}';
        final cacheKey = '${context.accountId}_${server.fingerprint}_$id';
        AreaCache.cacheArea(cacheKey, server.area);
        ServerManager.recordSuccess(server);

        SensitiveMask.logInfo(
            'season fallback成功: area=${server.area.name}');
        return RegionUnlockSuccess(pgcInfoModel, server.area);
      } on TimeoutException {
        errors[server.area] = '连接超时';
        ServerManager.recordFailure(server);
      } on DioException catch (e) {
        errors[server.area] = _parseDioError(e);
        ServerManager.recordFailure(server);
      } on RegionUnlockException catch (e) {
        errors[server.area] = e.message;
      } catch (e) {
        errors[server.area] = '解析失败: ${e.toString().substring(0, (e.toString().length).clamp(0, 50))}';
      }
    }

    // 4. 所有区域均失败
    SensitiveMask.logFallbackErrors(errors);
    return RegionUnlockFailure(RegionUnlockError(
      kind: RegionUnlockErrorKind.allAreaFailed,
      message: '所有区域fallback均失败',
      allErrors: errors,
    ));
  }

  /// 构建缓存key（含账号+服务器隔离）
  static String _buildCacheKey(
      RegionPlayUrlContext ctx, RegionServer server) {
    final id = ctx.seasonId != null && ctx.seasonId != 0
        ? 's${ctx.seasonId}'
        : '${ctx.epId ?? ''}';
    return '${ctx.accountId}_${server.fingerprint}_$id';
  }

  /// 解析Dio错误
  static String _parseDioError(DioException e) {
    return switch (e.type) {
      DioExceptionType.connectionTimeout => '连接超时',
      DioExceptionType.sendTimeout => '发送超时',
      DioExceptionType.receiveTimeout => '接收超时',
      DioExceptionType.connectionError => '连接失败',
      _ => '网络错误(${e.type.name})',
    };
  }

  /// 判断是否为区域限制错误
  static bool isAreaLimitError(Map<String, dynamic>? data) {
    if (data == null) return false;
    final code = data['code'] as int?;
    // -404: 视频不存在/区域限制
    // -10403: 请求非法/区域限制
    if (code == -404 || code == -10403) return true;
    // 检查dialog.type
    final dialog = data['dialog'];
    if (dialog is Map && dialog['type'] == 'area_limit') return true;
    return false;
  }
}
