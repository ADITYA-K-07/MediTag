// NTAG216 programming over raw NFC-A commands (NXP NTAG213/215/216 datasheet).
// Writes the NDEF bytes page by page, then sets a 32-bit write password (PWD/PACK) from page 4 onward.
// Reading stays open, so any phone can read the emergency info.
import 'dart:typed_data';

const _cmdGetVersion = 0x60;
const _cmdRead = 0x30;
const _cmdWrite = 0xA2;
const _cmdPwdAuth = 0x1B;
const _ack = 0x0A;

const firstUserPage = 0x04;
const lastUserPage = 0xE1; // 222 pages × 4 bytes = 888 bytes
const userBytes = (lastUserPage - firstUserPage + 1) * 4;
const _cfg0Page = 0xE3; // MIRROR, RFUI, MIRROR_PAGE, AUTH0
const _cfg1Page = 0xE4; // ACCESS, RFUI, RFUI, RFUI
const _pwdPage = 0xE5;
const _packPage = 0xE6;
const _authDisabled = 0xFF;

/// Sends one raw NFC-A command and returns the tag's answer. Implemented over Android's NfcA, and by a fake in tests.
abstract interface class NfcATransport {
  Future<Uint8List> transceive(Uint8List command);
}

class TagException implements Exception {
  TagException(this.message);
  final String message;
  @override
  String toString() => message;
}

class TagPassword {
  TagPassword(this.pwd, this.pack);
  factory TagPassword.fromHex(String pwdHex, String packHex) => TagPassword(_hex(pwdHex), _hex(packHex));
  final Uint8List pwd; // 4 bytes
  final Uint8List pack; // 2 bytes
}

Uint8List _hex(String s) => Uint8List.fromList([for (var i = 0; i < s.length; i += 2) int.parse(s.substring(i, i + 2), radix: 16)]);

bool _sameBytes(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

class Ntag216 {
  Ntag216(this._io);
  final NfcATransport _io;

  Future<void> _write(int page, List<int> data) async {
    final res = await _io.transceive(Uint8List.fromList([_cmdWrite, page, ...data]));
    // Android returns the 4-bit ACK (0x0A); anything else is a NAK (wrong password, locked page, glitch).
    if (res.isNotEmpty && (res[0] & 0x0F) != _ack) throw TagException('The tag refused the write (page $page).');
  }

  Future<Uint8List> _read(int page) async {
    final res = await _io.transceive(Uint8List.fromList([_cmdRead, page]));
    if (res.length < 16) throw TagException('Could not read the tag. Hold it still.');
    return res;
  }

  /// Refuses anything but an NTAG216, so a smaller tag never gets a truncated profile.
  Future<void> checkIsNtag216() async {
    final v = await _io.transceive(Uint8List.fromList([_cmdGetVersion]));
    // GET_VERSION: [header, vendor 0x04 = NXP, product 0x04 = NTAG, subtype, major, minor, storage 0x13 = NTAG216, protocol]
    final isNtag216 = v.length >= 8 && v[1] == 0x04 && v[2] == 0x04 && v[6] == 0x13;
    if (!isNtag216) throw TagException('This is not an NTAG216 tag. MediTag needs NTAG216 (888 bytes).');
  }

  /// True when the tag already has a write password (it's someone's MediTag, or another locked tag).
  Future<bool> isLocked() async => (await _read(_cfg0Page))[3] != _authDisabled;

  Future<void> authenticate(TagPassword password) async {
    final res = await _io.transceive(Uint8List.fromList([_cmdPwdAuth, ...password.pwd]));
    if (res.length < 2 || !_sameBytes(res.sublist(0, 2), password.pack)) {
      throw TagException("This tag's password doesn't match. It may belong to another account.");
    }
  }

  Future<void> writeUserMemory(Uint8List bytes) async {
    if (bytes.length > userBytes) throw TagException('Too much data for this tag (${bytes.length} of $userBytes bytes).');
    final padded = Uint8List(((bytes.length + 3) ~/ 4) * 4)..setRange(0, bytes.length, bytes);
    for (var offset = 0; offset < padded.length; offset += 4) {
      await _write(firstUserPage + offset ~/ 4, padded.sublist(offset, offset + 4));
    }
  }

  /// Reads back what was written and compares it byte for byte.
  Future<void> verifyUserMemory(Uint8List bytes) async {
    final got = BytesBuilder();
    for (var page = firstUserPage; got.length < bytes.length; page += 4) {
      got.add(await _read(page));
    }
    if (!_sameBytes(got.toBytes().sublist(0, bytes.length), bytes)) {
      throw TagException('The tag did not save correctly. Hold it still and try again.');
    }
  }

  /// Sets PWD/PACK, keeps reads open (PROT = 0), then turns protection on from page 4 (AUTH0).
  /// AUTH0 goes last: once it is set, every later write needs the password.
  Future<void> lock(TagPassword password) async {
    await _write(_pwdPage, password.pwd);
    await _write(_packPage, [...password.pack, 0x00, 0x00]);
    final cfg1 = await _read(_cfg1Page);
    await _write(_cfg1Page, [cfg1[0] & 0x7F, cfg1[1], cfg1[2], cfg1[3]]);
    final cfg0 = await _read(_cfg0Page);
    await _write(_cfg0Page, [cfg0[0], cfg0[1], cfg0[2], firstUserPage]);
  }
}

/// A new MediTag: blank, unlocked NTAG216 → data written, checked, then locked.
Future<void> programNewTag(Ntag216 tag, Uint8List bytes, TagPassword password) async {
  await tag.checkIsNtag216();
  if (await tag.isLocked()) {
    throw TagException('This tag is already locked. To change a MediTag, use "Update a tag" instead.');
  }
  await tag.writeUserMemory(bytes);
  await tag.verifyUserMemory(bytes);
  await tag.lock(password);
}

/// An existing MediTag of this account: unlock with its password, rewrite, check.
Future<void> rewriteTag(Ntag216 tag, Uint8List bytes, TagPassword password) async {
  await tag.checkIsNtag216();
  await tag.authenticate(password);
  await tag.writeUserMemory(bytes);
  await tag.verifyUserMemory(bytes);
}
