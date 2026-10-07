import 'dart:typed_data';

import 'bytes.dart';

/// Legacy ADBForward outer framing: u32be length + payload.
/// The reader fixes the original MINA decoder's sticky/half-packet defects by
/// accumulating bytes and slicing exactly 4+L per frame.
class LegacyFrame {
  static Uint8List wrap(Uint8List payload) =>
      concat([be32(payload.length), payload]);
}

class LegacyFrameReader {
  LegacyFrameReader({this.maxPayload = 64 * 1024 * 1024});

  /// Client-side policy cap; not a protocol limit.
  final int maxPayload;
  final StreamBuffer _buf = StreamBuffer();

  /// Append socket bytes; returns every complete frame INCLUDING its 4-byte
  /// length prefix.
  List<Uint8List> add(Uint8List chunk) {
    _buf.add(chunk);
    final out = <Uint8List>[];
    while (true) {
      final head = _buf.peek(4);
      if (head == null) break;
      final n = readBe32(head);
      if (n > maxPayload) {
        throw const FormatException('legacy frame length exceeds cap');
      }
      final frame = _buf.peek(4 + n);
      if (frame == null) break;
      _buf.skip(4 + n);
      out.add(frame);
    }
    _buf.compact();
    return out;
  }
}
