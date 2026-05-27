import 'package:PiliPlus/common/constants.dart';

/// 区域类型枚举
/// 每个区域携带对应的API路径、签名参数和客户端标识
enum RegionArea {
  cn(
    label: '大陆',
    playUrlPath: '/pgc/player/api/playurl',
    seasonPath: '/pgc/view/v2/app/season',
    appKey: Constants.appKey,
    appSec: Constants.appSec,
    mobiApp: 'android',
    build: '6400000',
    weight: 0,
  ),
  hk(
    label: '港澳',
    playUrlPath: '/pgc/player/api/playurl',
    seasonPath: '/pgc/view/v2/app/season',
    appKey: Constants.appKey,
    appSec: Constants.appSec,
    mobiApp: 'android',
    build: '6400000',
    weight: 1,
  ),
  tw(
    label: '台湾',
    playUrlPath: '/pgc/player/api/playurl',
    seasonPath: '/pgc/view/v2/app/season',
    appKey: Constants.appKey,
    appSec: Constants.appSec,
    mobiApp: 'android',
    build: '6400000',
    weight: 2,
  ),
  th(
    label: '东南亚',
    playUrlPath: '/intl/gateway/v2/ogv/playurl',
    seasonPath: '/intl/gateway/v2/ogv/view/app/season',
    appKey: '7d089525d3611b1c',
    appSec: 'acd7e97b3e0f4d22',
    mobiApp: 'bstar_a',
    build: '1001310',
    weight: 3,
  );

  const RegionArea({
    required this.label,
    required this.playUrlPath,
    required this.seasonPath,
    required this.appKey,
    required this.appSec,
    required this.mobiApp,
    required this.build,
    required this.weight,
  });

  final String label;
  final String playUrlPath;
  final String seasonPath;
  final String appKey;
  final String appSec;
  final String mobiApp;
  final String build;
  final int weight;

  /// 是否为泰区
  bool get isThailand => this == th;

  /// 从字符串值解析区域类型
  static RegionArea? fromName(String? value) =>
      RegionArea.values.cast<RegionArea?>().firstWhere(
            (e) => e?.name == value,
            orElse: () => null,
          );
}
