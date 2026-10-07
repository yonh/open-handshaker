import 'dart:async';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

import 'bytes.dart';
import 'crypto.dart';
import 'envelope.dart';
import 'frame.dart';
import 'transport.dart';

/// A decoded legacy request arriving on an agent connection.
class LegacyRequest {
  LegacyRequest({required this.command, required this.subtype,
      required this.version, required this.body});
  final int command;
  final int subtype;
  final int version;
  final Uint8List body;
}

/// Agent-side handler: returns the response body bytes.
/// [keepAlive] is set true by the server when command == KEEP_ALIVE — the
/// connection then stays open for heartbeats and pushes.
typedef LegacyRequestHandler = Future<Uint8List> Function(
    LegacyConnection conn, LegacyRequest req);

/// One legacy agent-side connection.
class LegacyConnection {
  LegacyConnection(this.channel);
  final ByteChannel channel;
  bool keepAlive = false;
  bool closed = false;

  void sendResponse(int command, int version, int subtype, Uint8List body) {
    final payload = Uint8List(3 + body.length)
      ..[0] = command
      ..[1] = version
      ..[2] = subtype
      ..setRange(3, 3 + body.length, body);
    channel.send(LegacyFrame.wrap(payload));
  }

  /// Agent-initiated heartbeat ping: `00 00 00 03 06 01 01`.
  void sendHeartbeatPing() =>
      channel.send(LegacyFrame.wrap(Uint8List.fromList([6, 1, 1])));

  /// Agent-initiated push: `[09][category][01][json-utf8]`.
  void sendPush(int category, String json) {
    final body = utf8Bytes(json);
    final payload = concat([
      Uint8List.fromList([9, category, 1]),
      body,
    ]);
    channel.send(LegacyFrame.wrap(payload));
  }

  Future<void> close() async {
    closed = true;
    await channel.close();
  }
}

/// Legacy ADBForward agent server on port 10086.
///
/// Behaviour mirrored from the recovered service:
///  * flag==0 frame → public-key handshake (single process-wide key slot —
///    first successful import wins until restart).
///  * flag!=0 → SHA256withRSA verify against the imported key, dispatch on
///    (command, subtype), send `[C][V][S][body]` reply, close unless
///    KEEP_ALIVE.
///  * one callback (keep-alive) connection at a time; a new one replaces the
///    old.
class LegacyAgentServer {
  LegacyAgentServer({required this.requestHandler});

  final LegacyRequestHandler requestHandler;

  /// Single process-wide public key slot, matching the original's static
  /// `utils/j.a` behaviour.
  RSAPublicKey? hostKey;

  /// The single callback connection, if any.
  LegacyConnection? callbackConnection;

  final _connections = <LegacyConnection>[];

  void Function(LegacyConnection)? onKeepAlive;

  void attach(ByteChannel channel) {
    final conn = LegacyConnection(channel);
    _connections.add(conn);
    final reader = LegacyFrameReader();
    channel.incoming.listen((bytes) async {
      try {
        for (final f in reader.add(bytes)) {
          await _handleFrame(conn, f);
        }
      } catch (_) {
        await conn.close();
        _connections.remove(conn);
      }
    }, onDone: () {
      conn.closed = true;
      _connections.remove(conn);
      if (callbackConnection == conn) callbackConnection = null;
    }, onError: (_) {
      conn.closed = true;
      _connections.remove(conn);
      if (callbackConnection == conn) callbackConnection = null;
    });
  }

  Future<void> _handleFrame(LegacyConnection conn, Uint8List frame) async {
    if (frame.length < 5) throw const FormatException('short frame');
    final flag = frame[4];
    if (flag == 0) {
      await _handleHandshake(conn, frame);
      return;
    }
    if (frame.length < 136) throw const FormatException('short signed frame');
    final sig = Uint8List.fromList(frame.sublist(5, 133));
    final covered = Uint8List.fromList(frame.sublist(133));
    final key = hostKey;
    if (key == null || !rsaVerify(key, covered, sig)) {
      throw const FormatException('signature verification failed');
    }
    final req = LegacyRequest(
      command: covered[0],
      subtype: covered[1],
      version: covered[2],
      body: Uint8List.fromList(covered.sublist(3)),
    );
    if (req.command == LegacyCmd.keepAlive) {
      conn.keepAlive = true;
      // Replace any existing callback connection.
      await callbackConnection?.close();
      callbackConnection = conn;
      onKeepAlive?.call(conn);
    }
    final body = await requestHandler(conn, req);
    conn.sendResponse(req.command, req.version, req.subtype, body);
    if (!conn.keepAlive) {
      await conn.close();
      _connections.remove(conn);
    }
  }

  /// flag==0 public-key handshake: MD5(DER) + u32 len + AES-CBC ciphertext.
  Future<void> _handleHandshake(LegacyConnection conn, Uint8List frame) async {
    // Host key slot is sticky: if a key is already imported the original code
    // still answers ok (encrypted with the OLD key).
    if (hostKey != null) {
      conn.channel.send(LegacyEnvelope.handshakeOkResponse(hostKey!));
      await conn.close();
      _connections.remove(conn);
      return;
    }
    try {
      if (frame.length < 28) throw const FormatException('short handshake');
      final md5v = Uint8List.fromList(frame.sublist(8, 24));
      final encLen = readBe32(frame, 24);
      if (frame.length < 28 + encLen) {
        throw const FormatException('truncated handshake');
      }
      final enc = Uint8List.fromList(frame.sublist(28, 28 + encLen));
      final unwrapped = unwrapPublicKey(enc, md5v);
      hostKey = unwrapped.key;
      conn.channel.send(LegacyEnvelope.handshakeOkResponse(hostKey!));
    } catch (_) {
      conn.channel.send(LegacyEnvelope.handshakeFailedResponse());
    }
    await conn.close();
    _connections.remove(conn);
  }
}
