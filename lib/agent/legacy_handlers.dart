import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';

import '../ssp/bytes.dart';
import '../ssp/envelope.dart';
import '../ssp/pb/SmartSyncProtocol.recovered.pb.dart' as pb;
import '../ssp/types.dart';
import '../ssp/legacy_server.dart';
import 'providers/channel_providers.dart';
import 'providers/files_provider.dart';

/// Legacy ADBForward command dispatch (port 10086).
///
/// Implements the request body parsing and response body formats from
/// PROTOCOL.md §3 (StringList/IdList/lpString bodies, JSON/gzip responses,
/// 'Y'/'N' one-char acks, heartbeat pong behaviour handled by the server
/// itself).
class LegacyAgentHandlers {
  LegacyAgentHandlers({required this.files, required this.channels});

  final FilesProvider files;
  final ChannelProviders channels;

  /// SspAgentServer-compatible handler: returns the response body bytes.
  Future<Uint8List> call(LegacyConnection conn, LegacyRequest req) async {
    switch (req.command) {
      case LegacyCmd.oldThumbnail: // 1
        return _oldThumbnail(req);
      case LegacyCmd.fetch: // 2
        return _fetch(req);
      case LegacyCmd.get: // 3 — device info JSON
        return _deviceInfo();
      case LegacyCmd.terminate: // 4
        return utf8Bytes('ok');
      case LegacyCmd.keepAlive: // 5 — device JSON; conn stays open
        return _deviceInfo();
      case LegacyCmd.heartbeat: // 6 — pong body (server wraps)
        return utf8Bytes('');
      case LegacyCmd.newFetch: // 7 — gzip media library JSON
        return _newFetch(req);
      case LegacyCmd.thumbnail: // 8
        return _thumbnail(req);
      case LegacyCmd.watch: // 10
        return utf8Bytes('Y');
      case LegacyCmd.delete: // 11
        return _delete(req);
      case LegacyCmd.scan: // 12 SCEN
        return utf8Bytes('Y');
      case LegacyCmd.exif: // 13
        return _exif(req);
      default:
        return utf8Bytes('');
    }
  }

  // ---------------- bodies ----------------

  /// Device JSON keys per §3.4 (utils/e.java): version, device_name,
  /// device_owner, sdcard_root, file_num, picture_number, audio_number,
  /// video_number, download_number, screen_locked, disk_usage,
  /// battery_level.
  Future<Uint8List> _deviceInfo() async {
    final fakeReq = pbDeviceInfoRequest();
    final info = await channels.deviceInfo(fakeReq);
    final j = <String, dynamic>{
      'version': 1,
      'device_name': info.phoneName.isNotEmpty
          ? info.phoneName
          : info.phoneModel,
      'device_owner': '',
      'sdcard_root': info.externalStoragePath.isNotEmpty
          ? info.externalStoragePath
          : info.rootPath,
      'file_num': 0,
      'picture_number': info.picVideoSize.toInt(),
      'audio_number': info.audioSize.toInt(),
      'video_number': 0,
      'download_number': info.downloadSize.toInt(),
      'screen_locked': info.phoneLocked ? 1 : 0,
      'disk_usage': info.usedDiskSize.toInt(),
      'battery_level': info.batteryPercentage,
    };
    return utf8Bytes(jsonEncode(j));
  }

  /// FETCH (C=2): body+0 filterId I32BE (album/bucket filter); response is a
  /// UTF-8 JSON *array* of records, or empty body when nothing matches.
  Future<Uint8List> _fetch(LegacyRequest req) async {
    var filterId = 0;
    if (req.body.length >= 4) {
      filterId = ByteData.sublistView(req.body).getUint32(0);
    }
    final items = await _mediaItems(req.subtype, filterId);
    if (items.isEmpty) return utf8Bytes('');
    return utf8Bytes(jsonEncode(items));
  }

  /// NEW_FETCH (C=7): S=1 photo, 2 audio, 3 video. Response = gzip(JSON with
  /// all_item / all_group / item_with_group).
  Future<Uint8List> _newFetch(LegacyRequest req) async {
    final items = await _mediaItems(req.subtype, 0);
    if (items.isEmpty) return Uint8List(0);
    // Group by albumId.
    final groups = <int, List<Map<String, dynamic>>>{};
    for (final it in items) {
      groups.putIfAbsent(it['album_id'] as int? ?? 0, () => []).add(it);
    }
    final j = {
      'all_item': items,
      'all_group': [
        for (final e in groups.entries) e.value.first,
      ],
      'item_with_group': [
        for (final e in groups.entries)
          {'id': e.key, 'list': e.value},
      ],
    };
    return Uint8List.fromList(gzip.encode(utf8.encode(jsonEncode(j))));
  }

