import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:pointycastle/export.dart';
import 'package:protobuf/protobuf.dart' as $pb;

import 'bytes.dart';
import 'crypto.dart';
import 'modern_transport.dart';
import 'pb/SmartSyncProtocol.recovered.pb.dart' as pb;
import 'pb/SmartSyncProtocol.recovered.pbenum.dart' as pbe;
import 'transport.dart';
import 'types.dart';
import 'trust_store.dart';

/// Device identity the agent presents during Handshake01.
class AgentIdentity {
  AgentIdentity({
    required this.deviceUuid,
    required this.deviceName,
    this.apkVersion = 1,
    this.apkVersionName = '1.0.0',
    this.smartSyncProtocolVersion = '2',
    this.minHostVersion = '1.0.197',
    this.minHostVersionCode = 1,
    this.isSmartisanDevice = false,
    this.usbSerial = '',
  });

  final String deviceUuid;
  final String deviceName;
  final int apkVersion;
  final String apkVersionName;
  final String smartSyncProtocolVersion;
  final String minHostVersion;
  final int minHostVersionCode;
  final bool isSmartisanDevice;
  final String usbSerial;
}

/// Decision the agent UI/policy layer returns for a pairing request.
enum TrustDecision { once, always, deny }

/// Request context passed to the trust approver.
class PairingRequest {
  PairingRequest({required this.hostUuid, required this.hostName});
  final String hostUuid;
  final String hostName;
}

/// Handler for a signed business request on an authenticated session.
/// Returns the protobuf response (sent as one logical message) or null to
/// leave the request unanswered.
typedef SspRequestHandler = FutureOr<$pb.GeneratedMessage?> Function(
    AgentSession session, Uint8List protoBytes, int typeValue, int sessionId);

/// Handler for raw flag3 file-body packets (upload data path).
typedef SspFileDataHandler = void Function(AgentSession session,
    int sessionId, Uint8List data);

/// One connected host session on the agent.
class AgentSession {
  AgentSession(this.id, this.channel);

  final int id;
  final ByteChannel channel;

  RSAPublicKey? hostKey;
  String hostUuid = '';
  String hostName = '';
  bool ready = false;
  int heartbeatTimeoutSecond = 60;

  void send(Uint8List chunk) {
    // A closed channel means the peer is gone — pushing to it would throw
    // an unhandled async error (e.g. folder-event pushes after link down).
    if (channel.isClosed) return;
    channel.send(chunk);
  }

  /// Send a protobuf response as a logical message (u64 len + payload) chunked
  /// over [sessionId].
  void respond(int sessionId, $pb.GeneratedMessage message) {
    for (final chunk
        in ModernTransport.logicalResponse(sessionId, message.writeToBuffer())) {
      send(chunk);
    }
  }

  /// Send a push message (high bit set).
  void push(int sessionId, $pb.GeneratedMessage message) {
    for (final chunk in ModernTransport.logicalResponse(
        sessionId, message.writeToBuffer(),
        push: true)) {
      send(chunk);
    }
  }

  /// Send raw body bytes on [sessionId] (download data phase): each piece is
  /// chunked without a logical header.
  void sendRaw(int sessionId, Uint8List data, {int chunkSize = 0xffff}) {
    var off = 0;
    while (off < data.length) {
      final n = data.length - off < chunkSize ? data.length - off : chunkSize;
      send(ModernTransport.responseChunk(sessionId,
          Uint8List.fromList(data.sublist(off, off + n))));
      off += n;
    }
  }
}

/// Modern SSP v2 agent server. Listens for packets, performs the two-stage
/// handshake (with interactive trust approval), then dispatches signed
/// protobuf requests by RequestType value.
class SspAgentServer {
  SspAgentServer({
    required this.identity,
    required this.hostTrustStore,
    this.onPairingRequest,
    this.derivedKeySize = 32,
  });

  final AgentIdentity identity;
  final HostTrustStore hostTrustStore;

  /// Called when an unknown host requests pairing. Return null to keep the
  /// host waiting (a later call must resolve via [resolvePairing]).
  final FutureOr<TrustDecision?> Function(PairingRequest request,
      Completer<TrustDecision> pending)? onPairingRequest;

  final int derivedKeySize;

  final _packetReader = <AgentSession, ModernPacketReader>{};
  final _pendingPairings = <int, Completer<TrustDecision>>{};
  final _sessions = <AgentSession>[];
  int _nextConnectionId = 1;

  SspRequestHandler? requestHandler;
  SspFileDataHandler? fileDataHandler;

  /// Sessions that completed the handshake.
  List<AgentSession> get readySessions =>
      _sessions.where((s) => s.ready).toList();

