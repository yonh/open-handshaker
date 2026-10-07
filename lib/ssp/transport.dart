import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

/// Byte-stream abstraction over a socket-like duplex channel so the same
/// session code runs over direct TCP (Wi-Fi), an `adb forward` local port,
/// or an in-memory fake in tests.
abstract class ByteChannel {
  /// Incoming bytes; emits Uint8List chunks.
  Stream<Uint8List> get incoming;

  /// Queue bytes for sending.
  void send(Uint8List data);

  /// Remote peer description for logs/UI.
  String get peerLabel;

  Future<void> close();
}

class SocketChannel extends ByteChannel {
  SocketChannel(this.socket);
  final Socket socket;
  Stream<Uint8List>? _stream;

  static Future<SocketChannel> connect(String host, int port,
      {Duration timeout = const Duration(seconds: 5)}) async {
    final s = await Socket.connect(host, port, timeout: timeout);
    s.setOption(SocketOption.tcpNoDelay, true);
    return SocketChannel(s);
  }

  @override
  Stream<Uint8List> get incoming =>
      _stream ??= socket.map((d) => Uint8List.fromList(d)).asBroadcastStream();

  @override
  void send(Uint8List data) => socket.add(data);

  @override
  String get peerLabel =>
      '${socket.remoteAddress.address}:${socket.remotePort}';

  @override
  Future<void> close() async {
    await socket.flush();
    await socket.close();
  }
}

/// In-memory full-duplex pair for loopback tests and the in-process bridge.
class DuplexChannel extends ByteChannel {
  DuplexChannel._(this._out, this._in, this._label);

  final StreamController<Uint8List> _out;
  final StreamController<Uint8List> _in;
  final String _label;

  /// Returns (a, b): bytes sent into a arrive at b's incoming and vice versa.
  static (DuplexChannel, DuplexChannel) pair({String label = 'duplex'}) {
    final ab = StreamController<Uint8List>();
    final ba = StreamController<Uint8List>();
    return (
      DuplexChannel._(ab, ba, '$label:a'),
      DuplexChannel._(ba, ab, '$label:b'),
    );
  }

  @override
  Stream<Uint8List> get incoming => _in.stream;

  @override
  void send(Uint8List data) => _out.add(data);

  @override
  String get peerLabel => _label;

  @override
  Future<void> close() async {
    await _out.close();
    await _in.close();
  }
}

/// Accept-side wrapper so servers can accept either real sockets or channels.
typedef ChannelAccept = Stream<ByteChannel>;

Stream<ByteChannel> socketChannelStream(ServerSocket server) =>
    server.map((s) {
      s.setOption(SocketOption.tcpNoDelay, true);
      return SocketChannel(s) as ByteChannel;
    });
