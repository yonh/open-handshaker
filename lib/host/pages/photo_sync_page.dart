import 'dart:async';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../photo_sync.dart';
import 'host_shell.dart';

/// 相册同步页与 [PhotoSyncEngine] 之间的最小接缝——widget 测试可注入
/// 假实现，不必真跑同步循环。
abstract class PhotoSyncDriver {
  /// 一轮全量比对：返回本次下载的文件数。
  Future<int> syncOnce();

  /// 开启 FileChange 推送监听（增量保持镜像）。
  Future<void> startMonitoring();

  Future<void> stop();
  Future<void> dispose();
}

/// 默认实现：包一层真正的 [PhotoSyncEngine]。
class EnginePhotoSyncDriver implements PhotoSyncDriver {
  EnginePhotoSyncDriver(this._engine);

  final PhotoSyncEngine _engine;

  @override
  Future<int> syncOnce() => _engine.syncOnce();
  @override
  Future<void> startMonitoring() => _engine.startMonitoring();
  @override
  Future<void> stop() => _engine.stop();
  @override
  Future<void> dispose() => _engine.dispose();
}

/// 相册同步页：选本地目录 → 全量同步 + FileChange 增量镜像，
/// 复刻原版「相册同步」功能。
class PhotoSyncPage extends StatefulWidget {
  const PhotoSyncPage({super.key, this.driverFactory, this.pickDir});

  /// 构造同步引擎；缺省用 [EnginePhotoSyncDriver] + [PhotoSyncEngine]。
  final PhotoSyncDriver Function(String localDir)? driverFactory;

  /// 选本地同步目录；缺省走系统目录选择器。
  final Future<String?> Function()? pickDir;

  @override
  State<PhotoSyncPage> createState() => _PhotoSyncPageState();
}

class _PhotoSyncPageState extends State<PhotoSyncPage> {
  PhotoSyncDriver? _driver;
  String? _localDir;
  bool _running = false;
  bool _syncing = false;
  String? _status;
  int _localFiles = 0;

  Future<String?> _defaultPickDir() =>
      getDirectoryPath(confirmButtonText: '选择同步目录');

  PhotoSyncDriver _defaultFactory(String localDir) {
    final scope = HostScope.of(context);
    final api = scope.controller.api;
    if (api == null) {
      throw StateError('未连接设备');
    }
    return EnginePhotoSyncDriver(PhotoSyncEngine(
      client: api.client,
      api: api,
      localDir: localDir,
      pcId: scope.pcId,
      pushHub: scope.pushHub,
    ));
  }

  int _countLocal(String dir) {
    var n = 0;
    try {
      for (final e
          in Directory(dir).listSync(recursive: true, followLinks: false)) {
        if (e is File && !e.path.split('/').last.startsWith('.')) n++;
      }
    } catch (_) {}
    return n;
  }

  Future<void> _start() async {
    final dir = await (widget.pickDir ?? _defaultPickDir)();
    if (dir == null || !mounted) return;
    setState(() {
      _localDir = dir;
      _syncing = true;
      _status = '正在首次同步…';
    });
    try {
      final driver = (widget.driverFactory ?? _defaultFactory)(dir);
      final n = await driver.syncOnce();
      await driver.startMonitoring();
      if (!mounted) {
        await driver.dispose();
        return;
      }
      setState(() {
        _driver = driver;
        _running = true;
        _localFiles = _countLocal(dir);
        _status = '首次同步完成，下载 $n 个文件，已开启实时监听';
      });
    } catch (e) {
      if (mounted) setState(() => _status = '同步失败：$e');
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _stop() async {
    await _driver?.stop();
    if (mounted) {
      setState(() {
        _running = false;
        _status = '已停止同步';
      });
    }
  }

  Future<void> _syncNow() async {
    final d = _driver;
    if (d == null || _syncing) return;
    setState(() {
      _syncing = true;
      _status = '正在同步…';
    });
    try {
      final n = await d.syncOnce();
      if (mounted) {
        setState(() {
          _localFiles = _countLocal(_localDir!);
          _status = n == 0 ? '已是最新' : '本次下载 $n 个文件';
        });
      }
    } catch (e) {
      if (mounted) setState(() => _status = '同步失败：$e');
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  void dispose() {
    unawaited(_driver?.dispose() ?? Future<void>.value());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar:
          AppBar(title: const Text('相册同步'), automaticallyImplyLeading: false),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.sync,
                          color: _running
                              ? scheme.primary
                              : scheme.outline),
                      const SizedBox(width: 8),
                      Text(_running ? '同步已开启' : '同步未开启',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                      '把手机相册镜像同步到 Mac 本地目录：新增/修改的照片自动下载，'
                      '手机上删除的照片也会从本地移除。',
                      style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 12),
                  if (_localDir != null)
                    Row(children: [
                      const Icon(Icons.folder_outlined, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text('$_localDir（$_localFiles 个文件）',
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ]),
                  if (_status != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(_status!,
                          style: TextStyle(
                              fontSize: 12, color: scheme.outline)),
                    ),
                  if (_syncing)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: LinearProgressIndicator(minHeight: 3),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (!_running)
                        FilledButton.icon(
                          onPressed: _syncing ? null : _start,
                          icon: const Icon(Icons.play_arrow, size: 18),
                          label: const Text('选择目录并开启'),
                        )
                      else ...[
                        FilledButton.tonalIcon(
                          onPressed: _syncing ? null : _syncNow,
                          icon: const Icon(Icons.sync, size: 18),
                          label: const Text('立即同步'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: _stop,
                          icon: const Icon(Icons.stop, size: 18),
                          label: const Text('停止'),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
