import 'package:PiliUltra/models/region_unlock/region_area.dart';

/// 代理服务器配置模型
class RegionServer {
  final RegionArea area;
  final String baseUrl;
  final bool enabled;
  final int priority;
  final Duration timeout;
  final String? accessKey;
  final ServerHealth? lastHealth;

  const RegionServer({
    required this.area,
    required this.baseUrl,
    this.enabled = true,
    this.priority = 0,
    this.timeout = const Duration(seconds: 5),
    this.accessKey,
    this.lastHealth,
  });

  /// 服务器指纹，用于缓存key隔离
  String get fingerprint => '${area.name}:${baseUrl.hashCode}';

  /// 序列化为JSON
  Map<String, dynamic> toJson() => {
        'area': area.name,
        'baseUrl': baseUrl,
        'enabled': enabled,
        'priority': priority,
        'timeout': timeout.inSeconds,
      };

  /// 从JSON反序列化
  static RegionServer? fromJson(Map<String, dynamic> json) {
    final area = RegionArea.fromName(json['area'] as String?);
    if (area == null) return null;
    return RegionServer(
      area: area,
      baseUrl: json['baseUrl'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? true,
      priority: json['priority'] as int? ?? 0,
      timeout: Duration(seconds: json['timeout'] as int? ?? 5),
    );
  }

  /// 复制并更新字段
  RegionServer copyWith({
    RegionArea? area,
    String? baseUrl,
    bool? enabled,
    int? priority,
    Duration? timeout,
    String? accessKey,
    ServerHealth? lastHealth,
  }) =>
      RegionServer(
        area: area ?? this.area,
        baseUrl: baseUrl ?? this.baseUrl,
        enabled: enabled ?? this.enabled,
        priority: priority ?? this.priority,
        timeout: timeout ?? this.timeout,
        accessKey: accessKey ?? this.accessKey,
        lastHealth: lastHealth ?? this.lastHealth,
      );
}

/// 服务器健康状态
class ServerHealth {
  final DateTime? lastSuccessTime;
  final DateTime? lastFailTime;
  final int consecutiveFailures;

  const ServerHealth({
    this.lastSuccessTime,
    this.lastFailTime,
    this.consecutiveFailures = 0,
  });

  /// 连续失败是否超过阈值（默认3次）
  bool get isUnhealthy => consecutiveFailures >= 3;

  ServerHealth recordSuccess() => ServerHealth(
        lastSuccessTime: DateTime.now(),
        consecutiveFailures: 0,
      );

  ServerHealth recordFailure() => ServerHealth(
        lastFailTime: DateTime.now(),
        consecutiveFailures: consecutiveFailures + 1,
      );
}
