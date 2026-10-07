import 'dart:async';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../idea_pills.dart';
import 'host_shell.dart';

/// 闪念胶囊页与 [IdeaPillsSync] 之间的最小接缝——widget 测试可注入
/// 假实现。
abstract class IdeaPillsDriver {
  /// 本地镜像目录（页面直接读它列出胶囊）。
  String get localDir;

  Future<void> start();
  Future<int> pullAll();
  Future<File> createPill(String title, String body);
  Future<void> stop();
  Future<void> dispose();
}

class EngineIdeaPillsDriver implements IdeaPillsDriver {
  EngineIdeaPillsDriver(this._engine, this.localDir);

  final IdeaPillsSync _engine;

  @override
  final String localDir;

  @override
  Future<void> start() => _engine.start();
  @override
  Future<int> pullAll() => _engine.pullAll();
  @override
  Future<File> createPill(String title, String body) =>
      _engine.createPill(title, body);
  @override
  Future<void> stop() => _engine.stop();
  @override
  Future<void> dispose() => _engine.dispose();
}

/// 闪念胶囊页：本地目录 ↔ 手机 `idea_pills/` 目录双向镜像，
/// 支持新建胶囊（保存即上传）。
class IdeaPillsPage extends StatefulWidget {
  const IdeaPillsPage(
      {super.key,
      this.driverFactory,
      this.pickDir,
      this.remoteDir = '/sdcard/idea_pills'});

  /// 构造同步驱动；缺省用 [EngineIdeaPillsDriver] + [IdeaPillsSync]。
  final IdeaPillsDriver Function(String localDir)? driverFactory;

  /// 选本地镜像目录；缺省走系统目录选择器。
  final Future<String?> Function()? pickDir;

  /// 手机端胶囊目录（SSP 无专用胶囊协议，用目录镜像近似）。
  final String remoteDir;

  @override
  State<IdeaPillsPage> createState() => _IdeaPillsPageState();
}

class _IdeaPillsPageState extends State<IdeaPillsPage> {
  IdeaPillsDriver? _driver;
  bool _running = false;
  String? _status;
  List<File> _pills = [];

  Future<String?> _defaultPickDir() =>
      getDirectoryPath(confirmButtonText: '选择胶囊目录');

  IdeaPillsDriver _defaultFactory(String localDir) {
    final scope = HostScope.of(context);
    final api = scope.controller.api;
    if (api == null) throw StateError('未连接设备');
    return EngineIdeaPillsDriver(
        IdeaPillsSync(
          client: api.client,
          api: api,
          localDir: localDir,
          remoteDir: widget.remoteDir,
          pushHub: scope.pushHub,
        ),
        localDir);
  }

  void _refreshList() {
    final d = _driver;
    if (d == null) return;
    try {
      final files = Directory(d.localDir)
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.md'))
          .toList()
        ..sort((a, b) => b
            .lastModifiedSync()
            .compareTo(a.lastModifiedSync()));
      setState(() => _pills = files);
    } catch (_) {}
  }

  Future<void> _start() async {
    final dir = await (widget.pickDir ?? _defaultPickDir)();
    if (dir == null || !mounted) return;
    try {
      final driver = (widget.driverFactory ?? _defaultFactory)(dir);
      await driver.start();
      final n = await driver.pullAll();
      if (!mounted) {
        await driver.dispose();
        return;
      }
      setState(() {
        _driver = driver;
        _running = true;
        _status = '同步已开启，已拉取 $n 个胶囊';
      });
      _refreshList();
    } catch (e) {
      if (mounted) setState(() => _status = '开启失败：$e');
    }
  }

  Future<void> _stop() async {
    await _driver?.stop();
    if (mounted) {
      setState(() {
        _running = false;
        _status = '同步已停止';
      });
    }
  }

