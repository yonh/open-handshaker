import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../agent/agent_service.dart';
import '../agent/providers/channel_providers.dart';
import '../ssp/server.dart'
    show AgentIdentity, PairingRequest, TrustDecision;
import '../ssp/trust_store.dart';

/// Android/iOS 端 agent 壳：前台服务开关、配对审批、连接指引。
/// Host 端（macOS/Windows）管理 UI 在 lib/host/pages/。
class AgentApp extends StatefulWidget {
  const AgentApp({super.key, this.agent});

  /// Injectable for widget tests; null → construct a live AgentService.
  final AgentService? agent;

  @override
  State<AgentApp> createState() => _AgentAppState();
}

class _AgentAppState extends State<AgentApp> {
  AgentService? _agent;
  bool _running = false;
  String? _error;
  List<String> _localIps = [];
  StreamSubscription<PairingRequest>? _pairingSub;
  final _channels = ChannelProviders();
  // Dialogs need a context below MaterialApp — the state context isn't one.
  final _navKey = GlobalKey<NavigatorState>();

  Future<AgentService> _ensureAgent() async {
    final a = _agent ??= widget.agent ?? AgentService(channels: _channels);
    return a;
  }

  @override
  void dispose() {
    _pairingSub?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() => _error = null);
    try {
      final agent = await _ensureAgent();
      _uuid = await _deviceUuid();
      await agent.start(
        identity: AgentIdentity(
          deviceUuid: _uuid,
          deviceName: _deviceName,
        ),
        hostTrustStore: HostTrustStore('${await _dataDir()}/hosts.json'),
        onPairingRequest: (req, pending) {
          if (!mounted) return null;
          _showPairingDialog(req, pending);
          return null;
        },
      );
      await _channels.startService(title: 'HandShaker', text: '互联服务运行中');
      _localIps = await _wifiIps();
      if (mounted) setState(() => _running = true);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  Future<void> _stop() async {
    await _agent?.stop();
    await _channels.stopService();
    if (mounted) setState(() => _running = false);
  }

  Future<String> _deviceUuid() async {
    // Stable-enough device id for pairing; Android real value comes from
    // ANDROID_ID via getDeviceInfo — pairing just needs persistence.
    final dir = await _dataDir();
    final f = File('$dir/device.uuid');
    if (f.existsSync()) return f.readAsStringSync().trim();
    final id = DateTime.now().microsecondsSinceEpoch.toRadixString(16) +
        UniqueKey().hashCode.toRadixString(16);
    f.writeAsStringSync(id);
    return id;
  }

  Future<String> _dataDir() async {
    // Persist identity/trust under app support (survives restarts); fall
    // back to a fixed temp subdir where plugin channels are unavailable.
    try {
      final dir = await getApplicationSupportDirectory();
      final d = Directory('${dir.path}/agent');
      if (!d.existsSync()) await d.create(recursive: true);
      return d.path;
    } catch (_) {
      final d = Directory('${Directory.systemTemp.path}/handshaker_agent');
      if (!d.existsSync()) d.createSync(recursive: true);
      return d.path;
    }
  }

  Future<List<String>> _wifiIps() async {
    final ips = <String>[];
    try {
      for (final nif in await NetworkInterface.list(
          type: InternetAddressType.IPv4, includeLinkLocal: false)) {
        for (final a in nif.addresses) {
          if (!a.isLoopback) ips.add(a.address);
        }
      }
    } catch (_) {}
    return ips;
  }

  /// QR 内容：`handshaker://connect?ip=..&port=..&name=..&uuid=..` —
  /// 承载 legacy 探测端口 + 设备标识（原版为 t.tt 短链，格式见
  /// docs/PROTOCOL.md「待验证」标注）。
  String _qrPayload() {
    final ip = _localIps.isNotEmpty ? _localIps.first : '';
    return 'handshaker://connect?ip=$ip'
        '&port=${AgentService.portLegacy}'
        '&name=${Uri.encodeComponent(_deviceName)}'
        '&uuid=$_uuid';
  }

  String _uuid = '';

  /// Platform-aware fallback name — the Kotlin channel may override it via
  /// getDeviceInfo, but pairing/QR need something sensible on iOS too.
  String get _deviceName =>
      Platform.isAndroid ? 'Android 设备' : 'iOS 设备';

  void _showPairingDialog(PairingRequest req, Completer<TrustDecision> done) {
    showDialog<void>(
      context: _navKey.currentContext ?? context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('新的连接请求'),
        content: Text('「${req.hostName}」(${req.hostUuid})\n想要连接此设备。'),
        actions: [
          TextButton(
            onPressed: () {
              if (!done.isCompleted) done.complete(TrustDecision.deny);
              Navigator.pop(ctx);
            },
            child: const Text('拒绝'),
          ),
          TextButton(
            onPressed: () {
              if (!done.isCompleted) done.complete(TrustDecision.once);
              Navigator.pop(ctx);
            },
            child: const Text('允许一次'),
          ),
          FilledButton(
            onPressed: () {
              if (!done.isCompleted) done.complete(TrustDecision.always);
              Navigator.pop(ctx);
            },
            child: const Text('始终信任'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navKey,
      title: 'HandShaker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5B7EF7)),
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('HandShaker')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          Card(
            child: SwitchListTile(
              title: const Text('互联服务'),
              subtitle: Text(_running
                  ? '运行中 · :${AgentService.portModern}/:${AgentService.portLegacy}'
                  : '已停止'),
              value: _running,
              onChanged: (v) => v ? _start() : _stop(),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(_error!,
                  style: const TextStyle(color: Colors.red)),
            ),
          if (_localIps.isNotEmpty)
            Card(
              child: ListTile(
                leading: const Icon(Icons.wifi),
                title: const Text('本机地址'),
                subtitle: Text(_localIps.join('  ')),
              ),
            ),
          const SizedBox(height: 16),
          if (_running && _localIps.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  const Text('扫码配对',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  QrImageView(
                    data: _qrPayload(),
                    size: 180,
                  ),
                  const SizedBox(height: 8),
                  Text('电脑端 HandShaker 扫一扫连接',
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 12)),
                ]),
              ),
            ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('连接 Mac / Windows',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(Platform.isAndroid
                      ? '1. 两端连上同一 Wi-Fi 网络\n'
                          '2. 打开电脑端 HandShaker，选择此设备\n'
                          '3. 在弹出的配对请求中选择「始终信任」\n'
                          '4. 也可以插上数据线走 USB 连接（需开启 USB 调试）'
                      : '1. 两端连上同一 Wi-Fi 网络\n'
                          '2. 打开电脑端 HandShaker，选择此设备\n'
                          '3. 在弹出的配对请求中选择「始终信任」'),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
