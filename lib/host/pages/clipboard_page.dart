import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../ssp/requests.dart';
import '../host_controller.dart';
import 'host_shell.dart';

/// UI-level bidirectional clipboard sync. HostController 没有内建
/// clipboardSync 开关，按交付约定由 UI 自行管理：启用后定时拉取手机
/// 剪贴板写回本机，并监听本机剪贴板变化推送到手机；连接提供 PushHub
/// 时同时也会订阅 clipboardChanges 推送即时刷新。
class ClipboardSync extends ChangeNotifier {
  ClipboardSync(
    this.controller, {
    this.interval = const Duration(seconds: 3),
    Future<String?> Function()? readLocal,
    Future<void> Function(String)? writeLocal,
  })  : _readLocal = readLocal ?? _defaultReadLocal,
        _writeLocal = writeLocal ?? _defaultWriteLocal;

  final HostController controller;

  /// 轮询间隔（Widget 测试可注入更小的值）。
  final Duration interval;

  final Future<String?> Function() _readLocal;
  final Future<void> Function(String) _writeLocal;

  static Future<String?> _defaultReadLocal() async {
    try {
      final d = await Clipboard.getData('text/plain');
      return d?.text;
    } catch (_) {
      return null;
    }
  }

  static Future<void> _defaultWriteLocal(String text) =>
      Clipboard.setData(ClipboardData(text: text));

  Timer? _timer;
  StreamSubscription<dynamic>? _pushSub;
  bool _enabled = false;
  bool _busy = false;

  /// 最近一次同步到的手机端文本（用于本机读取去重，避免回环）。
  String? _remoteText;

  /// 最近一次同步到的本机文本。
  String? _localText;

  Object? lastError;

  bool get enabled => _enabled;
  String? get remoteText => _remoteText;
  String? get localText => _localText;

  Future<void> setEnabled(bool v) async {
    if (v == _enabled) return;
    _enabled = v;
    _timer?.cancel();
    _timer = null;
    if (v) {
      _timer = Timer.periodic(interval, (_) => unawaited(tick()));
      unawaited(tick());
    }
    notifyListeners();
  }

  /// 订阅 PushHub 的剪贴板变更推送（可选；没有则只靠轮询）。
  void watchRemoteChanges(Stream<dynamic>? changes) {
    _pushSub?.cancel();
    _pushSub = changes?.listen((_) => unawaited(pullRemote()));
  }

  /// 拉手机剪贴板 → 本机。
  Future<String?> pullRemote() async {
    final api = controller.api;
    if (api == null) return null;
    try {
      final clips = await api.getClipboard();
      String? newest;
      var newestMs = -1;
      for (final c in clips) {
        String t;
        try {
          t = SspApi.clipboardContentToText(c);
        } catch (_) {
          continue;
        }
        if (t.isEmpty) continue;
        final ms = c.mstimestamp.toInt();
        if (ms >= newestMs) {
          newestMs = ms;
          newest = t;
        }
      }
      if (newest != null && newest != _remoteText) {
        _remoteText = newest;
        await _writeLocal(newest);
        _localText = newest;
        notifyListeners();
      }
      return newest;
    } catch (e) {
      lastError = e;
      return null;
    }
  }

  /// 一轮同步：先拉远端，再检查本机是否变化需推送。
  Future<void> tick() async {
    if (_busy || !_enabled) return;
    _busy = true;
    try {
      await pullRemote();
      final local = await _readLocal();
      if (local != null &&
          local.isNotEmpty &&
          local != _localText &&
          local != _remoteText) {
        await controller.api?.postClipboardText(local);
        _localText = local;
        _remoteText = local;
        notifyListeners();
      }
    } finally {
      _busy = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pushSub?.cancel();
    super.dispose();
  }
}

/// 剪贴板页：显示手机剪贴板文本、发送文本到手机、全局同步开关。
class ClipboardPage extends StatefulWidget {
  const ClipboardPage({super.key});

  @override
  State<ClipboardPage> createState() => _ClipboardPageState();
}

class _ClipboardPageState extends State<ClipboardPage> {
  final _text = TextEditingController();
  List<String> _clips = [];
  bool _loading = false;
  String? _status;

  HostController get _controller => HostScope.of(context).controller;
  ClipboardSync get _sync => HostScope.of(context).clipboardSync;

  @override
  void initState() {
    super.initState();
    unawaited(_reload());
    // 有推送通道时直接订阅，远端一变就刷新列表。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _sync.watchRemoteChanges(
          HostScope.of(context).pushHub?.clipboardChanges);
    });
  }

  Future<void> _reload() async {
    final api = _controller.api;
    if (api == null) return;
    setState(() => _loading = true);
    try {
      final clips = await api.getClipboard();
      final items = <({String text, int ms})>[];
      for (final c in clips) {
        String t;
        try {
          t = SspApi.clipboardContentToText(c);
        } catch (_) {
          continue;
        }
        if (t.isNotEmpty) {
          items.add((text: t, ms: c.mstimestamp.toInt()));
        }
      }
      items.sort((a, b) => b.ms.compareTo(a.ms));
      if (mounted) {
        setState(() => _clips = items.map((e) => e.text).toList());
      }
    } catch (e) {
      if (mounted) setState(() => _status = '读取失败：$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _text.text;
    if (text.isEmpty) return;
    final api = _controller.api;
    if (api == null) return;
    try {
      final ok = await api.postClipboardText(text);
      if (!ok) {
        setState(() => _status = '发送失败：设备未接受');
        return;
      }
      _text.clear();
      setState(() => _status = '已发送到手机');
      await _reload();
    } catch (e) {
      setState(() => _status = '发送失败：$e');
    }
  }

  Future<void> _clear() async {
    try {
      await _controller.api?.clearClipboard();
      setState(() {
        _clips = [];
        _status = '已清空手机剪贴板';
      });
    } catch (e) {
      setState(() => _status = '清空失败：$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('剪贴板'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
            onPressed: _reload,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListenableBuilder(
            listenable: _sync,
            builder: (context, _) => SwitchListTile(
              title: const Text('剪贴板同步'),
              subtitle:
                  const Text('开启后自动双向同步 Mac 与手机的剪贴板'),
              value: _sync.enabled,
              onChanged: (v) => unawaited(_sync.setEnabled(v)),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('发送到手机',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _text,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: '输入要发送到手机剪贴板的文本',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      FilledButton.icon(
                        onPressed: _send,
                        icon: const Icon(Icons.send, size: 16),
                        label: const Text('发送'),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: _clear,
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: const Text('清空手机剪贴板'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (_status != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(_status!,
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.outline)),
            ),
          const SizedBox(height: 8),
          const Text('手机剪贴板',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          if (_clips.isEmpty && !_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('手机剪贴板为空')),
            )
          else
            for (final c in _clips)
              Card(
                elevation: 0,
                child: ListTile(
                  dense: true,
                  title: SelectableText(c),
                  trailing: IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    tooltip: '复制到本机',
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: c));
                      if (context.mounted) {
                        setState(() => _status = '已复制到本机剪贴板');
                      }
                    },
                  ),
                ),
              ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }
}
