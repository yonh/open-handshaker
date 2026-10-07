import 'dart:async';
import 'dart:typed_data';

import '../ssp/requests.dart';
import '../ssp/trust_store.dart';

/// Connection lifecycle of the host app toward one agent device.
enum ConnState {
  /// No agent session.
  disconnected,

  /// Actively looking for devices on the network / USB.
  discovering,

  /// TCP/ADB channel up, SSP handshake in progress or waiting for the
  /// device-side pairing confirmation.
  handshaking,

  /// Device shows the pairing prompt; waiting for the user decision on the
  /// phone (TrustWaiting) — or, locally, for firstConnect confirmation.
  pairing,

  /// Handshake complete; [HostController.api] is usable.
  connected,

  /// Transient drop; auto-reconnect loop is running.
  reconnecting,
}

/// How a device was found.
enum DiscoverySource { wifi, usb, manual, remembered }

/// A discovered (or remembered) candidate we can connect to.
class DeviceCandidate {
  DeviceCandidate({
    required this.id,
    required this.label,
    required this.address,
    required this.port,
    required this.source,
    this.deviceUuid,
  });

  /// Stable identifier for dedup (e.g. '192.168.1.5:10088' or 'usb:serial').
  final String id;
  final String label;
  final String address;
  final int port;
  final DiscoverySource source;

  /// Agent deviceUuid once known (post-handshake or from trust store).
  final String? deviceUuid;

  @override
  String toString() => 'DeviceCandidate($label, $address:$port, $source)';
}

/// A pairing approval surfaced to the *host* UI (first connect to a device
/// we have never trusted — the device independently asks its own user too).
class PairingPrompt {
  PairingPrompt({required this.candidate, required this.completer});
  final DeviceCandidate candidate;

  /// Complete with true to continue pairing, false to abort.
  final Completer<bool> completer;
}

/// Aggregate transfer-job state for the transfer center (Phase 4/5).
class TransferTask {
  TransferTask({
    required this.id,
    required this.name,
    required this.total,
    this.isUpload = false,
    this.done = 0,
    this.completed = false,
    this.error,
    this.waiting = false,
    this.paused = false,
    this.cancelled = false,
    this.remotePath = '',
    this.localPath = '',
  });

  final String id;
  final String name;

  /// Total bytes — filled in once the transfer header arrives (0 = unknown).
  int total;
  final bool isUpload;
  int done;
  bool completed;
  String? error;

  /// Queued, not yet started (transfer center).
  bool waiting;

  /// Download paused (resume reuses the .hsdownload partial + Range offset).
  bool paused;

  /// Cancelled before finishing.
  bool cancelled;

  /// Remote source / target path (kept for pause-resume).
  String remotePath;

  /// Local target / source path.
  String localPath;

  double get progress => total == 0 ? 0 : done / total;
}

/// Everything the host UI needs: discovery state, connection state, the
/// typed SSP API once connected, pairing prompts and transfer queue.
///
/// Implemented by the real connection layer (Phase 3) and by
/// [MockHostController] for UI development and widget tests.
abstract class HostController {
  /// Current connection state.
  ConnState get state;

  Stream<ConnState> get stateStream;

  /// Devices found by discovery (Wi-Fi scan, adb, remembered hosts).
  List<DeviceCandidate> get candidates;

  Stream<List<DeviceCandidate>> get candidatesStream;

  /// Emitted when a first-connect confirmation is needed.
  Stream<PairingPrompt> get pairingPrompts;

  /// Typed SSP API; non-null only while [state] == connected.
  SspApi? get api;

  /// The trusted-device record of the connected device, if any.
  TrustedDevice? get connectedDevice;

  /// Live transfer queue for the transfer center page.
  List<TransferTask> get transfers;

  Stream<List<TransferTask>> get transfersStream;

  /// Start discovery (Wi-Fi scan + adb watch). Safe to call repeatedly.
  Future<void> startDiscovery();

  /// Connect to [candidate] and run the handshake. Surfaces a
  /// [PairingPrompt] on first connect and waits for the device-side
  /// decision (TrustWaiting).
  Future<void> connect(DeviceCandidate candidate);

  /// Connect to a manually entered address (UI "输入 IP 连接").
  Future<void> connectManual(String address, {int port});

  /// Disconnect and stop reconnecting.
  Future<void> disconnect();

