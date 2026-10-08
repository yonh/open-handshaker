import 'dart:async';
import 'dart:convert';
import 'dart:io' show File, zlib;
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';

import '../../ssp/client.dart';
import '../../ssp/pb/SmartSyncProtocol.recovered.pb.dart' as pb;
import '../../ssp/requests.dart';
import '../../ssp/transport.dart';
import '../../ssp/trust_store.dart';
import '../host_controller.dart';
import 'apps_page.dart';

// ---------------------------------------------------------------------------
// PNG encoder — pure-Dart minimal encoder (RGBA8, zlib stored via dart:io).
// Used to synthesize colored thumbnails for the demo/mock data source so the
// media pages render real Image.memory content without a device.
// ---------------------------------------------------------------------------

final _crcTable = _buildCrcTable();

List<int> _buildCrcTable() {
  final t = List<int>.filled(256, 0);
  for (var i = 0; i < 256; i++) {
    var c = i;
    for (var k = 0; k < 8; k++) {
      c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
    }
    t[i] = c;
  }
  return t;
}

int _crc32(List<int> bytes) {
  var crc = 0xFFFFFFFF;
  for (final b in bytes) {
    crc = _crcTable[(crc ^ b) & 0xFF] ^ (crc >> 8);
  }
  return crc ^ 0xFFFFFFFF;
}

List<int> _pngChunk(String type, List<int> data) {
  final len = ByteData(4)..setUint32(0, data.length, Endian.big);
  final body = [...type.codeUnits, ...data];
  final crc = ByteData(4)..setUint32(0, _crc32(body), Endian.big);
  return [...len.buffer.asUint8List(), ...body, ...crc.buffer.asUint8List()];
}

/// Encode a solid-color [width]x[height] RGBA PNG. [rgba] is (r,g,b,a).
Uint8List solidPng(int width, int height, (int, int, int, int) rgba) {
  final ihdr = ByteData(13)
    ..setUint32(0, width, Endian.big)
    ..setUint32(4, height, Endian.big)
    ..setUint8(8, 8) // bit depth
    ..setUint8(9, 6) // RGBA
    ..setUint8(10, 0)
    ..setUint8(11, 0)
    ..setUint8(12, 0);
  final row = Uint8List(1 + width * 4);
  for (var x = 0; x < width; x++) {
    row[1 + x * 4] = rgba.$1;
    row[2 + x * 4] = rgba.$2;
    row[3 + x * 4] = rgba.$3;
    row[4 + x * 4] = rgba.$4;
  }
  final raw = BytesBuilder();
  for (var y = 0; y < height; y++) {
    raw.add(row);
  }
  final idat = zlib.encode(raw.toBytes());
  return Uint8List.fromList([
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
    ..._pngChunk('IHDR', ihdr.buffer.asUint8List()),
    ..._pngChunk('IDAT', idat),
    ..._pngChunk('IEND', const []),
  ]);
}

// ---------------------------------------------------------------------------
// Inert channel + identity so DemoSspApi can satisfy the SspApi constructor.
// ---------------------------------------------------------------------------

class _StubChannel extends ByteChannel {
  @override
  Stream<Uint8List> get incoming => const Stream.empty();
  @override
  void send(Uint8List data) {}
  @override
  String get peerLabel => 'demo';
  @override
  Future<void> close() async {}
}

/// pointycastle 校验 p*q==n，占位数字会抛异常——生成一次真密钥对并缓存。
HostIdentity? _cachedIdentity;

HostIdentity _demoIdentity() =>
    _cachedIdentity ??= HostIdentity.generate(
        hostUuid: 'demo-host', hostName: 'Demo Mac');

/// Demo client whose transfers never touch the wire: download writes a
/// placeholder body locally, upload reports the local size. Lets
/// PhotoSyncEngine / IdeaPillsSync complete their round-trips in demo mode
/// instead of stalling on a stub channel.
class _DemoClient extends SspClient {
  _DemoClient() : super(_StubChannel(), identity: _demoIdentity());

