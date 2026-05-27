import 'dart:convert';

import 'package:PiliUltra/models/region_unlock/region_area.dart';
import 'package:PiliUltra/models/region_unlock/region_server.dart';
import 'package:PiliUltra/utils/storage.dart';
import 'package:encrypt/encrypt.dart';

/// 区域解锁配置管理
/// 读取GStorage.setting中的配置，提供类型安全的访问接口
class RegionUnlockConfig {
  static final RegionUnlockConfig instance = RegionUnlockConfig._();
  RegionUnlockConfig._();

  // AES加密密钥（16字节），用于access_key加密存储
  static final _key = Key.fromUtf8('ru_aek_20260527_');
  static final _encrypter = Encrypter(AES(_key, mode: AESMode.ecb));

  /// 全局开关（默认关闭）
  bool get enableRegionUnlock =>
      GStorage.setting.get('enableRegionUnlock', defaultValue: false) as bool;

  set enableRegionUnlock(bool v) =>
      GStorage.setting.put('enableRegionUnlock', v);

  /// 代理服务器列表
  List<RegionServer> get servers {
    final list =
        GStorage.setting.get('regionServers') as List<dynamic>?;
    if (list == null) return [];
    return list
        .map((e) {
          if (e is Map<String, dynamic>) {
            return RegionServer.fromJson(e);
          }
          return null;
        })
        .whereType<RegionServer>()
        .toList();
  }

  set servers(List<RegionServer> v) =>
      GStorage.setting.put('regionServers', v.map((e) => e.toJson()).toList());

  /// 已启用的服务器列表
  List<RegionServer> get enabledServers =>
      servers.where((s) => s.enabled && s.baseUrl.isNotEmpty).toList();

  /// 区域优先级列表
  List<RegionArea> get areaPriority {
    final list = GStorage.setting.get('areaPriority') as List<dynamic>?;
    if (list == null) return [RegionArea.tw, RegionArea.hk, RegionArea.th];
    return list
        .map((e) => RegionArea.fromName(e.toString()))
        .whereType<RegionArea>()
        .toList();
  }

  set areaPriority(List<RegionArea> v) =>
      GStorage.setting.put('areaPriority', v.map((e) => e.name).toList());

  /// 区域缓存开关
  bool get enableAreaCache =>
      GStorage.setting.get('enableAreaCache', defaultValue: true) as bool;

  set enableAreaCache(bool v) =>
      GStorage.setting.put('enableAreaCache', v);

  /// 稳定CDN替换开关
  bool get enableUposReplace =>
      GStorage.setting.get('enableUposReplace', defaultValue: false) as bool;

  set enableUposReplace(bool v) =>
      GStorage.setting.put('enableUposReplace', v);

  /// 偏好CDN服务商
  String get preferredUpos =>
      GStorage.setting.get('preferredUpos', defaultValue: 'ali') as String;

  set preferredUpos(String v) =>
      GStorage.setting.put('preferredUpos', v);

  /// 日志脱敏开关
  bool get enableLogMask =>
      GStorage.setting.get('enableLogMask', defaultValue: true) as bool;

  set enableLogMask(bool v) =>
      GStorage.setting.put('enableLogMask', v);

  /// 代理请求超时
  Duration get proxyTimeout => Duration(
        seconds: GStorage.setting.get('proxyTimeout', defaultValue: 5) as int,
      );

  set proxyTimeout(Duration v) =>
      GStorage.setting.put('proxyTimeout', v.inSeconds);

  /// 获取指定区域的access_key（解密后）
  String getAccessKey(RegionArea area) {
    final encrypted = GStorage.setting
        .get('areaAccessKey_${area.name}', defaultValue: '') as String;
    if (encrypted.isEmpty) return '';
    try {
      return _decrypt(encrypted);
    } catch (_) {
      return '';
    }
  }

  /// 设置指定区域的access_key（加密存储）
  void setAccessKey(RegionArea area, String key) {
    if (key.isEmpty) {
      GStorage.setting.put('areaAccessKey_${area.name}', '');
    } else {
      GStorage.setting.put('areaAccessKey_${area.name}', _encrypt(key));
    }
  }

  /// AES加密
  static String _encrypt(String plainText) {
    return _encrypter.encrypt(plainText).base64;
  }

  /// AES解密
  static String _decrypt(String cipherText) {
    return _encrypter.decrypt64(cipherText);
  }
}
