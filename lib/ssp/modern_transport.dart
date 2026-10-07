import 'dart:typed_data';

import 'package:pointycastle/export.dart';

import 'bytes.dart';
import 'crypto.dart';

/// Modern SSP v2 transport.
///
/// Host -> agent frame : [u32be sessionId][u8 flag][u32be dataLen][data]
/// Agent -> host chunk : [u32be rawSessionId][u16be chunkLen][data]
///   rawSessionId high bit (0x80000000) marks a push.
/// Logical message (per session): u64be payloadLen + payload, assembled by
///   concatenating that session's chunk data in order.
class ModernTransport {
  static const int flagHandshake = 0; // unsigned protobuf (sessions 1,2)
  static const int flagSigned = 1;    // sig128 || protobuf
  static const int flagFileData = 3;  // raw file bytes, <=16375 per chunk

  /// Apple reference sends file chunks of at most 16375 bytes.
  static const int maxFileChunk = 16375;

  static const int pushBit = 0x80000000;

  /// Build one host->agent frame.
  static Uint8List packet(int sessionId, int flag, Uint8List data) {
    RangeError.checkValueInInterval(sessionId, 0, 0x7fffffff);
    RangeError.checkValueInInterval(flag, 0, 255);
    return concat([be32(sessionId), u8(flag), be32(data.length), data]);
  }

  /// flag=0 unsigned protobuf (handshake requests).
  static Uint8List unsignedPacket(int sessionId, Uint8List proto) =>
      packet(sessionId, flagHandshake, proto);

  /// flag=1 signed protobuf: sig128 || proto.
  static Uint8List signedPacket(
      int sessionId, Uint8List proto, Uint8List Function(Uint8List) signRaw) {
    final sig = signRaw(proto);
    if (sig.length != kSignatureLen) {
      throw StateError('RSA signature must be 128 bytes');
    }
    return packet(sessionId, flagSigned, concat([sig, proto]));
  }

  /// flag=3 raw file bytes.
  static Uint8List filePacket(int sessionId, Uint8List data) =>
      packet(sessionId, flagFileData, data);

  // ---------------- agent side (phone) ----------------

  /// One agent->host physical chunk. [push] sets the high bit.
  static Uint8List responseChunk(int sessionId, Uint8List data,
      {bool push = false}) {
    RangeError.checkValueInInterval(sessionId, 0, 0x7fffffff);
    RangeError.checkValueInInterval(data.length, 0, 0xffff);
    final rawSid = push ? sessionId | pushBit : sessionId;
    return concat([be32(rawSid), be16(data.length), data]);
  }

  /// Wrap a logical response (u64be len + payload) into physical chunks sized
  /// to [chunkSize] (default fits u16).
  static List<Uint8List> logicalResponse(int sessionId, Uint8List payload,
      {bool push = false, int chunkSize = 0xffff}) {
    final logical = concat([be64(payload.length), payload]);
    final chunks = <Uint8List>[];
    var off = 0;
    while (off < logical.length) {
      final n =
          logical.length - off < chunkSize ? logical.length - off : chunkSize;
      chunks.add(responseChunk(sessionId, logical.sublist(off, off + n),
          push: push));
      off += n;
    }
    if (chunks.isEmpty) {
      // Empty logical payload still needs one chunk carrying the u64 header.
      chunks.add(responseChunk(sessionId, be64(0), push: push));
    }
    return chunks;
  }
}

class ModernChunk {
  ModernChunk(this.rawSessionId, this.data);
  final int rawSessionId;
  final Uint8List data;
  bool get isPush => (rawSessionId & ModernTransport.pushBit) != 0;
  int get sessionId => rawSessionId & 0x7fffffff;
}

/// Splits the agent->host byte stream into 6-byte-headed physical chunks.
class ModernChunkReader {
  final StreamBuffer _buf = StreamBuffer();

  List<ModernChunk> add(Uint8List bytes) {
    _buf.add(bytes);
    final out = <ModernChunk>[];
    while (true) {
      final head = _buf.peek(6);
      if (head == null) break;
      final rawSid = readBe32(head);
      final size = readBe16(head, 4);
      final data = _buf.peek(6 + size);
      if (data == null) break;
      _buf.skip(6 + size);
      out.add(ModernChunk(rawSid, Uint8List.fromList(data.sublist(6))));
    }
    _buf.compact();
    return out;
  }
}