  @override
  Future<pb.SSPDownloadFileResponseHeader> download(String remotePath,
      String localPath,
      {int offset = 0,
      int length = 0,
      bool needMd5 = false,
      void Function(int received, int total)? onProgress,
      bool Function()? cancelled}) async {
    final body = utf8.encode('demo content for $remotePath\n');
    final f = File(localPath);
    await f.parent.create(recursive: true);
    await f.writeAsBytes(body);
    onProgress?.call(body.length, body.length);
    return pb.SSPDownloadFileResponseHeader()
      ..ready = true
      ..range = (pb.SSPDataRange()
        ..offset = Int64(0)
        ..length = Int64(body.length));
  }

  @override
  Future<pb.SSPUploadFileResponse> upload(String localPath, String remotePath,
      {void Function(int sent, int total)? onProgress,
      bool Function()? cancelled}) async {
    final size = await File(localPath).length();
    onProgress?.call(size, size);
    return pb.SSPUploadFileResponse()
      ..succeed = true
      ..file = (pb.SSPFile()
        ..path = remotePath
        ..fileSize = Int64(size));
  }
}

// ---------------------------------------------------------------------------
// DemoSspApi — canned SSP responses for UI development and widget tests.
// ---------------------------------------------------------------------------

pb.SSPFile _f(String path,
        {bool dir = false,
        int size = 0,
        int created = 0,
        int modified = 0}) =>
    pb.SSPFile()
      ..path = path
      ..isDirectory = dir
      ..fileSize = Int64(size)
      ..createdTimestamp = Int64(created)
      ..modifiedTimestamp = Int64(modified);

/// [SspApi] subclass backed by canned data. Mutable fields let tests replace
/// fixtures; [calls] records invoked operations for assertions.
class DemoSspApi extends SspApi {
  DemoSspApi() : super(_DemoClient()) {
    _seed();
  }

  /// Invoked operations as 'name(arg,arg)' strings — tests assert on these.
  final List<String> calls = [];

  /// Directory listing fixtures: remote path -> children.
  final Map<String, List<pb.SSPFile>> dirs = {};

  List<pb.SSPImageFile> photos = [];
  List<pb.SSPImageAlbum> photoAlbums = [];
  List<pb.SSPVideoFile> videos = [];
  List<pb.SSPVideoAlbum> videoAlbums = [];
  List<pb.SSPAudioFile> songs = [];
  List<pb.SSPAudioAlbum> audioAlbums = [];
  List<String> clipboardTexts = ['手机里复制的文本示例'];
  pb.SSPGetDeviceInfoResponse? deviceInfo;

