import 'package:PiliUltra/models/region_unlock/region_unlock_result.dart';

/// 普通区域PlayURL响应标准化
/// 处理非泰区代理服务器返回的playurl响应
/// 兼容多种包裹层: data / result / video_info / 直接DASH
abstract final class PlayUrlNormalizer {
  /// 标准化非泰区playurl响应
  static Map<String, dynamic> normalize(Map<String, dynamic> rawJson) {
    // 1. 提取有效数据（兼容多种包裹层）
    final data = _extractPayload(rawJson);

    // 2. Schema校验
    _validateSchema(data);

    // 3. 返回可直接被PlayUrlModel.fromJson消费的JSON
    return data;
  }

  /// 提取有效payload
  static Map<String, dynamic> _extractPayload(Map<String, dynamic> json) {
    // 情况1: 直接DASH格式（含dash字段）
    if (json.containsKey('dash')) return json;

    // 情况2: PGC Web v2格式（result.video_info）
    final result = json['result'] as Map<String, dynamic>?;
    if (result != null && result.containsKey('video_info')) {
      return result['video_info'] as Map<String, dynamic>;
    }

    // 情况3: data字段包裹
    final data = json['data'] as Map<String, dynamic>?;
    if (data != null) {
      // data内可能还有video_info
      if (data.containsKey('video_info')) {
        return data['video_info'] as Map<String, dynamic>;
      }
      return data;
    }

    // 情况4: result字段直接包裹
    if (result != null) return result;

    // 无法识别格式，原样返回（后续fromJson会失败并给出明确错误）
    return json;
  }

  /// Schema校验：确保必要字段存在
  static void _validateSchema(Map<String, dynamic> data) {
    if (!data.containsKey('dash') && !data.containsKey('durl')) {
      throw const RegionUnlockException(
        kind: RegionUnlockErrorKind.schemaIncompatible,
        message: '响应缺少dash/durl字段',
      );
    }
  }
}
