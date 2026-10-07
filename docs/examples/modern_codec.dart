// ignore_for_file: avoid_print, curly_braces_in_flow_control_structures
import 'dart:typed_data';

Uint8List be32(int n) {
  if (n < 0 || n > 0x7fffffff) throw RangeError.value(n);
  return (ByteData(4)..setUint32(0, n, Endian.big)).buffer.asUint8List();
}
Uint8List concat(Iterable<List<int>> parts) {
  final b = BytesBuilder(copy: true);
  for (final part in parts) { b.add(part); }
  return b.takeBytes();
}
Uint8List modernPacket(int sid, int flag, List<int> data) {
  if (sid < 0 || sid > 0x7fffffff || flag < 0 || flag > 255) {
    throw RangeError('Invalid modern header');
  }
  return concat([be32(sid), [flag], be32(data.length), data]);
}
Uint8List modernSigned(int sid, Uint8List proto,
    Uint8List Function(Uint8List raw) signRaw) {
  final signature = signRaw(proto);
  if (signature.length != 128) throw StateError('RSA-1024 required');
  return modernPacket(sid, 1, concat([signature, proto]));
}
class ModernChunk {
  ModernChunk(this.rawSessionId, this.push, this.data);
  final int rawSessionId;
  int get sessionId => rawSessionId & 0x7fffffff;
  final bool push;
  final Uint8List data;
}
class ModernChunkReader {
  Uint8List pending = Uint8List(0);
  List<ModernChunk> add(List<int> bytes) {
    pending = concat([pending, bytes]);
    final out = <ModernChunk>[];
    var p = 0;
    while (pending.length - p >= 6) {
      final head = ByteData.sublistView(pending, p, p + 6);
      final rawSid = head.getUint32(0, Endian.big);
      final size = head.getUint16(4, Endian.big);
      if (pending.length - p < 6 + size) break;
      out.add(ModernChunk(rawSid,
          (rawSid & 0x80000000) != 0,
          Uint8List.fromList(pending.sublist(p + 6, p + 6 + size))));
      p += 6 + size;
    }
    pending = Uint8List.fromList(pending.sublist(p));
    return out;
  }
}
String hex(List<int> b) => b.map((n) => n.toRadixString(16).padLeft(2, '0')).join();
void main() {
  // A synthetic protobuf HeartBeat.type=1 fixture, no timestamp, invalid zerosig.
  final p = modernSigned(3, Uint8List.fromList([8, 1]), (_) => Uint8List(128));
  if (p.length != 139 || hex(p.sublist(0, 9)) != '000000030100000082') {
    throw StateError('Modern request');
  }
  final raw = [0x80,0,0,3,0,10, 0,0,0,0,0,0,0,2,8,1];
  final reader = ModernChunkReader();
  if (reader.add(raw.sublist(0, 5)).isNotEmpty) throw StateError('Split');
  final chunks = reader.add(raw.sublist(5));
  if (chunks.length != 1 || chunks[0].sessionId != 3 || !chunks[0].push ||
      hex(chunks[0].data) != '00000000000000020801') {
    throw StateError('Modern response');
  }
  print('modern request + split response chunk vectors: OK');
}
