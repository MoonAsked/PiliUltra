import 'package:PiliPlus/models/region_unlock/region_area.dart';
import 'package:PiliPlus/models/region_unlock/region_server.dart';
import 'package:PiliPlus/services/region_unlock/area_cache.dart';
import 'package:PiliPlus/services/region_unlock/region_unlock_config.dart';
import 'package:PiliPlus/services/region_unlock/sensitive_mask.dart';
import 'package:PiliPlus/services/region_unlock/server_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

class SwitchItem extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SwitchItem({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      value: value,
      onChanged: onChanged,
    );
  }
}

class RegionUnlockSetting extends StatefulWidget {
  const RegionUnlockSetting({super.key, this.showAppBar = true});
  final bool showAppBar;

  @override
  State<RegionUnlockSetting> createState() => _RegionUnlockSettingState();
}

class _RegionUnlockSettingState extends State<RegionUnlockSetting> {
  final _config = RegionUnlockConfig.instance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(title: const Text('区域解锁'))
          : null,
      body: ListView(
        children: [
          // 风险提示
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: theme.colorScheme.onErrorContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '区域解锁功能需要配置代理服务器，请确保代理来源可信。功能默认关闭，不内置任何代理服务器。',
                    style: TextStyle(
                        color: theme.colorScheme.onErrorContainer,
                        fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          // 总开关
          SwitchItem(
            title: '启用区域解锁',
            subtitle: 'PGC播放失败时尝试通过代理服务器获取',
            value: _config.enableRegionUnlock,
            onChanged: (v) {
              if (v) {
                _showRiskDialog().then((confirmed) {
                  if (confirmed) {
                    setState(() {
                      _config.enableRegionUnlock = true;
                    });
                  }
                });
              } else {
                setState(() {
                  _config.enableRegionUnlock = false;
                });
              }
            },
          ),

          // 代理超时
          ListTile(
            title: const Text('代理超时'),
            subtitle: Text('${_config.proxyTimeout.inSeconds}秒'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showTimeoutDialog(),
          ),

          // 区域优先级
          ListTile(
            title: const Text('区域优先级'),
            subtitle: Text(_config.areaPriority.map((e) => e.label).join(' > ')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showAreaPriorityDialog(),
          ),

          const Divider(),

          // 服务器配置
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('代理服务器配置',
                style: theme.textTheme.titleMedium),
          ),

          ..._buildServerList(),

          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('添加服务器'),
            onTap: () => _showAddServerDialog(),
          ),

          const Divider(),

          // access_key配置
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('区域 access_key',
                style: theme.textTheme.titleMedium),
          ),

          ...RegionArea.values.map((area) => ListTile(
                title: Text('${area.label}区域'),
                subtitle: Text(
                  _config.getAccessKey(area).isEmpty
                      ? '未配置'
                      : '${SensitiveMask.maskAccessKey(_config.getAccessKey(area))}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showAccessKeyDialog(area),
              )),

          const Divider(),

          // 缓存与高级
          SwitchItem(
            title: '启用区域缓存',
            subtitle: '缓存成功区域，下次优先尝试',
            value: _config.enableAreaCache,
            onChanged: (v) {
              setState(() {
                _config.enableAreaCache = v;
              });
            },
          ),

          SwitchItem(
            title: '稳定CDN替换',
            subtitle: '替换代理URL中的PCDN/mcdn等不稳定CDN',
            value: _config.enableUposReplace,
            onChanged: (v) {
              setState(() {
                _config.enableUposReplace = v;
              });
            },
          ),

          SwitchItem(
            title: '日志脱敏',
            subtitle: '日志中隐藏access_key、sign等敏感参数',
            value: _config.enableLogMask,
            onChanged: (v) {
              setState(() {
                _config.enableLogMask = v;
              });
            },
          ),

          ListTile(
            leading: const Icon(Icons.cleaning_services_outlined),
            title: const Text('清理区域缓存'),
            onTap: () {
              AreaCache.clearAll();
              ServerManager.clearHealthCache();
              SmartDialog.showToast('缓存已清理');
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _buildServerList() {
    final servers = _config.servers;
    if (servers.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('未配置任何代理服务器', style: TextStyle(color: Colors.grey)),
        ),
      ];
    }
    return servers.asMap().entries.map((entry) {
      final index = entry.key;
      final server = entry.value;
      return ListTile(
        leading: Icon(
          server.enabled ? Icons.cloud_outlined : Icons.cloud_off_outlined,
          color: server.enabled ? null : Colors.grey,
        ),
        title: Text('${server.area.label} - ${_maskUrl(server.baseUrl)}'),
        subtitle: Text(
            '优先级: ${server.priority} | 超时: ${server.timeout.inSeconds}s'),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, size: 20),
          onPressed: () {
            final list = _config.servers;
            list.removeAt(index);
            setState(() {
              _config.servers = list;
            });
          },
        ),
      );
    }).toList();
  }

  String _maskUrl(String url) {
    if (url.length <= 30) return url;
    return '${url.substring(0, 30)}...';
  }

  Future<bool> _showRiskDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('风险提示'),
            content: const Text(
                '区域解锁功能将通过您配置的代理服务器请求Bilibili API。'
                '请确保：\n\n'
                '1. 代理服务器来源可信\n'
                '2. 您的access_key不会被滥用\n'
                '3. 遵守相关法律法规\n\n'
                '本功能不内置任何代理服务器，不实现VIP伪造、SSL绕过等功能。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('我已了解，启用'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showTimeoutDialog() {
    final controller = TextEditingController(
        text: _config.proxyTimeout.inSeconds.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('代理超时（秒）'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: '默认5秒'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value != null && value > 0) {
                setState(() {
                  _config.proxyTimeout = Duration(seconds: value);
                });
              }
              Navigator.pop(context);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showAreaPriorityDialog() {
    final current = _config.areaPriority.toList();
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('区域优先级'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('拖动调整优先级顺序（越靠前越优先）', style: TextStyle(fontSize: 12)),
              const SizedBox(height: 8),
              ...current.asMap().entries.map((entry) => ListTile(
                    dense: true,
                    leading: Text('${entry.key + 1}'),
                    title: Text(entry.value.label),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (entry.key > 0)
                          IconButton(
                            icon: const Icon(Icons.arrow_upward, size: 18),
                            onPressed: () {
                              final i = entry.key;
                              final tmp = current[i];
                              current[i] = current[i - 1];
                              current[i - 1] = tmp;
                              setDialogState(() {});
                            },
                          ),
                        if (entry.key < current.length - 1)
                          IconButton(
                            icon: const Icon(Icons.arrow_downward, size: 18),
                            onPressed: () {
                              final i = entry.key;
                              final tmp = current[i];
                              current[i] = current[i + 1];
                              current[i + 1] = tmp;
                              setDialogState(() {});
                            },
                          ),
                      ],
                    ),
                  )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _config.areaPriority = current;
                });
                Navigator.pop(context);
              },
              child: const Text('确定'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddServerDialog() {
    RegionArea selectedArea = RegionArea.tw;
    final urlController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('添加代理服务器'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<RegionArea>(
                value: selectedArea,
                decoration: const InputDecoration(labelText: '区域'),
                items: RegionArea.values
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e.label),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    selectedArea = v;
                    setDialogState(() {});
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(
                  labelText: '服务器地址',
                  hintText: 'https://example.com',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                final url = urlController.text.trim();
                if (url.isEmpty || !url.startsWith('https://')) {
                  SmartDialog.showToast('请输入有效的HTTPS地址');
                  return;
                }
                final list = _config.servers;
                list.add(RegionServer(area: selectedArea, baseUrl: url));
                setState(() {
                  _config.servers = list;
                });
                Navigator.pop(context);
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAccessKeyDialog(RegionArea area) {
    final controller = TextEditingController();
    final current = _config.getAccessKey(area);
    if (current.isNotEmpty) {
      controller.text = current;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${area.label}区域 access_key'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'access_key',
            hintText: '从Bilibili App获取',
          ),
          obscureText: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _config.setAccessKey(area, controller.text.trim());
              });
              Navigator.pop(context);
              SmartDialog.showToast('已保存');
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}
