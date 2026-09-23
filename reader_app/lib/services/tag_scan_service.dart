import 'dart:convert';
import 'dart:typed_data';

import '../nfc_reader.dart';
import '../tag_verifier.dart';

abstract interface class TagScanService {
  Future<VerificationResult> scanAndVerify();
}

class NfcTagScanService implements TagScanService {
  NfcTagScanService({required this.publicKeyBase64, NfcReader? reader})
    : _reader = reader ?? NfcReader();

  final String publicKeyBase64;
  final NfcReader _reader;

  @override
  Future<VerificationResult> scanAndVerify() async {
    if (publicKeyBase64.isEmpty) {
      throw StateError(
        'This build has no issuer public key. Provision MEDITAG_PUBLIC_KEY before scanning real tags.',
      );
    }
    final key = TagVerifier.publicKeyFromUncompressed(
      Uint8List.fromList(base64Decode(publicKeyBase64)),
    );
    return TagVerifier(key).verify(await _reader.scanOne());
  }
}
