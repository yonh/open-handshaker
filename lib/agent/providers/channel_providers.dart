import 'dart:async';
import 'dart:convert';
import 'dart:io' show gzip;

import 'package:fixnum/fixnum.dart';
import 'package:flutter/services.dart';

import '../../ssp/pb/SmartSyncProtocol.recovered.pb.dart' as pb;
import '../../ssp/types.dart';
import '../platform_contract.dart';

/// Android-side providers reached over MethodChannel
/// (see platform_contract.dart for the method/map contract).
///
/// Every method degrades to an empty/default response on
/// MissingPluginException so the Dart agent runs on desktop for
/// development/testing without the Kotlin side.
class ChannelProviders {
  ChannelProviders({
    MethodChannel? providers,
    EventChannel? events,
    MethodChannel? service,
  })  : _providers =
            providers ?? const MethodChannel(AgentChannels.providers),
        _events = events ?? const EventChannel(AgentChannels.events),
        _service = service ?? const MethodChannel(AgentChannels.service);

  final MethodChannel _providers;
  final EventChannel _events;
  final MethodChannel _service;

  /// Raw event stream ('clipboard'/'mediaChange' events) from the platform.
  Stream<Map<dynamic, dynamic>> get platformEvents => _events
      .receiveBroadcastStream()
      .map((e) => e is Map ? e : const <dynamic, dynamic>{})
      .asBroadcastStream();

  Future<Map<dynamic, dynamic>?> _call(String method,
      [Map<String, dynamic>? args]) async {
    try {
      final r = await _providers.invokeMethod<dynamic>(method, args);
      return r is Map ? r : null;
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    } catch (_) {
      // ServicesBinding not initialized (desktop/unit-test context).
      return null;
    }
  }

  // ---------------- device info ----------------

  /// Fills device info fields of an SSPGetDeviceInfoResponse. Fields left
  /// absent on the platform side keep their defaults.
  Future<pb.SSPGetDeviceInfoResponse> deviceInfo(
      pb.SSPGetDeviceInfoRequest req) async {
    final resp = pb.SSPGetDeviceInfoResponse()
      ..type = Req.getDeviceInfo
      ..hostTimestamp = req.hostTimestamp
      ..hostSmartSyncProtocolVersion = req.hostSmartSyncProtocolVersion
      ..hostAppVersion = req.hostAppVersion
      ..hostMinClientVersion = req.hostMinClientVersion
      ..clientTimestamp =
          Int64(DateTime.now().millisecondsSinceEpoch ~/ 1000)
      ..clientSmartSyncProtocolVersion = '2';
    final m = await _call(AgentMethods.getDeviceInfo);
    if (m != null) {
      void s(String k, void Function(String) f) {
        final v = m[k];
        if (v is String && v.isNotEmpty) f(v);
      }

      void i(String k, void Function(Int64) f) {
        final v = m[k];
        if (v is int) f(Int64(v));
      }

      s('phoneModel', (v) => resp.phoneModel = v);
      s('phoneColor', (v) => resp.phoneColor = v);
      s('phoneName', (v) => resp.phoneName = v);
      s('productBrand', (v) => resp.productBrand = v);
      s('productManufacturer', (v) => resp.productManufacturer = v);
      s('smartisanVersion', (v) => resp.smartisanVersion = v);
      s('externalStoragePath', (v) => resp.externalStoragePath = v);
      s('rootPath', (v) => resp.rootPath = v);
      s('phoneId', (v) => resp.phoneId = v);
      s('apkVersionName', (v) => resp.apkVersionName = v);
      s('apkVersion', (v) => resp.apkVersion = v);
      i('diskSize', (v) => resp.diskSize = v);
      i('usedDiskSize', (v) => resp.usedDiskSize = v);
      i('ramSize', (v) => resp.ramSize = v);
      i('extDiskSize', (v) => resp.extDiskSize = v);
      i('extUsedDiskSize', (v) => resp.extUsedDiskSize = v);
      i('audioSize', (v) => resp.audioSize = v);
      i('picVideoSize', (v) => resp.picVideoSize = v);
      i('downloadSize', (v) => resp.downloadSize = v);
      i('otherSize', (v) => resp.otherSize = v);
      i('appSize', (v) => resp.appSize = v);
      i('cacheSize', (v) => resp.cacheSize = v);
      i('clientMinHostVersionCode',
          (v) => resp.clientMinHostVersionCode = v);
      final b = m['batteryPercentage'];
      if (b is int) resp.batteryPercentage = b;
      final locked = m['phoneLocked'];
      if (locked is bool) resp.phoneLocked = locked;
      final perm = m['externalStoragePermission'];
      if (perm is int) {
        resp.externalStoragePermission = FilePerm.readWrite;
        if (perm == StoragePermissionLevels.none) {
          resp.externalStoragePermission = FilePerm.none;
        } else if (perm == StoragePermissionLevels.read) {
          resp.externalStoragePermission = FilePerm.read;
        } else if (perm == StoragePermissionLevels.write) {
          resp.externalStoragePermission = FilePerm.write;
        }
      }
    }
    return resp;
  }

