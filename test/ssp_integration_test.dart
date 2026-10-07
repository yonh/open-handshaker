import 'dart:io';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handshaker_open/ssp/client.dart';
import 'package:handshaker_open/ssp/pb/SmartSyncProtocol.recovered.pb.dart'
    as pb;
import 'package:handshaker_open/ssp/server.dart';
import 'package:handshaker_open/ssp/transport.dart';
import 'package:handshaker_open/ssp/trust_store.dart';
import 'package:handshaker_open/ssp/types.dart';

/// End-to-end loopback tests: real SspClient <-> SspAgentServer over an
/// in-memory duplex channel. Covers the Phase-1 acceptance "echo test".
void main() {
  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('ssp_it'));
  tearDown(() => tmp.deleteSync(recursive: true));

  Future<(SspClient, SspAgentServer)> connectPair(
      {TrustDecision decision = TrustDecision.always,
      String hostStoreFile = 'hosts.json'}) async {
    final pair = DuplexChannel.pair();
    final agent = SspAgentServer(
      identity:
          AgentIdentity(deviceUuid: 'dev-1', deviceName: 'Pixel 7'),
      hostTrustStore: HostTrustStore('${tmp.path}/$hostStoreFile'),
      onPairingRequest: (req, pending) => decision,
    );
    agent.attach(pair.$1);
    final client = SspClient(
      pair.$2,
      identity:
          HostIdentity.generate(hostUuid: 'host-1', hostName: 'MacBook'),
      trustStore: TrustStore('${tmp.path}/devices.json'),
    );
    return (client, agent);
  }

  group('handshake', () {
    test('accept: two-stage completes, trust record persisted', () async {
      final (client, agent) = await connectPair();
      final r = await client.handshake();
      expect(r.trustType, Trust.always);
      expect(r.response02.deviceUuid, 'dev-1');
      expect(agent.readySessions, hasLength(1));
      // Host-side trust record saved with derivedKey.
      expect(client.trustStore!.devices, hasLength(1));
      expect(client.trustStore!.devices.first.derivedKey, isNotNull);
      await client.close();
    });

    test('deny: host gets TrustNo error', () async {
      final (client, agent) = await connectPair(
          decision: TrustDecision.deny);
      expect(client.handshake(), throwsA(isA<StateError>()));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(agent.readySessions, isEmpty);
      await client.close();
    });

    test('reconnect fast-path: derivedKey match skips pairing prompt',
        () async {
      // First connection establishes trust.
      var (client, agent) = await connectPair();
      await client.handshake();
      await client.close();

      // Second connection reuses the same agent store — never calls the
      // pairing callback because the derivedKey matches.
      var asked = 0;
      final pair = DuplexChannel.pair();
      agent = SspAgentServer(
        identity:
            AgentIdentity(deviceUuid: 'dev-1', deviceName: 'Pixel 7'),
        hostTrustStore: HostTrustStore('${tmp.path}/hosts.json')
          ..add(agent.hostTrustStore.hosts.first),
        onPairingRequest: (req, pending) {
          asked++;
          return TrustDecision.deny;
        },
      );
      agent.attach(pair.$1);
      client = SspClient(
        pair.$2,
        identity: HostIdentity.generate(
            hostUuid: 'host-1', hostName: 'MacBook'),
        trustStore: TrustStore('${tmp.path}/devices.json'),
      );
      // Reuse the persisted device record (with derivedKey) on a fresh store.
      final r = await client.handshake();
      expect(r.trustType, Trust.always);
      expect(asked, 0);
      await client.close();
    });
  });

  group('requests', () {
    test('signed echo round-trip', () async {
      final (client, agent) = await connectPair();
      agent.requestHandler = (session, proto, typeValue, sid) {
        if (typeValue == Req.getDeviceInfo.value) {
          return pb.SSPGetDeviceInfoResponse()
            ..type = Req.getDeviceInfo
            ..phoneName = 'Pixel 7';
        }
        return null;
      };
      await client.handshake();
      final resp = await client.call(
          pb.SSPGetDeviceInfoRequest()..type = Req.getDeviceInfo,
          pb.SSPGetDeviceInfoResponse.fromBuffer);
      expect(resp.phoneName, 'Pixel 7');
      await client.close();
    });
  });

  group('file transfer', () {
    test('download: header + raw body, .hsdownload rename', () async {
      final body = List<int>.generate(40000, (i) => i % 251);
      final (client, agent) = await connectPair();
      agent.requestHandler = (session, proto, typeValue, sid) async {
        if (typeValue == Req.downloadFile.value) {
          final header = pb.SSPDownloadFileResponseHeader()
            ..type = Req.downloadFileRespHeader
            ..ready = true
            ..range = (pb.SSPDataRange()
              ..offset = Int64(0)
              ..length = Int64(body.length))
            ..needMd5 = false;
          session.respond(sid, header);
          session.sendRaw(sid, Uint8List.fromList(body));
        }
        return null;
      };
      await client.handshake();
      final out = '${tmp.path}/out.bin';
      await client.download('/sdcard/x.bin', out);
      expect(File(out).readAsBytesSync(), body);
      expect(File('$out.hsdownload').existsSync(), isFalse);
      await client.close();
    });

    test('upload: header->ready->chunks->ack', () async {
      final (client, agent) = await connectPair();
      final received = <int>[];
      var expected = 0;
      agent.requestHandler = (session, proto, typeValue, sid) {
        if (typeValue == Req.uploadFileReqHeader.value) {
          final req = pb.SSPUploadFileRequest.fromBuffer(proto);
          expected = req.file.fileSize.toInt();

          return pb.SSPUploadFileResponseHeader()
            ..type = Req.uploadFileRespHeader
            ..ready = true;
        }
        return null;
      };
      agent.fileDataHandler = (session, sid, data) {
        received.addAll(data);
        if (received.length >= expected) {
          session.respond(
              sid,
              pb.SSPUploadFileResponse()
                ..type = Req.uploadFileResp
                ..succeed = true);
        }
      };
      await client.handshake();

      final payload =
          List<int>.generate(33000, (i) => (i * 7) & 0xff);
      final src = '${tmp.path}/src.bin';
      File(src).writeAsBytesSync(payload);
      final ack = await client.upload(src, '/sdcard/dst.bin');
      expect(ack.succeed, isTrue);
      expect(received, payload);
      await client.close();
    });
  });
}
