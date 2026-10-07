import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';

import 'client.dart';
import 'pb/SmartSyncProtocol.recovered.pb.dart' as pb;
import 'pb/SmartSyncProtocol.recovered.pbenum.dart' as pbe;
import 'types.dart';

/// Typed high-level operations over an established [SspClient].
/// One method per RequestType in the recovered registry.
class SspApi {
  SspApi(this.client);

  final SspClient client;

  Int64 get _nowSeconds =>
      Int64(DateTime.now().millisecondsSinceEpoch ~/ 1000);

  /// Clipboard ms timestamp per the original client: floor(seconds) * 1000.
  static Int64 clipboardTimestamp() =>
      Int64((DateTime.now().millisecondsSinceEpoch ~/ 1000) * 1000);

  // ---------- heartbeat / lifecycle ----------

  Future<pb.SSPHeartBeatResponse> heartbeat() => client.call(
      pb.SSPHeartBeatRequest()
        ..type = Req.heartBeat
        ..hostTimestamp = _nowSeconds,
      pb.SSPHeartBeatResponse.fromBuffer);

  Future<void> quit() => client.call(
      pb.SSPQuitRequest()
        ..type = Req.quit,
      (b) => b);

  Future<void> cancel(int sessionId,
          {pbe.SSPCancelErrorCode code =
              CancelErr.unknown}) =>
      client.call(
          pb.SSPCancelRequest()
            ..type = Req.cancel
            ..sessionId = Int64(sessionId)
            ..errorCode = code,
          (b) => b);

  // ---------- device info ----------

  Future<pb.SSPGetDeviceInfoResponse> getDeviceInfo({
    bool needDeviceInfoCallback = false,
    bool needPhotoLibraryCallback = false,
    bool needAudioLibraryCallback = false,
    bool needVideoLibraryCallback = false,
  }) =>
      client.call(
          pb.SSPGetDeviceInfoRequest()
            ..type = Req.getDeviceInfo
            ..hostTimestamp = _nowSeconds
            ..hostSmartSyncProtocolVersion = '2'
            ..needDeviceInfoCallback = needDeviceInfoCallback
            ..needPhotoLibraryCallback = needPhotoLibraryCallback
            ..needAudioLibraryCallback = needAudioLibraryCallback
            ..needVideoLibraryCallback = needVideoLibraryCallback
            ..hostAppVersion = client.identity.appVersion
            ..hostMinClientVersion = client.identity.minClientVersion,
          pb.SSPGetDeviceInfoResponse.fromBuffer,
          timeout: const Duration(seconds: 60));

  // ---------- filesystem ----------

  pb.SSPFile sspFile(String path,
          {bool isDirectory = false, int? fileSize, String? checksum}) =>
      pb.SSPFile()
        ..path = path
        ..isDirectory = isDirectory
        ..fileSize = Int64(fileSize ?? 0);

  Future<pb.SSPGetDirFilesResponse> listDir(String path,
          {int maxdepth = 1}) =>
      client.call(
          pb.SSPGetDirFilesRequest()
            ..type = Req.getDirFiles
            ..dir = sspFile(path, isDirectory: true)
            ..maxdepth = maxdepth,
          pb.SSPGetDirFilesResponse.fromBuffer,
          timeout: const Duration(minutes: 2));

  /// Recursive listing (original client uses 0xffffffff).
  Future<pb.SSPGetDirFilesResponse> listDirRecursive(String path) =>
      listDir(path, maxdepth: 0xffffffff);

  Future<pb.SSPGetFileCountResponse> fileCount(String path,
          {int maxdepth = 0xffffffff, List<String> exclusions = const []}) =>
      client.call(
          pb.SSPGetFileCountRequest()
            ..type = Req.getFileCount
            ..dir = sspFile(path, isDirectory: true)
            ..maxdepth = maxdepth
            ..exclusionPatternArray.addAll(exclusions),
          pb.SSPGetFileCountResponse.fromBuffer,
          timeout: const Duration(minutes: 2));

  Future<bool> fileExists(String path) => client.call(
      pb.SSPFileExistRequest()
        ..type = Req.getFileExist
        ..file = sspFile(path),
      (b) => pb.SSPFileExistResponse.fromBuffer(b).exist);

  Future<pb.SSPCreateFolderResponse> createFolder(String path) => client.call(
      pb.SSPCreateFolderRequest()
        ..type = Req.createFolder
        ..file = sspFile(path, isDirectory: true),
      pb.SSPCreateFolderResponse.fromBuffer);

  Future<pb.SSPRenameFileResponse> rename(String src, String dst) =>
      client.call(
          pb.SSPRenameFileRequest()
            ..type = Req.renameFile
            ..sourceFile = sspFile(src)
            ..targetFile = sspFile(dst),
          pb.SSPRenameFileResponse.fromBuffer);

  Future<pb.SSPDeleteFileResponse> delete(String path,
          {bool isSync = false, bool isTrash = false}) =>
      client.call(
          pb.SSPDeleteFileRequest()
            ..type = Req.deleteFile
            ..file = sspFile(path)
            ..isSync = isSync
            ..isTrash = isTrash,
          pb.SSPDeleteFileResponse.fromBuffer,
          timeout: const Duration(minutes: 2));

  // ---------- media libraries ----------

  Future<pb.SSPGetPhotoLibraryResponse> photoLibrary() => client.call(
      pb.SSPGetPhotoLibraryRequest()
        ..type = Req.getPhotoLib,
      pb.SSPGetPhotoLibraryResponse.fromBuffer,
      timeout: const Duration(minutes: 5));

