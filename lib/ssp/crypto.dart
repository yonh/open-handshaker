import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'dart:io' show File;

import 'package:pointycastle/export.dart';

import 'bytes.dart';

/// Fixed handshake key/IV recovered from the original binaries.
/// AES-256-CBC, space padding to a multiple of 32, no PKCS7.
final Uint8List kHandshakeKey = unhex(
    '28e3ee32b0de27ef6bc29792054ef9739ce8e87bb495f2ea0d72d4f4f40b3bde');
final Uint8List kHandshakeIv =
    unhex('2b9e34d4e1d9088994939ec4e3e960c5');

const int kSignatureLen = 128; // RSA-1024 signature size
const String kSha256RsaDigestId = '0609608648016503040201';

/// PKCS#1 RSAPublicKey DER encode: SEQUENCE { modulus INTEGER, exponent INTEGER }
Uint8List encodeRsaPublicKeyDer(RSAPublicKey key) {
  final n = _derInteger(key.modulus!);
  final e = _derInteger(key.exponent!);
  final body = concat([n, e]);
  return concat([
    Uint8List.fromList([0x30]),
    _derLength(body.length),
    body
  ]);
}

Uint8List _derInteger(BigInt v) {
  var b = _bigIntBytes(v);
  if (b.isEmpty) b = Uint8List.fromList([0]);
  if (b[0] & 0x80 != 0) {
    b = concat([Uint8List.fromList([0]), b]);
  }
  return concat([Uint8List.fromList([0x02]), _derLength(b.length), b]);
}

Uint8List _bigIntBytes(BigInt v) {
  if (v == BigInt.zero) return Uint8List(0);
  final hexStr = v.toRadixString(16);
  final padded = hexStr.length.isOdd ? '0$hexStr' : hexStr;
  var b = unhex(padded);
  var i = 0;
  while (i < b.length - 1 && b[i] == 0) {
    i++;
  }
  return b.sublist(i);
}

Uint8List _derLength(int len) {
  if (len < 0x80) return Uint8List.fromList([len]);
  final bytes = _bigIntBytes(BigInt.from(len));
  return concat([Uint8List.fromList([0x80 | bytes.length]), bytes]);
}

/// Parse a PKCS#1 RSAPublicKey DER blob.
RSAPublicKey decodeRsaPublicKeyDer(Uint8List der) {
  var offset = 0;
  int tag() => der[offset++];
  int len() {
    var l = der[offset++];
    if (l & 0x80 != 0) {
      final n = l & 0x7f;
      l = 0;
      for (var i = 0; i < n; i++) {
        l = (l << 8) | der[offset++];
      }
    }
    return l;
  }

  if (tag() != 0x30) throw const FormatException('expected SEQUENCE');
  len(); // sequence length
  if (tag() != 0x02) throw const FormatException('expected INTEGER modulus');
  final nLen = len();
  final modulus = _bytesToBigInt(der.sublist(offset, offset + nLen));
  offset += nLen;
  if (tag() != 0x02) throw const FormatException('expected INTEGER exponent');
  final eLen = len();
  final exponent = _bytesToBigInt(der.sublist(offset, offset + eLen));
  return RSAPublicKey(modulus, exponent);
}

BigInt _bytesToBigInt(Uint8List b) {
  var v = BigInt.zero;
  for (final byte in b) {
    v = (v << 8) | BigInt.from(byte);
  }
  return v;
}

/// Generate an RSA keypair ([bits] default 1024 for wire compatibility).
AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> generateRsaKeyPair(
    {int bits = 1024}) {
  final rnd = FortunaRandom();
  final seed = Uint8List(32);
  final r = Random.secure();
  for (var i = 0; i < seed.length; i++) {
    seed[i] = r.nextInt(256);
  }
  rnd.seed(KeyParameter(seed));
  final gen = RSAKeyGenerator()
    ..init(ParametersWithRandom(
        RSAKeyGeneratorParameters(BigInt.from(65537), bits, 64), rnd));
  return gen.generateKeyPair();
}

Uint8List sha256(Uint8List data) =>
    Uint8List.fromList(SHA256Digest().process(data));

Uint8List md5(Uint8List data) =>
    Uint8List.fromList(MD5Digest().process(data));

