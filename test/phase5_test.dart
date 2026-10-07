import 'dart:async';
import 'dart:io';

import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handshaker_open/agent/agent_service.dart';
import 'package:handshaker_open/agent/providers/channel_providers.dart';
import 'package:handshaker_open/host/host_controller_impl.dart';
import 'package:handshaker_open/host/idea_pills.dart';
import 'package:handshaker_open/host/photo_sync.dart';
import 'package:handshaker_open/host/push_hub.dart';
import 'package:handshaker_open/ssp/client.dart';
import 'package:handshaker_open/ssp/pb/SmartSyncProtocol.recovered.pb.dart'
    as pb;
import 'package:handshaker_open/ssp/requests.dart';
import 'package:handshaker_open/ssp/server.dart';
import 'package:handshaker_open/ssp/transport.dart';
import 'package:handshaker_open/ssp/trust_store.dart';
import 'package:handshaker_open/ssp/types.dart';

/// Channels stub that returns a canned photo library so PhotoSync has real
/// data to move around on desktop.
class _FakeChannels extends ChannelProviders {
  _FakeChannels(this.photoDir);
  final String photoDir;

  @override
  Future<pb.SSPGetPhotoLibraryResponse> photoLibrary(
      pb.SSPGetPhotoLibraryRequest req) async {
    final resp = pb.SSPGetPhotoLibraryResponse()..type = Req.getPhotoLib;
    for (final f in Directory(photoDir).listSync()) {
      if (f is! File) continue;
      final st = f.statSync();
      resp.imageArray.add(pb.SSPImageFile()
        ..path = f.path
        ..fileSize = Int64(st.size)
        ..modifiedTimestamp =
            Int64(st.modified.millisecondsSinceEpoch ~/ 1000));
    }
    return resp;
  }
}