  void attach(ByteChannel channel) {
    final session = AgentSession(_nextConnectionId++, channel);
    _sessions.add(session);
    _packetReader[session] = ModernPacketReader();
    channel.incoming.listen(
      (data) => _onData(session, data),
      onDone: () => _drop(session),
      onError: (_) => _drop(session),
    );
  }

  /// Resolve a pending pairing decision created by a null return from
  /// [onPairingRequest].
  void resolvePairing(AgentSession session, TrustDecision decision) {
    _pendingPairings.remove(session.id)?.complete(decision);
  }

  AgentSession? pendingPairing(int sessionId) =>
      _pendingPairings.containsKey(sessionId)
          ? _sessions.firstWhere((s) => s.id == sessionId)
          : null;

  void _drop(AgentSession s) {
    _sessions.remove(s);
    _packetReader.remove(s);
    _pendingPairings.remove(s.id)?.complete(TrustDecision.deny);
    onSessionClosed?.call(s);
  }

  void Function(AgentSession)? onSessionClosed;

  /// Close every attached session (daemon shutdown). Pending pairings are
  /// denied so their futures do not hang.
  Future<void> close() async {
    for (final s in List.of(_sessions)) {
      _pendingPairings.remove(s.id)?.complete(TrustDecision.deny);
      await s.channel.close().catchError((_) {});
      _drop(s);
    }
  }

  /// Debug/diagnostic hook for dropped connections (bad packets etc.).
  void Function(Object error, StackTrace st)? onError;

  Future<void> _onData(AgentSession session, Uint8List bytes) async {
    List<ModernPacket> packets;
    try {
      // Bytes can arrive after the session was already dropped.
      final reader = _packetReader[session];
      if (reader == null) return;
      packets = reader.add(bytes);
    } on FormatException {
      await session.channel.close();
      _drop(session);
      return;
    }
    for (final pkt in packets) {
      try {
        await _handlePacket(session, pkt);
      } catch (e, st) {
        onError?.call(e, st);
        // A malformed packet must not kill the daemon; drop the connection.
        await session.channel.close();
        _drop(session);
        return;
      }
    }
  }

  Future<void> _handlePacket(AgentSession session, ModernPacket pkt) async {
    switch (pkt.flag) {
      case ModernTransport.flagHandshake:
        await _handleHandshake(session, pkt);
      case ModernTransport.flagSigned:
        await _handleSigned(session, pkt);
      case ModernTransport.flagFileData:
        fileDataHandler?.call(session, pkt.sessionId, pkt.data);
      default:
        throw FormatException('unknown flag ${pkt.flag}');
    }
  }

  // ---------------- handshake ----------------

  Future<void> _handleHandshake(AgentSession session, ModernPacket pkt) async {
    if (pkt.sessionId == 1) {
      final req = pb.SSPHandShakeRequest01.fromBuffer(pkt.data);
      final unwrap = unwrapPublicKey(
          Uint8List.fromList(req.enckey), Uint8List.fromList(req.md5));
      session
        ..hostKey = unwrap.key
        ..hostUuid = req.hostUuid
        ..hostName = req.hostName
        ..heartbeatTimeoutSecond = req.heartbeatTimeoutSecond.toInt();

      final resp = pb.SSPHandShakeResponse01()
        ..type = Req.handshakeResp01
        ..apkVersion = identity.apkVersion.toString()
        ..apkVersionName = identity.apkVersionName
        ..clientTimestamp =
            Int64(DateTime.now().millisecondsSinceEpoch ~/ 1000)
        ..clientSmartSyncProtocolVersion = identity.smartSyncProtocolVersion
        ..clientMinHostVersion = identity.minHostVersion
        ..clientMinHostVersionCode = Int64(identity.minHostVersionCode)
        ..deviceUuid = identity.deviceUuid
        ..deviceName = identity.deviceName
        ..usbSerial = identity.usbSerial
        ..isSmartisanDevice = identity.isSmartisanDevice;
      session.respond(1, resp);
      return;
    }

    if (pkt.sessionId == 2) {
      final req = pb.SSPHandShakeRequest02.fromBuffer(pkt.data);
      final hostKey = session.hostKey;
      if (hostKey == null) {
        throw const FormatException('handshake02 before handshake01');
      }
      final existing = hostTrustStore.find(req.hostUuid);

      // Trusted host presenting a matching derived key: accept immediately.
      if (existing != null &&
          existing.derivedKey != null &&
          req.derivedKey.isNotEmpty &&
          const ListEq().equals(
              Uint8List.fromList(req.derivedKey), existing.derivedKey!) &&
          (existing.trustType == Trust.always ||
              existing.trustType == Trust.once)) {
        await _accept(session, req, existing.trustType, existing);
        return;
      }

      final decision = await _askPairingDecision(session, req);
      switch (decision) {
        case TrustDecision.deny:
          final resp = pb.SSPHandShakeResponse02()
            ..type = Req.handshakeResp02
            ..trustType = Trust.no
            ..deviceUuid = identity.deviceUuid
            ..deviceName = identity.deviceName
            ..result = 'failed';
          session.respond(2, resp);
        case TrustDecision.once:
          final h = _storeHost(req, session,
              Trust.once);
          await _accept(session, req,
              Trust.once, h);
        case TrustDecision.always:
          final h = _storeHost(req, session,
              Trust.always);
          await _accept(session, req,
              Trust.always, h);
      }
      return;
    }

    throw FormatException('unexpected handshake session ${pkt.sessionId}');
  }

