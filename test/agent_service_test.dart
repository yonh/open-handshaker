import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:handshaker_open/agent/agent_service.dart';
import 'package:handshaker_open/ssp/client.dart';
import 'package:handshaker_open/ssp/crypto.dart';
import 'package:handshaker_open/ssp/envelope.dart';
import 'package:handshaker_open/ssp/legacy_client.dart';
import 'package:handshaker_open/ssp/pb/SmartSyncProtocol.recovered.pb.dart'
    as pb;
import 'package:handshaker_open/ssp/server.dart';
import 'package:handshaker_open/ssp/transport.dart';
import 'package:handshaker_open/ssp/trust_store.dart';
import 'package:handshaker_open/ssp/types.dart';

/// Full-daemon loopback over real TCP sockets: legacy :12086, modern :12088,
/// HTTP :29999 (alternate test ports to avoid cross-file contention).
void main() {
  late Directory tmp;
  late AgentService agent;

  setUpAll(() async {
    tmp = Directory.systemTemp.createTempSync('agent_svc');
    agent = AgentService();
    await agent.start(
      identity: AgentIdentity(deviceUuid: 'dev-loop', deviceName: 'Loop Pixel'),
      hostTrustStore: HostTrustStore('${tmp.path}/hosts.json'),
      onPairingRequest: (req, pending) => TrustDecision.always,
      modernPort: 12088,
      legacyPort: 12086,
      httpPort: 29999,
    );
  });

  tearDownAll(() async {
    await agent.stop();
    tmp.deleteSync(recursive: true);
  });

  group('modern :12088', () {
    late SspClient client;
    setUp(() async {
      final ch = await SocketChannel.connect('127.0.0.1', 12088);
      client = SspClient(
        ch,
        identity: HostIdentity.generate(
            hostUuid: 'host-loop', hostName: 'LoopMac'),
        trustStore: TrustStore('${tmp.path}/devices.json'),
      );
    });
    tearDown(() => client.close());

    test('handshake + getDeviceInfo + dir ops + upload/download', () async {
      final hs = await client.handshake();
      expect(hs.trustType, Trust.always);
      expect(hs.response02.deviceUuid, 'dev-loop');

      final api = SspApiForTests(client);

      // device info (empty platform channel on desktop still returns a msg)
      final info = await api.getDeviceInfo();
      expect(info.type, Req.getDeviceInfo);

      // files
      final work = Directory('${tmp.path}/work')..createSync();
      File('${work.path}/a.txt').writeAsStringSync('hello-agent');
      final listed = await api.listDir(work.path);
      expect(listed.fileArray.map((f) => f.path), contains('${work.path}/a.txt'));

      final exists = await api.fileExists('${work.path}/a.txt');
      expect(exists, isTrue);

      final created = await api.createFolder('${work.path}/sub');
      expect(created.succeed, isTrue);
      expect(Directory('${work.path}/sub').existsSync(), isTrue);

      final renamed =
          await api.rename('${work.path}/a.txt', '${work.path}/b.txt');
      expect(renamed.succeed, isTrue);
      expect(File('${work.path}/b.txt').existsSync(), isTrue);

      // upload
      final src = '${tmp.path}/up.bin';
      final payload = List<int>.generate(50000, (i) => i % 253);
      File(src).writeAsBytesSync(payload);
      await client.upload(src, '${work.path}/up.bin');
      expect(File('${work.path}/up.bin').readAsBytesSync(), payload);

      // download
      final dl = '${tmp.path}/down.bin';
      await client.download('${work.path}/up.bin', dl);
      expect(File(dl).readAsBytesSync(), payload);

      final deleted = await api.delete('${work.path}/up.bin');
      expect(deleted.succeed, isTrue);
    });
  });

  group('legacy :12086', () {
    test('handshake + GET device info JSON + heartbeat', () async {
      final keyPair = generateRsaKeyPair();
      final client = LegacySspClient(keyPair: keyPair);
      // handshake
      final hs = await SocketChannel.connect('127.0.0.1', 12086);
      expect(await client.handshake(hs), isTrue);

      // GET (C=3) — device JSON
      final ch2 = await SocketChannel.connect('127.0.0.1', 12086);
      final resp = await client.request(ch2, LegacyCmd.get, 0);
      expect(resp.command, LegacyCmd.get);
      final j = jsonDecode(utf8.decode(resp.body)) as Map<String, dynamic>;
      expect(j.containsKey('device_name'), isTrue);
      expect(j.containsKey('battery_level'), isTrue);

      // heartbeat request (signed C=6) -> [6,V,2] response
      final ch3 = await SocketChannel.connect('127.0.0.1', 12086);
      final pong = await client.request(ch3, LegacyCmd.heartbeat, 1);
      expect(pong.command, 6);
      expect(pong.subtype, 2);
    });
  });

  group('http :29999', () {
    test('?test echo + ?file_path download + Range', () async {
      final c = HttpClient();

      // test endpoint
      var req = await c.getUrl(
          Uri.parse('http://127.0.0.1:29999/?test0123456789abcdefXYZ'));
      var resp = await req.close();
      expect(resp.statusCode, 200);
      final body = await resp.expand((c) => c).toList();
      expect(utf8.decode(body), '0123456789abcdef');

      // file
      final f = File('${tmp.path}/http.bin')
        ..writeAsBytesSync(List<int>.generate(100000, (i) => i % 251));
      req = await c.getUrl(Uri.parse(
          'http://127.0.0.1:29999/?file_path=${Uri.encodeComponent(f.path)}'));
      resp = await req.close();
      expect(resp.statusCode, 200);
      final data = await resp.expand((c) => c).toList();
      expect(data.length, 100000);

      // Range bytes=50000-
      req = await c.getUrl(Uri.parse(
          'http://127.0.0.1:29999/?file_path=${Uri.encodeComponent(f.path)}'));
      req.headers.set(HttpHeaders.rangeHeader, 'bytes=50000-');
      resp = await req.close();
      expect(resp.statusCode, 206);
      expect(resp.headers.value('content-range'), 'bytes 50000-99999/100000');
      final tail = await resp.expand((c) => c).toList();
      expect(tail.length, 50000);

      // bad range -> 416
      req = await c.getUrl(Uri.parse(
          'http://127.0.0.1:29999/?file_path=${Uri.encodeComponent(f.path)}'));
      req.headers.set(HttpHeaders.rangeHeader, 'bytes=10-20');
      resp = await req.close();
      expect(resp.statusCode, 416);

      // 404
      req = await c.getUrl(Uri.parse('http://127.0.0.1:29999/?nope'));
      resp = await req.close();
      expect(resp.statusCode, 404);
      c.close();
    });
  });
}