  /// Enable/disable auto-reconnect (default on).
  set autoReconnect(bool v);

  /// Remove the trusted record (revoke) for [deviceUuid].
  Future<void> revokeTrust(String deviceUuid);

  /// Local convenience wrappers the UI uses for transfers; they queue work
  /// (max a few concurrent) and publish [TransferTask] progress.
  /// Both return the enqueued task.
  Future<TransferTask> downloadFile(String remotePath, String localPath,
      {String? taskName});
  Future<TransferTask> uploadFile(String localPath, String remotePath,
      {String? taskName});

  /// Cancel a waiting or running transfer.
  void cancelTransfer(String taskId);

  /// Pause a running download (partial .hsdownload kept for resume).
  void pauseTransfer(String taskId);

  /// Resume a paused download (Range offset from the partial file).
  void resumeTransfer(String taskId);

  Future<void> dispose();
}

/// In-memory controller for UI development and widget tests. Simulates a
/// connected device with canned data and echoes requests locally.
class MockHostController extends HostController {
  MockHostController({this.api});

  final _stateCtl = StreamController<ConnState>.broadcast();
  final _candidatesCtl = StreamController<List<DeviceCandidate>>.broadcast();
  final _promptsCtl = StreamController<PairingPrompt>.broadcast();
  final _transfersCtl = StreamController<List<TransferTask>>.broadcast();

  ConnState _state = ConnState.disconnected;
  final List<DeviceCandidate> _candidates = [];
  final List<TransferTask> _transfers = [];

  /// When non-null the mock behaves as already connected.
  @override
  final SspApi? api;

  /// Push a simulated candidate list (UI tests).
  void addCandidate(DeviceCandidate c) {
    _candidates.add(c);
    _candidatesCtl.add(List.unmodifiable(_candidates));
  }

  /// Push a state change (UI tests).
  void setState(ConnState s) {
    _state = s;
    _stateCtl.add(s);
  }

  /// Push a pairing prompt (UI tests).
  void prompt(PairingPrompt p) => _promptsCtl.add(p);

  @override
  ConnState get state => _state;
  @override
  Stream<ConnState> get stateStream => _stateCtl.stream;
  @override
  List<DeviceCandidate> get candidates => List.unmodifiable(_candidates);
  @override
  Stream<List<DeviceCandidate>> get candidatesStream => _candidatesCtl.stream;
  @override
  Stream<PairingPrompt> get pairingPrompts => _promptsCtl.stream;
  @override
  TrustedDevice? get connectedDevice => null;
  @override
  List<TransferTask> get transfers => List.unmodifiable(_transfers);
  @override
  Stream<List<TransferTask>> get transfersStream => _transfersCtl.stream;
  @override
  Future<void> startDiscovery() async {}
  @override
  Future<void> connect(DeviceCandidate candidate) async {
    setState(ConnState.connected);
  }

  @override
  Future<void> connectManual(String address, {int port = 10088}) async {
    setState(ConnState.connected);
  }

  @override
  Future<void> disconnect() async => setState(ConnState.disconnected);
  @override
  set autoReconnect(bool v) {}
  @override
  Future<void> revokeTrust(String deviceUuid) async {}
  @override
  Future<TransferTask> downloadFile(String remotePath, String localPath,
      {String? taskName}) async {
    final t = TransferTask(
        id: 'mock', name: taskName ?? remotePath, total: 0)
      ..completed = true;
    return t;
  }

  @override
  Future<TransferTask> uploadFile(String localPath, String remotePath,
      {String? taskName}) async {
    final t = TransferTask(
        id: 'mock', name: taskName ?? localPath, total: 0, isUpload: true)
      ..completed = true;
    return t;
  }

  @override
  void cancelTransfer(String taskId) {}
  @override
  void pauseTransfer(String taskId) {}
  @override
  void resumeTransfer(String taskId) {}
  @override
  Future<void> dispose() async {
    await _stateCtl.close();
    await _candidatesCtl.close();
    await _promptsCtl.close();
    await _transfersCtl.close();
  }
}

/// Convenience: raw thumbnail bytes used by photo/video pages when the
/// mock has no real media.
Uint8List placeholderPng() => Uint8List.fromList(const [
      0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a,
      // 1x1 transparent png omitted — real impl fetches via api.thumbnails
    ]);
