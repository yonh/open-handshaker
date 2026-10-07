import 'dart:async';

import 'package:flutter/material.dart';

import '../../ssp/requests.dart';
import '../../ssp/trust_store.dart';
import '../host_controller.dart';
import '../host_controller_impl.dart';
import '../push_hub.dart';
import 'apps_page.dart';
import 'clipboard_page.dart';
import 'connect_page.dart';
import 'files_page.dart';
import 'idea_pills_page.dart';
import 'music_page.dart';
import 'photo_sync_page.dart';
import 'photos_page.dart';
import 'transfers_page.dart';
import 'videos_page.dart';

/// Provides the [HostController] (and UI-level services) to the page tree.
class HostScope extends InheritedWidget {
  HostScope({
    super.key,
    required this.controller,
    required this.appsSource,
    required this.clipboardSync,
    required super.child,
  });

  final HostController controller;
  final AppsSource appsSource;
  final ClipboardSync clipboardSync;

  final _PushHubCache _hubCache = _PushHubCache();

  /// 推送消息订阅入口：连接后按当前 api 的底层 SspClient 惰性构造。
  /// 未连接 / mock 返回 null，页面按“无推送”降级。
  PushHub? get pushHub {
    final api = controller.api;
    if (api == null) return null;
    if (!identical(api, _hubCache.api)) {
      unawaited(_hubCache.hub?.dispose());
      _hubCache.api = api;
      _hubCache.hub = PushHub(api.client);
    }
    return _hubCache.hub;
  }

  /// PhotoSync 的 pcId：真实连接层暴露 identity；mock 用常量。
  String get pcId {
    final c = controller;
    return c is HostControllerImpl ? c.identity.hostUuid : 'demo-host';
  }

  /// 非依赖式读取：页面 initState/异步回调里也能安全调用。scope 字段
  /// 构造后不再变化，不需要 rebuild 传播。
  static HostScope of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<HostScope>()!;

  @override
  bool updateShouldNotify(HostScope old) =>
      controller != old.controller ||
      appsSource != old.appsSource ||
      clipboardSync != old.clipboardSync;
}

/// Mutable PushHub cache kept out of the widget's field list so
/// [HostScope] stays immutable.
class _PushHubCache {
  SspApi? api;
  PushHub? hub;
}

/// Root host app: builds the [MaterialApp] + [HostScope] + [HostShell].
class HostApp extends StatelessWidget {
  const HostApp({
    super.key,
    required this.controller,
    this.appsSource,
    this.clipboardSync,
    this.navigatorObservers,
  });

  final HostController controller;

  /// Source for the apps page; defaults to a wire source that reports the
  /// "unsupported until the protocol grows an app-list op" empty state.
  final AppsSource? appsSource;

  /// Global clipboard-sync service; a default one is created when null.
  final ClipboardSync? clipboardSync;

  final List<NavigatorObserver>? navigatorObservers;

  @override
  Widget build(BuildContext context) {
    final sync = clipboardSync ?? ClipboardSync(controller);
    return HostScope(
      controller: controller,
      appsSource: appsSource ?? WireAppsSource(),
      clipboardSync: sync,
      child: MaterialApp(
        title: 'HandShaker Open',
        debugShowCheckedModeBanner: false,
        navigatorObservers: navigatorObservers ?? const [],
        theme: ThemeData(
          colorScheme:
              ColorScheme.fromSeed(seedColor: const Color(0xFF5B7EF7)),
          useMaterial3: true,
        ),
        home: HostShell(controller: controller),
      ),
    );
  }
}

/// Connection gate + sidebar layout. Rebuilds on every [ConnState] change.
class HostShell extends StatefulWidget {
  const HostShell({super.key, required this.controller});

  final HostController controller;

  @override
  State<HostShell> createState() => _HostShellState();
}

class _HostShellState extends State<HostShell> {
  StreamSubscription<ConnState>? _sub;
  StreamSubscription<PairingPrompt>? _promptSub;
  ConnState _state = ConnState.disconnected;
  int _tab = 0;

  static const _tabs = [
    (Icons.photo_library_outlined, '照片'),
    (Icons.music_note_outlined, '音乐'),
    (Icons.movie_outlined, '视频'),
    (Icons.folder_outlined, '文件'),
    (Icons.apps_outlined, '应用'),
    (Icons.content_paste_outlined, '剪贴板'),
    (Icons.sync_alt, '相册同步'),
    (Icons.lightbulb_outline, '闪念胶囊'),
    (Icons.swap_vert, '传输'),
  ];

  @override
  void initState() {
    super.initState();
    _state = widget.controller.state;
    _sub = widget.controller.stateStream.listen((s) {
      if (mounted) setState(() => _state = s);
    });
    _promptSub = widget.controller.pairingPrompts.listen((p) {
      if (mounted) unawaited(_showPairing(p));
    });
    if (_state == ConnState.disconnected) {
      unawaited(widget.controller.startDiscovery());
    }
  }

  Future<void> _showPairing(PairingPrompt p) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('信任此设备？'),
        content: Text(
            '首次连接「${p.candidate.label}」(${p.candidate.address})。\n'
            '信任后双方将完成配对，手机端也需确认。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('信任并连接'),
          ),
        ],
      ),
    );
    if (!p.completer.isCompleted) p.completer.complete(ok ?? false);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _promptSub?.cancel();
    super.dispose();
  }

  Widget _body() {
    switch (_tab) {
      case 0:
        return const PhotosPage();
      case 1:
        return const MusicPage();
      case 2:
        return const VideosPage();
      case 3:
        return const FilesPage();
      case 4:
        return const AppsPage();
      case 5:
        return const ClipboardPage();
      case 6:
        return const PhotoSyncPage();
      case 7:
        return const IdeaPillsPage();
      case 8:
        return const TransfersPage();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_state != ConnState.connected) {
      return ConnectPage(controller: widget.controller, state: _state);
    }
    final device = widget.controller.connectedDevice;
    return Scaffold(
      body: Row(
        children: [
          _sidebar(device),
          const VerticalDivider(width: 1),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _sidebar(TrustedDevice? device) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: SizedBox(
        width: 200,
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.phonelink,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('HandShaker',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: [
                for (var i = 0; i < _tabs.length; i++) _navItem(i),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.smartphone, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(device?.deviceName ?? '已连接设备',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.link_off, size: 16),
                    label: const Text('断开连接'),
                    onPressed: () =>
                        unawaited(widget.controller.disconnect()),
                  ),
                ),
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int i) {
    final (icon, label) = _tabs[i];
    final selected = _tab == i;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: ListTile(
        dense: true,
        selected: selected,
        selectedTileColor: scheme.primaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        leading: Icon(icon,
            size: 20,
            color: selected ? scheme.primary : scheme.onSurfaceVariant),
        title: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected ? scheme.primary : scheme.onSurface)),
        onTap: () => setState(() => _tab = i),
      ),
    );
  }
}
