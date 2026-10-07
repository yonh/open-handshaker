import 'dart:convert';
import 'dart:typed_data';

Uint8List be32(int n) {
  if (n < 0 || n > 0x7fffffff) throw RangeError.value(n);
  final b = ByteData(4)..setInt32(0, n, Endian.big);
  return b.buffer.asUint8List();
}

Uint8List concat(Iterable<List<int>> parts) {
  final b = BytesBuilder(copy: true);
  for (final part in parts) { b.add(part); }
  return b.takeBytes();
}

Uint8List frame(List<int> payload) => concat([be32(payload.length), payload]);

// signRaw must implement SHA256withRSA / PKCS#1 v1.5 over raw data.
Uint8List signedRequest(int command, int subtype, List<int> body,
    Uint8List Function(Uint8List raw) signRaw, {int version = 1}) {
  for (final v in [command, subtype, version]) {
    if (v < 0 || v > 255) throw RangeError.value(v);
  }
  final covered = concat([[command, subtype, version], body]);
  final signature = signRaw(covered);
  if (signature.length != 128) throw StateError('RSA signature must be 128 bytes');
  return frame(concat([[1], signature, covered]));
}

// encryptedBase64 is AES-CBC without PKCS#7; pad plaintext with spaces to 32.
Uint8List handshake(List<int> md5Der, List<int> encryptedBase64) {
  if (md5Der.length != 16 || encryptedBase64.isEmpty ||
      encryptedBase64.length % 32 != 0) {
    throw ArgumentError('Invalid handshake fields');
  }
  return frame(concat([[0, 14, 3, 1], md5Der,
                      be32(encryptedBase64.length), encryptedBase64]));
}

Uint8List lpString(String s) {
  final b = utf8.encode(s);
  return concat([be32(b.length), b]);
}

Uint8List stringList(List<String> paths) =>
    concat([be32(paths.length), ...paths.map(lpString)]);

// Signed 64-bit IDs are written as two's-complement. BigInt also works on web.
Uint8List i64be(BigInt n) {
  final min = -(BigInt.one << 63), max = (BigInt.one << 63) - BigInt.one;
  if (n < min || n > max) throw RangeError('I64 out of range');
  var v = n.toUnsigned(64);
  final b = Uint8List(8);
  for (var i = 7; i >= 0; i--) {
    b[i] = (v & BigInt.from(255)).toInt();
    v >>= 8;
  }
  return b;
}

Uint8List idList(List<BigInt> ids) =>
    concat([be32(ids.length), ...ids.map(i64be)]);

// Consume a TCP stream, yielding complete frames INCLUDING their length prefix.
// The cap is a client policy, not a discovered protocol maximum.
class FrameReader {
  FrameReader({this.maxPayload = 64 * 1024 * 1024});
  final int maxPayload;
  Uint8List pending = Uint8List(0);
  List<Uint8List> add(List<int> chunk) {
    pending = concat([pending, chunk]);
    final out = <Uint8List>[];
    var p = 0;
    while (pending.length - p >= 4) {
      final n = ByteData.sublistView(pending, p, p + 4).getInt32(0, Endian.big);
      if (n < 0 || n > maxPayload) throw FormatException('Invalid frame length');
      if (pending.length - p < 4 + n) break;
      out.add(Uint8List.fromList(pending.sublist(p, p + 4 + n)));
      p += 4 + n;
    }
    pending = Uint8List.fromList(pending.sublist(p));
    return out;
  }
}

String hex(List<int> b) => b.map((n) => n.toRadixString(16).padLeft(2, '0')).join();

void main() {
  // A structural fixture only: zero signature cannot pass phone verification.
  final get = signedRequest(3, 3, [], (_) => Uint8List(128));
  if (get.length != 136 || hex(get.sublist(0, 5)) != '0000008401' ||
      hex(get.sublist(133)) != '030301') throw StateError('GET layout');
  final h = handshake(List.filled(16, 0), List.filled(192, 0));
  if (h.length != 220 || hex(h.sublist(0, 8)) != '000000d8000e0301' ||
      hex(h.sublist(24, 28)) != '000000c0') throw StateError('Handshake layout');
  if (hex(idList([BigInt.from(42)])) != '00000001000000000000002a') {
    throw StateError('ID list');
  }
  if (hex(stringList(['/sdcard/a'])) != '00000001000000092f7364636172642f61') {
    throw StateError('String list');
  }
  final stream = FrameReader();
  final a = [0, 0, 0, 3, 6, 1, 1], b = [0, 0, 0, 3, 6, 1, 2];
  if (stream.add(a.sublist(0, 2)).isNotEmpty) throw StateError('Fragment');
  final frames = stream.add([...a.sublist(2), ...b]);
  if (frames.length != 2 || hex(frames[0]) != hex(a) || hex(frames[1]) != hex(b)) {
    throw StateError('Framing');
  }
  print('layout vectors: OK; split + coalesced frames: OK');
}
