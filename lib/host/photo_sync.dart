import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fixnum/fixnum.dart';

import '../ssp/client.dart';
import '../ssp/pb/SmartSyncProtocol.recovered.pb.dart' as pb;
import '../ssp/requests.dart';
import 'push_hub.dart';

/// Album sync (PhotoSync) engine: mirrors the device's photo library into a
/// local directory, then keeps it updated via FileChange pushes.
///
/// Wire semantics implemented (the original's diff algorithm is 待验证):
///   host → PhotoSyncRequest(pcId, filesArray = last-synced snapshot)
///   agent → PhotoSyncResponse(isFirst, isSuccess, filesArray = current lib)
///   host diffs snapshot vs filesArray: new/changed → download, gone → delete
///   host → UpdateFileRequest(filesArray = new snapshot, isSync = true)
///   host → SyncMonitorRequest(isSyncMonitor = true) to enable pushes
class PhotoSyncEngine {
  PhotoSyncEngine({
    required this.client,
    required this.api,
    required this.localDir,
    required this.pcId,
    PushHub? pushHub,
  })  : _hub = pushHub ?? PushHub(client),
        _ownsHub = pushHub == null;

  final SspClient client;
  final SspApi api;
  final String localDir;
  final String pcId;
  final PushHub _hub;

  /// Only dispose the hub when this engine created it — a hub passed
  /// in is shared with other pages/engines.
  final bool _ownsHub;

  StreamSubscription<pb.SSPFileChange>? _changeSub;
  bool _syncing = false;

  File get _snapshotFile => File('$localDir/.photo_sync_snapshot.json');

  /// Load the last-synced file list from the snapshot.
  Future<List<pb.SSPFile>> _loadSnapshot() async {
    if (!await _snapshotFile.exists()) return [];
    try {
      final j = jsonDecode(await _snapshotFile.readAsString()) as List;
      return j.map((e) {
        final m = e as Map<String, dynamic>;
        return pb.SSPFile()
          ..path = m['path'] as String? ?? ''
          ..fileSize = Int64(m['fileSize'] as int? ?? 0)
          ..modifiedTimestamp = Int64(m['modifiedTimestamp'] as int? ?? 0);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveSnapshot(List<pb.SSPFile> files) async {
    await _snapshotFile.parent.create(recursive: true);
    await _snapshotFile.writeAsString(jsonEncode([
      for (final f in files)
        {
          'path': f.path,
          'fileSize': f.fileSize.toInt(),
          'modifiedTimestamp': f.modifiedTimestamp.toInt(),
        }
    ]));
  }

  /// Where a device path lands inside [localDir] (basename only; album subdir
  /// kept when the remote path has ≥2 segments). `.`/`..` segments are
  /// stripped — a hostile or buggy agent path must not escape [localDir].
  String _localPathFor(String remotePath) {
    final seg = remotePath
        .split('/')
        .where((s) => s.isNotEmpty && s != '.' && s != '..')
        .toList();
    if (seg.length >= 2) {
      return '$localDir/${seg[seg.length - 2]}/${seg.last}';
    }
    return '$localDir/${seg.isEmpty ? 'file' : seg.last}';
  }

  /// One full sync round-trip. Returns the number of files downloaded.
  Future<int> syncOnce() async {
    if (_syncing) return 0;
    _syncing = true;
    try {
      final last = await _loadSnapshot();
      final resp = await api.photoSync(pcId, files: last);
      if (!resp.isSuccess) {
        throw StateError('photoSync refused by agent');
      }
      final lastByPath = {for (final f in last) f.path: f};
      final remoteByPath = {for (final f in resp.filesArray) f.path: f};

      var downloaded = 0;
      for (final f in resp.filesArray) {
        final prev = lastByPath[f.path];
        final changed = prev == null ||
            prev.fileSize != f.fileSize ||
            prev.modifiedTimestamp != f.modifiedTimestamp;
        if (!changed) continue;
        final lp = _localPathFor(f.path);
        await File(lp).parent.create(recursive: true);
        await client.download(f.path, lp);
        downloaded++;
      }
      // Removed on the device → delete locally.
      for (final f in last) {
        if (!remoteByPath.containsKey(f.path)) {
          final lp = _localPathFor(f.path);
          if (File(lp).existsSync()) await File(lp).delete();
        }
      }
      await _saveSnapshot(resp.filesArray);
      unawaited(api.updateFileInfo(resp.filesArray, isSync: true));
      return downloaded;
    } finally {
      _syncing = false;
    }
  }

  /// Start listening for FileChange pushes that keep the mirror hot.
  /// Each added/modified item is downloaded; deleted items removed locally.
  Future<void> startMonitoring() async {
    await api.syncMonitor(enable: true);
    _changeSub ??= _hub.fileChanges.listen((change) async {
      for (final item in change.fileChangeItemsArray) {
        final p = item.file.path;
        if (p.isEmpty) continue;
        switch (item.status.value) {
          case 2: // Deleted
            final lp = _localPathFor(p);
            if (File(lp).existsSync()) await File(lp).delete();
            break;
          case 1: // Added
          case 3: // Modified
          case 4:
          case 5:
            try {
              final lp = _localPathFor(p);
              await File(lp).parent.create(recursive: true);
              await client.download(p, lp);
              final snap = await _loadSnapshot();
              final i = snap.indexWhere((f) => f.path == p);
              if (i >= 0) {
                snap[i] = item.file;
              } else {
                snap.add(item.file);
              }
              await _saveSnapshot(snap);
            } catch (_) {
              // next syncOnce reconciles
            }
            break;
          default:
        }
      }
    });
  }

  Future<void> stop() async {
    await _changeSub?.cancel();
    _changeSub = null;
    try {
      await api.syncMonitor(enable: false);
    } catch (_) {}
  }

  Future<void> dispose() async {
    await stop();
    if (_ownsHub) await _hub.dispose();
  }
}