  // ---------------- media libraries ----------------

  pb.SSPImageFile _imageFile(Map<dynamic, dynamic> m) {
    return pb.SSPImageFile()
      ..path = m['path'] as String? ?? ''
      ..fileSize = Int64(m['fileSize'] as int? ?? 0)
      ..createdTimestamp =
          Int64(m['createdTimestamp'] as int? ?? 0)
      ..modifiedTimestamp =
          Int64(m['modifiedTimestamp'] as int? ?? 0)
      ..mediaId = Int64(m['mediaId'] as int? ?? 0)
      ..albumId = Int64(m['albumId'] as int? ?? 0)
      ..albumName = m['albumName'] as String? ?? ''
      ..mimeType = m['mimeType'] as String? ?? ''
      ..width = m['width'] as int? ?? 0
      ..height = m['height'] as int? ?? 0
      ..orientation = m['orientation'] as int? ?? 0
      ..title = m['title'] as String? ?? '';
  }

  pb.SSPVideoFile _videoFile(Map<dynamic, dynamic> m) {
    return pb.SSPVideoFile()
      ..path = m['path'] as String? ?? ''
      ..fileSize = Int64(m['fileSize'] as int? ?? 0)
      ..createdTimestamp = m['createdTimestamp'] as int? ?? 0
      ..modifiedTimestamp = m['modifiedTimestamp'] as int? ?? 0
      ..mediaId = Int64(m['mediaId'] as int? ?? 0)
      ..albumId = Int64(m['albumId'] as int? ?? 0)
      ..mimeType = m['mimeType'] as String? ?? ''
      ..width = m['width'] as int? ?? 0
      ..height = m['height'] as int? ?? 0
      ..duration = (m['durationMs'] as int? ?? 0) / 1000.0;
  }

  pb.SSPAudioFile _audioFile(Map<dynamic, dynamic> m) {
    return pb.SSPAudioFile()
      ..path = m['path'] as String? ?? ''
      ..fileSize = Int64(m['fileSize'] as int? ?? 0)
      ..createdTimestamp =
          Int64(m['createdTimestamp'] as int? ?? 0)
      ..modifiedTimestamp =
          Int64(m['modifiedTimestamp'] as int? ?? 0)
      ..mediaId = Int64(m['mediaId'] as int? ?? 0)
      ..albumId = Int64(m['albumId'] as int? ?? 0)
      ..title = m['title'] as String? ?? ''
      ..mimeType = m['mimeType'] as String? ?? ''
      ..artist = m['artist'] as String? ?? ''
      ..duration = (m['durationMs'] as int? ?? 0) / 1000.0;
  }

  Future<pb.SSPGetPhotoLibraryResponse> photoLibrary(
      pb.SSPGetPhotoLibraryRequest req) async {
    final resp = pb.SSPGetPhotoLibraryResponse()..type = Req.getPhotoLib;
    final m = await _call(AgentMethods.getPhotoLibrary);
    final albums = m?['albums'];
    if (albums is List) {
      for (final a in albums) {
        if (a is! Map) continue;
        final album = pb.SSPImageAlbum()
          ..albumName = a['name'] as String? ?? ''
          ..albumId = Int64(a['albumId'] as int? ?? 0)
          ..albumPath = a['path'] as String? ?? '';
        final files = a['files'];
        if (files is List) {
          for (final f in files) {
            if (f is Map) {
              final img = _imageFile(f)..albumName = album.albumName;
              album.coverImage = img;
              resp.imageArray.add(img);
            }
          }
        }
        resp.albumArray.add(album);
      }
    }
    return resp;
  }

  Future<pb.SSPGetVideoLibraryResponse> videoLibrary(
      pb.SSPGetVideoLibraryRequest req) async {
    final resp = pb.SSPGetVideoLibraryResponse()..type = Req.getVideoLib;
    final m = await _call(AgentMethods.getVideoLibrary);
    final albums = m?['albums'];
    if (albums is List) {
      for (final a in albums) {
        if (a is! Map) continue;
        final album = pb.SSPVideoAlbum()
          ..albumName = a['name'] as String? ?? ''
          ..albumId = Int64(a['albumId'] as int? ?? 0)
          ..albumPath = a['path'] as String? ?? '';
        final files = a['files'];
        if (files is List) {
          for (final f in files) {
            if (f is Map) resp.videoArray.add(_videoFile(f));
          }
        }
        resp.albumArray.add(album);
      }
    }
    return resp;
  }

  Future<pb.SSPGetAudioLibraryResponse> audioLibrary(
      pb.SSPGetAudioLibraryRequest req) async {
    final resp = pb.SSPGetAudioLibraryResponse()..type = Req.getAudioLib;
    final m = await _call(AgentMethods.getAudioLibrary);
    final albums = m?['albums'];
    if (albums is List) {
      for (final a in albums) {
        if (a is! Map) continue;
        final album = pb.SSPAudioAlbum()
          ..albumName = a['name'] as String? ?? ''
          ..albumId = Int64(a['albumId'] as int? ?? 0)
          ..albumPath = a['path'] as String? ?? '';
        final files = a['files'];
        if (files is List) {
          for (final f in files) {
            if (f is Map) resp.audioArray.add(_audioFile(f));
          }
        }
        resp.albumArray.add(album);
      }
    }
    return resp;
  }

