import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:protobuf/protobuf.dart' show GeneratedMessage;

import '../ssp/crypto.dart';
import '../ssp/pb/SmartSyncProtocol.recovered.pb.dart' as pb;
import '../ssp/server.dart';
import '../ssp/types.dart';
import 'providers/channel_providers.dart';
import 'providers/files_provider.dart';

/// Per-session upload bookkeeping (flag1 header → flag3 body → ack).
class _Upload {
  _Upload(this.file, this.expected, this.md5)
      : raf = null,
        received = 0;
  final File file;
  final int expected;
  final String md5;
  RandomAccessFile? raf;
  int received;
}

/// Wires the modern SSP request surface to the data providers.
///
/// Handles: heartbeat, device info, dir/file ops (delegated to
/// [FilesProvider]), media libraries + thumbnails (delegated to
/// [ChannelProviders]), clipboard, download (header + raw body on the same
/// session), and upload (header → accumulate flag3 bytes → ack).
/// MonitorFolder/PhotoSync/syncMonitor stubs return success/no-op for now
/// (Phase 5 implements them fully).
class AgentHandlers {
  AgentHandlers({
    required this.files,
    required this.channels,
    this.onQuit,
    this.onCancel,
  });

  final FilesProvider files;
  final ChannelProviders channels;

  /// Called when a host sends QuitRequest.
  void Function(AgentSession session)? onQuit;
  void Function(AgentSession session, int sessionId)? onCancel;

  final _uploads = <int, _Upload>{};
  final _monitoredFolders = <int, String>{};
  final _watchers = <int, StreamSubscription<FileSystemEvent>>{};

  /// SspAgentServer.requestHandler entry point.
  Future<GeneratedMessage?> call(AgentSession session, Uint8List proto,
      int typeValue, int sessionId) async {
    switch (typeValue) {
      case 0x01: // Req.heartBeat
        final req = pb.SSPHeartBeatRequest.fromBuffer(proto);
        return pb.SSPHeartBeatResponse()
          ..type = Req.heartBeat
          ..hostTimestamp = req.hostTimestamp
          ..clientTimestamp =
              Int64(DateTime.now().millisecondsSinceEpoch ~/ 1000);
      case 0x23: // Req.quit (35)
        onQuit?.call(session);
        return pb.SSPHeartBeatResponse()
          ..type = Req.quit
          ..clientTimestamp =
              Int64(DateTime.now().millisecondsSinceEpoch ~/ 1000);
      case 0x24: // Req.cancel (36)
        final req = pb.SSPCancelRequest.fromBuffer(proto);
        final sid = req.sessionId.toInt();
        _uploads.remove(sid)?.raf?.close();
        onCancel?.call(session, sid);
        return pb.SSPHeartBeatResponse()..type = Req.cancel;
      case 0x02: // getDeviceInfo
        return channels.deviceInfo(
            pb.SSPGetDeviceInfoRequest.fromBuffer(proto));
      case 0x07: // getDirFiles
        return files.listDir(pb.SSPGetDirFilesRequest.fromBuffer(proto));
      case 0x08: // getFileCount
        return files
            .fileCount(pb.SSPGetFileCountRequest.fromBuffer(proto));
      case 0x09: // getFileExist
        return files
            .fileExists(pb.SSPFileExistRequest.fromBuffer(proto));
      case 0x0a: // createFolder
        return files
            .createFolder(pb.SSPCreateFolderRequest.fromBuffer(proto));
      case 0x0b: // renameFile
        return files.rename(pb.SSPRenameFileRequest.fromBuffer(proto));
      case 0x13: // deleteFile
        return files.delete(pb.SSPDeleteFileRequest.fromBuffer(proto));
      case 0x04: // getPhotoLib
        return channels
            .photoLibrary(pb.SSPGetPhotoLibraryRequest.fromBuffer(proto));
      case 0x06: // getAudioLib
        return channels
            .audioLibrary(pb.SSPGetAudioLibraryRequest.fromBuffer(proto));
      case 0x05: // getVideoLib
        return channels
            .videoLibrary(pb.SSPGetVideoLibraryRequest.fromBuffer(proto));
      case 0x03: // getThumbnail
        return channels
            .thumbnails(pb.SSPGetThumbnailRequest.fromBuffer(proto));
      case 0x1a: // getClipboard (26)
        return channels.getClipboard();
      case 0x1b: // postClipboard (27)
        return channels
            .postClipboard(pb.SSPPostClipboardRequest.fromBuffer(proto));
      case 0x1c: // clearClipboard (28)
        return channels.clearClipboard();
      case 0x1d: // deleteClipboard (29) — treated as clear on Android
        return pb.SSPDeleteClipboardResponse()
          ..type = Req.deleteClipboard
          ..succeed = true;
      case 0x0c: // downloadFile (12) — responds header+body itself
        await _download(session, proto, sessionId);
        return null;
      case 0x0f: // uploadFileReqHeader (15)
        return _uploadHeader(session, proto, sessionId);
      case 0x17: // monitorFolder (23)
        final req = pb.SSPMonitorFolderRequest.fromBuffer(proto);
        if (req.registerP) {
          _watchFolder(session, sessionId, req.file.path);
        } else {
          _unwatchFolder(sessionId);
        }
        return pb.SSPMonitorFolderResponseHeader()
          ..type = Req.monitorFolderHeader
          ..succeed = true;
      case 0x25: // photoSync (37)
        return _photoSync(proto);
      case 0x27: // syncMonitor (39)
        return pb.SSPSyncMonitorResponse()
          ..type = Req.syncMonitor
          ..isSuccess = true;
      case 0x28: // updateFileInfo (40)
        return pb.SSPUpdateFileResponse()
          ..type = Req.updateFileInfoResp
          ..isSuccess = true;
      default:
        // Unknown request: respond with an empty generic message so the
        // session does not stall the host.
        return pb.SSPHeartBeatResponse()
          ..clientTimestamp =
              Int64(DateTime.now().millisecondsSinceEpoch ~/ 1000);
    }
  }