  void _seed() {
    const t = 1700000000;
    dirs['/'] = [
      _f('/sdcard', dir: true, modified: t),
    ];
    dirs['/sdcard'] = [
      _f('/sdcard/DCIM', dir: true, modified: t - 100),
      _f('/sdcard/Download', dir: true, modified: t - 200),
      _f('/sdcard/Music', dir: true, modified: t - 300),
      _f('/sdcard/文档说明.txt', size: 2048, modified: t - 400),
    ];
    dirs['/sdcard/DCIM'] = [
      _f('/sdcard/DCIM/Camera', dir: true, modified: t),
    ];
    dirs['/sdcard/DCIM/Camera'] = [
      _f('/sdcard/DCIM/Camera/IMG_001.jpg', size: 3456789, modified: t - 50),
      _f('/sdcard/DCIM/Camera/IMG_002.jpg', size: 2876543, modified: t - 60),
    ];
    dirs['/sdcard/Download'] = [
      _f('/sdcard/Download/报告.pdf', size: 1024000, modified: t - 900),
      _f('/sdcard/Download/app-release.apk',
          size: 24567890, modified: t - 800),
    ];
    dirs['/sdcard/Music'] = [
      _f('/sdcard/Music/demo.mp3', size: 4567890, modified: t - 700),
    ];

    final thumbA = solidPng(96, 96, (91, 126, 247, 255));
    final thumbB = solidPng(96, 96, (240, 128, 96, 255));
    final thumbC = solidPng(96, 96, (80, 180, 120, 255));

    photos = [
      pb.SSPImageFile()
        ..path = '/sdcard/DCIM/Camera/IMG_001.jpg'
        ..fileSize = Int64(3456789)
        ..mediaId = Int64(101)
        ..albumId = Int64(1)
        ..albumName = '相机'
        ..title = 'IMG_001.jpg'
        ..mimeType = 'image/jpeg'
        ..width = 4000
        ..height = 3000
        ..dateTaken = Int64(t - 3600)
        ..thumbnail = thumbA,
      pb.SSPImageFile()
        ..path = '/sdcard/DCIM/Camera/IMG_002.jpg'
        ..fileSize = Int64(2876543)
        ..mediaId = Int64(102)
        ..albumId = Int64(1)
        ..albumName = '相机'
        ..title = 'IMG_002.jpg'
        ..mimeType = 'image/jpeg'
        ..width = 4000
        ..height = 3000
        ..dateTaken = Int64(t - 7200)
        ..thumbnail = thumbB,
      pb.SSPImageFile()
        ..path = '/sdcard/Pictures/截图.png'
        ..fileSize = Int64(456789)
        ..mediaId = Int64(103)
        ..albumId = Int64(2)
        ..albumName = '截图'
        ..title = '截图.png'
        ..mimeType = 'image/png'
        ..width = 1080
        ..height = 2400
        ..dateTaken = Int64(t - 10800)
        ..thumbnail = thumbC,
    ];
    photoAlbums = [
      pb.SSPImageAlbum()
        ..albumId = Int64(1)
        ..albumName = '相机'
        ..albumPath = '/sdcard/DCIM/Camera'
        ..coverImage = photos[0],
      pb.SSPImageAlbum()
        ..albumId = Int64(2)
        ..albumName = '截图'
        ..albumPath = '/sdcard/Pictures'
        ..coverImage = photos[2],
    ];

    videos = [
      pb.SSPVideoFile()
        ..path = '/sdcard/DCIM/Camera/VID_001.mp4'
        ..fileSize = Int64(52428800)
        ..mediaId = Int64(201)
        ..albumId = Int64(1)
        ..mimeType = 'video/mp4'
        ..width = 1920
        ..height = 1080
        ..duration = 95.5
        ..createdTimestamp = t - 5000
        ..modifiedTimestamp = t - 5000
        ..thumbnail = thumbA,
      pb.SSPVideoFile()
        ..path = '/sdcard/Movies/演示.webm'
        ..fileSize = Int64(20971520)
        ..mediaId = Int64(202)
        ..albumId = Int64(2)
        ..mimeType = 'video/webm'
        ..width = 1280
        ..height = 720
        ..duration = 32.0
        ..createdTimestamp = t - 6000
        ..modifiedTimestamp = t - 6000
        ..thumbnail = thumbB,
    ];
    videoAlbums = [
      pb.SSPVideoAlbum()
        ..albumId = Int64(1)
        ..albumName = '相机视频'
        ..albumPath = '/sdcard/DCIM/Camera',
      pb.SSPVideoAlbum()
        ..albumId = Int64(2)
        ..albumName = '电影'
        ..albumPath = '/sdcard/Movies',
    ];

    songs = [
      pb.SSPAudioFile()
        ..path = '/sdcard/Music/晴天.mp3'
        ..fileSize = Int64(8901234)
        ..mediaId = Int64(301)
        ..albumId = Int64(10)
        ..title = '晴天'
        ..artist = '周杰伦'
        ..duration = 269.0
        ..mimeType = 'audio/mpeg'
        ..year = 2003,
      pb.SSPAudioFile()
        ..path = '/sdcard/Music/Lemon.mp3'
        ..fileSize = Int64(7654321)
        ..mediaId = Int64(302)
        ..albumId = Int64(11)
        ..title = 'Lemon'
        ..artist = '米津玄師'
        ..duration = 255.0
        ..mimeType = 'audio/mpeg'
        ..year = 2018,
      pb.SSPAudioFile()
        ..path = '/sdcard/Music/demo.flac'
        ..fileSize = Int64(25678901)
        ..mediaId = Int64(303)
        ..albumId = Int64(10)
        ..title = '演示曲目'
        ..artist = '未知艺人'
        ..duration = 312.0
        ..mimeType = 'audio/flac'
        ..year = 2024,
    ];
    audioAlbums = [
      pb.SSPAudioAlbum()
        ..albumId = Int64(10)
        ..albumName = '叶惠美'
        ..artist = '周杰伦'
        ..thumbnail = thumbA,
      pb.SSPAudioAlbum()
        ..albumId = Int64(11)
        ..albumName = 'STRAY SHEEP'
        ..artist = '米津玄師'
        ..thumbnail = thumbC,
    ];

    deviceInfo = pb.SSPGetDeviceInfoResponse()
      ..phoneModel = 'OE106'
      ..phoneName = '坚果 Pro 3 (Demo)'
      ..productBrand = 'smartisan'
      ..productManufacturer = 'smartisan'
      ..smartisanVersion = '8.0.0'
      ..batteryPercentage = 76
      ..diskSize = Int64(128 * 1024 * 1024 * 1024)
      ..usedDiskSize = Int64(60 * 1024 * 1024 * 1024)
      ..rootPath = '/sdcard'
      ..externalStoragePath = '/sdcard';
  }

