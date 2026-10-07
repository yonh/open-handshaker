import 'dart:async';

import 'package:flutter/material.dart';

import '../host_controller.dart';

/// Welcome + device-connection guide shown while [state] is not
/// [ConnState.connected]. Two entries (USB / Wi-Fi), live candidate list,
/// manual IP connect and a ConnState state-machine visualization.
class ConnectPage extends StatefulWidget {
  const ConnectPage({super.key, required this.controller, required this.state});

  final HostController controller;
  final ConnState state;

  @override
  State<ConnectPage> createState() => _ConnectPageState();
}

class _ConnectPageState extends State<ConnectPage> {
  StreamSubscription<List<DeviceCandidate>>? _sub;
  List<DeviceCandidate> _candidates = [];
  bool _usbTab = false;
  final _ipCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _candidates = widget.controller.candidates;
    _sub = widget.controller.candidatesStream.listen((l) {
      if (mounted) setState(() => _candidates = l);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _ipCtl.dispose();
    super.dispose();
  }

  List<DeviceCandidate> get _visible => _candidates
      .where((c) => _usbTab
          ? c.source == DiscoverySource.usb
          : c.source != DiscoverySource.usb)
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(32),
            children: [
              _header(),
              const SizedBox(height: 24),
              _stateViz(),
              const SizedBox(height: 24),
              if (widget.state == ConnState.reconnecting) _reconnectBanner(),
              if (widget.state == ConnState.handshaking ||
                  widget.state == ConnState.pairing)
                _busyBanner(),
              _entries(),
              const SizedBox(height: 16),
              _candidateList(),
              if (!_usbTab) _manualEntry(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Column(
      children: [
        Icon(Icons.phonelink_ring,
            size: 56, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 12),
        const Text('欢迎使用 HandShaker',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text('通过 USB 或 Wi-Fi 将手机连接到这台 Mac，即可管理照片、音乐、视频与文件。',
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.outline)),
      ],
    );
  }

  /// ConnState 状态机可视化：未连接→扫描中→握手→配对→已连接，重连单独标记。
  Widget _stateViz() {
    const steps = [
      (ConnState.disconnected, '未连接', Icons.link_off),
      (ConnState.discovering, '扫描中', Icons.radar),
      (ConnState.handshaking, '握手', Icons.handshake_outlined),
      (ConnState.pairing, '配对确认', Icons.verified_user_outlined),
      (ConnState.connected, '已连接', Icons.link),
    ];
    final s = widget.state;
    final activeIdx = s == ConnState.reconnecting
        ? 1
        : steps.indexWhere((e) => e.$1 == s).clamp(0, steps.length - 1);
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            for (var i = 0; i < steps.length; i++) ...[
              Expanded(
                child: Column(
                  children: [
                    Icon(steps[i].$3,
                        size: 20,
                        color: i <= activeIdx
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outline),
                    const SizedBox(height: 4),
                    Text(steps[i].$2,
                        style: TextStyle(
                            fontSize: 11,
                            color: i <= activeIdx
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.outline)),
                  ],
                ),
              ),
              if (i < steps.length - 1)
                Expanded(
                  child: Divider(
                    indent: 4,
                    endIndent: 4,
                    color: i < activeIdx
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _reconnectBanner() {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: ListTile(
        leading: const Icon(Icons.sync_problem),
        title: const Text('连接中断，正在自动重连…'),
        trailing: TextButton(
          onPressed: () => unawaited(widget.controller.disconnect()),
          child: const Text('取消'),
        ),
      ),
    );
  }

  Widget _busyBanner() {
    final pairing = widget.state == ConnState.pairing;
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: ListTile(
        leading: const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2)),
        title: Text(pairing ? '请在手机上确认配对…' : '正在握手…'),
        subtitle:
            pairing ? const Text('手机端弹出信任确认框，确认后完成连接') : null,
      ),
    );
  }

  Widget _entries() {
    return SegmentedButton<bool>(
      segments: const [
        ButtonSegment(
            value: false,
            icon: Icon(Icons.wifi),
            label: Text('Wi-Fi 连接')),
        ButtonSegment(
            value: true,
            icon: Icon(Icons.usb),
            label: Text('USB 连接')),
      ],
      selected: {_usbTab},
      onSelectionChanged: (s) => setState(() => _usbTab = s.first),
    );
  }

  Widget _candidateList() {
    final list = _visible;
    final hint = _usbTab
        ? '通过数据线连接 Android 手机（需开启 USB 调试），识别后点按即可连接。'
        : '手机与电脑在同一局域网内时会被自动发现；也可以手动输入手机 IP。';
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(hint,
                      style: TextStyle(
                          fontSize: 12,
                          color:
                              Theme.of(context).colorScheme.outline)),
                ),
                IconButton(
                  tooltip: '重新扫描',
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: () =>
                      unawaited(widget.controller.startDiscovery()),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (list.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: widget.state == ConnState.discovering
                      ? const Text('正在扫描设备…')
                      : const Text('尚未发现设备'),
                ),
              )
            else
              for (final c in list) _candidateTile(c),
          ],
        ),
      ),
    );
  }

  Widget _candidateTile(DeviceCandidate c) {
    return ListTile(
      leading: Icon(c.source == DiscoverySource.usb
          ? Icons.usb
          : Icons.wifi),
      title: Text(c.label),
      subtitle: Text('${c.address}:${c.port}'),
      trailing: FilledButton.tonal(
        onPressed: () => unawaited(widget.controller.connect(c)),
        child: const Text('连接'),
      ),
    );
  }

  Widget _manualEntry() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _ipCtl,
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
                labelText: '手机 IP 地址',
                hintText: '例如 192.168.1.23',
              ),
              onSubmitted: (_) => _connectManual(),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonal(
            onPressed: _connectManual,
            child: const Text('连接'),
          ),
        ],
      ),
    );
  }

  void _connectManual() {
    final addr = _ipCtl.text.trim();
    if (addr.isEmpty) return;
    unawaited(widget.controller.connectManual(addr));
  }
}