  Future<void> _pull() async {
    final d = _driver;
    if (d == null) return;
    try {
      final n = await d.pullAll();
      if (mounted) setState(() => _status = '已从手机拉取 $n 个胶囊');
      _refreshList();
    } catch (e) {
      if (mounted) setState(() => _status = '拉取失败：$e');
    }
  }

  Future<void> _newPill() async {
    final d = _driver;
    if (d == null) return;
    final title = TextEditingController();
    final body = TextEditingController();
    // 文本在弹窗回调里取出：对话框退出动画期间 TextField 仍持有 controller，
    // 此时 dispose 会触发 "used after being disposed"。controller 随 GC 回收。
    final result = await showDialog<List<String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新建闪念胶囊'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: title,
                decoration: const InputDecoration(
                    labelText: '标题', isDense: true),
                autofocus: true,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: body,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                    labelText: '内容',
                    border: OutlineInputBorder(),
                    isDense: true),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('取消')),
          FilledButton(
              onPressed: () =>
                  Navigator.of(ctx).pop([title.text, body.text]),
              child: const Text('保存')),
        ],
      ),
    );
    if (result == null) return;
    try {
      await d.createPill(
          result[0].trim().isEmpty ? '未命名' : result[0], result[1]);
      if (mounted) setState(() => _status = '已保存，将同步到手机');
      _refreshList();
    } catch (e) {
      if (mounted) setState(() => _status = '保存失败：$e');
    }
  }

  String _snippet(File f) {
    try {
      final lines = f
          .readAsStringSync()
          .split('\n')
          .where((l) => l.trim().isNotEmpty && !l.startsWith('#'))
          .toList();
      return lines.isEmpty ? '' : lines.first;
    } catch (_) {
      return '';
    }
  }

  String _title(File f) =>
      f.path.split('/').last.replaceAll(RegExp(r'\.md$'), '');

  @override
  void dispose() {
    unawaited(_driver?.dispose() ?? Future<void>.value());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('闪念胶囊'),
        automaticallyImplyLeading: false,
        actions: [
          if (_driver != null)
            IconButton(
                onPressed: _pull,
                icon: const Icon(Icons.refresh),
                tooltip: '从手机拉取'),
          if (_running)
            IconButton(
                onPressed: _stop,
                icon: const Icon(Icons.stop_circle_outlined),
                tooltip: '停止同步'),
          IconButton(
              onPressed: _driver == null ? null : _newPill,
              icon: const Icon(Icons.add),
              tooltip: '新建胶囊'),
        ],
      ),
      body: _driver == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lightbulb_outline,
                      size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text('闪念胶囊：与手机双向同步的想法便签'),
                  const SizedBox(height: 8),
                  Text('本机目录与手机 ${widget.remoteDir} 互相镜像',
                      style:
                          TextStyle(fontSize: 12, color: scheme.outline)),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _start,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('选择目录并开启同步'),
                  ),
                  if (_status != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(_status!,
                          style: TextStyle(
                              fontSize: 12, color: scheme.outline)),
                    ),
                ],
              ),
            )
          : Column(
              children: [
                if (_status != null)
                  Padding(
                    padding:
                        const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Row(children: [
                      Expanded(
                        child: Text(_status!,
                            style: TextStyle(
                                fontSize: 12, color: scheme.outline)),
                      ),
                    ]),
                  ),
                Expanded(
                  child: _pills.isEmpty
                      ? const Center(child: Text('暂无胶囊，点右上角 + 新建'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _pills.length,
                          itemBuilder: (ctx, i) {
                            final f = _pills[i];
                            return Card(
                              elevation: 0,
                              child: ListTile(
                                leading: Icon(Icons.lightbulb_outline,
                                    color: scheme.primary),
                                title: Text(_title(f),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                subtitle: Text(_snippet(f),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: _driver == null
          ? null
          : FloatingActionButton.small(
              onPressed: _newPill,
              tooltip: '新建胶囊',
              child: const Icon(Icons.add),
            ),
    );
  }
}
