import 'dart:convert';
import 'dart:typed_data';

/// Big-endian byte helpers shared by the legacy and v2 wire formats.
Uint8List u8(int v) => Uint8List.fromList([v & 0xff]);

Uint8List be16(int v) => Uint8List(2)..buffer.asByteData().setUint16(0, v);

Uint8List be32(int v) => Uint8List(4)..buffer.asByteData().setUint32(0, v);

Uint8List be64(int v) => Uint8List(8)..buffer.asByteData().setUint64(0, v);

int readBe16(Uint8List b, [int offset = 0]) =>
    b.buffer.asByteData(b.offsetInBytes).getUint16(offset);

int readBe32(Uint8List b, [int offset = 0]) =>
    b.buffer.asByteData(b.offsetInBytes).getUint32(offset);

int readBe64(Uint8List b, [int offset = 0]) =>
    b.buffer.asByteData(b.offsetInBytes).getUint64(offset);

Uint8List concat(List<Uint8List> parts) {
  var total = 0;
  for (final p in parts) {
    total += p.length;
  }
  final out = Uint8List(total);
  var off = 0;
  for (final p in parts) {
    out.setRange(off, off + p.length, p);
    off += p.length;
  }
  return out;
}

String hex(Uint8List b) =>
    b.map((e) => e.toRadixString(16).padLeft(2, '0')).join();

Uint8List unhex(String s) {
  final cleaned = s.replaceAll(RegExp(r'\s+'), '');
  final out = Uint8List(cleaned.length ~/ 2);
  for (var i = 0; i < out.length; i++) {
    out[i] = int.parse(cleaned.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return out;
}

Uint8List utf8Bytes(String s) => Uint8List.fromList(utf8.encode(s));

/// Incremental buffer that lets frame readers append socket data and pull
/// complete units out, tolerating sticky and half packets.
class StreamBuffer {
  final BytesBuilder _buf = BytesBuilder(copy: false);
  int _consumed = 0;

  int get available => _buf.length - _consumed;

  void add(Uint8List data) {
    _buf.add(data);
  }

  /// Peek at [n] bytes from the current read position, or null if not enough.
  Uint8List? peek(int n) {
    if (available < n) return null;
    final b = _buf.toBytes();
    return Uint8List.fromList(b.sublist(_consumed, _consumed + n));
  }

  Uint8List? take(int n) {
    final p = peek(n);
    if (p == null) return null;
    _consumed += n;
    return p;
  }

  void skip(int n) {
    _consumed += n;
  }

  /// Remove and return every buffered byte that has not been consumed.
  Uint8List drain() {
    final b = _buf.toBytes();
    final out = Uint8List.fromList(b.sublist(_consumed));
    _buf.clear();
    _consumed = 0;
    return out;
  }

  /// Drop already-consumed bytes to bound memory growth.
  void compact() {
    if (_consumed == 0) return;
    final b = _buf.toBytes();
    final remaining = Uint8List.fromList(b.sublist(_consumed));
    _buf.clear();
    _buf.add(remaining);
    _consumed = 0;
  }
}
