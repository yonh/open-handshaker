import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

import 'bytes.dart';
import 'crypto.dart';
import 'frame.dart';

/// Legacy ADBForward envelope codec (port 10086).
///
/// Signed request  : [u32 L][flag!=0][sig128][C][S][V][B]  L = 132 + len(B)
///                   signature covers C||S||V||B
/// Handshake req   : [u32 L][0][0x0e][3][1][md5 16][u32 N][AES N]  L = 24+N
/// Normal response : [u32 L][C][V][S][B]                     L = 3 + len(B)
/// Push            : [u32 L][0x09][category][0x01][JSON utf8]
/// Heartbeat       : phone->host ping 00 00 00 03 06 01 01 ;
///                   response frame 06 01 02; host replies a signed type6
///                   request (not a raw response frame).
class LegacyEnvelope {
  static const int cmdHandshake = 0x0e;
  static const int cmdPush = 0x09;
  static const int cmdHeartbeat = 0x06;
  static const int version = 1;

  // ---------------- requests (host -> agent) ----------------

  /// Build a complete signed-request frame. [signRaw] must do
  /// SHA256withRSA (PKCS#1 v1.5) over the given bytes and return 128 bytes.
  static Uint8List signedRequest(
      int command, int subtype, Uint8List body, Uint8List Function(Uint8List) signRaw,
      {int version = version}) {
    for (final v in [command, subtype, version]) {
      RangeError.checkValueInInterval(v, 0, 255);
    }
    final covered = concat([Uint8List.fromList([command, subtype, version]), body]);
    final sig = signRaw(covered);
    if (sig.length != kSignatureLen) {
      throw StateError('RSA signature must be 128 bytes');
    }
    return LegacyFrame.wrap(concat([u8(1), sig, covered]));
  }

  /// Build the unsigned public-key handshake request frame.
  static Uint8List handshakeRequest(RSAPublicKey hostKey) {
    final w = wrapPublicKey(hostKey);
    return LegacyFrame.wrap(concat([
      Uint8List.fromList([0, cmdHandshake, 3, 1]),
      w.keyMd5,
      be32(w.encKey.length),
      w.encKey,
    ]));
  }

  // ---------------- response / push parsing ----------------

  /// Parse a normal response frame (includes length prefix).
  static LegacyResponse parseResponse(Uint8List frame) {
    if (frame.length < 7) throw const FormatException('short response');
    final l = readBe32(frame);
    if (frame.length != 4 + l) {
      throw const FormatException('response length mismatch');
    }
    return LegacyResponse(
      command: frame[4],
      version: frame[5],
      subtype: frame[6],
      body: Uint8List.fromList(frame.sublist(7)),
    );
  }

  /// A frame is a push if command == 9.
  static bool isPush(Uint8List frame) =>
      frame.length >= 7 && frame[4] == cmdPush;

  static LegacyPush parsePush(Uint8List frame) {
    if (frame.length < 7 || frame[4] != cmdPush) {
      throw const FormatException('not a push frame');
    }
    return LegacyPush(
      category: frame[5],
      json: utf8.decode(frame.sublist(7)),
    );
  }

  /// Phone-initiated heartbeat ping: 00 00 00 03 06 01 01.
  static bool isHeartbeatPing(Uint8List frame) =>
      frame.length == 7 &&
      readBe32(frame) == 3 &&
      frame[4] == cmdHeartbeat &&
      frame[6] == 1;

  /// Build the host's signed heartbeat reply (request type 6, S=2).
  static Uint8List heartbeatPong(Uint8List Function(Uint8List) signRaw,
      {int version = version}) =>
      signedRequest(cmdHeartbeat, 2, Uint8List(0), signRaw, version: version);

  /// Agent-side heartbeat response body/headers: [6, V, 2] where V echoes the
  /// request version (normally 1).
  static Uint8List heartbeatResponseFrame({int version = version}) =>
      LegacyFrame.wrap(Uint8List.fromList([cmdHeartbeat, version, 2]));

  // ---------------- handshake response ----------------

