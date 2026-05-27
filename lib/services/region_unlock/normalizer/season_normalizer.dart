import 'package:PiliUltra/models/region_unlock/region_area.dart';

/// Season响应标准化
/// 将代理服务器返回的season JSON转换为PiliUltra PgcInfoModel可消费格式
/// 处理泰区Episode字段补全和rights修正
abstract final class SeasonNormalizer {
  /// 标准化season响应
  static Map<String, dynamic> normalize(
    Map<String, dynamic> rawJson, {
    required RegionArea area,
    Map<String, dynamic>? officialResult,
  }) {
    // 1. 提取有效数据
    var data = _extractPayload(rawJson);

    // 2. 泰区特殊处理
    if (area.isThailand) {
      data = _normalizeThailandSeason(data);
    }

    // 3. 合并用户状态字段（官方优先）
    if (officialResult != null) {
      data = _mergeUserStatus(data, officialResult);
    }

    return data;
  }

  /// 泰区Season字段补全
  static Map<String, dynamic> _normalizeThailandSeason(
      Map<String, dynamic> data) {
    // 补全Episode缺失字段
    final episodes = data['episodes'] as List<dynamic>?;
    if (episodes != null) {
      for (final ep in episodes) {
        final epMap = ep as Map<String, dynamic>;
        // ep_id缺失时用id填充
        epMap.putIfAbsent('ep_id', () => epMap['id']);
        // duration缺失时填充默认值
        epMap.putIfAbsent('duration', () => 1436000);
        // link缺失时构造
        epMap.putIfAbsent(
            'link', () => 'https://www.bilibili.com/bangumi/play/ep${epMap['id']}');
        // rights.area_limit必须设为0
        if (epMap['rights'] is Map) {
          (epMap['rights'] as Map)['area_limit'] = 0;
        } else {
          epMap['rights'] = {'area_limit': 0};
        }
      }
    }

    // 处理modules结构差异（泰区可能用不同字段名）
    final modules = data['modules'] as List<dynamic>?;
    if (modules != null) {
      for (final module in modules) {
        final moduleMap = module as Map<String, dynamic>;
        // 确保module中的episodes也有正确的字段
        final moduleEpisodes = moduleMap['data']?['episodes'] as List<dynamic>?;
        if (moduleEpisodes != null) {
          for (final ep in moduleEpisodes) {
            final epMap = ep as Map<String, dynamic>;
            epMap.putIfAbsent('ep_id', () => epMap['id']);
            epMap.putIfAbsent('duration', () => 1436000);
            if (epMap['rights'] is Map) {
              (epMap['rights'] as Map)['area_limit'] = 0;
            } else {
              epMap['rights'] = {'area_limit': 0};
            }
          }
        }
      }
    }

    // 确保rights.area_limit为0
    if (data['rights'] is Map) {
      (data['rights'] as Map)['area_limit'] = 0;
    }

    return data;
  }

  /// 合并用户状态（收藏、追番、历史进度等）
  static Map<String, dynamic> _mergeUserStatus(
    Map<String, dynamic> proxyData,
    Map<String, dynamic> officialData,
  ) {
    // 保留官方的user_status、progress等字段
    if (officialData.containsKey('user_status')) {
      proxyData['user_status'] = officialData['user_status'];
    }
    if (officialData.containsKey('progress')) {
      proxyData['progress'] = officialData['progress'];
    }
    return proxyData;
  }

  static Map<String, dynamic> _extractPayload(Map<String, dynamic> json) {
    if (json.containsKey('result')) {
      return json['result'] as Map<String, dynamic>;
    }
    if (json.containsKey('data')) {
      return json['data'] as Map<String, dynamic>;
    }
    return json;
  }
}
