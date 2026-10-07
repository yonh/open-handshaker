import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:handshaker_open/host/host_controller.dart';
import 'package:handshaker_open/host/pages/apps_page.dart';
import 'package:handshaker_open/host/pages/clipboard_page.dart';
import 'package:handshaker_open/host/pages/connect_page.dart';
import 'package:handshaker_open/host/pages/demo_support.dart';
import 'package:handshaker_open/host/pages/files_page.dart';
import 'package:handshaker_open/host/pages/host_shell.dart';
import 'package:handshaker_open/host/pages/idea_pills_page.dart';
import 'package:handshaker_open/host/pages/music_page.dart';
import 'package:handshaker_open/host/pages/photo_sync_page.dart';
import 'package:handshaker_open/host/pages/photos_page.dart';
import 'package:handshaker_open/host/pages/transfers_page.dart';
import 'package:handshaker_open/host/pages/videos_page.dart';

/// MockHostController 增强版：记录下载/上传/暂停/恢复/取消调用，
/// download 时真的写个小文件到 localPath（供预览/播放路径用）。
class RecController extends MockHostController {
  RecController({super.api});

  final downloads = <(String remote, String local)>[];
  final uploads = <(String local, String remote)>[];
  final cancelledIds = <String>[];
  final pausedIds = <String>[];
  final resumedIds = <String>[];
  final tasks = <TransferTask>[];
  int _seq = 0;
  final _tx = StreamController<List<TransferTask>>.broadcast();

  @override
  List<TransferTask> get transfers => List.unmodifiable(tasks);

  @override
  Stream<List<TransferTask>> get transfersStream => _tx.stream;

  void pushTask(TransferTask t) {
    tasks.add(t);
    _tx.add(List.of(tasks));
  }

  @override
  Future<TransferTask> downloadFile(String remotePath, String localPath,
      {String? taskName}) async {
    downloads.add((remotePath, localPath));
    File(localPath)
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(const [1, 2, 3, 4]);
    return TransferTask(
        id: 'r${++_seq}', name: taskName ?? remotePath, total: 4)
      ..completed = true;
  }

  @override
  Future<TransferTask> uploadFile(String localPath, String remotePath,
      {String? taskName}) async {
    uploads.add((localPath, remotePath));
    return TransferTask(
        id: 'r${++_seq}',
        name: taskName ?? localPath,
        total: 4,
        isUpload: true)
      ..completed = true;
  }

  @override
  void cancelTransfer(String taskId) => cancelledIds.add(taskId);
  @override
  void pauseTransfer(String taskId) => pausedIds.add(taskId);
  @override
  void resumeTransfer(String taskId) => resumedIds.add(taskId);

  @override
  Future<void> dispose() async {
    await _tx.close();
    await super.dispose();
  }
}

class _FakeAudioPreview extends AudioPreview {
  String? now;
  @override
  Future<void> play(String localPath) async => now = localPath;
  @override
  Future<void> stop() async => now = null;
  @override
  String? get nowPlaying => now;
}

class _FakePhotoSyncDriver implements PhotoSyncDriver {
  int syncs = 0;
  bool monitoring = false;
  bool stopped = false;
  @override
  Future<int> syncOnce() async {
    syncs++;
    return 2;
  }

  @override
  Future<void> startMonitoring() async => monitoring = true;
  @override
  Future<void> stop() async => stopped = true;
  @override
  Future<void> dispose() async {}
}

class _FakePillsDriver implements IdeaPillsDriver {
  _FakePillsDriver(this.localDir);
  @override
  final String localDir;
  bool started = false;
  int pulls = 0;
  @override
  Future<void> start() async => started = true;
  @override
  Future<int> pullAll() async {
    pulls++;
    return 1;
  }

  @override
  Future<File> createPill(String title, String body) async {
    final f = File('$localDir/$title.md');
    f.writeAsStringSync('# $title\n\n$body\n');
    return f;
  }

  @override
  Future<void> stop() async {}
  @override
  Future<void> dispose() async {}
}

