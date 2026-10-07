import 'dart:async';

import '../ssp/client.dart';
import '../ssp/pb/SmartSyncProtocol.recovered.pb.dart' as pb;
import '../ssp/requests.dart';

/// Typed access to agent push messages (library changes, folder events,
/// clipboard changes, FileChange items).
///
/// Wraps [SspClient.pushes]: each raw push frame is decoded with
/// [SspApi.decodePush] and re-broadcast so multiple listeners can subscribe.
class PushHub {
  PushHub(SspClient client) {
    _sub = client.pushes.listen((p) {
      try {
        _ctl.add(SspApi.decodePush(p.payload));
      } catch (_) {
        // Unknown/corrupt push — drop it rather than killing the stream.
      }
    });
  }

  final _ctl = StreamController<SspPushMessage>.broadcast();
  late final StreamSubscription<SspPush> _sub;

  /// Every decoded push.
  Stream<SspPushMessage> get stream => _ctl.stream;

  /// MonitorFolder events (type 25).
  Stream<pb.SSPMonitorFolderResponse> get folderEvents => stream
      .where((m) => m.message is pb.SSPMonitorFolderResponse)
      .map((m) => m.message as pb.SSPMonitorFolderResponse);

  /// FileChange items (type 38).
  Stream<pb.SSPFileChange> get fileChanges => stream
      .where((m) => m.message is pb.SSPFileChange)
      .map((m) => m.message as pb.SSPFileChange);

  /// Clipboard changes (type 30).
  Stream<pb.SSPClipboardChange> get clipboardChanges => stream
      .where((m) => m.message is pb.SSPClipboardChange)
      .map((m) => m.message as pb.SSPClipboardChange);

  /// Photo library changes (type 20).
  Stream<pb.SSPPhotoLibraryChange> get photoLibraryChanges => stream
      .where((m) => m.message is pb.SSPPhotoLibraryChange)
      .map((m) => m.message as pb.SSPPhotoLibraryChange);

  /// Audio library changes (type 21).
  Stream<pb.SSPAudioLibraryChange> get audioLibraryChanges => stream
      .where((m) => m.message is pb.SSPAudioLibraryChange)
      .map((m) => m.message as pb.SSPAudioLibraryChange);

  /// Video library changes (type 22).
  Stream<pb.SSPVideoLibraryChange> get videoLibraryChanges => stream
      .where((m) => m.message is pb.SSPVideoLibraryChange)
      .map((m) => m.message as pb.SSPVideoLibraryChange);

  Future<void> dispose() => _sub.cancel();
}