  /// Agent-side success: [u32 L][0x0e][0x01][0x03] + base64(rsa_enc(host,"ok")).
  static Uint8List handshakeOkResponse(RSAPublicKey hostKey) {
    final cipher = rsaEncrypt(hostKey, utf8Bytes('ok'));
    final result = utf8Bytes(base64.encode(cipher));
    return LegacyFrame.wrap(concat([
      Uint8List.fromList([cmdHandshake, 1, 3]),
      result,
    ]));
  }

  static Uint8List handshakeFailedResponse() => LegacyFrame.wrap(concat([
        Uint8List.fromList([cmdHandshake, 1, 3]),
        utf8Bytes('failed'),
      ]));

  /// Host-side: verify handshake response body by decrypting with our private key.
  static bool verifyHandshakeResult(String body, RSAPrivateKey privateKey) {
    final trimmed = body.trim();
    if (trimmed.startsWith('failed')) return false;
    try {
      final cipher = Uint8List.fromList(base64.decode(trimmed));
      final plain = rsaDecrypt(privateKey, cipher);
      return utf8.decode(plain) == 'ok';
    } catch (_) {
      return false;
    }
  }

  // ---------------- request body builders ----------------

  /// StringList: count u32be + per-item u32be len + utf8 bytes.
  static Uint8List stringListBody(List<String> items) {
    final parts = <Uint8List>[be32(items.length)];
    for (final s in items) {
      final b = utf8Bytes(s);
      parts.add(be32(b.length));
      parts.add(b);
    }
    return concat(parts);
  }

  /// IdList: count u32be + per-item i64be.
  static Uint8List idListBody(List<int> ids) {
    final parts = <Uint8List>[be32(ids.length)];
    for (final id in ids) {
      parts.add(be64(id));
    }
    return concat(parts);
  }

  /// Single length-prefixed string (used by EXIF request type 13).
  static Uint8List lpString(String s) {
    final b = utf8Bytes(s);
    return concat([be32(b.length), b]);
  }

  static Uint8List lpStringBody(String s) => lpString(s);

  // ---------------- body parsers ----------------

  static List<String> parseStringList(Uint8List body) {
    if (body.length < 4) throw const FormatException('string list too short');
    final count = readBe32(body);
    final out = <String>[];
    var p = 4;
    for (var i = 0; i < count; i++) {
      if (p + 4 > body.length) throw const FormatException('truncated list');
      final len = readBe32(body, p);
      p += 4;
      if (len > body.length - p) throw const FormatException('truncated item');
      out.add(utf8.decode(body.sublist(p, p + len)));
      p += len;
    }
    return out;
  }

  static List<int> parseIdList(Uint8List body) {
    if (body.length < 4) throw const FormatException('id list too short');
    final count = readBe32(body);
    if (body.length != 4 + count * 8) {
      throw const FormatException('id list length mismatch');
    }
    return [
      for (var i = 0; i < count; i++) readBe64(body, 4 + i * 8),
    ];
  }
}

class LegacyResponse {
  LegacyResponse(
      {required this.command,
      required this.version,
      required this.subtype,
      required this.body});
  final int command;
  final int version;
  final int subtype;
  final Uint8List body;
}

class LegacyPush {
  LegacyPush({required this.category, required this.json});
  final int category;
  final String json;
}

/// Legacy command codes.
class LegacyCmd {
  static const int oldThumbnail = 1; // StringList, S: 1 img 2 video 3 audio art
  static const int fetch = 2; // empty or u32 groupId; subtype per media table
  static const int get = 3; // device info
  static const int terminate = 4;
  static const int keepAlive = 5; // persistent callback socket
  static const int heartbeat = 6;
  static const int newFetch = 7; // S: 1 photo, 2 audio, 3 video -> gzip JSON
  static const int thumbnail = 8; // IdList, S: 1 img 2 video 3 album art
  static const int watch = 10; // StringList, S=1 register else unregister
  static const int delete = 11; // IdList of MediaStore _id
  static const int scan = 12; // StringList paths to media-scan
  static const int exif = 13; // lpString path
}