  @override
  Future<pb.SSPGetDirFilesResponse> listDir(String path,
      {int maxdepth = 1}) async {
    calls.add('listDir($path)');
    final resp = pb.SSPGetDirFilesResponse()
      ..dir = _f(path, dir: true)
      ..maxdepth = maxdepth;
    resp.fileArray.addAll(dirs[path] ?? []);
    return resp;
  }

  @override
  Future<bool> fileExists(String path) async {
    calls.add('fileExists($path)');
    for (final files in dirs.values) {
      for (final f in files) {
        if (f.path == path) return true;
      }
    }
    return dirs.containsKey(path);
  }

  @override
  Future<pb.SSPCreateFolderResponse> createFolder(String path) async {
    calls.add('createFolder($path)');
    final f = _f(path, dir: true, modified: _now());
    final parent = path.substring(0, path.lastIndexOf('/'));
    dirs.putIfAbsent(parent.isEmpty ? '/' : parent, () => []).add(f);
    dirs[path] = [];
    return pb.SSPCreateFolderResponse()
      ..file = f
      ..succeed = true;
  }

  @override
  Future<pb.SSPRenameFileResponse> rename(String src, String dst) async {
    calls.add('rename($src,$dst)');
    pb.SSPFile? found;
    for (final files in dirs.values) {
      for (final f in files) {
        if (f.path == src) {
          f.path = dst;
          found = f;
        }
      }
    }
    return pb.SSPRenameFileResponse()
      ..sourceFile = _f(src)
      ..targetFile = found ?? _f(dst)
      ..succeed = found != null;
  }

  @override
  Future<pb.SSPDeleteFileResponse> delete(String path,
      {bool isSync = false, bool isTrash = false}) async {
    calls.add('delete($path)');
    var removed = false;
    for (final files in dirs.values) {
      final n = files.length;
      files.removeWhere((f) => f.path == path);
      removed |= files.length != n;
    }
    photos.removeWhere((f) => f.path == path);
    videos.removeWhere((f) => f.path == path);
    songs.removeWhere((f) => f.path == path);
    return pb.SSPDeleteFileResponse()
      ..file = _f(path)
      ..succeed = removed;
  }

  @override
  Future<pb.SSPGetDeviceInfoResponse> getDeviceInfo({
    bool needDeviceInfoCallback = false,
    bool needPhotoLibraryCallback = false,
    bool needAudioLibraryCallback = false,
    bool needVideoLibraryCallback = false,
  }) async {
    calls.add('getDeviceInfo()');
    return deviceInfo ?? pb.SSPGetDeviceInfoResponse();
  }

  @override
  Future<pb.SSPGetPhotoLibraryResponse> photoLibrary() async {
    calls.add('photoLibrary()');
    final resp = pb.SSPGetPhotoLibraryResponse()
      ..cameraAlbumId = Int64(1);
    resp.imageArray.addAll(photos);
    resp.albumArray.addAll(photoAlbums);
    return resp;
  }

  @override
  Future<pb.SSPGetVideoLibraryResponse> videoLibrary() async {
    calls.add('videoLibrary()');
    final resp = pb.SSPGetVideoLibraryResponse();
    resp.videoArray.addAll(videos);
    resp.albumArray.addAll(videoAlbums);
    return resp;
  }

  @override
  Future<pb.SSPGetAudioLibraryResponse> audioLibrary() async {
    calls.add('audioLibrary()');
    final resp = pb.SSPGetAudioLibraryResponse();
    resp.audioArray.addAll(songs);
    resp.albumArray.addAll(audioAlbums);
    return resp;
  }

