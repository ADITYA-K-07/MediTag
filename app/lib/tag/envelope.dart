// Decodes and verifies the application/vnd.meditag.v1 record. Format: schema/README.md.
// Must stay byte-compatible with functions/src/core/envelope.ts; schema/test-vectors.json checks both.
import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

import 'payload.dart';

const _headerLength = 3;
const _signatureLength = 64;

class EnvelopeException implements Exception {
  EnvelopeException(this.message);
  final String message;
  @override
  String toString() => 'EnvelopeException: $message';
}

class Envelope {
  Envelope(this.json, this.keyId, this.signature);
  final Uint8List json;
  final int keyId;
  final Uint8List signature;
}

Envelope decodeEnvelope(Uint8List bytes) {
  if (bytes.length < _headerLength + 1 + _signatureLength) throw EnvelopeException('envelope too short');
  if (bytes[0] != 1) throw EnvelopeException('unsupported envelope version ${bytes[0]}');
  final jsonLength = (bytes[1] << 8) | bytes[2];
  if (bytes.length != _headerLength + jsonLength + 1 + _signatureLength) throw EnvelopeException('length mismatch');
  return Envelope(
    Uint8List.sublistView(bytes, _headerLength, _headerLength + jsonLength),
    bytes[_headerLength + jsonLength],
    Uint8List.sublistView(bytes, _headerLength + jsonLength + 1),
  );
}

enum TagTrust { verified, unverified, server }

sealed class ReadResult {}

class ReadOk extends ReadResult {
  ReadOk(this.payload, this.trust);
  final TagPayload payload;
  final TagTrust trust;
}

class ReadUnreadable extends ReadResult {
  ReadUnreadable(this.error);
  final String error;
}

Uint8List hexToBytes(String hex) {
  final clean = hex.replaceAll(RegExp(r'[^0-9a-fA-F]'), '');
  return Uint8List.fromList([for (var i = 0; i < clean.length; i += 2) int.parse(clean.substring(i, i + 2), radix: 16)]);
}

BigInt _toBigInt(Uint8List bytes) => bytes.fold(BigInt.zero, (acc, b) => (acc << 8) | BigInt.from(b));

final _p256 = ECDomainParameters('secp256r1');

/// ECDSA P-256 / SHA-256 with a raw r‖s signature, as produced by the server.
bool verifySignature(Envelope env, Uint8List publicKey) {
  try {
    final point = _p256.curve.decodePoint(publicKey);
    final verifier = ECDSASigner(SHA256Digest())..init(false, PublicKeyParameter<ECPublicKey>(ECPublicKey(point, _p256)));
    final r = _toBigInt(Uint8List.sublistView(env.signature, 0, 32));
    final s = _toBigInt(Uint8List.sublistView(env.signature, 32));
    return verifier.verifySignature(env.json, ECSignature(r, s));
  } catch (_) {
    return false;
  }
}

/// Works fully offline. An unverified payload is still returned so a bystander can see it,
/// but the UI must show it with the "Unverified" warning.
ReadResult readEnvelope(Uint8List bytes, Map<int, Uint8List> publicKeys) {
  final Envelope env;
  try {
    env = decodeEnvelope(bytes);
  } on EnvelopeException catch (e) {
    return ReadUnreadable(e.message);
  }
  final TagPayload payload;
  try {
    payload = TagPayload.fromJson(jsonDecode(utf8.decode(env.json)) as Map<String, dynamic>);
  } catch (_) {
    return ReadUnreadable('payload is not valid MediTag data');
  }
  final key = publicKeys[env.keyId];
  final ok = key != null && verifySignature(env, key);
  return ReadOk(payload, ok ? TagTrust.verified : TagTrust.unverified);
}
