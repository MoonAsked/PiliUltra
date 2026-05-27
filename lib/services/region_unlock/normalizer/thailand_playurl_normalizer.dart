import 'package:PiliPlus/models/region_unlock/region_unlock_result.dart';

/// 泰区PlayURL响应标准化
/// 将bstar格式的stream_list+dash_audio转换为标准DASH格式
/// 参考BiliRoamingX BiliRoamingApi.fixThailandPlayurl()的业务逻辑
abstract final class ThailandPlayUrlNormalizer {
  /// 标准化泰区playurl响应
  /// 输入: 泰区代理服务器返回的完整JSON（含data.video_info结构）
  /// 输出: 标准DASH格式JSON（可直接被PlayUrlModel.fromJson消费）
  static Map<String, dynamic> normalize(Map<String, dynamic> rawJson) {
    // 1. 提取video_info
    final videoInfo = rawJson['data']?['video_info'] as Map<String, dynamic>?;
    if (videoInfo == null) {
      throw const RegionUnlockException(
        kind: RegionUnlockErrorKind.schemaIncompatible,
        message: '泰区响应缺少data.video_info',
      );
    }

    // 2. 提取stream_list和dash_audio
    final streamList = videoInfo['stream_list'] as List<dynamic>?;
    final dashAudio = videoInfo['dash_audio'] as List<dynamic>?;

    if (streamList == null || streamList.isEmpty) {
      throw const RegionUnlockException(
        kind: RegionUnlockErrorKind.schemaIncompatible,
        message: '泰区响应缺少stream_list',
      );
    }

    // 3. 构建标准DASH video流
    final dashVideo = <Map<String, dynamic>>[];
    final acceptQuality = <int>[];
    final acceptDescription = <String>[];
    final supportFormats = <Map<String, dynamic>>[];

    for (final stream in streamList) {
      final streamMap = stream as Map<String, dynamic>;
      final dashVideoItem = streamMap['dash_video'] as Map<String, dynamic>?;
      final streamInfo = streamMap['stream_info'] as Map<String, dynamic>?;

      // 跳过base_url为空的视频流
      if (dashVideoItem == null ||
          (dashVideoItem['base_url'] as String?)?.isEmpty != false) {
        continue;
      }

      // 设置video id为quality值
      if (streamInfo != null) {
        dashVideoItem['id'] = streamInfo['quality'];
        acceptQuality.add(streamInfo['quality'] as int);
        acceptDescription
            .add(streamInfo['new_description']?.toString() ?? '');
        supportFormats.add(streamInfo);
      }

      dashVideo.add(dashVideoItem);
    }

    if (dashVideo.isEmpty) {
      throw const RegionUnlockException(
        kind: RegionUnlockErrorKind.noVideoStream,
        message: '泰区无可用视频流',
      );
    }

    // 4. 构建标准DASH输出
    return {
      'code': 0,
      'result': 'suee',
      'format': 'flv720',
      'type': 'DASH',
      'video_codecid': 7,
      'no_rexcode': 0,
      'timelength': videoInfo['timelength'],
      'quality': videoInfo['quality'],
      'accept_format':
          'hdflv2_4k,hdflv2_hdr,hdflv2_dolby,hdflv2,flv,flv720,flv480,mp4',
      'accept_quality': acceptQuality,
      'accept_description': acceptDescription,
      'support_formats': supportFormats,
      'dash': {
        'duration': 0,
        'minBufferTime': 0.0,
        'min_buffer_time': 0.0,
        'video': dashVideo,
        'audio': dashAudio ?? [],
      },
    };
  }
}