/// Splits the host->agent byte stream into 9-byte-headed request packets.
class ModernPacketReader {
  final StreamBuffer _buf = StreamBuffer();
  final int maxData;

  ModernPacketReader({this.maxData = 256 * 1024 * 1024});

  List<ModernPacket> add(Uint8List bytes) {
    _buf.add(bytes);
    final out = <ModernPacket>[];
    while (true) {
      final head = _buf.peek(9);
      if (head == null) break;
      final sid = readBe32(head);
      final flag = head[4];
      final len = readBe32(head, 5);
      if (len > maxData) {
        throw const FormatException('modern packet too large');
      }
      final pkt = _buf.peek(9 + len);
      if (pkt == null) break;
      _buf.skip(9 + len);
      out.add(ModernPacket(sid, flag, Uint8List.fromList(pkt.sublist(9))));
    }
    _buf.compact();
    return out;
  }
}

class ModernPacket {
  ModernPacket(this.sessionId, this.flag, this.data);
  final int sessionId;
  final int flag;
  final Uint8List data;

  /// flag=1 payloads are sig128 || protobuf. Returns the proto bytes if the
  /// signature verifies against [key], else null.
  Uint8List? signedProto(RSAPublicKey key) {
    if (flag != ModernTransport.flagSigned || data.length < kSignatureLen) {
      return null;
    }
    final sig = Uint8List.fromList(data.sublist(0, kSignatureLen));
    final proto = Uint8List.fromList(data.sublist(kSignatureLen));
    return rsaVerify(key, proto, sig) ? proto : null;
  }
}

/// Per-session logical message assembler: concatenates chunk data, then reads
/// repeated `u64be len + payload` messages from the stream.
class LogicalMessageReader {
  final StreamBuffer _buf = StreamBuffer();
  final int maxMessage;

  LogicalMessageReader({this.maxMessage = 256 * 1024 * 1024});

  /// Feed chunk payload bytes; returns every complete logical message payload.
  List<Uint8List> add(Uint8List data) {
    _buf.add(data);
    final out = <Uint8List>[];
    while (true) {
      final head = _buf.peek(8);
      if (head == null) break;
      final n = readBe64(head);
      if (n > maxMessage) {
        throw const FormatException('logical message too large');
      }
      final msg = _buf.peek(8 + n);
      if (msg == null) break;
      _buf.skip(8 + n);
      out.add(Uint8List.fromList(msg.sublist(8)));
    }
    _buf.compact();
    return out;
  }

  /// Bytes that arrived past the last complete logical message — e.g. file
  /// body bytes that follow a download response header on the same session.
  Uint8List drainRemainder() => _buf.drain();
}

/// Routes physical chunks to per-session logical assemblers; emits
/// (sessionId, payload) pairs. Push chunks route by low-31-bit sessionId.
class SessionDemux {
  final _sessions = <int, LogicalMessageReader>{};
  final int maxMessage;

  SessionDemux({this.maxMessage = 256 * 1024 * 1024});

  LogicalMessageReader _reader(int sid) =>
      _sessions.putIfAbsent(sid, () => LogicalMessageReader(maxMessage: maxMessage));

  /// Returns list of (sessionId, isPush, payload) completed messages.
  List<({int sessionId, bool isPush, Uint8List payload})> addChunk(
      ModernChunk chunk) {
    final msgs = _reader(chunk.sessionId).add(chunk.data);
    return [
      for (final m in msgs)
        (sessionId: chunk.sessionId, isPush: chunk.isPush, payload: m)
    ];
  }

  /// Forget a session's buffered partial message (desync recovery).
  void dropSession(int sessionId) => _sessions.remove(sessionId);

  /// Raw remaining per-session bytes not yet a complete logical message
  /// (used by file-body phase where bytes after the header are raw file data).
  Uint8List drainRemainder(int sessionId) {
    final r = _sessions.remove(sessionId);
    return r?.drainRemainder() ?? Uint8List(0);
  }
}
