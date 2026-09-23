import 'dart:typed_data';

import 'package:pointycastle/export.dart';

import 'protocol.dart';

class VerificationResult {
  const VerificationResult._({this.payload, this.error});
  const VerificationResult.verified(Tier1Payload payload)
    : this._(payload: payload);
  const VerificationResult.invalid(String error) : this._(error: error);
  final Tier1Payload? payload;
  final String? error;
  bool get isVerified => payload != null;
}

/// Pure-Dart P-256 verifier. It accepts the NFC wire format: 32-byte r || 32-byte s.
/// This avoids Android's DER ECDSA convention and keeps verification identical on iOS
/// and Android while the tag stays at a fixed 79-byte payload.
class TagVerifier {
  TagVerifier(this._publicKey);
  final ECPublicKey _publicKey;

  /// Input is the 65-byte SEC1/X9.62 public key from GET /public-key.
  static ECPublicKey publicKeyFromUncompressed(Uint8List point) {
    if (point.length != 65 || point.first != 4) {
      throw const FormatException(
        'Expected a 65-byte uncompressed P-256 public key.',
      );
    }
    final parameters = ECDomainParameters('prime256v1');
    final q = parameters.curve.decodePoint(point);
    if (q == null) throw const FormatException('Invalid P-256 public key.');
    return ECPublicKey(q, parameters);
  }

  Future<VerificationResult> verify(Uint8List tagBytes) async {
    if (tagBytes.length != tier1TagPayloadLength) {
      return VerificationResult.invalid(
        'Unexpected NFC payload size (${tagBytes.length} bytes).',
      );
    }
    try {
      final unsigned = Uint8List.sublistView(
        tagBytes,
        0,
        unsignedPayloadLength,
      );
      final signatureBytes = Uint8List.sublistView(
        tagBytes,
        unsignedPayloadLength,
      );
      final signature = ECSignature(
        _unsignedBigInt(signatureBytes.sublist(0, 32)),
        _unsignedBigInt(signatureBytes.sublist(32, 64)),
      );
      final verifier = ECDSASigner(SHA256Digest())
        ..init(false, PublicKeyParameter<ECPublicKey>(_publicKey));
      if (!verifier.verifySignature(unsigned, signature)) {
        return const VerificationResult.invalid(
          'Signature check failed — do not trust this tag.',
        );
      }
      return VerificationResult.verified(Tier1Payload.decode(unsigned));
    } on FormatException catch (error) {
      return VerificationResult.invalid(error.message);
    } catch (_) {
      return const VerificationResult.invalid('Could not verify this tag.');
    }
  }
}

BigInt _unsignedBigInt(List<int> bytes) => BigInt.parse(
  bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join(),
  radix: 16,
);