  @override
  Future<pb.SSPGetThumbnailResponse> thumbnails({
    List<pb.SSPImageFile> images = const [],
    List<pb.SSPVideoFile> videos = const [],
    List<pb.SSPAudioAlbum> audioAlbums = const [],
  }) async {
    calls.add('thumbnails(${images.length}i,${videos.length}v,'
        '${audioAlbums.length}a)');
    final resp = pb.SSPGetThumbnailResponse();
    // Demo fixtures already carry thumbnail bytes; echo requests back.
    resp.imageArray.addAll(images);
    resp.videoArray.addAll(videos);
    resp.audioAlbumArray.addAll(audioAlbums);
    return resp;
  }

  @override
  Future<List<pb.SSPClipboard>> getClipboard() async {
    calls.add('getClipboard()');
    return [
      for (final t in clipboardTexts) SspApi.clipboardText(t),
    ];
  }

  @override
  Future<bool> postClipboardText(String text) async {
    calls.add('postClipboardText($text)');
    clipboardTexts = [text];
    return true;
  }

  @override
  Future<bool> clearClipboard() async {
    calls.add('clearClipboard()');
    clipboardTexts = [];
    return true;
  }

  @override
  Future<pb.SSPMonitorFolderResponseHeader> monitorFolder(String path,
      {bool register = true}) async {
    calls.add('monitorFolder($path,$register)');
    return pb.SSPMonitorFolderResponseHeader()..succeed = true;
  }

  @override
  Future<pb.SSPPhotoSyncResponse> photoSync(String pcId,
      {List<pb.SSPFile> files = const []}) async {
    calls.add('photoSync($pcId,${files.length})');
    final resp = pb.SSPPhotoSyncResponse()
      ..isFirst = files.isEmpty
      ..isSuccess = true;
    // 把手机照片按路径喂给同步引擎，演示镜像逻辑。
    for (final p in photos) {
      resp.filesArray.add(pb.SSPFile()
        ..path = p.path
        ..fileSize = p.fileSize
        ..modifiedTimestamp = p.modifiedTimestamp
        ..isDirectory = false);
    }
    return resp;
  }

  @override
  Future<pb.SSPSyncMonitorResponse> syncMonitor({bool enable = true}) async {
    calls.add('syncMonitor($enable)');
    return pb.SSPSyncMonitorResponse()..isSuccess = true;
  }

  @override
  Future<pb.SSPUpdateFileResponse> updateFileInfo(List<pb.SSPFile> files,
      {bool isSync = false}) async {
    calls.add('updateFileInfo(${files.length},$isSync)');
    return pb.SSPUpdateFileResponse()..isSuccess = true;
  }

  int _now() => DateTime.now().millisecondsSinceEpoch ~/ 1000;
}

// ---------------------------------------------------------------------------
// DemoHostController — MockHostController with seeded candidates, a fake
// connected device and simulated transfer progress for the demo run.
// ---------------------------------------------------------------------------

class DemoHostController extends MockHostController {
  DemoHostController({super.api}) {
    addCandidate(DeviceCandidate(
      id: 'wifi:192.168.1.23',
      label: '坚果 Pro 3 (Demo)',
      address: '192.168.1.23',
      port: 10088,
      source: DiscoverySource.wifi,
    ));
    addCandidate(DeviceCandidate(
      id: 'usb:emulator-5554',
      label: 'Android Emulator',
      address: '127.0.0.1',
      port: 10088,
      source: DiscoverySource.usb,
    ));
  }

  final _demoTransfers = <TransferTask>[];
  final _demoTransfersCtl =
      StreamController<List<TransferTask>>.broadcast();
  int _seq = 0;

  @override
  TrustedDevice? get connectedDevice =>
      state == ConnState.connected
          ? TrustedDevice(
              deviceUuid: 'demo-uuid',
              deviceName: '坚果 Pro 3 (Demo)',
              connectionCount: 3,
            )
          : null;

  @override
  List<TransferTask> get transfers => List.unmodifiable(_demoTransfers);

  @override
  Stream<List<TransferTask>> get transfersStream => _demoTransfersCtl.stream;

  void _pushTransfers() =>
      _demoTransfersCtl.add(List.unmodifiable(_demoTransfers));

