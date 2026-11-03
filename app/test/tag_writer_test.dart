import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meditag/tag/envelope.dart';
import 'package:meditag/tag/ndef_encoder.dart';
import 'package:meditag/tag/ntag216.dart';

final vectors = jsonDecode(File('../schema/test-vectors.json').readAsStringSync()) as Map<String, dynamic>;
Uint8List validEnvelope() => hexToBytes(
    (vectors['cases'] as List<dynamic>).cast<Map<String, dynamic>>().firstWhere((c) => c['name'] == 'valid')['envelopeHex'] as String);

Uint8List sampleBytes() => meditagTagBytes(
      uri: vectors['uri'] as String,
      mimeType: 'application/vnd.meditag.v1',
      envelope: validEnvelope(),
      androidPackage: 'com.meditag.app',
    );

/// An NTAG216 in memory: 231 pages, GET_VERSION, READ (4 pages), WRITE, PWD_AUTH and AUTH0 write protection.
class FakeNtag216 implements NfcATransport {
  FakeNtag216({this.storageByte = 0x13}) {
    pages[0xE3] = [0x04, 0x00, 0x00, 0xFF]; // AUTH0 = 0xFF: no protection
    pages[0xE5] = [0xFF, 0xFF, 0xFF, 0xFF];
  }
  final int storageByte;
  final pages = List.generate(0xE7, (_) => [0, 0, 0, 0]);
  bool authenticated = false;

  int get auth0 => pages[0xE3][3];

  @override
  Future<Uint8List> transceive(Uint8List c) async {
    switch (c[0]) {
      case 0x60:
        return Uint8List.fromList([0x00, 0x04, 0x04, 0x02, 0x01, 0x00, storageByte, 0x03]);
      case 0x30:
        return Uint8List.fromList([for (var p = c[1]; p < c[1] + 4; p++) ...pages[p % pages.length]]);
      case 0xA2:
        if (c[1] >= auth0 && !authenticated) return Uint8List.fromList([0x00]); // NAK
        pages[c[1]] = c.sublist(2, 6);
        return Uint8List.fromList([0x0A]);
      case 0x1B:
        if (_eq(c.sublist(1, 5), pages[0xE5])) {
          authenticated = true;
          return Uint8List.fromList(pages[0xE6].sublist(0, 2));
        }
        return Uint8List(0);
    }
    throw StateError('unknown command ${c[0]}');
  }

  Uint8List userMemory(int length) => Uint8List.fromList([for (var p = 4; p < 0xE2; p++) ...pages[p]].sublist(0, length));

  static bool _eq(List<int> a, List<int> b) => a.length == b.length && List.generate(a.length, (i) => a[i] == b[i]).every((x) => x);
}

final password = TagPassword.fromHex('1a2b3c4d', 'beef');

void main() {
  group('NDEF encoding', () {
    test('uses exactly the bytes the server budgets for (test vectors)', () {
      expect(sampleBytes().length, vectors['bytesNeeded']);
      expect(sampleBytes().length, lessThanOrEqualTo(userBytes));
    });

    test('starts with the URI record so phones without the app open the website', () {
      final bytes = sampleBytes();
      expect(bytes[0], 0x03); // NDEF TLV
      expect(bytes.last, 0xFE); // terminator
      final msgStart = bytes[1] == 0xFF ? 4 : 2;
      expect(bytes[msgStart] & 0x80, 0x80, reason: 'first record has MB');
      expect(bytes[msgStart] & 0x07, 0x01, reason: 'first record is well-known');
      expect(String.fromCharCode(bytes[msgStart + 3]), 'U');
      expect(bytes[msgStart + 4], 0x04, reason: 'https:// compressed to one byte');
    });

    test('carries the signed envelope unchanged', () {
      final bytes = sampleBytes();
      final env = validEnvelope();
      final start = _indexOf(bytes, env);
      expect(start, greaterThan(0));
      expect(readEnvelope(Uint8List.sublistView(bytes, start, start + env.length), {1: hexToBytes(vectors['publicKeyHex'] as String)}),
          isA<ReadOk>().having((r) => r.trust, 'trust', TagTrust.verified));
    });
  });

  group('NTAG216 programming', () {
    test('writes, verifies and locks a blank tag', () async {
      final tag = FakeNtag216();
      await programNewTag(Ntag216(tag), sampleBytes(), password);
      expect(tag.userMemory(sampleBytes().length), sampleBytes());
      expect(tag.pages[0xE5], password.pwd);
      expect(tag.pages[0xE6].sublist(0, 2), password.pack);
      expect(tag.auth0, firstUserPage, reason: 'protected from page 4');
      expect(tag.pages[0xE4][0] & 0x80, 0, reason: 'reading stays open');
    });

    test('after locking, a stranger cannot overwrite it', () async {
      final tag = FakeNtag216();
      await programNewTag(Ntag216(tag), sampleBytes(), password);
      tag.authenticated = false; // tag leaves the field
      final stranger = Ntag216(tag);
      await expectLater(stranger.writeUserMemory(Uint8List.fromList([1, 2, 3, 4])), throwsA(isA<TagException>()));
      expect(tag.userMemory(sampleBytes().length), sampleBytes(), reason: 'data unchanged');
    });

    test('refuses to program a tag that is already locked', () async {
      final tag = FakeNtag216();
      await programNewTag(Ntag216(tag), sampleBytes(), password);
      tag.authenticated = false;
      await expectLater(programNewTag(Ntag216(tag), sampleBytes(), password), throwsA(isA<TagException>()));
    });

    test('rewrites its own tag with the right password', () async {
      final tag = FakeNtag216();
      await programNewTag(Ntag216(tag), sampleBytes(), password);
      tag.authenticated = false;
      final updated = Uint8List.fromList([...sampleBytes()]..[10] ^= 0xFF);
      await rewriteTag(Ntag216(tag), updated, password);
      expect(tag.userMemory(updated.length), updated);
    });

    test('rejects a wrong password', () async {
      final tag = FakeNtag216();
      await programNewTag(Ntag216(tag), sampleBytes(), password);
      tag.authenticated = false;
      await expectLater(rewriteTag(Ntag216(tag), sampleBytes(), TagPassword.fromHex('00000000', '0000')), throwsA(isA<TagException>()));
    });

    test('refuses smaller tags such as NTAG213', () async {
      await expectLater(programNewTag(Ntag216(FakeNtag216(storageByte: 0x0F)), sampleBytes(), password), throwsA(isA<TagException>()));
    });
  });
}

int _indexOf(Uint8List hay, Uint8List needle) {
  for (var i = 0; i <= hay.length - needle.length; i++) {
    var ok = true;
    for (var j = 0; j < needle.length && ok; j++) {
      ok = hay[i + j] == needle[j];
    }
    if (ok) return i;
  }
  return -1;
}
