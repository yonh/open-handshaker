import 'dart:async';
import 'dart:io';

import '../ssp/client.dart';
import '../ssp/requests.dart';
import '../ssp/transport.dart';
import '../ssp/trust_store.dart';
import 'discovery/usb_discovery.dart';
import 'discovery/wifi_discovery.dart';
import 'host_controller.dart';

/// Real [HostController]: Wi-Fi scan + adb probe discovery, SSP handshake
/// with first-connect approval, TrustedDevice persistence, auto-reconnect,
/// and a queued transfer facade.
class HostControllerImpl extends HostController {
  HostControllerImpl({
    required this.identity,
    required this.trustStore,
    WifiDiscovery? wifi,
    UsbDiscovery? usb,
    this.discoveryInterval = const Duration(seconds: 6),
    this.reconnectInterval = const Duration(seconds: 5),
    this.scanPort = 10086,
    this.servicePort = 10088,
  })  : wifi = wifi ?? WifiDiscovery(),
        usb = usb ?? UsbDiscovery();

  final HostIdentity identity;
  final TrustStore trustStore;
  final WifiDiscovery wifi;
  final UsbDiscovery usb;
  final Duration discoveryInterval;
  final Duration reconnectInterval;

  /// Legacy port probed during Wi-Fi scan (the original app scans :10086).
  final int scanPort;

  /// Modern SSP port connections use.
  final int servicePort;

  final _stateCtl = StreamController<ConnState>.broadcast();
  final _candidatesCtl = StreamController<List<DeviceCandidate>>.broadcast();
  final _promptsCtl = StreamController<PairingPrompt>.broadcast();
  final _transfersCtl = StreamController<List<TransferTask>>.broadcast();

  ConnState _state = ConnState.disconnected;
  final Map<String, DeviceCandidate> _candidates = {};
  final List<TransferTask> _transfers = [];
  final List<TransferTask> _doneTasks = [];

  Timer? _discoveryTimer;
  Timer? _reconnectTimer;
  bool _autoReconnect = true;
  bool _discovering = false;
  bool _closed = false;

  SspClient? _client;
  SspApi? _api;
  DeviceCandidate? _activeCandidate;
  int _transferSeq = 0;

  @override
  ConnState get state => _state;
  @override
  Stream<ConnState> get stateStream => _stateCtl.stream;
  @override
  List<DeviceCandidate> get candidates => _candidates.values.toList();
  @override
  Stream<List<DeviceCandidate>> get candidatesStream => _candidatesCtl.stream;
  @override
  Stream<PairingPrompt> get pairingPrompts => _promptsCtl.stream;
  @override
  SspApi? get api => _api;
  @override
  TrustedDevice? get connectedDevice => _client?.trustedDevice;
  @override
  List<TransferTask> get transfers =>
      List.unmodifiable([..._transfers, ..._doneTasks.reversed]);
  @override
  Stream<List<TransferTask>> get transfersStream => _transfersCtl.stream;
  @override
  set autoReconnect(bool v) => _autoReconnect = v;

  void _setState(ConnState s) {
    if (_state == s) return;
    _state = s;
    if (!_closed) _stateCtl.add(s);
  }

  void _publishCandidates() {
    if (!_closed) _candidatesCtl.add(candidates);
  }

  void _publishTransfers() {
    if (!_closed) _transfersCtl.add(transfers);
  }

  // ---------------- discovery ----------------

  @override
  Future<void> startDiscovery() async {
    await trustStore.load();
    if (_discovering) return;
    _discovering = true;
    if (_state == ConnState.disconnected) _setState(ConnState.discovering);
    _discoveryTimer ??=
        Timer.periodic(discoveryInterval, (_) => unawaited(_scanOnce()));
    await _scanOnce();
  }

  Future<void> _scanOnce() async {
    if (_closed) return;
    final results = await Future.wait([wifi.scan(), usb.scan()]);
    var changed = false;
    for (final list in results) {
      for (final c in list) {
        if (!_candidates.containsKey(c.id)) changed = true;
        _candidates[c.id] = c;
      }
    }
    // Evict vanished non-manual candidates while disconnected.
    if (_state == ConnState.disconnected ||
        _state == ConnState.discovering) {
      final liveIds = {for (final l in results) for (final c in l) c.id};
      final stale = _candidates.keys
          .where((id) =>
              !liveIds.contains(id) &&
              !id.startsWith('manual:') &&
              _activeCandidate?.id != id)
          .toList();
      for (final id in stale) {
        _candidates.remove(id);
        changed = true;
      }
    }
    if (changed) _publishCandidates();
  }

  Future<void> stopDiscovery() async {
    _discoveryTimer?.cancel();
    _discoveryTimer = null;
    _discovering = false;
  }

  // ---------------- connect ----------------

  @override
  Future<void> connectManual(String address, {int port = 10088}) =>
      connect(DeviceCandidate(
        id: 'manual:$address:$port',
        label: address,
        address: address,
        port: port,
        source: DiscoverySource.manual,
      ));