  /// Simulates a chunked transfer with visible progress. The task object
  /// lives in [_demoTransfers] while it runs; pause/cancel mutate it in
  /// place like HostControllerImpl does.
  TransferTask _enqueue(String name, int total,
      {required bool isUpload,
      required String remotePath,
      required String localPath}) {
    final t = TransferTask(
        id: 'd${++_seq}',
        name: name,
        total: total,
        isUpload: isUpload,
        remotePath: remotePath,
        localPath: localPath);
    _demoTransfers.insert(0, t);
    _pushTransfers();
    unawaited(_simulate(t));
    return t;
  }

  Future<void> _simulate(TransferTask t) async {
    const step = 8 * 1024 * 1024;
    while (t.done < t.total) {
      await Future<void>.delayed(const Duration(milliseconds: 120));
      if (t.cancelled) return;
      if (t.paused) continue;
      t.done = (t.done + step) > t.total ? t.total : t.done + step;
      _pushTransfers();
    }
    t.completed = true;
    _pushTransfers();
  }

  @override
  Future<TransferTask> downloadFile(String remotePath, String localPath,
      {String? taskName}) async {
    final total = _sizeOf(remotePath) ?? 8 * 1024 * 1024;
    return _enqueue(taskName ?? remotePath.split('/').last, total,
        isUpload: false, remotePath: remotePath, localPath: localPath);
  }

  @override
  Future<TransferTask> uploadFile(String localPath, String remotePath,
      {String? taskName}) async {
    return _enqueue(taskName ?? localPath.split('/').last, 16 * 1024 * 1024,
        isUpload: true, remotePath: remotePath, localPath: localPath);
  }

  @override
  void cancelTransfer(String taskId) {
    final t = _demoTransfers.where((t) => t.id == taskId).firstOrNull;
    if (t == null) return;
    t
      ..cancelled = true
      ..waiting = false
      ..paused = false;
    _pushTransfers();
  }

  @override
  void pauseTransfer(String taskId) {
    final t = _demoTransfers.where((t) => t.id == taskId).firstOrNull;
    if (t == null) return;
    t.paused = true;
    _pushTransfers();
  }

  @override
  void resumeTransfer(String taskId) {
    final t = _demoTransfers.where((t) => t.id == taskId).firstOrNull;
    if (t == null) return;
    t.paused = false;
    _pushTransfers();
  }

  int? _sizeOf(String path) {
    final api = this.api;
    if (api is DemoSspApi) {
      for (final files in api.dirs.values) {
        for (final f in files) {
          if (f.path == path) return f.fileSize.toInt();
        }
      }
      for (final f in api.photos) {
        if (f.path == path) return f.fileSize.toInt();
      }
      for (final f in api.videos) {
        if (f.path == path) return f.fileSize.toInt();
      }
      for (final f in api.songs) {
        if (f.path == path) return f.fileSize.toInt();
      }
    }
    return null;
  }

  @override
  Future<void> dispose() async {
    await _demoTransfersCtl.close();
    await super.dispose();
  }
}

// ---------------------------------------------------------------------------
// DemoAppsSource — canned installed-app inventory for the apps page.
// ---------------------------------------------------------------------------

class DemoAppsSource extends AppsSource {
  List<InstalledApp>? _apps;

  @override
  Future<List<InstalledApp>> load(HostController controller) async {
    return List.unmodifiable(_apps ??= [
        InstalledApp(
          packageName: 'com.tencent.mm',
          label: '微信',
          versionName: '8.0.47',
          sizeBytes: 812 * 1024 * 1024,
          apkPath: '/data/app/com.tencent.mm/base.apk',
        ),
        InstalledApp(
          packageName: 'com.smartisan.notes',
          label: '便签',
          versionName: '4.2.1',
          sizeBytes: 96 * 1024 * 1024,
          apkPath: '/data/app/com.smartisan.notes/base.apk',
        ),
        InstalledApp(
          packageName: 'com.example.player',
          label: '音乐播放器',
          versionName: '1.3.0',
          sizeBytes: 42 * 1024 * 1024,
          apkPath: '/data/app/com.example.player/base.apk',
        ),
        InstalledApp(
          packageName: 'com.android.settings',
          label: '设置',
          versionName: '10',
          sizeBytes: 28 * 1024 * 1024,
          apkPath: '/system/app/Settings/Settings.apk',
          system: true,
        ),
      ]);
  }

  @override
  Future<bool> uninstall(
      HostController controller, InstalledApp app) async {
    _apps?.removeWhere((a) => a.packageName == app.packageName);
    return true;
  }
}
