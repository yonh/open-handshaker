import 'dart:async';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../host_controller.dart';
import 'format.dart';
import 'host_shell.dart';
import 'transfers_panel.dart';

/// One installed app on the connected device.
class InstalledApp {
  InstalledApp({
    required this.packageName,
    required this.label,
    this.versionName = '',
    this.versionCode = 0,
    this.sizeBytes = 0,
    this.apkPath = '',
    this.iconBytes,
    this.system = false,
  });

  final String packageName;
  final String label;
  final String versionName;
  final int versionCode;
  final int sizeBytes;

  /// Absolute path of the installed APK on the device — exporting an app is
  /// `controller.downloadFile(apkPath, local)`.
  final String apkPath;
  final Uint8List? iconBytes;
  final bool system;
}

/// Pluggable inventory source for [AppsPage].
///
/// The recovered SSP protocol has no app-list request — the original client
/// pushed APKs over adb. Our agent already exposes `getInstalledApps` /
/// `uninstallApp` / `exportApk` on its platform channel
/// (lib/agent/platform_contract.dart); wiring it onto a wire op or the
/// :19999 HTTP endpoint is a connection-layer addition. Until then
/// [WireAppsSource] reports empty and the page shows the honest
/// "暂不支持" placeholder; [DemoAppsSource] (demo_support.dart) feeds the
/// demo run and widget tests.
abstract class AppsSource {
  Future<List<InstalledApp>> load(HostController controller);

  /// Attempts device-side uninstall (an uninstall *intent* on Android — the
  /// user confirms on the phone). Default: unsupported.
  Future<bool> uninstall(HostController controller, InstalledApp app) async =>
      false;
}

/// Wire-backed source. Returns empty until the protocol grows an
/// app-inventory operation.
class WireAppsSource extends AppsSource {
  @override
  Future<List<InstalledApp>> load(HostController controller) async =>
      const [];
}

/// App management page: installed-app list (name/version/size), multi-select
/// export of APKs (downloadFile over the SSP file channel), uninstall where
/// the source supports it.
class AppsPage extends StatefulWidget {
  const AppsPage({super.key, this.pickSaveLocation});

  /// Injectable save-path picker (per APK).
  final Future<String?> Function(String suggestedName)? pickSaveLocation;

  @override
  State<AppsPage> createState() => _AppsPageState();
}

class _AppsPageState extends State<AppsPage> {
  List<InstalledApp> _apps = [];
  final Set<String> _selected = {};
  bool _loading = false;
  String? _error;
  String _query = '';
  bool _hideSystem = true;

  HostController get _controller => HostScope.of(context).controller;
  AppsSource get _source => HostScope.of(context).appsSource;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final apps = await _source.load(_controller);
      if (!mounted) return;
      setState(() {
        _apps = apps;
        _selected.clear();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  List<InstalledApp> get _visible => _apps.where((a) {
        if (_hideSystem && a.system) return false;
        if (_query.isEmpty) return true;
        final q = _query.toLowerCase();
        return a.label.toLowerCase().contains(q) ||
            a.packageName.toLowerCase().contains(q);
      }).toList()
    ..sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));

  void _toggle(InstalledApp a) {
    setState(() => _selected.contains(a.packageName)
        ? _selected.remove(a.packageName)
        : _selected.add(a.packageName));
  }

  Future<String?> _pickSave(String name) {
    final custom = widget.pickSaveLocation;
    if (custom != null) return custom(name);
    return getSaveLocation(suggestedName: name).then((l) => l?.path);
  }

  Future<void> _export(InstalledApp a) async {
    if (a.apkPath.isEmpty) {
      _toast('缺少 APK 路径，无法导出');
      return;
    }
    final dst = await _pickSave('${a.label}-${a.versionName}.apk');
    if (dst == null) return;
    unawaited(_controller.downloadFile(a.apkPath, dst,
        taskName: '${a.label}.apk'));
    _toast('已加入下载队列：${a.label}');
  }

  Future<void> _uninstall(InstalledApp a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('卸载应用'),
        content: Text(
            '确定卸载「${a.label}」(${a.packageName})？\n需要在手机上确认卸载弹窗。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('取消')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('卸载')),
        ],
      ),
    );
    if (ok != true) return;
    final done = await _source.uninstall(_controller, a);
    if (!mounted) return;
    _toast(done ? '已在手机上发起卸载' : '当前连接暂不支持卸载操作');
    if (done) unawaited(_load());
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _toolbar(),
        Expanded(child: _list()),
        const TransfersPanel(),
      ],
    );
  }

  Widget _toolbar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          Text('共 ${_apps.length} 个应用',
              style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 12),
          FilterChip(
            label: const Text('隐藏系统应用'),
            selected: _hideSystem,
            onSelected: (v) => setState(() => _hideSystem = v),
          ),
          const Spacer(),
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 200),
              child: TextField(
                decoration: const InputDecoration(
                  isDense: true,
                  prefixIcon: Icon(Icons.search, size: 18),
                  hintText: '搜索应用',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
          ),
          IconButton(
              tooltip: '刷新',
              onPressed: () => unawaited(_load()),
              icon: const Icon(Icons.refresh, size: 20)),
        ],
      ),
    );
  }

  Widget _list() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('加载失败：$_error'),
            const SizedBox(height: 8),
            FilledButton(
                onPressed: () => unawaited(_load()),
                child: const Text('重试')),
          ],
        ),
      );
    }
    final items = _visible;
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.apps_outlined, size: 48),
              const SizedBox(height: 12),
              const Text('当前连接暂不提供应用列表',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(
                  'SSP 协议尚未包含应用枚举请求；Agent 端已具备能力，'
                  '待连接层扩展后此处自动可用。',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.outline)),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (ctx, i) => _row(items[i]),
    );
  }

  Widget _row(InstalledApp a) {
    final selected = _selected.contains(a.packageName);
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.primaryContainer : Colors.transparent,
      child: InkWell(
        onTap: () => _toggle(a),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              a.iconBytes != null
                  ? Image.memory(a.iconBytes!,
                      width: 36,
                      height: 36,
                      errorBuilder: (_, _, _) => _appIcon())
                  : _appIcon(),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(a.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                        ),
                        if (a.system) ...[
                          const SizedBox(width: 6),
                          Text('系统',
                              style: TextStyle(
                                  fontSize: 10, color: scheme.outline)),
                        ],
                      ],
                    ),
                    Text(a.packageName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 11, color: scheme.outline)),
                  ],
                ),
              ),
              SizedBox(
                  width: 80,
                  child: Text(a.versionName,
                      style: const TextStyle(fontSize: 12))),
              SizedBox(
                  width: 80,
                  child: Text(fmtBytes(a.sizeBytes),
                      style: const TextStyle(fontSize: 12))),
              TextButton(
                  onPressed: () => unawaited(_export(a)),
                  child: const Text('导出 APK')),
              TextButton(
                  onPressed:
                      a.system ? null : () => unawaited(_uninstall(a)),
                  child: const Text('卸载')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _appIcon() => Icon(Icons.android,
      size: 32, color: Theme.of(context).colorScheme.primary);
}
