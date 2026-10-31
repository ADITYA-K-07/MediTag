import 'dart:convert';

import 'package:flutter/services.dart';

import 'tag/envelope.dart';

// Public keys the server signs tags with: --dart-define=TAG_PUBLIC_KEYS='{"1":"04…"}'
// (from `npm --prefix functions run keys`). Without it the app runs in demo mode and trusts only the
// throwaway TEST key bundled in assets/demo/test-vectors.json.
const _configuredKeys = String.fromEnvironment('TAG_PUBLIC_KEYS');

const demoMode = _configuredKeys == '';

class DemoTags {
  DemoTags(this.genuine, this.tampered);
  final Uint8List genuine;
  final Uint8List tampered;
}

class AppConfig {
  AppConfig(this.publicKeys, this.demoTags);
  final Map<int, Uint8List> publicKeys;
  final DemoTags? demoTags;

  static Future<AppConfig> load() async {
    if (!demoMode) {
      final keys = (jsonDecode(_configuredKeys) as Map<String, dynamic>).map((id, hex) => MapEntry(int.parse(id), hexToBytes(hex as String)));
      return AppConfig(keys, null);
    }
    final vectors = jsonDecode(await rootBundle.loadString('assets/demo/test-vectors.json')) as Map<String, dynamic>;
    Uint8List envelope(String name) => hexToBytes(
        (vectors['cases'] as List<dynamic>).cast<Map<String, dynamic>>().firstWhere((c) => c['name'] == name)['envelopeHex'] as String);
    return AppConfig(
      {1: hexToBytes(vectors['publicKeyHex'] as String)},
      DemoTags(envelope('valid'), envelope('tampered-blood-group')),
    );
  }
}
