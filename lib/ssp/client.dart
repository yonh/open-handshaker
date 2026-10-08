import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:pointycastle/export.dart';
import 'package:protobuf/protobuf.dart' as $pb;

import 'crypto.dart';
import 'modern_transport.dart';
import 'pb/SmartSyncProtocol.recovered.pb.dart' as pb;
import 'pb/SmartSyncProtocol.recovered.pbenum.dart' as pbe;
import 'transport.dart';
import 'types.dart';
import 'trust_store.dart';

/// Host identity sent during Handshake01.
class HostIdentity {
  HostIdentity({
    required this.hostUuid,
    required this.hostName,
    required this.keyPair,
    this.appVersion = '1.0.0',
    this.minClientVersion = '1.0.197',
    this.model = 'Dart Host',
    this.heartbeatTimeoutSecond = 60,
  });

  final String hostUuid;
  final String hostName;
  final AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> keyPair;
  final String appVersion;
  final String minClientVersion;
  final String model;
  final int heartbeatTimeoutSecond;

  RSAPublicKey get publicKey => keyPair.publicKey;
  RSAPrivateKey get privateKey => keyPair.privateKey;

  /// Key pair persists in PEM-ish form — we store DER + regenerate private
  /// from modulus/exponents is awkward, so persist the pair serialized as a
  /// simple JSON blob of big integers.
  Map<String, dynamic> toJson() => {
        'hostUuid': hostUuid,
        'hostName': hostName,
        'appVersion': appVersion,
        'model': model,
        'heartbeatTimeoutSecond': heartbeatTimeoutSecond,
        'modulus': publicKey.modulus!.toString(),
        'publicExponent': publicKey.exponent!.toString(),
        'privateExponent': privateKey.exponent!.toString(),
        'p': privateKey.p!.toString(),
        'q': privateKey.q!.toString(),
      };

  factory HostIdentity.fromJson(Map<String, dynamic> j) {
    final n = BigInt.parse(j['modulus'] as String);
    final e = BigInt.parse(j['publicExponent'] as String);
    final d = BigInt.parse(j['privateExponent'] as String);
    final p = BigInt.parse(j['p'] as String);
    final q = BigInt.parse(j['q'] as String);
    return HostIdentity(
      hostUuid: j['hostUuid'] as String,
      hostName: j['hostName'] as String? ?? '',
      appVersion: j['appVersion'] as String? ?? '1.0.0',
      model: j['model'] as String? ?? 'Dart Host',
      heartbeatTimeoutSecond:
          j['heartbeatTimeoutSecond'] as int? ?? 60,
      keyPair: AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>(
        RSAPublicKey(n, e),
        RSAPrivateKey(n, d, p, q),
      ),
    );
  }

  static HostIdentity generate(
      {required String hostUuid, required String hostName}) {
    return HostIdentity(
        hostUuid: hostUuid,
        hostName: hostName,
        keyPair: generateRsaKeyPair());
  }
}

/// Result of a completed two-stage modern handshake.
class SspHandshakeResult {
  SspHandshakeResult({
    required this.response01,
    required this.response02,
    required this.trustType,
  });
  final pb.SSPHandShakeResponse01 response01;
  final pb.SSPHandShakeResponse02 response02;
  final pbe.SSPHandShakeTrustType trustType;
}

class SspPush {
  SspPush(this.sessionId, this.payload);
  final int sessionId;
  final Uint8List payload;
}

/// Ordered queue of logical payloads for one session.
class _SessionQueue {
  final _items = <Uint8List>[];
  Completer<Uint8List>? _waiter;
  bool closed = false;

  void push(Uint8List payload) {
    if (_waiter != null) {
      final w = _waiter!;
      _waiter = null;
      w.complete(payload);
    } else {
      _items.add(payload);
    }
  }

  Future<Uint8List> next({Duration? timeout}) {
    if (_items.isNotEmpty) {
      return Future.value(_items.removeAt(0));
    }
    if (closed) {
      return Future.error(StateError('session closed'));
    }
    final w = Completer<Uint8List>();
    _waiter = w;
    if (timeout == null) return w.future;
    return w.future.timeout(timeout).whenComplete(() {
      if (identical(_waiter, w)) _waiter = null;
    });
  }

  void close() {
    closed = true;
    _waiter?.completeError(StateError('session closed'));
    _waiter = null;
  }
}

