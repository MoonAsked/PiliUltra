import 'package:PiliUltra/models/region_unlock/region_area.dart';
import 'package:PiliUltra/utils/storage.dart';

/// 区域命中缓存
/// 双层缓存：内存LRU + Hive持久化
/// 缓存key格式: "{accountId}_{serverFp}_{epId}" 或 "{accountId}_{serverFp}_s{seasonId}"
/// 上限: 内存8条(LRU), 持久化64条(LRU)
/// TTL: 默认24小时
abstract final class AreaCache {
  static final _memoryCache = <String, _CacheEntry>{};
  static const int _memoryLimit = 8;
  static const int _persistLimit = 64;
  static const Duration _defaultTtl = Duration(hours: 24);
  static const String _cacheKeyPrefix = 'ru_area_';

  /// 查询缓存区域
  static RegionArea? getCachedArea(String cacheKey) {
    // 1. 查内存缓存
    final memEntry = _memoryCache[cacheKey];
    if (memEntry != null && !memEntry.isExpired) {
      return memEntry.area;
    }
    if (memEntry != null && memEntry.isExpired) {
      _memoryCache.remove(cacheKey);
    }

    // 2. 查持久化缓存
    final stored = GStorage.localCache.get('$_cacheKeyPrefix$cacheKey');
    if (stored != null) {
      final parts = stored.toString().split('|');
      final area = RegionArea.fromName(parts[0]);
      final timestamp = parts.length > 1 ? int.tryParse(parts[1]) : null;
      if (area != null && timestamp != null) {
        final age = DateTime.now().millisecondsSinceEpoch - timestamp;
        if (age < _defaultTtl.inMilliseconds) {
          _putMemoryCache(cacheKey, area);
          return area;
        } else {
          GStorage.localCache.delete('$_cacheKeyPrefix$cacheKey');
        }
      }
    }
    return null;
  }

  /// 缓存成功区域
  static void cacheArea(String cacheKey, RegionArea area) {
    _putMemoryCache(cacheKey, area);
    _putPersistCache(cacheKey, area);
  }

  /// 清理所有缓存（切换账号/关闭功能时）
  static void clearAll() {
    _memoryCache.clear();
    _clearPersistPrefix();
  }

  /// 清理指定账号的缓存
  static void clearForAccount(String accountId) {
    _memoryCache.removeWhere((key, _) => key.startsWith(accountId));
    _clearPersistForAccount(accountId);
  }

  static void _putMemoryCache(String key, RegionArea area) {
    if (_memoryCache.length >= _memoryLimit && !_memoryCache.containsKey(key)) {
      _memoryCache.remove(_memoryCache.keys.first);
    }
    _memoryCache[key] = _CacheEntry(area, DateTime.now());
  }

  static void _putPersistCache(String key, RegionArea area) {
    // 检查持久化缓存数量上限
    _enforcePersistLimit();
    final value = '${area.name}|${DateTime.now().millisecondsSinceEpoch}';
    GStorage.localCache.put('$_cacheKeyPrefix$key', value);
  }

  /// 检查并执行持久化缓存LRU淘汰
  static void _enforcePersistLimit() {
    try {
      final keys = GStorage.localCache.keys
          .where((k) => k.toString().startsWith(_cacheKeyPrefix))
          .toList();
      if (keys.length >= _persistLimit) {
        // 删除最旧的条目
        final toRemove = keys.length - _persistLimit + 1;
        for (var i = 0; i < toRemove && i < keys.length; i++) {
          GStorage.localCache.delete(keys[i]);
        }
      }
    } catch (_) {}
  }

  /// 清理Hive中所有ru_area_前缀的key
  static void _clearPersistPrefix() {
    try {
      final keys = GStorage.localCache.keys
          .where((k) => k.toString().startsWith(_cacheKeyPrefix))
          .toList();
      for (final key in keys) {
        GStorage.localCache.delete(key);
      }
    } catch (_) {}
  }

  /// 清理指定账号的持久化缓存
  static void _clearPersistForAccount(String accountId) {
    try {
      final keys = GStorage.localCache.keys
          .where((k) =>
              k.toString().startsWith(_cacheKeyPrefix) &&
              k.toString().contains(accountId))
          .toList();
      for (final key in keys) {
        GStorage.localCache.delete(key);
      }
    } catch (_) {}
  }
}

class _CacheEntry {
  final RegionArea area;
  final DateTime cachedAt;
  const _CacheEntry(this.area, this.cachedAt);
  bool get isExpired =>
      DateTime.now().difference(cachedAt) > AreaCache._defaultTtl;
}
