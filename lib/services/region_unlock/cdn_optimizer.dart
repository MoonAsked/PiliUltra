import 'package:PiliUltra/models/video/play/url.dart';
import 'package:PiliUltra/services/region_unlock/region_unlock_config.dart';

/// CDN/PCDN优化
/// 检测并替换代理URL中的不稳定CDN host
/// 复用PiliUltra现有VideoUtils.getCdnUrl
abstract final class CdnOptimizer {
  /// 不稳定CDN host正则
  static final _unstableCdnRegex = RegExp(
    r'(?:pcdn|gotcha|mcdn)',
  );

  /// 优化PlayUrlModel中的CDN URL
  /// 仅在有备用URL时替换，无备用保留原URL
  static void optimize(PlayUrlModel model) {
    if (!RegionUnlockConfig.instance.enableUposReplace) return;

    // 优化video流URL
    if (model.dash?.video != null) {
      for (final video in model.dash!.video!) {
        _optimizeItem(video);
      }
    }

    // 优化audio流URL
    if (model.dash?.audio != null) {
      for (final audio in model.dash!.audio!) {
        _optimizeItem(audio);
      }
    }
  }

  /// 优化单个流项的URL
  static void _optimizeItem(BaseItem item) {
    if (item.baseUrl != null && _unstableCdnRegex.hasMatch(item.baseUrl!)) {
      // 有备用URL时替换
      if (item.backupUrl != null && item.backupUrl!.isNotEmpty) {
        item.baseUrl = item.backupUrl!.first;
      }
      // 无备用URL时保留原URL
    }
  }
}