  Future<TrustDecision> _askPairingDecision(
      AgentSession session, pb.SSPHandShakeRequest02 req) async {
    // Tell the host we're waiting, then ask the policy/UI layer.
    final waiting = pb.SSPHandShakeResponse02()
      ..type = Req.handshakeResp02
      ..trustType = Trust.waiting
      ..deviceUuid = identity.deviceUuid
      ..deviceName = identity.deviceName;
    session.respond(2, waiting);

    if (onPairingRequest == null) return TrustDecision.deny;
    final pending = Completer<TrustDecision>();
    _pendingPairings[session.id] = pending;
    final immediate =
        await onPairingRequest!(PairingRequest(hostUuid: req.hostUuid, hostName: session.hostName), pending);
    if (immediate != null) {
      _pendingPairings.remove(session.id);
      return immediate;
    }
    try {
      return await pending.future.timeout(const Duration(minutes: 2),
          onTimeout: () => TrustDecision.deny);
    } finally {
      _pendingPairings.remove(session.id);
    }
  }

  TrustedHost _storeHost(pb.SSPHandShakeRequest02 req, AgentSession session,
      pbe.SSPHandShakeTrustType trust) {
    final rnd = Random.secure();
    final derived = Uint8List.fromList(
        List.generate(derivedKeySize, (_) => rnd.nextInt(256)));
    final host = TrustedHost(
      hostUuid: req.hostUuid,
      hostName: session.hostName,
      trustType: trust,
      hostKeyDer: encodeRsaPublicKeyDer(session.hostKey!),
      derivedKey: derived,
    );
    hostTrustStore.add(host);
    unawaited(hostTrustStore.save());
    return host;
  }

  Future<void> _accept(AgentSession session, pb.SSPHandShakeRequest02 req,
      pbe.SSPHandShakeTrustType trustType, TrustedHost host) async {
    final proof =
        base64.encode(rsaEncrypt(session.hostKey!, utf8Bytes('ok')));
    final resp = pb.SSPHandShakeResponse02()
      ..type = Req.handshakeResp02
      ..trustType = trustType
      ..deviceUuid = identity.deviceUuid
      ..deviceName = identity.deviceName
      ..derivedKey = host.derivedKey ?? Uint8List(0)
      ..result = proof;
    session.respond(2, resp);
    session.ready = true;
    onSessionReady?.call(session);
  }

  void Function(AgentSession)? onSessionReady;

  // ---------------- business ----------------

  Future<void> _handleSigned(AgentSession session, ModernPacket pkt) async {
    if (!session.ready || session.hostKey == null) {
      throw const FormatException('signed request before handshake');
    }
    final proto = pkt.signedProto(session.hostKey!);
    if (proto == null) {
      throw const FormatException('bad request signature');
    }
    final type = pb.SSPRequest.fromBuffer(proto).type.value;
    final response = await requestHandler?.call(session, proto, type, pkt.sessionId);
    if (response != null) {
      session.respond(pkt.sessionId, response);
    }
  }
}

/// Convenience TCP listener that feeds accepted sockets into an
/// [SspAgentServer].
class SspAgentListener {
  SspAgentListener(this.server, this.socket);
  final SspAgentServer server;
  final ServerSocket socket;

  static Future<SspAgentListener> bind(SspAgentServer server, int port,
      {InternetAddress? address}) async {
    final s = await ServerSocket.bind(address ?? InternetAddress.anyIPv4, port);
    s.listen((sock) {
      sock.setOption(SocketOption.tcpNoDelay, true);
      server.attach(SocketChannel(sock));
    });
    return SspAgentListener(server, s);
  }

  Future<void> close() => socket.close();
}