Widget _wrap(Widget page, MockHostController ctl,
        {AppsSource? appsSource, ClipboardSync? sync}) =>
    MaterialApp(
      home: HostScope(
        controller: ctl,
        appsSource: appsSource ?? DemoAppsSource(),
        clipboardSync: sync ?? ClipboardSync(ctl),
        child: Scaffold(body: page),
      ),
    );

Future<void> _doubleTap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 60));
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// 卡片同时注册了 onTap/onDoubleTap 时，GestureRecognizer 会等 300ms
/// 双击窗口才派发单击——测试里必须推过这个时长。
Future<void> _tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConnectPage', () {
    testWidgets('欢迎页 + 发现列表 + 点击连接', (tester) async {
      final ctl = DemoHostController();
      await tester.pumpWidget(MaterialApp(
          home: ConnectPage(
              controller: ctl, state: ConnState.discovering)));
      await tester.pumpAndSettle();
      expect(find.text('欢迎使用 HandShaker'), findsOneWidget);
      expect(find.text('坚果 Pro 3 (Demo)'), findsOneWidget);
      expect(find.text('Wi-Fi 连接'), findsOneWidget);
      expect(find.text('USB 连接'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, '连接').first);
      await tester.pump();
      expect(ctl.state, ConnState.connected);
      await ctl.dispose();
    });

    testWidgets('手动输入 IP 连接', (tester) async {
      final ctl = DemoHostController();
      await tester.pumpWidget(MaterialApp(
          home: ConnectPage(
              controller: ctl, state: ConnState.disconnected)));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byWidgetPredicate(
              (w) => w is TextField && w.decoration?.labelText == '手机 IP 地址'),
          '10.0.0.8');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(ctl.state, ConnState.connected);
      await ctl.dispose();
    });

    testWidgets('重连横幅', (tester) async {
      final ctl = DemoHostController();
      await tester.pumpWidget(MaterialApp(
          home: ConnectPage(
              controller: ctl, state: ConnState.reconnecting)));
      await tester.pumpAndSettle();
      expect(find.text('连接中断，正在自动重连…'), findsOneWidget);
      await ctl.dispose();
    });
  });

  group('HostShell', () {
    testWidgets('连接后显示左侧分类导航', (tester) async {
      final ctl = DemoHostController(api: DemoSspApi());
      await tester.pumpWidget(HostApp(
          controller: ctl, appsSource: DemoAppsSource()));
      await tester.pumpAndSettle();
      ctl.setState(ConnState.connected);
      await tester.pumpAndSettle();
      for (final label in [
        '照片', '音乐', '视频', '文件', '应用', '剪贴板', '相册同步', '闪念胶囊', '传输'
      ]) {
        expect(find.text(label), findsWidgets, reason: label);
      }
      await tester.tap(find.widgetWithText(OutlinedButton, '断开连接'));
      await tester.pumpAndSettle();
      expect(find.text('欢迎使用 HandShaker'), findsOneWidget);
      await ctl.dispose();
    });

    testWidgets('配对弹窗', (tester) async {
      final ctl = DemoHostController(api: DemoSspApi());
      await tester.pumpWidget(HostApp(controller: ctl));
      await tester.pumpAndSettle();
      final c = Completer<bool>();
      ctl.prompt(PairingPrompt(
          candidate: DeviceCandidate(
              id: 'wifi:x',
              label: '新设备',
              address: '1.2.3.4',
              port: 10088,
              source: DiscoverySource.wifi),
          completer: c));
      await tester.pumpAndSettle();
      expect(find.text('信任此设备？'), findsOneWidget);
      await tester.tap(find.text('信任并连接'));
      await tester.pumpAndSettle();
      expect(await c.future, isTrue);
      await ctl.dispose();
    });
  });

  group('FilesPage', () {
    testWidgets('目录列表 / 选择 / 搜索 / 新建文件夹 / 下载', (tester) async {
      final api = DemoSspApi();
      final ctl = RecController(api: api);
      await tester.pumpWidget(_wrap(
          FilesPage(
              rootPath: '/sdcard',
              pickSaveLocation: (name) async => '/tmp/host_ui_test/$name'),
          ctl));
      await tester.pumpAndSettle();
      expect(find.text('DCIM'), findsOneWidget);
      expect(find.text('文档说明.txt'), findsOneWidget);

      // 搜索过滤
      await tester.enterText(find.byType(TextField).first, '说明');
      await tester.pump();
      expect(find.text('文档说明.txt'), findsOneWidget);
      expect(find.text('DCIM'), findsNothing);
      await tester.enterText(find.byType(TextField).first, '');
      await tester.pump();

      // 新建文件夹 → createFolder 入列
      await tester.tap(find.text('新建文件夹'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '测试目录');
      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();
      expect(api.calls.any((c) => c.startsWith('createFolder(/sdcard/测试目录')),
          isTrue);

      // 选中 + 下载到本机
      await _tapAndSettle(tester, find.text('文档说明.txt'));
      expect(find.text('已选 1 项'), findsOneWidget);
      await tester.tap(find.text('下载'));
      await tester.pumpAndSettle();
      expect(ctl.downloads.single.$1, '/sdcard/文档说明.txt');
      await ctl.dispose();
    });
  });

  group('PhotosPage', () {
    testWidgets('相册分组 / 网格 / 预览 / 导入', (tester) async {
      final api = DemoSspApi();
      final ctl = RecController(api: api);
      await tester.pumpWidget(_wrap(
          PhotosPage(pickSaveDir: () async => '/tmp/host_ui_photos'), ctl));
      await tester.pumpAndSettle();
      expect(find.text('全部照片'), findsOneWidget);
      expect(find.text('相机'), findsWidgets);
      expect(find.text('IMG_001.jpg'), findsWidgets);

      // 相册过滤
      await tester.tap(find.text('截图'));
      await tester.pump();
      expect(find.text('截图.png'), findsWidgets);
      expect(find.text('IMG_001.jpg'), findsNothing);
      await tester.tap(find.text('全部照片'));
      await tester.pump();

      // 双击大图预览
      await _doubleTap(tester, find.text('IMG_001.jpg'));
      expect(find.text('导入到 Mac'), findsWidgets);
      expect(find.text('4000×3000', findRichText: true), findsNothing);
      await tester.tap(find.text('关闭'));
      await tester.pumpAndSettle();

      // 选中 + 导入
      await _tapAndSettle(tester, find.text('IMG_001.jpg'));
      await tester.tap(find.text('导入到 Mac').first);
      await tester.pumpAndSettle();
      expect(
          ctl.downloads.any((d) => d.$1.endsWith('IMG_001.jpg')), isTrue);
      await ctl.dispose();
    });
  });

  group('VideosPage', () {
    testWidgets('时长角标 / 预览 / 导出', (tester) async {
      final ctl = RecController(api: DemoSspApi());
      final opened = <String>[];
      await tester.pumpWidget(_wrap(
          VideosPage(
              pickSaveDir: () async => '/tmp/host_ui_videos',
              openLocal: (p) async => opened.add(p)),
          ctl));
      await tester.pumpAndSettle();
      expect(find.text('VID_001.mp4'), findsWidgets);
      expect(find.text('01:35'), findsOneWidget); // 95.5s → 01:35

      await _doubleTap(tester, find.text('VID_001.mp4'));
      expect(find.text('在 Mac 上播放'), findsOneWidget);
      await tester.tap(find.text('在 Mac 上播放'));
      await tester.pumpAndSettle();
      expect(opened.single.endsWith('VID_001.mp4'), isTrue);

      // 选中 + 导出
      await _tapAndSettle(
          tester, find.widgetWithText(Card, 'VID_001.mp4'));
      expect(find.byIcon(Icons.check_circle), findsWidgets);
      await tester.tap(find.text('导出到 Mac'));
      await tester.pumpAndSettle();
      expect(ctl.downloads.any((d) => d.$2 == '/tmp/host_ui_videos/VID_001.mp4'),
          isTrue);
      await ctl.dispose();
    });
  });

  group('MusicPage', () {
    testWidgets('歌曲列表 / 搜索 / 双击试听 / 导出', (tester) async {
      final ctl = RecController(api: DemoSspApi());
      final preview = _FakeAudioPreview();
      await tester.pumpWidget(_wrap(
          MusicPage(
              pickSaveDir: () async => '/tmp/host_ui_music',
              preview: preview),
          ctl));
      await tester.pumpAndSettle();
      expect(find.text('晴天'), findsOneWidget);
      expect(find.text('周杰伦'), findsOneWidget);
      expect(find.text('Lemon'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, '米津');
      await tester.pump();
      expect(find.text('晴天'), findsNothing);
      expect(find.text('Lemon'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, '');
      await tester.pump();

      // 双击试听（下载到临时目录后播放）
      await _doubleTap(tester, find.text('晴天'));
      expect(preview.nowPlaying?.endsWith('晴天.mp3'), isTrue);
      expect(find.textContaining('正在试听'), findsOneWidget);

      await _tapAndSettle(tester, find.text('晴天'));
      await tester.tap(find.text('导出到 Mac'));
      await tester.pumpAndSettle();
      expect(ctl.downloads.any((d) => d.$2 == '/tmp/host_ui_music/晴天.mp3'),
          isTrue);
      await ctl.dispose();
    });
  });

  group('AppsPage', () {
    testWidgets('应用列表 / 卸载 / 导出 APK / 空态', (tester) async {
      final ctl = RecController(api: DemoSspApi());
      await tester.pumpWidget(_wrap(
          AppsPage(
              pickSaveLocation: (name) async => '/tmp/host_ui_apps/$name'),
          ctl));
      await tester.pumpAndSettle();
      expect(find.text('微信'), findsOneWidget);
      expect(find.text('8.0.47'), findsOneWidget);

      // 导出 APK → downloadFile(apkPath)
      await tester.tap(find.text('导出 APK').first);
      await tester.pumpAndSettle();
      expect(ctl.downloads.any((d) => d.$1.endsWith('base.apk')), isTrue);

      // 卸载 → 确认 → 列表移除
      await tester.tap(find.text('卸载').first);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, '卸载'));
      await tester.pumpAndSettle();
      expect(find.text('微信'), findsNothing);
      await ctl.dispose();
    });

    testWidgets('WireAppsSource 显示协议缺口占位', (tester) async {
      final ctl = RecController(api: DemoSspApi());
      await tester.pumpWidget(
          _wrap(const AppsPage(), ctl, appsSource: WireAppsSource()));
      await tester.pumpAndSettle();
      expect(find.textContaining('暂不提供应用列表'), findsOneWidget);
      await ctl.dispose();
    });
  });

  group('ClipboardPage', () {
    testWidgets('远端剪贴板展示 / 发送 / 同步开关', (tester) async {
      final api = DemoSspApi();
      final ctl = RecController(api: api);
      final written = <String>[];
      final sync = ClipboardSync(ctl,
          interval: const Duration(seconds: 60),
          readLocal: () async => null,
          writeLocal: (t) async => written.add(t));
      await tester.pumpWidget(
          _wrap(const ClipboardPage(), ctl, sync: sync));
      await tester.pumpAndSettle();
      expect(find.text('手机里复制的文本示例'), findsOneWidget);

      // 开启同步 → 立即 tick → 远端文本写入本机
      await tester.tap(find.byType(Switch));
      await tester.pump();
      expect(sync.enabled, isTrue);
      expect(written, contains('手机里复制的文本示例'));
      await sync.setEnabled(false);

      await tester.enterText(
          find.byType(TextField).first, 'Mac 上的文本');
      await tester.tap(find.text('发送'));
      await tester.pumpAndSettle();
      expect(api.calls.any((c) => c == 'postClipboardText(Mac 上的文本)'),
          isTrue);
      await ctl.dispose();
    });
  });

  group('PhotoSyncPage', () {
    testWidgets('选择目录开启 / 状态 / 立即同步', (tester) async {
      final ctl = RecController(api: DemoSspApi());
      final driver = _FakePhotoSyncDriver();
      await tester.pumpWidget(_wrap(
          PhotoSyncPage(
              pickDir: () async => '/tmp/host_ui_photosync',
              driverFactory: (_) => driver),
          ctl));
      await tester.pumpAndSettle();
      expect(find.text('同步未开启'), findsOneWidget);
      await tester.tap(find.text('选择目录并开启'));
      await tester.pumpAndSettle();
      expect(driver.syncs, 1);
      expect(driver.monitoring, isTrue);
      expect(find.text('同步已开启'), findsOneWidget);
      expect(find.textContaining('下载 2 个文件'), findsOneWidget);
      await tester.tap(find.text('立即同步'));
      await tester.pumpAndSettle();
      expect(driver.syncs, 2);
      await ctl.dispose();
    });
  });

  group('IdeaPillsPage', () {
    testWidgets('开启同步 / 胶囊列表 / 新建', (tester) async {
      final dir = Directory.systemTemp
          .createTempSync('host_ui_pills');
      File('${dir.path}/买牛奶.md')
          .writeAsStringSync('# 买牛奶\n\n下班路上记得\n');
      final ctl = RecController(api: DemoSspApi());
      final driver = _FakePillsDriver(dir.path);
      await tester.pumpWidget(_wrap(
          IdeaPillsPage(
              pickDir: () async => dir.path,
              driverFactory: (_) => driver),
          ctl));
      await tester.pump();
      await tester.tap(find.text('选择目录并开启同步'));
      await tester.pump();
      expect(driver.started, isTrue);
      expect(find.text('买牛奶'), findsWidgets);

      // 新建胶囊（AppBar IconButton 上的 tooltip）
      await tester.tap(find.byTooltip('新建胶囊').first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '测试想法');
      await tester.enterText(find.byType(TextField).last, '内容正文');
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      expect(File('${dir.path}/测试想法.md').existsSync(), isTrue);
      expect(find.text('测试想法'), findsWidgets);
      await ctl.dispose();
      dir.deleteSync(recursive: true);
    });
  });

  group('TransfersPage', () {
    testWidgets('队列/进行/历史三段 + 暂停恢复取消', (tester) async {
      final ctl = RecController(api: DemoSspApi());
      ctl.pushTask(TransferTask(
          id: 'w1', name: '排队.bin', total: 100, waiting: true));
      ctl.pushTask(TransferTask(
          id: 'a1', name: '跑.bin', total: 100, done: 40));
      ctl.pushTask(TransferTask(
          id: 'p1', name: '停.bin', total: 100, done: 60, paused: true));
      ctl.pushTask(TransferTask(
          id: 'd1', name: '完.bin', total: 100, completed: true));
      await tester
          .pumpWidget(_wrap(const TransfersPage(), ctl));
      await tester.pumpAndSettle();
      expect(find.text('等待中（1）'), findsOneWidget);
      expect(find.text('进行中（1）'), findsOneWidget);
      expect(find.text('历史（2）'), findsOneWidget);

      // 进行中 → 暂停
      await tester.tap(find.widgetWithIcon(IconButton, Icons.pause));
      await tester.pump();
      expect(ctl.pausedIds, ['a1']);
      // 历史里 paused → 恢复
      await tester.tap(find.widgetWithIcon(IconButton, Icons.play_arrow));
      await tester.pump();
      expect(ctl.resumedIds, ['p1']);
      // 等待中 → 取消（两个取消按钮，第一个是 waiting 的）
      await tester.tap(find.widgetWithIcon(IconButton, Icons.close).first);
      await tester.pump();
      expect(ctl.cancelledIds, isNotEmpty);
      await ctl.dispose();
    });
  });
}