  @override
  Future<void> connect(DeviceCandidate candidate) async {
    _reconnectTimer?.cancel();
    _activeCandidate = candidate;
    _setState(ConnState.handshaking);
    SspClient? client;
    try {
      final ch =
          await SocketChannel.connect(candidate.address, candidate.port);
      client = SspClient(ch, identity: identity, trustStore: trustStore);
      client.onDisconnected = () => unawaited(_onLinkDown());

      final result = await client.handshake(
        approveUnknownDevice: (device) {
          _setState(ConnState.pairing);
          final c = Completer<bool>();
          _promptsCtl.add(PairingPrompt(candidate: candidate, completer: c));
          return c.future;
        },
        onTrustWaiting: () => _setState(ConnState.pairing),
      );
      _client = client;
      _api = SspApi(client);
      // Refresh the candidate label with the real device name.
      _candidates[candidate.id] = DeviceCandidate(
        id: candidate.id,
        label: result.response01.deviceName.isNotEmpty
            ? result.response01.deviceName
            : candidate.label,
        address: candidate.address,
        port: candidate.port,
        source: candidate.source,
        deviceUuid: result.response01.deviceUuid,
      );
      _publishCandidates();
      _setState(ConnState.connected);
    } catch (_) {
      await client?.close().catchError((_) {});
      if (_autoReconnect &&
          candidate.source != DiscoverySource.manual &&
          !_closed) {
        _setState(ConnState.reconnecting);
        _scheduleReconnect();
      } else {
        _setState(_discovering ? ConnState.discovering : ConnState.disconnected);
        _activeCandidate = null;
      }
      rethrow;
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer =
        Timer(reconnectInterval, () => unawaited(_tryReconnect()));
  }

  Future<void> _tryReconnect() async {
    final c = _activeCandidate;
    if (c == null || _closed || _state == ConnState.connected) return;
    try {
      await connect(c);
    } catch (_) {
      // connect() already moved us to reconnecting and re-scheduled.
    }
  }

  Future<void> _onLinkDown() async {
    if (_closed || _state != ConnState.connected) return;
    _api = null;
    _client = null;
    if (_autoReconnect) {
      _setState(ConnState.reconnecting);
      _scheduleReconnect();
    } else {
      _setState(_discovering ? ConnState.discovering : ConnState.disconnected);
    }
  }

  @override
  Future<void> disconnect() async {
    _autoReconnect = false;
    _reconnectTimer?.cancel();
    _activeCandidate = null;
    await _client?.close().catchError((_) {});
    _client = null;
    _api = null;
    _setState(_discovering ? ConnState.discovering : ConnState.disconnected);
  }

  @override
  Future<void> revokeTrust(String deviceUuid) async {
    trustStore.remove(deviceUuid);
    await trustStore.save();
  }

  // ---------------- transfers ----------------

  TransferTask _enqueue(String name, int total, {required bool isUpload}) {
    final t = TransferTask(
        id: 't${++_transferSeq}', name: name, total: total, isUpload: isUpload);
    _transfers.add(t);
    _publishTransfers();
    return t;
  }

  void _finish(TransferTask t, [Object? error]) {
    _transfers.remove(t);
    if (error != null) {
      t.error = error.toString();
    } else {
      t.completed = true;
      t.done = t.total;
    }
    _doneTasks.add(t);
    if (_doneTasks.length > 100) _doneTasks.removeAt(0);
    _publishTransfers();
  }

  @override
  Future<void> downloadFile(String remotePath, String localPath,
      {String? taskName}) async {
    final client = _client;
    if (client == null) throw StateError('not connected');
    var t = _enqueue(taskName ?? remotePath.split('/').last, 0,
        isUpload: false);
    try {
      await client.download(remotePath, localPath,
          onProgress: (done, total) {
        if (t.total == 0) t = _replaceTotal(t, total);
        t.done = done;
        _publishTransfers();
      });
      _finish(t);
    } catch (e) {
      _finish(t, e);
      rethrow;
    }
  }

  @override
  Future<void> uploadFile(String localPath, String remotePath,
      {String? taskName}) async {
    final client = _client;
    if (client == null) throw StateError('not connected');
    final total = await File(localPath).length();
    final t = _enqueue(taskName ?? localPath.split('/').last, total,
        isUpload: true);
    try {
      await client.upload(localPath, remotePath, onProgress: (done, _) {
        t.done = done;
        _publishTransfers();
      });
      _finish(t);
    } catch (e) {
      _finish(t, e);
      rethrow;
    }
  }

  TransferTask _replaceTotal(TransferTask t, int total) {
    final idx = _transfers.indexOf(t);
    final nt = TransferTask(
        id: t.id, name: t.name, total: total, isUpload: t.isUpload)
      ..done = t.done
      ..completed = t.completed
      ..error = t.error;
    if (idx >= 0) _transfers[idx] = nt;
    return nt;
  }

  @override
  Future<void> dispose() async {
    _closed = true;
    _discoveryTimer?.cancel();
    _reconnectTimer?.cancel();
    await _client?.close().catchError((_) {});
    await _stateCtl.close();
    await _candidatesCtl.close();
    await _promptsCtl.close();
    await _transfersCtl.close();
  }
}