  /// SspAgentServer.fileDataHandler entry point — flag3 upload body bytes.
  void onFileData(AgentSession session, int sessionId, Uint8List data) {
    final up = _uploads[sessionId];
    if (up == null) {
      // Stray body bytes: no matching header — drop.
      return;
    }
    final raf = up.raf!;
    raf.writeFromSync(data.sublist(0,
        data.length > up.expected - up.received
            ? up.expected - up.received
            : data.length));
    up.received += data.length > up.expected - up.received
        ? up.expected - up.received
        : data.length;
    if (up.received >= up.expected) {
      final u = _uploads.remove(sessionId)!;
      unawaited(u.raf!.close());
      _finishUpload(session, sessionId, u);
    }
  }

  Future<void> _finishUpload(
      AgentSession session, int sessionId, _Upload u) async {
    var succeed = true;
    var err = FileErr.unknow;
    if (u.md5.isNotEmpty) {
      final digest = md5Hex(await u.file.readAsBytes());
      if (digest.toLowerCase() != u.md5.toLowerCase()) {
        succeed = false;
        err = FileErr.md5Check;
        try {
          await u.file.delete();
        } on FileSystemException {
          // keep partial file on delete failure
        }
      }
    }
    session.respond(
        sessionId,
        pb.SSPUploadFileResponse()
          ..type = Req.uploadFileResp
          ..succeed = succeed
          ..canceled = false
          ..errorCode = succeed ? FileErr.unknow : err);
  }

  Future<void> _download(
      AgentSession session, Uint8List proto, int sid) async {
    final req = pb.SSPDownloadFileRequest.fromBuffer(proto);
    final f = File(req.file.path);
    pb.SSPDownloadFileResponseHeader header;
    Uint8List? body;
    if (await f.exists()) {
      final all = await f.length();
      final off = req.range.offset.toInt();
      var len = req.range.length.toInt();
      if (len == 0 || off + len > all) len = all - off;
      if (len < 0) len = 0;
      final raf = await f.open();
      try {
        await raf.setPosition(off);
        body = Uint8List.fromList(await raf.read(len));
      } finally {
        await raf.close();
      }
      header = pb.SSPDownloadFileResponseHeader()
        ..type = Req.downloadFileRespHeader
        ..file = req.file
        ..ready = true
        ..needMd5 = req.needMd5
        ..dataMd5 = req.needMd5 ? md5Hex(body) : ''
        ..range = (pb.SSPDataRange()
          ..offset = Int64(off)
          ..length = Int64(body.length));
    } else {
      header = pb.SSPDownloadFileResponseHeader()
        ..type = Req.downloadFileRespHeader
        ..file = req.file
        ..ready = false
        ..errorCode = FileErr.invalidSource;
    }
    session.respond(sid, header);
    if (body != null) {
      session.sendRaw(sid, body);
    }
  }

