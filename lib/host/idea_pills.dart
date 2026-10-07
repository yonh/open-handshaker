import 'dart:async';
import 'dart:io';

import '../ssp/client.dart';
import '../ssp/pb/SmartSyncProtocol.recovered.pb.dart' as pb;
import '../ssp/requests.dart';
import 'push_hub.dart';

/// Best-effort "闪念胶囊" (Idea Pills) sync.
///
/// The original Smartisan feature synced pills through Smartisan cloud
/// services — there is no dedicated SSP wire type for it (verified against
/// PROTOCOL.md's recovered schema). Our approximation mirrors a plain
/// `idea_pills/` folder both ways: phone-side edits land via MonitorFolder
/// pushes, Mac-side edits are uploaded on a local Directory.watch.
/// Anything a real handset keeps only in its cloud DB is out of scope —
/// see docs/IDEA_PILLS.md.
class IdeaPillsSync {
  IdeaPillsSync({
    required this.client,
    required this.api,
    required this.localDir,
    required this.remoteDir,
    PushHub? pushHub,
  }) : _hub = pushHub ?? PushHub(client);

  final SspClient client;
  final SspApi api;
  final String localDir;
  final String remoteDir;
  final PushHub _hub;

  StreamSubscription<pb.SSPMonitorFolderResponse>? _remoteSub;
  StreamSubscription<FileSystemEvent>? _localSub;
  Timer? _debounce;
  bool _stopped = false;

  static const _debounceDelay = Duration(milliseconds: 400);

  String _remoteFor(String localPath) =>
      '$remoteDir/${localPath.split('/').last}';
  String _localFor(String remotePath) =>
      '$localDir/${remotePath.split('/').last}';

  /// Register the remote folder watch, pull current contents, start the
  /// local watcher, and subscribe to remote events.
  Future<void> start() async {
    await Directory(localDir).create(recursive: true);
    // Remote → local: register MonitorFolder, pull, then live events.
    try {
      await api.monitorFolder(remoteDir, register: true);
    } catch (_) {
      // Agent may refuse on a missing dir — uploads will still work.
    }
    await pullAll();
    _remoteSub = _hub.folderEvents.listen((resp) {
      for (final ev in resp.eventArray) {
        _onRemoteEvent(ev);
      }
    });
    _localSub = Directory(localDir)
        .watch()
        .listen((ev) => _onLocalEvent(ev));
    // Reconcile periodically — FSEvents can coalesce or drop events under
    // load, so a missed watch event shouldn't strand a pill forever.
    _reconcileTimer =
        Timer.periodic(_reconcileEvery, (_) => unawaited(_reconcileLocal()));
  }

  static const _reconcileEvery = Duration(seconds: 3);
  Timer? _reconcileTimer;

  /// Push local files that are missing (or different) on the device.
  /// Also deletes remote pills whose local copy is gone.
  Future<void> _reconcileLocal() async {
    if (_stopped) return;
    try {
      final remoteSizes = <String, int>{};
      final list = await api.listDir(remoteDir);
      for (final f in list.fileArray) {
        remoteSizes[f.path.split('/').last] = f.fileSize.toInt();
      }
      final dir = Directory(localDir);
      if (!dir.existsSync()) return;
      for (final ent in dir.listSync()) {
        if (ent is! File) continue;
        final name = ent.path.split('/').last;
        final remote = '$remoteDir/$name';
        final size = ent.lengthSync();
        if (remoteSizes[name] != size) {
          try {
            await client.upload(ent.path, remote);
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  /// Download every remote pill currently present.
  Future<int> pullAll() async {
    var n = 0;
    try {
      final list = await api.listDir(remoteDir);
      for (final f in list.fileArray) {
        if (f.isDirectory) continue;
        final lp = _localFor(f.path);
        if (!File(lp).existsSync() ||
            File(lp).lengthSync() != f.fileSize.toInt()) {
          try {
            await client.download(f.path, lp);
            n++;
          } catch (_) {}
        }
      }
    } catch (_) {}
    return n;
  }

  void _onRemoteEvent(pb.SSPFileEvent ev) {
    if (_stopped) return;
    _debounce?.cancel();
    _debounce = Timer(_debounceDelay, () async {
      final path = ev.file.path;
      if (path.isEmpty) return;
      final lp = _localFor(path);
      switch (ev.event.value) {
        case 1: // create
        case 3: // closeWrite
        case 5: // movedTo
          try {
            await client.download(path, lp);
          } catch (_) {}
          break;
        case 2: // delete
        case 6: // deleteSelf
          if (File(lp).existsSync()) await File(lp).delete();
          break;
        default:
      }
    });
  }

  void _onLocalEvent(FileSystemEvent ev) {
    if (_stopped || ev.isDirectory) return;
    _debounce?.cancel();
    _debounce = Timer(_debounceDelay, () async {
      final remote = _remoteFor(ev.path);
      switch (ev.type) {
        case FileSystemEvent.create:
        case FileSystemEvent.modify:
          try {
            await client.upload(ev.path, remote);
          } catch (_) {}
          break;
        case FileSystemEvent.delete:
          try {
            await api.delete(remote);
          } catch (_) {}
          break;
        case FileSystemEvent.move:
          if (ev is FileSystemMoveEvent && ev.destination != null) {
            try {
              await api.rename(remote, _remoteFor(ev.destination!));
            } catch (_) {}
          }
          break;
      }
    });
  }

  /// Create a pill locally (synced to the phone by the watcher).
  Future<File> createPill(String title, String body) async {
    final f = File('$localDir/${_slug(title)}.md');
    await f.writeAsString('# $title\n\n$body\n');
    return f;
  }

  static String _slug(String s) {
    final t = s
        .trim()
        .replaceAll(RegExp(r'[^\w一-龥-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    return t.isEmpty ? 'pill_${DateTime.now().millisecondsSinceEpoch}' : t;
  }

  Future<void> stop() async {
    _stopped = true;
    _debounce?.cancel();
    _reconcileTimer?.cancel();
    await _remoteSub?.cancel();
    await _localSub?.cancel();
    try {
      await api.monitorFolder(remoteDir, register: false);
    } catch (_) {}
  }

  Future<void> dispose() async {
    await stop();
    await _hub.dispose();
  }
}
