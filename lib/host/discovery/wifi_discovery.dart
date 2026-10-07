import 'dart:async';
import 'dart:io';

import '../host_controller.dart';

/// LAN discovery: scans each local private /24 for agents listening on
/// [probePort] (the legacy :10086 port the original app scans). Found hosts
/// are reported as candidates for the modern service on [servicePort]
/// (:10088) on the same address.
class WifiDiscovery {
  WifiDiscovery({
    this.probePort = 10086,
    this.servicePort = 10088,
    this.connectTimeout = const Duration(milliseconds: 350),
    this.batchSize = 96,
  });

  final int probePort;
  final int servicePort;
  final Duration connectTimeout;

  /// How many connection attempts run concurrently per subnet.
  final int batchSize;

  /// Local private IPv4 /24 prefixes to scan, e.g. ['192.168.1'].
  Future<List<String>> localPrefixes() async {
    final prefixes = <String>{};
    final ifaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4, includeLinkLocal: false);
    for (final iface in ifaces) {
      for (final addr in iface.addresses) {
        final a = addr.address;
        if (a.startsWith('127.') || a.startsWith('169.254.')) continue;
        if (!_isPrivate(a)) continue;
        prefixes.add(a.split('.').take(3).join('.'));
      }
    }
    return prefixes.toList();
  }

  static bool _isPrivate(String a) {
    final p = a.split('.').map(int.tryParse).toList();
    if (p.length != 4 || p.contains(null)) return false;
    if (p[0] == 10) return true;
    if (p[0] == 172 && p[1]! >= 16 && p[1]! <= 31) return true;
    if (p[0] == 192 && p[1] == 168) return true;
    return false;
  }

  Future<bool> probe(String host, int port) async {
    try {
      final s = await Socket.connect(host, port, timeout: connectTimeout);
      await s.close();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// One full scan of every local subnet. Returns live candidates.
  Future<List<DeviceCandidate>> scan() async {
    final prefixes = await localPrefixes();
    final found = <DeviceCandidate>[];
    for (final prefix in prefixes) {
      for (var start = 1; start <= 254; start += batchSize) {
        final batch = <Future<void>>[];
        for (var i = start; i < start + batchSize && i <= 254; i++) {
          final host = '$prefix.$i';
          batch.add(probe(host, probePort).then((up) {
            if (up) {
              found.add(DeviceCandidate(
                id: '$host:$servicePort',
                label: host,
                address: host,
                port: servicePort,
                source: DiscoverySource.wifi,
              ));
            }
          }));
        }
        await Future.wait(batch);
      }
    }
    return found;
  }
}