  Future<GeneratedMessage> _uploadHeader(
      AgentSession session, Uint8List proto, int sid) async {
    final req = pb.SSPUploadFileRequest.fromBuffer(proto);
    final target = File(req.file.path);
    try {
      await target.parent.create(recursive: true);
      final raf = await target.open(mode: FileMode.write);
      _uploads[sid] = _Upload(target, req.file.fileSize.toInt(),
          req.file.checksum.isNotEmpty ? req.file.checksum : req.dataMd5)
        ..raf = raf;
      // Empty file finishes immediately.
      if (req.file.fileSize == Int64(0)) {
        final u = _uploads.remove(sid)!;
        await u.raf!.close();
        unawaited(_finishUpload(session, sid, u));
      }
      return pb.SSPUploadFileResponseHeader()
        ..type = Req.uploadFileRespHeader
        ..file = req.file
        ..ready = true;
    } on FileSystemException {
      return pb.SSPUploadFileResponseHeader()
        ..type = Req.uploadFileRespHeader
        ..file = req.file
        ..ready = false
        ..errorCode = FileErr.permission;
    }
  }

  /// Monitored folders registered by hosts.
  Map<int, String> get monitoredFolders =>
      Map.unmodifiable(_monitoredFolders);

  /// PhotoSync: respond with the device's current photo-library file list
  /// (`filesArray`); the host diffs it against its last snapshot — the
  /// original's exact incremental algorithm is 待验证 but this semantics
  /// makes sync work end-to-end against our agent.
  Future<GeneratedMessage> _photoSync(Uint8List proto) async {
    final req = pb.SSPPhotoSyncRequest.fromBuffer(proto);
    final resp = pb.SSPPhotoSyncResponse()
      ..type = Req.photoSync
      ..isSuccess = true
      ..isFirst = req.filesArray.isEmpty;
    try {
      final lib = await channels.photoLibrary(pb.SSPGetPhotoLibraryRequest()
        ..type = Req.getPhotoLib);
      for (final img in lib.imageArray) {
        resp.filesArray.add(pb.SSPFile()
          ..path = img.path
          ..fileSize = img.fileSize
          ..createdTimestamp = img.createdTimestamp
          ..modifiedTimestamp = img.modifiedTimestamp
          ..isDirectory = false
          ..fileType = pb.SSPFileType.SSPFileType_Normal);
      }
    } catch (_) {
      resp.isSuccess = false;
    }
    return resp;
  }

  // ---------------- folder watch ----------------

  void _watchFolder(AgentSession session, int sessionId, String path) {
    _unwatchFolder(sessionId);
    _monitoredFolders[sessionId] = path;
    final dir = Directory(path);
    if (!dir.existsSync()) return;
    // FileSystemEntity.watch is unsupported on iOS — degrade to no-op
    // rather than letting the exception kill the session.
    try {
      _watchers[sessionId] =
          dir.watch(recursive: true).listen((ev) => _emitEvent(session, sessionId, ev));
      unawaited(_watchers[sessionId]!.asFuture().catchError((_) {}));
    } catch (_) {
      _monitoredFolders.remove(sessionId);
    }
  }

  void _unwatchFolder(int sessionId) {
    _watchers.remove(sessionId)?.cancel();
    _monitoredFolders.remove(sessionId);
  }

  void _emitEvent(AgentSession session, int sessionId, FileSystemEvent ev) {
    final type = switch (ev) {
      FileSystemCreateEvent _ => FileEventType.create,
      FileSystemDeleteEvent _ => FileEventType.delete,
      FileSystemMoveEvent _ => FileEventType.movedFrom,
      _ => FileEventType.closeWrite,
    };
    final f = ev is FileSystemMoveEvent && ev.destination != null
        ? ev.destination!
        : ev.path;
    session.push(
        sessionId,
        pb.SSPMonitorFolderResponse()
          ..type = Req.monitorFolderResp
          ..eventArray.add(pb.SSPFileEvent()
            ..file = (pb.SSPFile()
              ..path = f
              ..isDirectory = FileSystemEntity.isDirectorySync(f))
            ..event = type));
  }

  /// Daemon shutdown helper: cancel every watcher + pending upload.
  Future<void> dispose() async {
    for (final w in _watchers.values) {
      await w.cancel();
    }
    _watchers.clear();
    for (final u in _uploads.values) {
      await u.raf?.close();
    }
    _uploads.clear();
  }
}