/// Thrown by download/upload when the caller's `cancelled` probe fires.
class TransferCancelled implements Exception {
  const TransferCancelled();
  @override
  String toString() => 'transfer cancelled';
}

/// Modern SSP v2 host client over a [ByteChannel].
class SspClient {
  /// Deterministic temp path for a download's partial body. The original
  /// `.hsdownload`-beside-target convention breaks under the macOS sandbox
  /// (the save-panel grant covers the selected path only, not a sibling
  /// temp file), so partials live in system temp instead.
  static String downloadTmpPath(String localPath,
          [String remotePath = '']) =>
      '${Directory.systemTemp.path}/handshaker_dl_'
      '${md5Hex(utf8.encode('$remotePath\u2192$localPath')).substring(0, 16)}'
      '.part';

  SspClient(this.channel, {required this.identity, this.trustStore});

  final ByteChannel channel;
  final HostIdentity identity;
  final TrustStore? trustStore;

  final _chunkReader = ModernChunkReader();
  final _demux = SessionDemux();
  final _pushDemux = SessionDemux();
  final _sessions = <int, _SessionQueue>{};
  final _pushCtl = StreamController<SspPush>.broadcast();
  final _fileBodyCtl = <int, StreamController<Uint8List>>{};

  int _nextSessionId = 3;
  bool _started = false;
  bool _ready = false;
  StreamSubscription<Uint8List>? _sub;

  pb.SSPHandShakeResponse01? deviceInfo01;
  TrustedDevice? trustedDevice;

  /// Called once when the channel goes down (peer close or error).
  void Function()? onDisconnected;

  bool get isReady => _ready;
  Stream<SspPush> get pushes => _pushCtl.stream;

  /// Start consuming the channel. Must be called before handshake.
  void start() {
    if (_started) return;
    _started = true;
    _sub = channel.incoming.listen(_onData, onDone: _onDone, onError: _onDone);
  }

  void _onData(Uint8List bytes) {
    for (final chunk in _chunkReader.add(bytes)) {
      if (_fileBodySessions.contains(chunk.sessionId) && !chunk.isPush) {
        _fileBodyCtl[chunk.sessionId]?.add(chunk.data);
        continue;
      }
      if (chunk.isPush) {
        try {
          for (final m in _pushDemux.addChunk(chunk)) {
            _pushCtl.add(SspPush(m.sessionId, m.payload));
          }
        } catch (_) {
          _pushDemux.dropSession(chunk.sessionId);
        }
        continue;
      }
      try {
        for (final m in _demux.addChunk(chunk)) {
          _queueFor(m.sessionId).push(m.payload);
        }
      } catch (_) {
        // A stray chunk on a drained session (cancelled transfer leftovers)
        // can desync the logical reader — drop the session's buffered state
        // and resync rather than killing the connection.
        _demux.dropSession(chunk.sessionId);
      }
    }
  }

  final _fileBodySessions = <int>{};

  _SessionQueue _queueFor(int sid) =>
      _sessions.putIfAbsent(sid, _SessionQueue.new);

  void _onDone([Object? _]) {
    _ready = false;
    for (final q in _sessions.values) {
      q.close();
    }
    for (final c in _fileBodyCtl.values) {
      c.close();
    }
    onDisconnected?.call();
  }

  int _allocSession() => _nextSessionId++;

  void _send(Uint8List frame) => channel.send(frame);

  Uint8List _sign(Uint8List data) => rsaSign(identity.privateKey, data);

  // ---------------- handshake ----------------

