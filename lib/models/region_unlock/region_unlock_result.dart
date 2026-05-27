import 'package:PiliUltra/models/region_unlock/region_area.dart';

/// 区域解锁统一结果
sealed class RegionUnlockResult<T> {
  const RegionUnlockResult();
}

class RegionUnlockSuccess<T> extends RegionUnlockResult<T> {
  final T data;
  final RegionArea area;
  final String source;
  const RegionUnlockSuccess(this.data, this.area, {this.source = 'proxy'});
}

class RegionUnlockFailure extends RegionUnlockResult<Never> {
  final RegionUnlockError error;
  const RegionUnlockFailure(this.error);
}

/// 区域解锁统一错误类型
enum RegionUnlockErrorKind {
  notConfigured,
  timeout,
  httpError,
  proxyCodeError,
  schemaIncompatible,
  authFailed,
  noVideoStream,
  allAreaFailed,
}

class RegionUnlockError {
  final RegionUnlockErrorKind kind;
  final RegionArea? area;
  final String message;
  final int? proxyCode;
  final Map<RegionArea, String>? allErrors;

  const RegionUnlockError({
    required this.kind,
    this.area,
    required this.message,
    this.proxyCode,
    this.allErrors,
  });
}

/// 区域解锁内部异常（用于Normalizer等内部抛出）
class RegionUnlockException implements Exception {
  final RegionUnlockErrorKind kind;
  final String message;
  const RegionUnlockException({
    required this.kind,
    required this.message,
  });

  @override
  String toString() => 'RegionUnlockException($kind): $message';
}
