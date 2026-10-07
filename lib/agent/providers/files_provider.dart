import 'dart:io';

import 'package:fixnum/fixnum.dart';

import '../../ssp/pb/SmartSyncProtocol.recovered.pb.dart' as pb;
import '../../ssp/pb/SmartSyncProtocol.recovered.pbenum.dart' as pbe;
import '../../ssp/types.dart';

/// Pure-Dart filesystem provider backing the SSP file operations
/// (GetDirFiles / GetFileCount / GetFileExist / CreateFolder / Rename /
/// Delete). Works on every platform; on Android it handles the paths that
/// do not require special storage permissions — the platform channel
/// (AgentChannels.providers) covers the rest.
class FilesProvider {
  pb.SSPFile fileInfo(FileSystemEntity e, FileStat st) {
    return pb.SSPFile()
      ..path = e.path
      ..fileSize = Int64(st.size)
      ..createdTimestamp = Int64(st.changed.millisecondsSinceEpoch ~/ 1000)
      ..modifiedTimestamp =
          Int64(st.modified.millisecondsSinceEpoch ~/ 1000)
      ..isDirectory = st.type == FileSystemEntityType.directory
      ..fileType = _fileTypeOf(e, st)
      ..checksum = ''
      ..prefixMd5 = ''
      ..extData = '';
  }

  /// SSPFileType only defines Normal(0)/Data(1); directories are carried by
  /// isDirectory, media kind by mime-type/extData.
  pbe.SSPFileType _fileTypeOf(FileSystemEntity e, FileStat st) =>
      pbe.SSPFileType.SSPFileType_Normal;

  Future<pb.SSPGetDirFilesResponse> listDir(
      pb.SSPGetDirFilesRequest req) async {
    final resp = pb.SSPGetDirFilesResponse()
      ..type = Req.getDirFiles
      ..dir = req.dir
      ..maxdepth = req.maxdepth;
    final sw = Stopwatch()..start();
    final dir = Directory(req.dir.path);
    if (!await dir.exists()) {
      resp.timecost = sw.elapsedMilliseconds;
      return resp;
    }
    final maxDepth = req.maxdepth == 0 ? 1 : req.maxdepth;
    await _walk(dir, resp.fileArray, maxDepth);
    resp.timecost = sw.elapsedMilliseconds;
    return resp;
  }

  Future<void> _walk(Directory dir, List<pb.SSPFile> out, int depthLeft,
      {bool countOnly = false}) async {
    if (depthLeft <= 0) return;
    try {
      await for (final e in dir.list(followLinks: false)) {
        try {
          final st = await e.stat();
          out.add(fileInfo(e, st));
          if (st.type == FileSystemEntityType.directory && depthLeft > 1) {
            await _walk(Directory(e.path), out, depthLeft - 1,
                countOnly: countOnly);
          }
        } on FileSystemException {
          // unreadable entry — skip
        }
      }
    } on FileSystemException {
      // unreadable dir — return what we have
    }
  }

  Future<pb.SSPGetFileCountResponse> fileCount(
      pb.SSPGetFileCountRequest req) async {
    final resp = pb.SSPGetFileCountResponse()
      ..type = Req.getFileCount
      ..dir = req.dir
      ..maxdepth = req.maxdepth;
    final excl = req.exclusionPatternArray
        .map((p) => RegExp(p))
        .toList(growable: false);
    var count = 0;
    final dir = Directory(req.dir.path);
    if (await dir.exists()) {
      final files = <pb.SSPFile>[];
      final maxDepth = req.maxdepth == 0 ? 1 : req.maxdepth;
      await _walk(dir, files, maxDepth);
      count = files
          .where((f) => !excl.any((re) => re.hasMatch(f.path)))
          .length;
    }
    resp.count = Int64(count);
    return resp;
  }

  Future<pb.SSPFileExistResponse> fileExists(
      pb.SSPFileExistRequest req) async {
    final p = req.file.path;
    return pb.SSPFileExistResponse()
      ..type = Req.getFileExist
      ..file = req.file
      ..exist =
          await File(p).exists() || await Directory(p).exists();
  }

  Future<pb.SSPCreateFolderResponse> createFolder(
      pb.SSPCreateFolderRequest req) async {
    final resp = pb.SSPCreateFolderResponse()
      ..type = Req.createFolder
      ..file = req.file;
    try {
      await Directory(req.file.path).create(recursive: true);
      resp.succeed = true;
    } on FileSystemException catch (e) {
      resp
        ..succeed = false
        ..errorCode = FileErr.permission
        ..errorMessage = e.message;
    }
    return resp;
  }

  Future<pb.SSPRenameFileResponse> rename(
      pb.SSPRenameFileRequest req) async {
    final resp = pb.SSPRenameFileResponse()
      ..type = Req.renameFile
      ..sourceFile = req.sourceFile
      ..targetFile = req.targetFile;
    try {
      final src = req.sourceFile.path;
      if (await Directory(src).exists()) {
        await Directory(src).rename(req.targetFile.path);
      } else {
        await File(src).rename(req.targetFile.path);
      }
      resp.succeed = true;
    } on FileSystemException catch (e) {
      resp
        ..succeed = false
        ..errorCode = FileErr.invalidName
        ..errorMessage = e.message;
    }
    return resp;
  }

  Future<pb.SSPDeleteFileResponse> delete(
      pb.SSPDeleteFileRequest req) async {
    final resp = pb.SSPDeleteFileResponse()
      ..type = Req.deleteFile
      ..file = req.file;
    try {
      final p = req.file.path;
      if (await Directory(p).exists()) {
        await Directory(p).delete(recursive: true);
      } else {
        await File(p).delete();
      }
      resp.succeed = true;
    } on FileSystemException catch (e) {
      resp
        ..succeed = false
        ..errorCode = FileErr.unknow
        ..errorMessage = e.message;
    }
    return resp;
  }
}