  /// Run Handshake01+02. [approveUnknownDevice] fires after stage 1 when the
  /// device has no trust record yet — return false to abort the pairing.
  /// [onTrustWaiting] fires each time the device answers TrustWaiting while
  /// its own user decides.
  /// Throws [StateError] on TrustNo or a failed `result` proof.
  Future<SspHandshakeResult> handshake(
      {Duration stepTimeout = const Duration(seconds: 15),
      Future<bool> Function(pb.SSPHandShakeResponse01 device)?
          approveUnknownDevice,
      void Function()? onTrustWaiting}) async {
    start();
    final wrap = wrapPublicKey(identity.publicKey);

    // ---- stage 1
    final req01 = pb.SSPHandShakeRequest01()
      ..type = Req.handshakeReq01
      ..hostUuid = identity.hostUuid
      ..hostName = identity.hostName
      ..hostTimestamp =
          Int64(DateTime.now().millisecondsSinceEpoch ~/ 1000)
      ..hostSmartSyncProtocolVersion = '2'
      ..hostAppVersion = identity.appVersion
      ..hostMinClientVersion = identity.minClientVersion
      ..md5 = wrap.keyMd5
      ..enckey = wrap.encKey
      ..hostModel = identity.model
      ..heartbeatTimeoutSecond = Int64(identity.heartbeatTimeoutSecond);
    _send(ModernTransport.unsignedPacket(1, req01.writeToBuffer()));
    final resp01Payload = await _queueFor(1).next(timeout: stepTimeout);
    final resp01 = pb.SSPHandShakeResponse01.fromBuffer(resp01Payload);
    deviceInfo01 = resp01;

    // ---- stage 2
    final store = trustStore;
    await store?.load();
    var record = store?.find(resp01.deviceUuid);
    if (record == null && approveUnknownDevice != null) {
      if (!await approveUnknownDevice(resp01)) {
        throw StateError('pairing rejected by host');
      }
    }
    final req02 = pb.SSPHandShakeRequest02()
      ..type = Req.handshakeReq02
      ..hostUuid = identity.hostUuid
      ..trustType = record?.trustType ?? Trust.unknow;
    final knownKey = record?.derivedKey;
    if (knownKey != null) {
      req02.derivedKey = knownKey;
    }
    _send(ModernTransport.unsignedPacket(2, req02.writeToBuffer()));

    record ??= TrustedDevice(deviceUuid: resp01.deviceUuid);
    record
      ..deviceName = resp01.deviceName
      ..apkVersion = int.tryParse(resp01.apkVersion) ?? 0
      ..apkVersionName = resp01.apkVersionName
      ..clientSmartSyncProtocolVersion = resp01.clientSmartSyncProtocolVersion
      ..clientMinHostVersion = resp01.clientMinHostVersion
      ..isSmartisanDevice = resp01.isSmartisanDevice
      ..lastConnection = DateTime.now()
      ..connectionCount = record.connectionCount + 1;
    // Do NOT persist the record yet — a stored row would skip
    // approveUnknownDevice and (with a forged trustType) bypass pairing
    // on the next connect. The record is only saved after the device
    // grants trust AND proves it with the signed result.

    // Loop: TrustWaiting -> keep reading on session 2.
    while (true) {
      final payload = await _queueFor(2).next(
          timeout: const Duration(seconds: 120));
      final resp02 = pb.SSPHandShakeResponse02.fromBuffer(payload);
      switch (resp02.trustType) {
        case Trust.waiting:
          onTrustWaiting?.call();
          continue;
        case Trust.no:
          record.trustType = Trust.no;
          await store?.save();
          throw StateError('device ${resp02.deviceUuid} refused pairing');
        case Trust.once:
        case Trust.always:
          if (!_verifyResultProof(resp02.result)) {
            throw StateError('handshake result proof failed');
          }
          record
            ..trustType = resp02.trustType
            ..derivedKey =
                resp02.derivedKey.isEmpty ? null : Uint8List.fromList(resp02.derivedKey);
          store?.add(record);
          await store?.save();
          _ready = true;
          trustedDevice = record;
          return SspHandshakeResult(
              response01: resp01,
              response02: resp02,
              trustType: resp02.trustType);
        default:
          throw StateError(
              'unexpected trustType ${resp02.trustType.value}');
      }
    }
  }

  /// Verify `result` = Base64(RSA_public_encrypt("ok")) with our private key.
  bool _verifyResultProof(String result) {
    final trimmed = result.trim();
    if (trimmed.isEmpty || trimmed.startsWith('failed')) return false;
    try {
      final cipher = Uint8List.fromList(base64.decode(trimmed));
      if (cipher.isEmpty ||
          cipher.length % (identity.publicKey.modulus!.bitLength / 8) != 0) {
        return false;
      }
      final blockSize = identity.publicKey.modulus!.bitLength ~/ 8;
      final buf = BytesBuilder();
      for (var off = 0; off < cipher.length; off += blockSize) {
        buf.add(rsaDecrypt(
            identity.privateKey, Uint8List.fromList(cipher.sublist(off, off + blockSize))));
      }
      return utf8.decode(buf.takeBytes()) == 'ok';
    } catch (_) {
      return false;
    }
  }

