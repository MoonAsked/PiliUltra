import 'package:PiliUltra/models/region_unlock/region_area.dart';
import 'package:PiliUltra/models/region_unlock/region_playurl_context.dart';
import 'package:PiliUltra/models/region_unlock/region_server.dart';
import 'package:PiliUltra/services/region_unlock/area_cache.dart';
import 'package:PiliUltra/services/region_unlock/region_unlock_config.dart';

/// 区域服务器管理
/// 负责读取配置、按优先级排序、关键词匹配提升、健康状态管理
abstract final class ServerManager {
  /// 健康状态缓存
  static final _healthCache = <String, ServerHealth>{};

  /// 获取候选服务器列表（已排序、已过滤）
  /// 排序优先级：缓存区域 > 关键词匹配 > 用户首选 > 默认权重
  static List<RegionServer> getCandidates(RegionPlayUrlContext context) {
    final config = RegionUnlockConfig.instance;
    var servers = config.enabledServers.toList();

    // 1. 过滤：空地址、已禁用
    servers = servers.where((s) => s.baseUrl.isNotEmpty && s.enabled).toList();

    if (servers.isEmpty) return [];

    // 2. 按用户优先级排序
    servers.sort((a, b) => a.priority.compareTo(b.priority));

    // 3. 关键词匹配提升
    if (context.seasonTitle != null) {
      _applyKeywordPriority(servers, context.seasonTitle!);
    }

    // 4. 缓存区域提升
    final cacheKey = _buildCacheKeyPrefix(context);
    final cachedArea = AreaCache.getCachedArea(cacheKey);
    if (cachedArea != null) {
      _promoteArea(servers, cachedArea);
    }

    // 5. 不健康区域降级（移至末尾，但不完全排除）
    final healthy = servers
        .where((s) => !(getHealth(s.fingerprint).isUnhealthy))
        .toList();
    final unhealthy = servers
        .where((s) => getHealth(s.fingerprint).isUnhealthy)
        .toList();
    return [...healthy, ...unhealthy];
  }

  /// 获取候选服务器列表（Season上下文版本）
  static List<RegionServer> getCandidatesForSeason(
    int? seasonId,
    int? epId,
    String accountId,
  ) {
    final config = RegionUnlockConfig.instance;
    var servers = config.enabledServers.toList();

    servers = servers.where((s) => s.baseUrl.isNotEmpty && s.enabled).toList();
    if (servers.isEmpty) return [];

    servers.sort((a, b) => a.priority.compareTo(b.priority));

    // 缓存区域提升
    final id = seasonId != null && seasonId != 0
        ? 's$seasonId'
        : '${epId ?? ''}';
    final cacheKey = '${accountId}_$id';
    final cachedArea = AreaCache.getCachedArea(cacheKey);
    if (cachedArea != null) {
      _promoteArea(servers, cachedArea);
    }

    final healthy = servers
        .where((s) => !(getHealth(s.fingerprint).isUnhealthy))
        .toList();
    final unhealthy = servers
        .where((s) => getHealth(s.fingerprint).isUnhealthy)
        .toList();
    return [...healthy, ...unhealthy];
  }

  /// 记录服务器成功
  static void recordSuccess(RegionServer server) {
    final key = server.fingerprint;
    _healthCache[key] = (_healthCache[key] ?? const ServerHealth()).recordSuccess();
  }

  /// 记录服务器失败
  static void recordFailure(RegionServer server) {
    final key = server.fingerprint;
    _healthCache[key] = (_healthCache[key] ?? const ServerHealth()).recordFailure();
  }

  /// 获取服务器健康状态
  static ServerHealth getHealth(String fingerprint) {
    return _healthCache[fingerprint] ?? const ServerHealth();
  }

  /// 关键词匹配提升优先级
  /// 参考BiliRoamingX: twRegex="僅.*台", hkRegex="僅.*港", thRegex="[仅|僅].*[东南亚|其他]"
  static void _applyKeywordPriority(List<RegionServer> servers, String title) {
    if (_twRegex.hasMatch(title)) {
      _promoteArea(servers, RegionArea.tw);
    } else if (_hkRegex.hasMatch(title)) {
      _promoteArea(servers, RegionArea.hk);
    } else if (_thRegex.hasMatch(title)) {
      _promoteArea(servers, RegionArea.th);
    }
  }

  static final RegExp _twRegex = RegExp(r'僅.*台');
  static final RegExp _hkRegex = RegExp(r'僅.*港');
  static final RegExp _thRegex = RegExp(r'[仅|僅].*[东南亚|其他]');

  /// 将指定区域的服务器提升至列表首位
  static void _promoteArea(List<RegionServer> servers, RegionArea area) {
    final target = servers.where((s) => s.area == area).toList();
    if (target.isEmpty) return;
    servers.removeWhere((s) => s.area == area);
    servers.insertAll(0, target);
  }

  /// 构建缓存key前缀
  static String _buildCacheKeyPrefix(RegionPlayUrlContext context) {
    final id = context.seasonId != null && context.seasonId != 0
        ? 's${context.seasonId}'
        : '${context.epId ?? ''}';
    return '${context.accountId}_$id';
  }

  /// 清理健康缓存
  static void clearHealthCache() {
    _healthCache.clear();
  }
}