String md5Hex(Uint8List data) => hex(md5(data));

/// Streaming MD5 of a file range — reads in bounded chunks so large
/// transfers never buffer the whole file in memory.
Future<String> md5FileHex(File file, {int offset = 0, int? length}) async {
  final digest = MD5Digest();
  final raf = await file.open();
  try {
    await raf.setPosition(offset);
    var remaining = length ?? (await file.length()) - offset;
    while (remaining > 0) {
      final piece =
          await raf.read(remaining < 1 << 18 ? remaining : 1 << 18);
      if (piece.isEmpty) break;
      digest.update(Uint8List.fromList(piece), 0, piece.length);
      remaining -= piece.length;
    }
  } finally {
    await raf.close();
  }
  final out = Uint8List(digest.digestSize);
  digest.doFinal(out, 0);
  return hex(out);
}

/// SHA256withRSA (PKCS#1 v1.5) sign.
Uint8List rsaSign(RSAPrivateKey key, Uint8List data) {
  final signer = RSASigner(SHA256Digest(), kSha256RsaDigestId)
    ..init(true, PrivateKeyParameter<RSAPrivateKey>(key));
  return signer.generateSignature(data).bytes;
}

bool rsaVerify(RSAPublicKey key, Uint8List data, Uint8List signature) {
  final signer = RSASigner(SHA256Digest(), kSha256RsaDigestId)
    ..init(false, PublicKeyParameter<RSAPublicKey>(key));
  try {
    return signer.verifySignature(data, RSASignature(signature));
  } catch (_) {
    return false;
  }
}

/// RSA PKCS#1 v1.5 encrypt (small payloads e.g. "ok").
Uint8List rsaEncrypt(RSAPublicKey key, Uint8List data) {
  final c = PKCS1Encoding(RSAEngine())
    ..init(true, PublicKeyParameter<RSAPublicKey>(key));
  return c.process(data);
}

Uint8List rsaDecrypt(RSAPrivateKey key, Uint8List data) {
  final c = PKCS1Encoding(RSAEngine())
    ..init(false, PrivateKeyParameter<RSAPrivateKey>(key));
  return c.process(data);
}

/// AES-256-CBC without padding; [data] length must be a multiple of 16.
Uint8List aesCbcCrypt(Uint8List key, Uint8List iv, Uint8List data,
    {required bool encrypt}) {
  if (data.length % 16 != 0) {
    throw ArgumentError('AES-CBC input must be block-aligned');
  }
  final cbc = CBCBlockCipher(AESEngine())
    ..init(encrypt, ParametersWithIV(KeyParameter(key), iv));
  final out = Uint8List(data.length);
  for (var off = 0; off < data.length; off += 16) {
    cbc.processBlock(data, off, out, off);
  }
  return out;
}

/// Handshake key wrap: Base64(DER) without newlines, space-padded to a
/// multiple of 32, AES-256-CBC encrypted. Returns (encKey, md5(DER)).
({Uint8List encKey, Uint8List keyMd5, Uint8List der}) wrapPublicKey(
    RSAPublicKey key) {
  final der = encodeRsaPublicKeyDer(key);
  var b64 = base64.encode(der).replaceAll('\n', '');
  while (b64.length % 32 != 0) {
    b64 += ' ';
  }
  final encKey =
      aesCbcCrypt(kHandshakeKey, kHandshakeIv, utf8Bytes(b64), encrypt: true);
  return (encKey: encKey, keyMd5: md5(der), der: der);
}

/// Reverse of [wrapPublicKey]. Throws FormatException on malformed input.
({RSAPublicKey key, Uint8List der}) unwrapPublicKey(
    Uint8List encKey, Uint8List expectedMd5) {
  final padded = aesCbcCrypt(kHandshakeKey, kHandshakeIv, encKey, encrypt: false);
  final b64 = utf8.decode(padded).trimRight();
  final der = Uint8List.fromList(base64.decode(b64));
  if (!const ListEq().equals(md5(der), expectedMd5)) {
    throw const FormatException('handshake key md5 mismatch');
  }
  return (key: decodeRsaPublicKeyDer(der), der: der);
}

class ListEq {
  const ListEq();
  bool equals(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