  Future<List<Map<String, dynamic>>> _mediaItems(
      int subtype, int filterId) async {
    // subtype: 1 photo / 2 audio / 3 video
    switch (subtype) {
      case 1:
        final lib = await channels.photoLibrary(pbPhotoLibRequest());
        return [
          for (final f in lib.imageArray)
            if (filterId == 0 || f.albumId.toInt() == filterId)
              {
                '_id': f.mediaId.toInt(),
                '_data': f.path,
                '_size': f.fileSize.toInt(),
                'mime_type': f.mimeType,
                'bucket_id': f.albumId.toInt(),
                'bucket_display_name': f.albumName,
                'date_added': f.createdTimestamp.toInt(),
                'date_modified': f.modifiedTimestamp.toInt(),
                'width': f.width,
                'height': f.height,
                'orientation': f.orientation,
                'title': f.title,
              },
        ];
      case 2:
        final lib = await channels.audioLibrary(pbAudioLibRequest());
        return [
          for (final f in lib.audioArray)
            if (filterId == 0 || f.albumId.toInt() == filterId)
              {
                '_id': f.mediaId.toInt(),
                '_data': f.path,
                '_size': f.fileSize.toInt(),
                'mime_type': f.mimeType,
                'album_id': f.albumId.toInt(),
                'artist': f.artist,
                'title': f.title,
                'duration': (f.duration * 1000).toInt(),
                'date_added': f.createdTimestamp.toInt(),
                'date_modified': f.modifiedTimestamp.toInt(),
              },
        ];
      case 3:
        final lib = await channels.videoLibrary(pbVideoLibRequest());
        return [
          for (final f in lib.videoArray)
            if (filterId == 0 || f.albumId.toInt() == filterId)
              {
                '_id': f.mediaId.toInt(),
                '_data': f.path,
                '_size': f.fileSize.toInt(),
                'mime_type': f.mimeType,
                'bucket_id': f.albumId.toInt(),
                'date_added': f.createdTimestamp.toInt(),
                'date_modified': f.modifiedTimestamp.toInt(),
                'width': f.width,
                'height': f.height,
                'duration': (f.duration * 1000).toInt(),
              },
        ];
    }
    return const [];
  }

  /// OLD_THUMBNAIL (C=1): StringList body of file paths; response = count +
  /// per-item lpString thumbnail-path entries (§3.4 thumbnail layout).
  Future<Uint8List> _oldThumbnail(LegacyRequest req) async {
    final paths = LegacyEnvelope.parseStringList(req.body);
    final thumbs = await channels.thumbnails(
        pbThumbnailRequest(paths.map((p) => 0).toList(), 1));
    // We cannot map path→mediaId without the platform index; respond with
    // empty entries (count + zero-length strings) when thumbs unavailable.
    final out = BytesBuilder();
    out.add(_be32(paths.length));
    for (var i = 0; i < paths.length; i++) {
      final thumbPath = i < thumbs.imageArray.length
          ? thumbs.imageArray[i].path
          : '';
      out.add(_be32(utf8.encode(thumbPath).length));
      out.add(utf8.encode(thumbPath));
    }
    return out.toBytes();
  }

  /// THUMBNAIL (C=8): IdList body of media ids; same response layout.
  Future<Uint8List> _thumbnail(LegacyRequest req) async {
    final ids = LegacyEnvelope.parseIdList(req.body);
    final thumbs = await channels.thumbnails(
        pbThumbnailRequest(ids.map((i) => i.toInt()).toList(),
            req.subtype == 2 ? 2 : (req.subtype == 3 ? 3 : 1)));
    final out = BytesBuilder();
    out.add(_be32(ids.length));
    for (final f in thumbs.imageArray) {
      final b = f.thumbnail;
      out.add(_be32(b.length));
      out.add(b);
    }
    return out.toBytes();
  }

  /// DELETE (C=11): IdList of MediaStore _id values. Response: IdList of
  /// successfully deleted ids (§3.4 delete layout) — our impl returns the
  /// input ids when the platform delete succeeds, empty otherwise.
  Future<Uint8List> _delete(LegacyRequest req) async {
    LegacyEnvelope.parseIdList(req.body);
    // Media deletion by _id needs the platform channel; without it we report
    // no deletions (empty IdList) rather than claiming success.
    final out = BytesBuilder()..add(_be32(0));
    return out.toBytes();
  }

  /// EXIF (C=13): lpString path → JSON object of EXIF attributes. We do not
  /// parse EXIF in Dart yet — respond with {} (a valid JSON object body).
  Future<Uint8List> _exif(LegacyRequest req) async {
    return utf8Bytes('{}');
  }
}

Uint8List _be32(int v) =>
    Uint8List(4)..buffer.asByteData().setUint32(0, v);

pb.SSPGetDeviceInfoRequest pbDeviceInfoRequest() =>
    pb.SSPGetDeviceInfoRequest()..type = Req.getDeviceInfo;
pb.SSPGetPhotoLibraryRequest pbPhotoLibRequest() =>
    pb.SSPGetPhotoLibraryRequest()..type = Req.getPhotoLib;
pb.SSPGetAudioLibraryRequest pbAudioLibRequest() =>
    pb.SSPGetAudioLibraryRequest()..type = Req.getAudioLib;
pb.SSPGetVideoLibraryRequest pbVideoLibRequest() =>
    pb.SSPGetVideoLibraryRequest()..type = Req.getVideoLib;
pb.SSPGetThumbnailRequest pbThumbnailRequest(List<int> ids, int mediaType) {
  final req = pb.SSPGetThumbnailRequest()..type = Req.getThumbnail;
  if (mediaType == 1) {
    for (final id in ids) {
      req.imageArray.add(pb.SSPImageFile()..mediaId = Int64(id));
    }
  } else if (mediaType == 2) {
    for (final id in ids) {
      req.videoArray.add(pb.SSPVideoFile()..mediaId = Int64(id));
    }
  } else {
    for (final id in ids) {
      req.audioAlbumArray.add(pb.SSPAudioAlbum()..albumId = Int64(id));
    }
  }
  return req;
}
