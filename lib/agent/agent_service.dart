import 'dart:async';
import 'dart:io';

import '../ssp/legacy_server.dart';
import '../ssp/server.dart';
import '../ssp/transport.dart';
import '../ssp/trust_store.dart';
import 'agent_handlers.dart';
import 'http_file_server.dart';
import 'legacy_handlers.dart';
import 'providers/channel_providers.dart';
import 'providers/files_provider.dart';

/// The on-device agent daemon.
///
/// Ports (per DESIGN.md):
///   10086 — legacy ADBForward SSP server
///   10088 — modern SSP v2 server (port choice is ours; original's is 待验证)
///   19999 — HTTP file/test server
///
/// Construct it with the platform-side [ChannelProviders]; on desktop the
/// channel calls degrade gracefully so the daemon runs for development.
class AgentService {
  AgentService({ChannelProviders? channels, FilesProvider? files})
      : channels = channels ?? ChannelProviders(),
        files = files ?? FilesProvider();

  final FilesProvider files;
  final ChannelProviders channels;
  late AgentHandlers handlers =
      AgentHandlers(files: files, channels: channels);
  late final LegacyAgentHandlers legacyHandlers =
      LegacyAgentHandlers(files: files, channels: channels);

  SspAgentServer? modern;
  LegacyAgentServer? legacy;
  HttpFileServer? http;
  ServerSocket? _legacySocket;
  ServerSocket? _modernSocket;

  /// Emitted when an unknown host requests pairing; UI should complete the
  /// attached completer with the user's TrustDecision (or call
  /// SspAgentServer.resolvePairing later).
  final pairingRequests = StreamController<PairingRequest>.broadcast();

  static const portLegacy = 10086;
  static const portModern = 10088;
  static const portHttp = 19999;

  /// Start all three listeners. [identity] is the device's SSP identity;
  /// [hostTrustStore] persists approved hosts.
  ///
  /// [onPairingRequest] — return a TrustDecision immediately or null and
  /// resolve later via the emitted pairingRequests stream +
  /// resolvePairing. If omitted, unknown hosts are denied.
  Future<void> start({
    required AgentIdentity identity,
    required HostTrustStore hostTrustStore,
    FutureOr<TrustDecision?> Function(PairingRequest,
            Completer<TrustDecision>)?
        onPairingRequest,
    int modernPort = portModern,
    int legacyPort = portLegacy,
    int httpPort = portHttp,
  }) async {
    handlers.onQuit = (s) => s.channel.close();

    modern = SspAgentServer(
      identity: identity,
      hostTrustStore: hostTrustStore,
      onPairingRequest: onPairingRequest ??
          (req, pending) {
            pairingRequests.add(req);
            return null; // resolved via resolvePairing / pending completer
          },
    )
      ..requestHandler = handlers.call
      ..fileDataHandler = handlers.onFileData;

    _modernSocket = await ServerSocket.bind(
        InternetAddress.anyIPv4, modernPort,
        shared: true);
    _modernSocket!.listen((sock) {
      sock.setOption(SocketOption.tcpNoDelay, true);
      modern!.attach(SocketChannel(sock));
    });

    legacy = LegacyAgentServer(requestHandler: legacyHandlers.call);
    _legacySocket = await ServerSocket.bind(
        InternetAddress.anyIPv4, legacyPort,
        shared: true);
    _legacySocket!.listen((sock) {
      sock.setOption(SocketOption.tcpNoDelay, true);
      legacy!.attach(SocketChannel(sock));
    });

    http = await HttpFileServer.bind(port: httpPort);
  }

  /// Resolve a pending pairing request (device-side UI decision).
  void resolvePairing(AgentSession session, TrustDecision decision) =>
      modern?.resolvePairing(session, decision);

  /// Sessions that completed the modern handshake.
  List<AgentSession> get readySessions => modern?.readySessions ?? const [];

  Future<void> stop() async {
    await _modernSocket?.close();
    await _legacySocket?.close();
    await modern?.close();
    await legacy?.close();
    await http?.close();
    await handlers.dispose();
  }
}
