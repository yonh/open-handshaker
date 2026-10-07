import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'pb/SmartSyncProtocol.recovered.pbenum.dart' as pbe;
import 'types.dart';

/// Host-side trusted-device record (mirrors SFDeviceTrustStore fields).
class TrustedDevice {
  TrustedDevice({
    required this.deviceUuid,
    this.deviceName = '',
    this.trustType = Trust.unknow,
    this.derivedKey,
    this.apkVersion = 0,
    this.apkVersionName = '',
    this.clientSmartSyncProtocolVersion = '',
    this.clientMinHostVersion = '',
    this.isSmartisanDevice = false,
    DateTime? lastConnection,
    this.connectionCount = 0,
  }) : lastConnection = lastConnection ?? DateTime.now();

  final String deviceUuid;
  String deviceName;
  pbe.SSPHandShakeTrustType trustType;
  Uint8List? derivedKey;
  int apkVersion;
  String apkVersionName;
  String clientSmartSyncProtocolVersion;
  String clientMinHostVersion;
  bool isSmartisanDevice;
  DateTime lastConnection;
  int connectionCount;

  Map<String, dynamic> toJson() => {
        'deviceUuid': deviceUuid,
        'deviceName': deviceName,
        'trustType': trustType.value,
        'derivedKey': derivedKey == null ? null : base64.encode(derivedKey!),
        'apkVersion': apkVersion,
        'apkVersionName': apkVersionName,
        'clientSmartSyncProtocolVersion': clientSmartSyncProtocolVersion,
        'clientMinHostVersion': clientMinHostVersion,
        'isSmartisanDevice': isSmartisanDevice,
        'lastConnection': lastConnection.toIso8601String(),
        'connectionCount': connectionCount,
      };

  factory TrustedDevice.fromJson(Map<String, dynamic> j) => TrustedDevice(
        deviceUuid: j['deviceUuid'] as String? ?? '',
        deviceName: j['deviceName'] as String? ?? '',
        trustType: pbe.SSPHandShakeTrustType.valueOf(
                j['trustType'] as int? ?? 2) ??
            Trust.unknow,
        derivedKey: j['derivedKey'] == null
            ? null
            : Uint8List.fromList(base64.decode(j['derivedKey'] as String)),
        apkVersion: j['apkVersion'] as int? ?? 0,
        apkVersionName: j['apkVersionName'] as String? ?? '',
        clientSmartSyncProtocolVersion:
            j['clientSmartSyncProtocolVersion'] as String? ?? '',
        clientMinHostVersion: j['clientMinHostVersion'] as String? ?? '',
        isSmartisanDevice: j['isSmartisanDevice'] as bool? ?? false,
        lastConnection: DateTime.tryParse(j['lastConnection'] as String? ?? ''),
        connectionCount: j['connectionCount'] as int? ?? 0,
      );
}

/// Simple JSON-file-backed host trust store. Pure dart:io; the app passes an
/// application-support path.
class TrustStore {
  TrustStore(this.filePath);

  final String filePath;
  final Map<String, TrustedDevice> _devices = {};

  List<TrustedDevice> get devices => List.unmodifiable(_devices.values);

  TrustedDevice? find(String deviceUuid) => _devices[deviceUuid];

  void add(TrustedDevice d) {
    _devices[d.deviceUuid] = d;
  }

  void remove(String deviceUuid) {
    _devices.remove(deviceUuid);
  }

  Future<void> load() async {
    final f = File(filePath);
    if (!f.existsSync()) return;
    final j = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
    _devices.clear();
    for (final e in (j['devices'] as List? ?? [])) {
      final d = TrustedDevice.fromJson(e as Map<String, dynamic>);
      _devices[d.deviceUuid] = d;
    }
  }

  Future<void> save() async {
    final f = File(filePath);
    await f.parent.create(recursive: true);
    await f.writeAsString(jsonEncode({
      'version': 1,
      'devices': [for (final d in _devices.values) d.toJson()],
    }));
  }
}

/// Agent-side approved-host record keyed by hostUuid.
class TrustedHost {
  TrustedHost({
    required this.hostUuid,
    this.hostName = '',
    this.trustType = Trust.unknow,
    this.hostKeyDer,
    this.derivedKey,
    DateTime? approvedAt,
  }) : approvedAt = approvedAt ?? DateTime.now();

  final String hostUuid;
  String hostName;
  pbe.SSPHandShakeTrustType trustType;
  Uint8List? hostKeyDer;
  Uint8List? derivedKey;
  DateTime approvedAt;

  Map<String, dynamic> toJson() => {
        'hostUuid': hostUuid,
        'hostName': hostName,
        'trustType': trustType.value,
        'hostKeyDer':
            hostKeyDer == null ? null : base64.encode(hostKeyDer!),
        'derivedKey':
            derivedKey == null ? null : base64.encode(derivedKey!),
        'approvedAt': approvedAt.toIso8601String(),
      };

  factory TrustedHost.fromJson(Map<String, dynamic> j) => TrustedHost(
        hostUuid: j['hostUuid'] as String? ?? '',
        hostName: j['hostName'] as String? ?? '',
        trustType: pbe.SSPHandShakeTrustType.valueOf(
                j['trustType'] as int? ?? 2) ??
            Trust.unknow,
        hostKeyDer: j['hostKeyDer'] == null
            ? null
            : Uint8List.fromList(base64.decode(j['hostKeyDer'] as String)),
        derivedKey: j['derivedKey'] == null
            ? null
            : Uint8List.fromList(base64.decode(j['derivedKey'] as String)),
        approvedAt: DateTime.tryParse(j['approvedAt'] as String? ?? ''),
      );
}

class HostTrustStore {
  HostTrustStore(this.filePath);

  final String filePath;
  final Map<String, TrustedHost> _hosts = {};

  List<TrustedHost> get hosts => List.unmodifiable(_hosts.values);

  TrustedHost? find(String hostUuid) => _hosts[hostUuid];

  void add(TrustedHost h) => _hosts[h.hostUuid] = h;

  void remove(String hostUuid) => _hosts.remove(hostUuid);

  Future<void> load() async {
    final f = File(filePath);
    if (!f.existsSync()) return;
    final j = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
    _hosts.clear();
    for (final e in (j['hosts'] as List? ?? [])) {
      final h = TrustedHost.fromJson(e as Map<String, dynamic>);
      _hosts[h.hostUuid] = h;
    }
  }

  Future<void> save() async {
    final f = File(filePath);
    await f.parent.create(recursive: true);
    await f.writeAsString(jsonEncode({
      'version': 1,
      'hosts': [for (final h in _hosts.values) h.toJson()],
    }));
  }
}
