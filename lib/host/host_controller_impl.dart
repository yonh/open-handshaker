import 'dart:async';
import 'dart:io';

import '../ssp/client.dart';
import '../ssp/requests.dart';
import '../ssp/transport.dart';
import '../ssp/trust_store.dart';
import 'discovery/usb_discovery.dart';
import 'discovery/wifi_discovery.dart';
import 'host_controller.dart';
import 'push_hub.dart';

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
  PushHub? _hub;
  DeviceCandidate? _activeCandidate;
  int _transferSeq = 0;

  /// Typed push stream for the live connection (MonitorFolder events,
  /// FileChange, library/clipboard changes). Null while disconnected.
  PushHub? get pushHub {
    final c = _client;
    if (c == null) return null;
    return _hub ??= PushHub(c);
  }

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
    // Tear down a previous link so its stale disconnect signal can't
    // kill the new session, and re-arm auto-reconnect for manual connects.
    final old = _client;
    _client = null;
    _api = null;
    if (old != null) {
      old.onDisconnected = null;
      unawaited(old.close().catchError((_) {}));
    }
    _autoReconnect = true;
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
    unawaited(_hub?.dispose());
    _hub = null;
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
    unawaited(_hub?.dispose());
    _hub = null;
    _setState(_discovering ? ConnState.discovering : ConnState.disconnected);
  }

  @override
  Future<void> revokeTrust(String deviceUuid) async {
    trustStore.remove(deviceUuid);
    await trustStore.save();
  }

  // ---------------- transfer center ----------------

  /// How many transfers may run at once (queue drains the rest).
  int maxConcurrentTransfers = 2;
  final _queue = <TransferTask>[];
  final _abortFlags = <String, bool>{};
  final _pauseFlags = <String, bool>{};

  @override
  List<TransferTask> get transfers => List.unmodifiable(
      [..._transfers, ..._queue, ..._doneTasks.reversed]);

  TransferTask _enqueue(TransferTask t) {
    _queue.add(t..waiting = true);
    _publishTransfers();
    unawaited(_pump());
    return t;
  }

  Future<void> _pump() async {
    while (_transfers.length < maxConcurrentTransfers && _queue.isNotEmpty) {
      final t = _queue.removeAt(0)..waiting = false;
      _transfers.add(t);
      _publishTransfers();
      unawaited(_run(t));
    }
  }

  Future<void> _run(TransferTask t) async {
    final client = _client;
    if (client == null) {
      _finish(t, StateError('not connected'));
      return;
    }
    bool cancelled() => _abortFlags[t.id] == true || _pauseFlags[t.id] == true;
    try {
      if (t.isUpload) {
        await client.upload(t.localPath, t.remotePath, cancelled: cancelled,
            onProgress: (done, total) {
          t.done = done;
          _publishTransfers();
        });
      } else {
        final tmp = SspClient.downloadTmpPath(t.localPath);
        final offset = File(tmp).existsSync() ? File(tmp).lengthSync() : 0;
        t.done = offset;
        await client.download(t.remotePath, t.localPath,
            offset: offset, cancelled: cancelled,
            onProgress: (done, total) {
          if (t.total == 0) _setTotal(t, offset + total);
          t.done = offset + done;
          _publishTransfers();
        });
      }
      if (_pauseFlags[t.id] == true) {
        t.paused = true;
        _transfers.remove(t);
        _doneTasks.add(t);
      } else if (_abortFlags[t.id] == true) {
        t.cancelled = true;
        _transfers.remove(t);
        _doneTasks.add(t);
      } else {
        _finish(t);
      }
    } catch (e) {
      if (_pauseFlags[t.id] == true) {
        t.paused = true;
        _transfers.remove(t);
        _doneTasks.add(t);
      } else if (_abortFlags[t.id] == true || e is TransferCancelled) {
        t.cancelled = true;
        _transfers.remove(t);
        _doneTasks.add(t);
      } else {
        _finish(t, e);
      }
    } finally {
      _abortFlags.remove(t.id);
      _pauseFlags.remove(t.id);
      _trimDone();
      _publishTransfers();
      unawaited(_pump());
    }
  }

  void _setTotal(TransferTask t, int total) {
    // Mutate in place — replacing the object would freeze it in `transfers`
    // while the running closure keeps mutating the stale instance.
    t.total = total;
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
    _trimDone();
    _publishTransfers();
  }

  void _trimDone() {
    while (_doneTasks.length > 100) {
      _doneTasks.removeAt(0);
    }
  }

  @override
  Future<TransferTask> downloadFile(String remotePath, String localPath,
      {String? taskName}) async {
    final t = TransferTask(
        id: 't${++_transferSeq}',
        name: taskName ?? remotePath.split('/').last,
        total: 0,
        remotePath: remotePath,
        localPath: localPath);
    return _enqueue(t);
  }

  @override
  Future<TransferTask> uploadFile(String localPath, String remotePath,
      {String? taskName}) async {
    final t = TransferTask(
        id: 't${++_transferSeq}',
        name: taskName ?? localPath.split('/').last,
        total: await File(localPath).length().catchError((_) => 0),
        isUpload: true,
        remotePath: remotePath,
        localPath: localPath);
    return _enqueue(t);
  }

  @override
  void cancelTransfer(String taskId) {
    final qi = _queue.indexWhere((t) => t.id == taskId);
    if (qi >= 0) {
      final t = _queue.removeAt(qi)
        ..cancelled = true
        ..waiting = false;
      _doneTasks.add(t);
      _publishTransfers();
      return;
    }
    _abortFlags[taskId] = true;
    _publishTransfers();
  }

  @override
  void pauseTransfer(String taskId) {
    final qi = _queue.indexWhere((t) => t.id == taskId);
    if (qi >= 0) {
      _queue.removeAt(qi).paused = true;
      _publishTransfers();
      return;
    }
    _pauseFlags[taskId] = true;
  }

  @override
  void resumeTransfer(String taskId) {
    final i = _doneTasks.indexWhere((t) => t.id == taskId);
    if (i < 0) return;
    final old = _doneTasks.removeAt(i);
    _enqueue(TransferTask(
        id: old.id,
        name: old.name,
        total: 0,
        isUpload: old.isUpload,
        remotePath: old.remotePath,
        localPath: old.localPath)
      ..done = old.done);
  }

  /// Test hook: attach an already-handshaken client without running
  /// [connect]. Marks the controller connected.
  void debugUseClient(SspClient client, SspApi api) {
    _client = client;
    _api = api;
    client.onDisconnected = () => unawaited(_onLinkDown());
    _setState(ConnState.connected);
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