/// Thin typed surface mirroring lib/ssp/requests.dart SspApi for the calls
/// the test exercises.
class SspApiForTests {
  SspApiForTests(this.client);
  final SspClient client;

  Future<pb.SSPGetDeviceInfoResponse> getDeviceInfo() => client.call(
      pb.SSPGetDeviceInfoRequest()..type = Req.getDeviceInfo,
      pb.SSPGetDeviceInfoResponse.fromBuffer);

  Future<pb.SSPGetDirFilesResponse> listDir(String path) => client.call(
      pb.SSPGetDirFilesRequest()
        ..type = Req.getDirFiles
        ..dir = (pb.SSPFile()..path = path)
        ..maxdepth = 1,
      pb.SSPGetDirFilesResponse.fromBuffer);

  Future<bool> fileExists(String path) => client.call(
      pb.SSPFileExistRequest()
        ..type = Req.getFileExist
        ..file = (pb.SSPFile()..path = path),
      (b) => pb.SSPFileExistResponse.fromBuffer(b).exist);

  Future<pb.SSPCreateFolderResponse> createFolder(String path) => client.call(
      pb.SSPCreateFolderRequest()
        ..type = Req.createFolder
        ..file = (pb.SSPFile()..path = path),
      pb.SSPCreateFolderResponse.fromBuffer);

  Future<pb.SSPRenameFileResponse> rename(String a, String b) => client.call(
      pb.SSPRenameFileRequest()
        ..type = Req.renameFile
        ..sourceFile = (pb.SSPFile()..path = a)
        ..targetFile = (pb.SSPFile()..path = b),
      pb.SSPRenameFileResponse.fromBuffer);

  Future<pb.SSPDeleteFileResponse> delete(String path) => client.call(
      pb.SSPDeleteFileRequest()
        ..type = Req.deleteFile
        ..file = (pb.SSPFile()..path = path),
      pb.SSPDeleteFileResponse.fromBuffer);
}
