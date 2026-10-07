import 'dart:async';
import 'dart:io';

import '../host_controller.dart';

/// USB discovery via adb: enumerates attached devices, sets up
/// `adb forward` for both SSP ports and reports the agent as a candidate at
/// 127.0.0.1. Best-effort: adb absence or failures yield an empty list.
class UsbDiscovery {
  UsbDiscovery({this.adbPath, this.legacyPort = 10086, this.modernPort = 10088});

  /// Explicit adb binary path; when null the usual locations are probed.
  final String? adbPath;
  final int legacyPort;
  final int modernPort;

  static const _candidatePaths = [
    'adb',
    '/usr/local/bin/adb',
    '/opt/homebrew/bin/adb',
    '~/Library/Android/sdk/platform-tools/adb',
    '~/Android/Sdk/platform-tools/adb',
  ];

  String? _resolved;

  /// Resolves an adb executable path or null when adb is unavailable.
  Future<String?> findAdb() async {
    if (_resolved != null) return _resolved;
    for (final c in _candidatePaths) {
      final path =
          c.startsWith('~') ? c.replaceFirst('~', Platform.environment['HOME'] ?? '') : c;
      if (c.contains('/')) {
        if (File(path).existsSync()) {
          _resolved = path;
          return path;
        }
      } else {
        try {
          final r = await Process.run('which', [c]);
          if (r.exitCode == 0 && (r.stdout as String).trim().isNotEmpty) {
            _resolved = (r.stdout as String).trim().split('\n').first;
            return _resolved;
          }
        } catch (_) {}
      }
    }
    return null;
  }

  Future<ProcessResult> _run(String adb, List<String> args) =>
      Process.run(adb, args).timeout(const Duration(seconds: 8));

  /// `adb devices` serials (state == device).
  Future<List<String>> serials() async {
    final adb = await findAdb();
    if (adb == null) return const [];
    try {
      final r = await _run(adb, ['devices']);
      final out = r.stdout as String;
      return out
          .split('\n')
          .skip(1)
          .map((l) => l.trim())
          .where((l) => l.endsWith('\tdevice'))
          .map((l) => l.split('\t').first)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// forward tcp:port -> device tcp:port for the given serial.
  Future<bool> forward(String adb, String serial, int local, int remote) async {
    try {
      final r = await _run(
          adb, ['-s', serial, 'forward', 'tcp:$local', 'tcp:$remote']);
      return r.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// One probe pass: for each adb device, forward both ports and report a
  /// candidate at 127.0.0.1:[modernPort].
  Future<List<DeviceCandidate>> scan() async {
    final adb = await findAdb();
    if (adb == null) return const [];
    final out = <DeviceCandidate>[];
    for (final serial in await serials()) {
      await forward(adb, serial, legacyPort, legacyPort);
      if (await forward(adb, serial, modernPort, modernPort)) {
        out.add(DeviceCandidate(
          id: 'usb:$serial',
          label: 'USB ($serial)',
          address: '127.0.0.1',
          port: modernPort,
          source: DiscoverySource.usb,
        ));
      }
    }
    return out;
  }

  /// Launches the agent app on the device (best effort). [package] is the
  /// agent's application id, [activity] its main activity.
  Future<bool> launchAgent(String serial,
      {String package = 'com.openhandshaker.agent',
      String activity = '.MainActivity'}) async {
    final adb = await findAdb();
    if (adb == null) return false;
    try {
      final r = await _run(adb, [
        '-s',
        serial,
        'shell',
        'am',
        'start',
        '-n',
        '$package/$activity'
      ]);
      return r.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// Installs the agent APK via `adb install -r`. Best effort.
  Future<bool> installAgent(String serial, String apkPath) async {
    final adb = await findAdb();
    if (adb == null) return false;
    try {
      final r = await Process.run(adb, ['-s', serial, 'install', '-r', apkPath])
          .timeout(const Duration(minutes: 2));
      return r.exitCode == 0;
    } catch (_) {
      return false;
    }
  }
}