  Future<pb.SSPGetVideoLibraryResponse> videoLibrary() => client.call(
      pb.SSPGetVideoLibraryRequest()
        ..type = Req.getVideoLib,
      pb.SSPGetVideoLibraryResponse.fromBuffer,
      timeout: const Duration(minutes: 5));

  Future<pb.SSPGetAudioLibraryResponse> audioLibrary() => client.call(
      pb.SSPGetAudioLibraryRequest()
        ..type = Req.getAudioLib,
      pb.SSPGetAudioLibraryResponse.fromBuffer,
      timeout: const Duration(minutes: 5));

  Future<pb.SSPGetThumbnailResponse> thumbnails({
    List<pb.SSPImageFile> images = const [],
    List<pb.SSPVideoFile> videos = const [],
    List<pb.SSPAudioAlbum> audioAlbums = const [],
  }) =>
      client.call(
          pb.SSPGetThumbnailRequest()
            ..type = Req.getThumbnail
            ..imageArray.addAll(images)
            ..videoArray.addAll(videos)
            ..audioAlbumArray.addAll(audioAlbums),
          pb.SSPGetThumbnailResponse.fromBuffer,
          timeout: const Duration(minutes: 5));

  // ---------- clipboard ----------

  /// content is gzip(UTF-8 text).
  static pb.SSPClipboard clipboardText(String text) => pb.SSPClipboard()
    ..content = Uint8List.fromList(gzip.encode(utf8.encode(text)))
    ..mstimestamp = clipboardTimestamp();

  static String clipboardContentToText(pb.SSPClipboard c) =>
      utf8.decode(gzip.decode(c.content));

  Future<List<pb.SSPClipboard>> getClipboard() => client.call(
      pb.SSPGetClipboardRequest()
        ..type = Req.getClipboard,
      (b) => pb.SSPGetClipboardResponse.fromBuffer(b).clipboardArray);

  Future<bool> postClipboard(pb.SSPClipboard clip) => client.call(
      pb.SSPPostClipboardRequest()
        ..type = Req.postClipboard
        ..clipboard = clip,
      (b) => pb.SSPPostClipboardResponse.fromBuffer(b).succeed);

  Future<bool> postClipboardText(String text) =>
      postClipboard(clipboardText(text));

  Future<bool> clearClipboard() => client.call(
      pb.SSPClearClipboardRequest()
        ..type = Req.clearClipboard,
      (b) => pb.SSPClearClipboardResponse.fromBuffer(b).succeed);

  Future<bool> deleteClipboard(pb.SSPClipboard clip) => client.call(
      pb.SSPDeleteClipboardRequest()
        ..type = Req.deleteClipboard
        ..clipboard = clip,
      (b) => pb.SSPDeleteClipboardResponse.fromBuffer(b).succeed);

  // ---------- folder monitoring ----------

  /// Register (register=true) or unregister a watched folder. Change events
  /// arrive later as push type=25 messages on the same channel.
  Future<pb.SSPMonitorFolderResponseHeader> monitorFolder(String path,
          {bool register = true}) =>
      client.call(
          pb.SSPMonitorFolderRequest()
            ..type = Req.monitorFolder
            ..file = sspFile(path.replaceAll(RegExp(r'/+$'), ''))
            ..registerP = register,
          pb.SSPMonitorFolderResponseHeader.fromBuffer);

  // ---------- sync ----------

  Future<pb.SSPPhotoSyncResponse> photoSync(String pcId,
          {List<pb.SSPFile> files = const []}) =>
      client.call(
          pb.SSPPhotoSyncRequest()
            ..type = Req.photoSync
            ..pcId = pcId
            ..filesArray.addAll(files),
          pb.SSPPhotoSyncResponse.fromBuffer,
          timeout: const Duration(minutes: 5));

  Future<pb.SSPSyncMonitorResponse> syncMonitor({bool enable = true}) =>
      client.call(
          pb.SSPSyncMonitorRequest()
            ..type = Req.syncMonitor
            ..isSyncMonitor = enable,
          pb.SSPSyncMonitorResponse.fromBuffer);

  Future<pb.SSPUpdateFileResponse> updateFileInfo(List<pb.SSPFile> files,
          {bool isSync = false}) =>
      client.call(
          pb.SSPUpdateFileRequest()
            ..type = Req.updateFileInfo
            ..filesArray.addAll(files)
            ..isSync = isSync,
          pb.SSPUpdateFileResponse.fromBuffer);

  // ---------- push decoding ----------

  /// Decode a push payload into a typed protobuf message based on its
  /// tag-1 type value. [SspPushMessage.message] is null for unknown types.
  static SspPushMessage decodePush(Uint8List payload) =>
      SspPushMessage.decode(payload);
}

/// Decoded push: [message] is the concrete protobuf instance when known.
class SspPushMessage {
  SspPushMessage._(this.type, this.message);

  final int type;
  final Object? message;

  static SspPushMessage decode(Uint8List payload) {
    final type = pb.SSPRequest.fromBuffer(payload).type.value;
    switch (type) {
      case 20:
        return SspPushMessage._(
            type, pb.SSPPhotoLibraryChange.fromBuffer(payload));
      case 21:
        return SspPushMessage._(
            type, pb.SSPAudioLibraryChange.fromBuffer(payload));
      case 22:
        return SspPushMessage._(
            type, pb.SSPVideoLibraryChange.fromBuffer(payload));
      case 25:
        return SspPushMessage._(
            type, pb.SSPMonitorFolderResponse.fromBuffer(payload));
      case 30:
        return SspPushMessage._(
            type, pb.SSPClipboardChange.fromBuffer(payload));
      case 38:
        return SspPushMessage._(type, pb.SSPFileChange.fromBuffer(payload));
      default:
        return SspPushMessage._(type, null);
    }
  }
}