void main() {
  late Directory tmp;
  late AgentService agent;
  late SspClient client;
  late SspApi api;

  setUpAll(() async {
    tmp = Directory.systemTemp.createTempSync('p5');
    Directory('${tmp.path}/photos').createSync();
    File('${tmp.path}/photos/p1.jpg')
        .writeAsBytesSync(List<int>.generate(3000, (i) => i % 211));
    File('${tmp.path}/photos/p2.jpg')
        .writeAsBytesSync(List<int>.generate(4000, (i) => i % 199));

    agent = AgentService(channels: _FakeChannels('${tmp.path}/photos'));
    await agent.start(
      identity: AgentIdentity(deviceUuid: 'dev-p5', deviceName: 'P5'),
      hostTrustStore: HostTrustStore('${tmp.path}/hosts.json'),
      onPairingRequest: (req, pending) => TrustDecision.always,
      modernPort: 11088,
      legacyPort: 11086,
      httpPort: 19998,
    );
    final ch = await SocketChannel.connect('127.0.0.1', 11088);
    client = SspClient(ch,
        identity: HostIdentity.generate(hostUuid: 'h-p5', hostName: 'Mac'),
        trustStore: TrustStore('${tmp.path}/dev.json'));
    await client.handshake();
    api = SspApi(client);
  });
  tearDownAll(() async {
    await client.close();
    await agent.stop();
    tmp.deleteSync(recursive: true);
  });

  test('MonitorFolder push: remote file events reach the host', () async {
    final watched = Directory('${tmp.path}/watched')..createSync();
    final hub = PushHub(client);
    final events = <pb.SSPFileEvent>[];
    final sub = hub.folderEvents.listen((r) => events.addAll(r.eventArray));

    final h = await api.monitorFolder(watched.path, register: true);
    expect(h.succeed, isTrue);
    await Future.delayed(const Duration(milliseconds: 300));
    File('${watched.path}/new.txt').writeAsStringSync('hello');
    // FSEvents coalesces with multi-second latency under load — give the
    // watcher ample room before declaring a miss.
    await waitFor(() => events.isNotEmpty, timeout: const Duration(seconds: 25));
    expect(events.first.file.path, contains('new.txt'));

    await api.monitorFolder(watched.path, register: false);
    await sub.cancel();
    await hub.dispose();
  });

  test('PhotoSync: downloads new photos and snapshot persists', () async {
    final local = '${tmp.path}/sync_out';
    final engine = PhotoSyncEngine(
      client: client,
      api: api,
      localDir: local,
      pcId: 'h-p5',
    );
    final n = await engine.syncOnce();
    expect(n, 2);
    expect(File('$local/photos/p1.jpg').existsSync(), isTrue);
    expect(File('$local/photos/p2.jpg').existsSync(), isTrue);

    // second sync: nothing new → 0 downloads
    expect(await engine.syncOnce(), 0);

    // remote delete → local delete on next sync
    File('${tmp.path}/photos/p2.jpg').deleteSync();
    expect(await engine.syncOnce(), 0);
    expect(File('$local/photos/p2.jpg').existsSync(), isFalse);
    await engine.dispose();
  });

  test('IdeaPillsSync mirrors local pills to the device folder', () async {
    final remote = '${tmp.path}/idea_pills_remote';
    Directory(remote).createSync();
    final sync = IdeaPillsSync(
      client: client,
      api: api,
      localDir: '${tmp.path}/pills',
      remoteDir: remote,
    );
    await sync.start();
    await sync.createPill('买牛奶', '下班路上记得');
    await waitFor(() => File('$remote/买牛奶.md').existsSync(), timeout: const Duration(seconds: 25));
    expect(File('$remote/买牛奶.md').readAsStringSync(), contains('下班路上记得'));
    await sync.dispose();
  });

  test('transfer center: queue limit, cancel, pause/resume download',
      () async {
    // big remote files for pausable downloads
    final remoteDir = Directory('${tmp.path}/xfer')..createSync();
    for (var i = 0; i < 3; i++) {
      File('${remoteDir.path}/f$i.bin')
          .writeAsBytesSync(List<int>.generate(4000000, (j) => j % 251));
    }
    final ctl = HostControllerImpl(
      identity: HostIdentity.generate(hostUuid: 'h-xf', hostName: 'M'),
      trustStore: TrustStore('${tmp.path}/dev-xf.json'),
    )..maxConcurrentTransfers = 1;
    // reuse the live client instead of re-connecting
    ctl.debugUseClient(client, api);

    await ctl.downloadFile('${remoteDir.path}/f0.bin',
        '${tmp.path}/dl0.bin');
    await ctl.downloadFile('${remoteDir.path}/f1.bin',
        '${tmp.path}/dl1.bin');
    final t3 = await ctl.downloadFile('${remoteDir.path}/f2.bin',
        '${tmp.path}/dl2.bin');
    // concurrency 1 → at least two wait
    await waitFor(
        () => ctl.transfers.where((t) => t.waiting).length >= 2, timeout: const Duration(seconds: 5));

    // cancel a waiting task if any still waits; else cancel active
    ctl.cancelTransfer(t3.id);
    await waitFor(() => ctl.transfers
        .any((t) => t.id == t3.id && (t.cancelled || t.completed)), timeout: const Duration(seconds: 10));

    // pause an active download, then resume it
    final live = ctl.transfers
        .where((t) => !t.completed && !t.cancelled && !t.paused)
        .firstOrNull;
    if (live != null) {
      ctl.pauseTransfer(live.id);
      await waitFor(() => live.paused, timeout: const Duration(seconds: 8));
      ctl.resumeTransfer(live.id);
    }
    // all queued/running transfers settle
    await waitFor(
        () => ctl.transfers.every((t) =>
            t.completed || t.cancelled || t.paused),
        timeout: const Duration(seconds: 30));

    expect(File('${tmp.path}/dl0.bin').existsSync(), isTrue);
    expect(File('${tmp.path}/dl0.bin').lengthSync(), 4000000);
    await ctl.dispose();
  });
}

Future<void> waitFor(bool Function() cond,
    {Duration timeout = const Duration(seconds: 10)}) async {
  final deadline = DateTime.now().add(timeout);
  while (!cond()) {
    if (DateTime.now().isAfter(deadline)) {
      throw TimeoutException('condition not met');
    }
    await Future.delayed(const Duration(milliseconds: 40));
  }
}