  /// Fetches thumbnails: the channel returns cache-file paths; the bytes are
  /// loaded and embedded in the matching SSPImageFile.thumbnail field.
  Future<pb.SSPGetThumbnailResponse> thumbnails(
      pb.SSPGetThumbnailRequest req) async {
    final resp = pb.SSPGetThumbnailResponse()
      ..type = Req.getThumbnail
      ..imageArray.addAll(req.imageArray)
      ..videoArray.addAll(req.videoArray)
      ..audioAlbumArray.addAll(req.audioAlbumArray);
    final ids = <int>[
      for (final f in req.imageArray) f.mediaId.toInt(),
      for (final f in req.videoArray) f.mediaId.toInt(),
      for (final a in req.audioAlbumArray) a.albumId.toInt(),
    ];
    final mediaType = req.imageArray.isNotEmpty
        ? 1
        : req.videoArray.isNotEmpty
            ? 2
            : 3;
    final m = await _call(AgentMethods.getThumbnail,
        {'ids': ids, 'mediaType': mediaType});
    final thumbs = m?['thumbnails'];
    if (thumbs is List) {
      final byId = <int, Uint8List>{};
      for (final t in thumbs) {
        if (t is Map && t['bytes'] is Uint8List) {
          byId[t['mediaId'] as int? ?? 0] = t['bytes'] as Uint8List;
        }
      }
      for (final f in resp.imageArray) {
        final b = byId[f.mediaId.toInt()];
        if (b != null) f.thumbnail = b;
      }
      for (final f in resp.videoArray) {
        final b = byId[f.mediaId.toInt()];
        if (b != null) f.thumbnail = b;
      }
      for (final a in resp.audioAlbumArray) {
        final b = byId[a.albumId.toInt()];
        if (b != null) a.thumbnail = b;
      }
    }
    return resp;
  }

  // ---------------- clipboard ----------------

  Future<pb.SSPGetClipboardResponse> getClipboard() async {
    final resp = pb.SSPGetClipboardResponse()..type = Req.getClipboard;
    final m = await _call(AgentMethods.getClipboard);
    final content = m?['content'];
    if (content is String && content.isNotEmpty) {
      resp.clipboardArray.add(pb.SSPClipboard()
        ..content = Uint8List.fromList(
            gzipBytes(content))
        ..mstimestamp =
            Int64((DateTime.now().millisecondsSinceEpoch ~/ 1000) * 1000));
    }
    return resp;
  }

  Future<pb.SSPPostClipboardResponse> postClipboard(
      pb.SSPPostClipboardRequest req) async {
    final resp = pb.SSPPostClipboardResponse()
      ..type = Req.postClipboard
      ..succeed = true;
    try {
      final text = utf8GzipDecode(req.clipboard.content);
      await _providers.invokeMethod(
          AgentMethods.setClipboard, {'content': text});
    } on MissingPluginException {
      resp.succeed = false;
    } on PlatformException {
      resp.succeed = false;
    } catch (_) {
      resp.succeed = false;
    }
    return resp;
  }

  Future<pb.SSPClearClipboardResponse> clearClipboard() async {
    final resp = pb.SSPClearClipboardResponse()
      ..type = Req.clearClipboard
      ..succeed = true;
    try {
      await _providers.invokeMethod(
          AgentMethods.setClipboard, {'content': ''});
    } on MissingPluginException {
      resp.succeed = false;
    } on PlatformException {
      resp.succeed = false;
    } catch (_) {
      resp.succeed = false;
    }
    return resp;
  }

  // ---------------- installed apps ----------------

  Future<List<Map<dynamic, dynamic>>> installedApps() async {
    try {
      final r = await _providers.invokeMethod<List<dynamic>>(
          AgentMethods.getInstalledApps);
      return r?.whereType<Map<dynamic, dynamic>>().toList() ?? [];
    } catch (_) {
      return const [];
    }
  }

  Future<void> uninstallApp(String packageName) async {
    try {
      await _providers.invokeMethod(
          AgentMethods.uninstallApp, {'packageName': packageName});
    } catch (_) {
      // no platform side
    }
  }

  // ---------------- foreground service ----------------

  Future<void> startService({String title = '', String text = ''}) async {
    try {
      await _service.invokeMethod(
          'startService', {'title': title, 'text': text});
    } on MissingPluginException {
      // desktop dev — no-op
    } on PlatformException {
      // leave disabled
    } catch (_) {
      // no binding
    }
  }

  Future<void> stopService() async {
    try {
      await _service.invokeMethod('stopService');
    } on MissingPluginException {
      // no-op
    } on PlatformException {
      // no-op
    } catch (_) {
      // no binding
    }
  }
}

Uint8List gzipBytes(String s) =>
    Uint8List.fromList(gzip.encode(utf8.encode(s)));

String utf8GzipDecode(List<int> bytes) =>
    utf8.decode(gzip.decode(bytes));