  // ---------------- requests ----------------

  /// Send a signed protobuf request and return the first response payload.
  Future<Uint8List> request($pb.GeneratedMessage message,
      {Duration? timeout, int? sessionId}) async {
    if (!_ready) throw StateError('handshake not complete');
    final sid = sessionId ?? _allocSession();
    final proto = message.writeToBuffer();
    _send(ModernTransport.signedPacket(sid, proto, _sign));
    try {
      return await _queueFor(sid)
          .next(timeout: timeout ?? const Duration(seconds: 30));
    } finally {
      // Reply consumed — free the sid bookkeeping so the maps don't grow
      // forever on a long-lived connection.
      _sessions.remove(sid);
      _demux.dropSession(sid);
    }
  }

  /// Typed request: send [requestMsg], decode the response with [parse].
  Future<T> call<T>($pb.GeneratedMessage requestMsg,
      T Function(Uint8List) parse,
      {Duration? timeout}) async {
    final payload = await request(requestMsg, timeout: timeout);
    return parse(payload);
  }

  // ---------------- file transfer ----------------

  /// Download remote [path] into [localPath] via the .hsdownload convention.
  /// [range] offset/length 0 = whole file. Reports received byte count via
  /// [onProgress].
  ///
  /// The session switches to raw-byte mode BEFORE the request is sent so body
  /// bytes that share a physical chunk with the header are never mis-parsed.
  Future<pb.SSPDownloadFileResponseHeader> download(String remotePath,
      String localPath,
      {int offset = 0,
      int length = 0,
      bool needMd5 = false,
      void Function(int received, int total)? onProgress,
      bool Function()? cancelled}) async {
    final sid = _allocSession();
    _fileBodySessions.add(sid);
    final bodyCtl = StreamController<Uint8List>();
    _fileBodyCtl[sid] = bodyCtl;

    final req = pb.SSPDownloadFileRequest()
      ..type = Req.downloadFile
      ..file = (pb.SSPFile()..path = remotePath)
      ..range = (pb.SSPDataRange()
        ..offset = Int64(offset)
        ..length = Int64(length))
      ..needMd5 = needMd5
      ..isSync = false;
    _send(ModernTransport.signedPacket(sid, req.writeToBuffer(), _sign));

    // Accumulate the whole session stream: first a logical message
    // (u64be len + ResponseHeader proto), then raw file bytes.
    final pending = BytesBuilder(copy: false);
    pb.SSPDownloadFileResponseHeader? header;
    var expected = -1;
    RandomAccessFile? raf;
    var received = 0;
    final tmpPath = downloadTmpPath(localPath, remotePath);

    Future<void> handleBytes(Uint8List b, {bool skipWrite = false}) async {
      pending.add(b);
      var data = pending.toBytes();
      if (header == null) {
        if (data.length < 8) return;
        final n = ByteData.sublistView(data).getUint64(0);
        if (data.length < 8 + n) return;
        header = pb.SSPDownloadFileResponseHeader.fromBuffer(
            Uint8List.fromList(data.sublist(8, 8 + n)));
        // remainder after the header is already file body
        data = Uint8List.fromList(data.sublist(8 + n));
        pending
          ..clear()
          ..add(data);
        if (!header!.ready) {
          throw StateError(
              'download refused: errorCode=${header!.errorCode.value}');
        }
        expected = header!.range.length.toInt();
        final f = File(tmpPath);
        await f.parent.create(recursive: true);
        // Resume appends to the partial .hsdownload when offset > 0.
        raf = await f.open(
            mode: offset > 0 ? FileMode.append : FileMode.write);
      }
      // flush pending body bytes
      final body = pending.toBytes();
      final need = expected - received;
      if (need > 0 && body.isNotEmpty) {
        final slice = body.length > need ? body.sublist(0, need) : body;
        if (!skipWrite) {
          await raf!.writeFrom(slice);
          onProgress?.call(received + slice.length, expected);
        }
        received += slice.length;
      }
      pending.clear();
    }

    // On cancel we keep reading the body off the wire (the agent has
    // already queued it — the only sane abort) and count bytes without
    // writing them, then throw TransferCancelled once drained.
    var aborted = false;
    try {
      await for (final chunk in bodyCtl.stream) {
        if (!aborted && cancelled?.call() == true) aborted = true;
        await handleBytes(chunk, skipWrite: aborted);
        if (header != null && received >= expected) break;
      }
    } finally {
      await raf?.close();
      _fileBodySessions.remove(sid);
      await _fileBodyCtl.remove(sid)?.close();
    }

    if (header == null) {
      throw StateError('connection closed before download header');
    }
    if (aborted) throw const TransferCancelled();
    if (received < expected) {
      await File(tmpPath).delete().catchError((_) => File(tmpPath));
      throw StateError(
          'download truncated: got $received of $expected bytes');
    }
    if (needMd5 && header!.dataMd5.isNotEmpty) {
      final digest = await md5FileHex(File(tmpPath));
      if (digest.toLowerCase() != header!.dataMd5.toLowerCase()) {
        await File(tmpPath).delete();
        throw StateError('download md5 mismatch');
      }
    }
    final target = File(localPath);
    if (target.existsSync()) await target.delete();
    try {
      await File(tmpPath).rename(localPath);
    } on FileSystemException {
      // EXDEV: temp and target on different volumes — copy then delete.
      await File(tmpPath).copy(localPath);
      await File(tmpPath).delete();
    }
    return header!;
  }

