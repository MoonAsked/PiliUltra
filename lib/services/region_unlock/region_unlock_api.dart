import 'dart:convert';

import 'package:PiliUltra/common/constants.dart';
import 'package:PiliUltra/models/region_unlock/region_area.dart';
import 'package:PiliUltra/models/region_unlock/region_playurl_context.dart';
import 'package:PiliUltra/models/region_unlock/region_season_context.dart';
import 'package:PiliUltra/services/region_unlock/region_unlock_config.dart';
import 'package:PiliUltra/utils/app_sign.dart';
import 'package:dio/dio.dart';

/// 代理服务器API请求封装
/// 使用独立Dio实例，不经过PiliUltra的AccountManager拦截器
abstract final class RegionUnlockApi {
  /// 请求代理服务器获取playurl
  static Future<Map<String, dynamic>> requestPlayUrl({
    required RegionArea area,
    required String serverUrl,
    required RegionPlayUrlContext context,
    required String accessKey,
    CancelToken? cancelToken,
  }) async {
    // 1. 构建请求参数
    final params = <String, dynamic>{
      'ep_id': context.epId?.toString(),
      'cid': context.cid.toString(),
      'qn': context.qn.toString(),
      'fnval': context.fnval.toString(),
      'fourk': context.fourk.toString(),
      'access_key': accessKey,
      'area': area.name,
    };

    // 2. 区域特殊参数
    if (area.isThailand) {
      params['build'] = area.build;
      params['mobi_app'] = area.mobiApp;
      params['platform'] = 'android';
    } else {
      params['build'] = area.build;
    }

    // 3. App签名（复用PiliUltra现有AppSign，使用对应区域的appkey/appsec）
    AppSign.appSign(params, appkey: area.appKey, appsec: area.appSec);

    // 4. 构建完整URL
    final uri = Uri.parse('$serverUrl${area.playUrlPath}').replace(
      queryParameters: params.map((k, v) => MapEntry(k, v.toString())),
    );

    // 5. 发送请求（独立Dio实例）
    final timeout = RegionUnlockConfig.instance.proxyTimeout;
    final response = await _proxyDio.getUri(
      uri,
      options: Options(
        responseType: ResponseType.plain,
        receiveTimeout: timeout,
        sendTimeout: timeout,
      ),
      cancelToken: cancelToken,
    );

    // 6. 解析响应
    return jsonDecode(response.data as String) as Map<String, dynamic>;
  }

  /// 请求代理服务器获取season
  static Future<Map<String, dynamic>> requestSeason({
    required RegionArea area,
    required String serverUrl,
    required RegionSeasonContext context,
    required String accessKey,
    CancelToken? cancelToken,
  }) async {
    final params = <String, dynamic>{
      if (context.seasonId != null)
        'season_id': context.seasonId.toString(),
      if (context.epId != null) 'ep_id': context.epId.toString(),
      'access_key': accessKey,
      'mobi_app': area.mobiApp,
      'build': area.build,
    };

    if (area.isThailand) {
      params['platform'] = 'android';
    }

    AppSign.appSign(params, appkey: area.appKey, appsec: area.appSec);

    final uri = Uri.parse('$serverUrl${area.seasonPath}').replace(
      queryParameters: params.map((k, v) => MapEntry(k, v.toString())),
    );
    final timeout = RegionUnlockConfig.instance.proxyTimeout;
    final response = await _proxyDio.getUri(
      uri,
      options: Options(
        responseType: ResponseType.plain,
        receiveTimeout: timeout,
        sendTimeout: timeout,
      ),
      cancelToken: cancelToken,
    );

    return jsonDecode(response.data as String) as Map<String, dynamic>;
  }

  /// 健康检查：向服务器发送轻量请求测试连通性
  static Future<int> healthCheck({
    required String serverUrl,
    required RegionArea area,
    required String accessKey,
  }) async {
    final params = <String, dynamic>{
      'access_key': accessKey,
      'build': area.build,
      'mobi_app': area.mobiApp,
    };
    AppSign.appSign(params, appkey: area.appKey, appsec: area.appSec);

    final uri = Uri.parse('$serverUrl${area.seasonPath}').replace(
      queryParameters: params.map((k, v) => MapEntry(k, v.toString())),
    );
    final stopwatch = Stopwatch()..start();
    try {
      await _proxyDio.getUri(
        uri,
        options: Options(
          responseType: ResponseType.plain,
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
        ),
      );
      stopwatch.stop();
      return stopwatch.elapsedMilliseconds;
    } catch (_) {
      stopwatch.stop();
      return -1;
    }
  }

  /// 独立Dio实例
  /// 不挂AccountManager拦截器，不携带全局cookie
  /// 默认HTTP/1.1，短超时
  static final Dio _proxyDio = Dio(BaseOptions(
    headers: {
      'User-Agent': Constants.userAgentApp,
      ...Constants.baseHeaders,
    },
    validateStatus: (status) => status != null && status < 500,
  ));
}
