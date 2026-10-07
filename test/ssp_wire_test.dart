import 'dart:convert';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handshaker_open/ssp/bytes.dart';
import 'package:handshaker_open/ssp/crypto.dart';
import 'package:handshaker_open/ssp/envelope.dart';
import 'package:handshaker_open/ssp/frame.dart';
import 'package:handshaker_open/ssp/modern_transport.dart';
import 'package:handshaker_open/ssp/pb/SmartSyncProtocol.recovered.pb.dart'
    as pb;
import 'package:handshaker_open/ssp/types.dart';

/// §10.4 verification vectors + round-trips.
void main() {
  group('wire layout vectors', () {
    test('legacy GET signed request layout', () {
      final get =
          LegacyEnvelope.signedRequest(3, 3, Uint8List(0), (_) => Uint8List(128));
      expect(get.length, 136);
      expect(hex(get.sublist(0, 5)), '0000008401');
      expect(hex(get.sublist(133)), '030301');
    });

    test('legacy handshake frame layout (192B cipher)', () {
      // exercise via wrapPublicKey-independent path: craft manually
      final md5v = Uint8List(16);
      final cipher = Uint8List(192);
      final frame = LegacyFrame.wrap(concat([
        Uint8List.fromList([0, 14, 3, 1]),
        md5v,
        be32(cipher.length),
        cipher,
      ]));
      expect(frame.length, 220);
      expect(hex(frame.sublist(0, 8)), '000000d8000e0301');
      expect(hex(frame.sublist(24, 28)), '000000c0');
    });

    test('legacy IdList / StringList', () {
      expect(hex(LegacyEnvelope.idListBody([42])),
          '00000001000000000000002a');
      expect(hex(LegacyEnvelope.stringListBody(['/sdcard/a'])),
          '00000001000000092f7364636172642f61');
    });

    test('legacy heartbeat frames', () {
      // phone->host ping and its response
      final ping = LegacyFrame.wrap(Uint8List.fromList([6, 1, 1]));
      expect(hex(ping), '000000030601 01'.replaceAll(' ', ''));
      final pongResp = LegacyEnvelope.heartbeatResponseFrame();
      expect(hex(pongResp), '00000003060102');
      expect(LegacyEnvelope.isHeartbeatPing(ping), isTrue);
    });

    test('modern signed request layout', () {
      final p = ModernTransport.signedPacket(
          3, Uint8List.fromList([8, 1]), (_) => Uint8List(128));
      expect(p.length, 139);
      expect(hex(p.sublist(0, 9)), '000000030100000082');
    });

    test('modern push chunk layout', () {
      final chunk = ModernTransport.responseChunk(
          3, unhex('00000000000000020801'),
          push: true);
      expect(hex(chunk), '80000003000a00000000000000020801');
    });

    test('proto vectors: Request02 / DataRange / maxdepth', () {
      final r = pb.SSPHandShakeRequest02()
        ..type = Req.handshakeReq02
        ..hostUuid = 'test'
        ..trustType = Trust.always;
      expect(hex(r.writeToBuffer()), '08211204746573742005');

      final range = pb.SSPDataRange()
        ..offset = Int64(300)
        ..length = Int64(4096);
      expect(hex(range.writeToBuffer()), '08ac02108020');

      final dir = pb.SSPGetDirFilesRequest()
        ..type = Req.getDirFiles
        ..maxdepth = 0xffffffff;
      final b = dir.writeToBuffer();
      expect(hex(b.sublist(b.length - 6)), '18ffffffff0f');
    });
  });

  group('framing', () {
    test('legacy reader splits coalesced + half frames', () {
      final r = LegacyFrameReader();
      final a = Uint8List.fromList([0, 0, 0, 3, 6, 1, 1]);
      final b = Uint8List.fromList([0, 0, 0, 3, 6, 1, 2]);
      expect(r.add(a.sublist(0, 2)), isEmpty);
      final frames = r.add(Uint8List.fromList([...a.sublist(2), ...b]));
      expect(frames.length, 2);
      expect(hex(frames[0]), hex(a));
      expect(hex(frames[1]), hex(b));
    });

    test('modern chunk reader tolerates split header', () {
      final raw =
          unhex('80000003000a00000000000000020801');
      final r = ModernChunkReader();
      expect(r.add(raw.sublist(0, 5)), isEmpty);
      final chunks = r.add(raw.sublist(5));
      expect(chunks.length, 1);
      expect(chunks[0].sessionId, 3);
      expect(chunks[0].isPush, isTrue);
      expect(hex(chunks[0].data), '00000000000000020801');
    });

    test('logical message reader handles multi-message streams', () {
      final r = LogicalMessageReader();
      final m1 = Uint8List.fromList([1, 2, 3]);
      final m2 = Uint8List.fromList([9]);
      final wire = concat([be64(3), m1, be64(1), m2]);
      // feed in awkward slices
      expect(r.add(wire.sublist(0, 5)), isEmpty);
      expect(r.add(wire.sublist(5, 11)), [m1]);
      expect(r.add(wire.sublist(11)), [m2]);
    });
  });

  group('crypto', () {
    test('public key wrap/unwrap round-trip incl. md5', () {
      final kp = generateRsaKeyPair();
      final w = wrapPublicKey(kp.publicKey);
      expect(w.encKey.length % 16, 0);
      expect(w.encKey.length % 32, 0);
      final u = unwrapPublicKey(w.encKey, w.keyMd5);
      expect(u.key.modulus, kp.publicKey.modulus);
      expect(u.key.exponent, kp.publicKey.exponent);
      // tampered md5 rejected
      expect(
          () => unwrapPublicKey(w.encKey, Uint8List(16)),
          throwsFormatException);
    });

    test('sha256withRSA sign/verify', () {
      final kp = generateRsaKeyPair();
      final data = utf8Bytes('c||s||v||body');
      final sig = rsaSign(kp.privateKey, data);
      expect(sig.length, 128);
      expect(rsaVerify(kp.publicKey, data, sig), isTrue);
      expect(rsaVerify(kp.publicKey, utf8Bytes('tampered'), sig), isFalse);
    });

    test('result proof: rsa_encrypt("ok") round-trips', () {
      final kp = generateRsaKeyPair();
      final cipher = rsaEncrypt(kp.publicKey, utf8Bytes('ok'));
      final b64 = base64.encode(cipher);
      expect(
          LegacyEnvelope.verifyHandshakeResult(b64, kp.privateKey), isTrue);
      expect(LegacyEnvelope.verifyHandshakeResult('failed', kp.privateKey),
          isFalse);
    });
  });
}