  /// Upload [localPath] to [remotePath]. Sends SSPUploadFileRequest (flag1),
  /// waits for SSPUploadFileResponseHeader.ready, streams flag3 chunks,
  /// then awaits the final SSPUploadFileResponse ack (our agent sends one).
  Future<pb.SSPUploadFileResponse> upload(String localPath, String remotePath,
      {void Function(int sent, int total)? onProgress,
      bool Function()? cancelled}) async {
    final file = File(localPath);
    final total = await file.length();
    final sid = _allocSession();
    final checksum = await md5FileHex(file);
    final stat = await file.stat();
    final req = pb.SSPUploadFileRequest()
      ..type = Req.uploadFileReqHeader
      ..file = (pb.SSPFile()
        ..path = remotePath
        ..fileSize = Int64(total)
        ..isDirectory = false
        ..checksum = checksum
        ..modifiedTimestamp =
            Int64(stat.modified.millisecondsSinceEpoch ~/ 1000)
        ..createdTimestamp =
            Int64(stat.changed.millisecondsSinceEpoch ~/ 1000))
      ..dataMd5 = ''
      ..isSync = false;
    _send(ModernTransport.signedPacket(sid, req.writeToBuffer(), _sign));

    final headerPayload =
        await _queueFor(sid).next(timeout: const Duration(seconds: 30));
    final header = pb.SSPUploadFileResponseHeader.fromBuffer(headerPayload);
    if (!header.ready) {
      throw StateError('upload refused: errorCode=${header.errorCode.value}');
    }

    final raf = await file.open();
    try {
      var sent = 0;
      while (sent < total) {
        if (cancelled?.call() == true) {
          // Tell the agent to discard the partial upload (type 36 cancel).
          try {
            _send(ModernTransport.signedPacket(
                _allocSession(),
                (pb.SSPCancelRequest()
                      ..type = Req.cancel
                      ..sessionId = Int64(sid))
                    .writeToBuffer(),
                _sign));
          } catch (_) {}
          throw const TransferCancelled();
        }
        final n =
            (total - sent) < ModernTransport.maxFileChunk ? (total - sent) : ModernTransport.maxFileChunk;
        final chunk = await raf.read(n);
        if (chunk.isEmpty) {
          throw StateError('local file truncated during upload');
        }
        _send(ModernTransport.filePacket(sid, chunk));
        sent += chunk.length;
        onProgress?.call(sent, total);
      }
    } finally {
      await raf.close();
    }

    // Final ack — agent sends SSPUploadFileResponse as a second logical
    // message on this session.
    final ackPayload =
        await _queueFor(sid).next(timeout: const Duration(seconds: 60));
    final ack = pb.SSPUploadFileResponse.fromBuffer(ackPayload);
    if (!ack.succeed) {
      throw StateError('upload failed: errorCode=${ack.errorCode.value}');
    }
    return ack;
  }

  Future<void> close() async {
    await _sub?.cancel();
    _onDone();
    await channel.close();
  }
}
