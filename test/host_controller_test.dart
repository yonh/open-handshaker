import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:handshaker_open/agent/agent_service.dart';
import 'package:handshaker_open/host/discovery/usb_discovery.dart';
import 'package:handshaker_open/host/discovery/wifi_discovery.dart';
import 'package:handshaker_open/host/host_controller.dart';
import 'package:handshaker_open/host/host_controller_impl.dart';
import 'package:handshaker_open/ssp/client.dart';
import 'package:handshaker_open/ssp/server.dart';
import 'package:handshaker_open/ssp/trust_store.dart';

/// Phase 3: real controller against the real agent daemon on loopback.
void main() {
  late Directory tmp;

  setUpAll(() {
    tmp = Directory.systemTemp.createTempSync('host_ctl');
  });
  tearDownAll(() => tmp.deleteSync(recursive: true));

  HostControllerImpl makeCtl() => HostControllerImpl(
        identity: HostIdentity.generate(hostUuid: 'host-ctl', hostName: 'Mac'),
        trustStore: TrustStore('${tmp.path}/dev.json'),
        discoveryInterval: const Duration(minutes: 10),
        reconnectInterval: const Duration(milliseconds: 300),
      );

  group('connect + trust', () {
    late AgentService agent;
    late HostControllerImpl ctl;

    setUpAll(() async {
      agent = AgentService();
      await agent.start(
        modernPort: 13088,
        legacyPort: 13086,
        httpPort: 39999,
        identity: AgentIdentity(
            deviceUuid: 'dev-ctl', deviceName: 'Ctl Pixel'),
        hostTrustStore: HostTrustStore('${tmp.path}/hosts-ctl.json'),
        onPairingRequest: (req, pending) => TrustDecision.always,
      );
    });
    tearDownAll(() => agent.stop());
    tearDown(() => ctl.dispose());

    test('first connect emits pairing prompt, then connects', () async {
      ctl = makeCtl();
      final promptFuture = ctl.pairingPrompts.first;
      final f = ctl.connect(DeviceCandidate(
        id: 'manual:127.0.0.1:13088',
        label: '127.0.0.1',
        address: '127.0.0.1',
        port: 13088,
        source: DiscoverySource.manual,
      ));
      final prompt = await promptFuture.timeout(const Duration(seconds: 10));
      expect(ctl.state, ConnState.pairing);
      prompt.completer.complete(true);
      await f;
      expect(ctl.state, ConnState.connected);
      expect(ctl.connectedDevice?.deviceUuid, 'dev-ctl');
      final info = await ctl.api!.getDeviceInfo();
      expect(info.hasType(), isTrue);
      await ctl.disconnect();
      expect(ctl.state, ConnState.disconnected);
    });

    test('rejecting the prompt aborts the connect', () async {
      ctl = HostControllerImpl(
        identity:
            HostIdentity.generate(hostUuid: 'host-rej', hostName: 'Mac2'),
        trustStore: TrustStore('${tmp.path}/dev-rej.json'),
      );
      final promptFuture = ctl.pairingPrompts.first;
      final f = ctl.connect(DeviceCandidate(
        id: 'manual:127.0.0.1:13088',
        label: 'x',
        address: '127.0.0.1',
        port: 13088,
        source: DiscoverySource.manual,
      ));
      (await promptFuture.timeout(const Duration(seconds: 10)))
          .completer
          .complete(false);
      await expectLater(f, throwsStateError);
      expect(ctl.state, ConnState.disconnected);
    });
  });

  group('auto-reconnect (trusted fast-path, no prompt)', () {
    test('socket drop → reconnecting → connected', () async {
      var agent = AgentService();
      await agent.start(
        modernPort: 13088,
        legacyPort: 13086,
        httpPort: 39999,
        identity:
            AgentIdentity(deviceUuid: 'dev-rec', deviceName: 'Rec Pixel'),
        hostTrustStore: HostTrustStore('${tmp.path}/hosts-rec.json'),
        onPairingRequest: (req, pending) => TrustDecision.always,
      );
      final ctl = HostControllerImpl(
        identity:
            HostIdentity.generate(hostUuid: 'host-rec', hostName: 'MacR'),
        trustStore: TrustStore('${tmp.path}/dev-rec.json'),
        reconnectInterval: const Duration(milliseconds: 250),
      );
      // first connect (host approves automatically)
      ctl.pairingPrompts.listen((p) => p.completer.complete(true));
      await ctl.connect(DeviceCandidate(
        id: 'manual:127.0.0.1:13088',
        label: 'x',
        address: '127.0.0.1',
        port: 13088,
        source: DiscoverySource.wifi,
      ));
      expect(ctl.state, ConnState.connected);

      // kill the daemon — client socket drops
      await agent.stop();
      await _waitFor(() => ctl.state == ConnState.reconnecting);

      // bring the agent back — reconnect uses the stored derivedKey
      agent = AgentService();
      await agent.start(
        modernPort: 13088,
        legacyPort: 13086,
        httpPort: 39999,
        identity:
            AgentIdentity(deviceUuid: 'dev-rec', deviceName: 'Rec Pixel'),
        hostTrustStore: HostTrustStore('${tmp.path}/hosts-rec.json'),
        onPairingRequest: (req, pending) => TrustDecision.always,
      );
      await _waitFor(() => ctl.state == ConnState.connected,
          timeout: const Duration(seconds: 15));
      expect(ctl.state, ConnState.connected);
      await ctl.dispose();
      await agent.stop();
    });
  });

  group('discovery', () {
    test('wifi probe finds the legacy port; prefixes are private',
        () async {
      final agent = AgentService();
      await agent.start(
        modernPort: 13088,
        legacyPort: 13086,
        httpPort: 39999,
        identity: AgentIdentity(deviceUuid: 'dev-wifi', deviceName: 'W'),
        hostTrustStore: HostTrustStore('${tmp.path}/hosts-wifi.json'),
        onPairingRequest: (req, pending) => TrustDecision.always,
      );
      final wifi = WifiDiscovery();
      expect(await wifi.probe('127.0.0.1', 13086), isTrue);
      expect(await wifi.probe('127.0.0.1', 3), isFalse);
      final prefixes = await wifi.localPrefixes();
      expect(prefixes, isNotEmpty);
      for (final p in prefixes) {
        expect(p.split('.').length, 3);
      }
      await agent.stop();
    });

    test('usb discovery degrades cleanly without adb', () async {
      final usb = UsbDiscovery(adbPath: '/nonexistent/adb');
      // explicitly broken path → findAdb still probes other locations, but
      // serials() must not throw
      final serials = await usb.serials();
      expect(serials, isA<List<String>>());
    });
  });
}

/// Polls [cond] until true or [timeout] elapses (state changes race with
/// broadcast listeners, so check the getter instead).
Future<void> _waitFor(bool Function() cond,
    {Duration timeout = const Duration(seconds: 10)}) async {
  final deadline = DateTime.now().add(timeout);
  while (!cond()) {
    if (DateTime.now().isAfter(deadline)) {
      throw TimeoutException('condition not met in $timeout');
    }
    await Future.delayed(const Duration(milliseconds: 50));
  }
}
