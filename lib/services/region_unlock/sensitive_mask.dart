import 'package:PiliPlus/models/region_unlock/region_area.dart';
import 'package:PiliPlus/services/region_unlock/region_unlock_config.dart';
import 'package:flutter/foundation.dart';

/// 日志脱敏
/// 确保日志中不包含access_key、cookie、sign、完整代理URL
abstract final class SensitiveMask {
  /// 脱敏URL：保留scheme+host，替换敏感query参数值为***
  static String maskUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final maskedParams = uri.queryParameters.map(
        (k, v) => MapEntry(k, _isSensitiveParam(k) ? '***' : v),
      );
      return uri.replace(queryParameters: maskedParams).toString();
    } catch (_) {
      return '***';
    }
  }

  /// 脱敏access_key：保留前4位，其余用***替代
  static String maskAccessKey(String key) {
    if (key.length <= 4) return '***';
    return '${key.substring(0, 4)}***';
  }

  /// 记录fallback错误（脱敏后）
  static void logFallbackErrors(Map<RegionArea, String> errors) {
    for (final entry in errors.entries) {
      debugPrint('[RegionUnlock] ${entry.key.name}: ${entry.value}');
    }
  }

  /// 记录信息日志
  static void logInfo(String message) {
    debugPrint('[RegionUnlock] $message');
  }

  /// 敏感参数名列表
  static const _sensitiveParams = {
    'access_key',
    'sign',
    'appkey',
    'appsec',
    'cookie',
  };

  static bool _isSensitiveParam(String key) =>
      _sensitiveParams.contains(key.toLowerCase());
}
