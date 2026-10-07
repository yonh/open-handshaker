import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

import 'crypto.dart';
import 'envelope.dart';
import 'frame.dart';
import 'transport.dart';

/// Host-side client for the legacy ADBForward protocol (port 10086).
///
/// Mirrors the original model: one TCP connection per request; a separate
/// persistent "callback" connection carries KEEP_ALIVE (type 5), heartbeat
/// pings, and push events (command 9).
class LegacySspClient {
  LegacySspClient({required this.keyPair});

  final AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> keyPair;

  Uint8List _sign(Uint8List data) => rsaSign(keyPair.privateKey, data);

  /// Send the public-key handshake frame over [channel], read and verify the
  /// base64(RSA("ok")) response. The original agent closes the socket after
  /// the handshake; callers should use a fresh channel.
  Future<bool> handshake(ByteChannel channel,
      {Duration timeout = const Duration(seconds: 10)}) async {
    final reader = LegacyFrameReader();
    channel.send(LegacyEnvelope.handshakeRequest(keyPair.publicKey));
    final c = Completer<bool>();
    late StreamSubscription<Uint8List> sub;
    sub = channel.incoming.listen((bytes) {
      for (final f in reader.add(bytes)) {
        if (c.isCompleted) continue;
        final body = f.length >= 7 ? f.sublist(7) : Uint8List(0);
        c.complete(LegacyEnvelope.verifyHandshakeResult(
            utf8.decode(body, allowMalformed: true), keyPair.privateKey));
      }
    }, onDone: () {
      if (!c.isCompleted) c.complete(false);
    }, onError: (_) {
      if (!c.isCompleted) c.complete(false);
    });
    final ok = await c.future.timeout(timeout, onTimeout: () => false);
    await sub.cancel();
    return ok;
  }

  /// One signed request on a fresh [channel]; returns the parsed response.
  Future<LegacyResponse> request(ByteChannel channel, int command, int subtype,
      {Uint8List? body,
      Duration timeout = const Duration(seconds: 30)}) async {
    final reader = LegacyFrameReader();
    channel.send(LegacyEnvelope.signedRequest(
        command, subtype, body ?? Uint8List(0), _sign));
    final c = Completer<LegacyResponse>();
    late StreamSubscription<Uint8List> sub;
    sub = channel.incoming.listen((bytes) {
      for (final f in reader.add(bytes)) {
        if (c.isCompleted) continue;
        if (LegacyEnvelope.isHeartbeatPing(f)) {
          // Be polite if a ping strays onto a short-lived socket.
          channel.send(LegacyEnvelope.heartbeatPong(_sign));
          continue;
        }
        c.complete(LegacyEnvelope.parseResponse(f));
      }
    }, onDone: () {
      if (!c.isCompleted) {
        c.completeError(StateError('connection closed'));
      }
    }, onError: (e) {
      if (!c.isCompleted) c.completeError(e);
    });
    try {
      return await c.future.timeout(timeout);
    } finally {
      await sub.cancel();
    }
  }
}

/// Persistent callback connection (KEEP_ALIVE type 5). Emits pushes and
/// answers heartbeat pings with signed type-6 requests.
class LegacyCallbackConnection {
  LegacyCallbackConnection(this.channel, this.client);

  final ByteChannel channel;
  final LegacySspClient client;

  final _pushCtl = StreamController<LegacyPush>.broadcast();
  final _reader = LegacyFrameReader();
  StreamSubscription<Uint8List>? _sub;

  Stream<LegacyPush> get pushes => _pushCtl.stream;
  final _closedCtl = StreamController<void>.broadcast();
  Stream<void> get closed => _closedCtl.stream;

  /// Send signed KEEP_ALIVE, return the device-info response body.
  Future<LegacyResponse> connect(
      {Duration timeout = const Duration(seconds: 15)}) async {
    final first = Completer<LegacyResponse>();
    _sub = channel.incoming.listen((bytes) {
      for (final f in _reader.add(bytes)) {
        if (LegacyEnvelope.isPush(f)) {
          _pushCtl.add(LegacyEnvelope.parsePush(f));
        } else if (LegacyEnvelope.isHeartbeatPing(f)) {
          channel.send(
              LegacyEnvelope.heartbeatPong(client._sign));
        } else if (!first.isCompleted) {
          first.complete(LegacyEnvelope.parseResponse(f));
        }
        // Later non-push frames on the callback socket are ignored.
      }
    }, onDone: () {
      if (!first.isCompleted) {
        first.completeError(StateError('callback socket closed'));
      }
      _closedCtl.add(null);
    }, onError: (e) {
      if (!first.isCompleted) first.completeError(e);
      _closedCtl.add(null);
    });
    channel.send(LegacyEnvelope.signedRequest(
        LegacyCmd.keepAlive, 0, Uint8List(0), client._sign));
    return first.future.timeout(timeout);
  }

  Future<void> close() async {
    await _sub?.cancel();
    await channel.close();
  }
}
