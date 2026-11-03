// Builds the exact bytes MediTag writes to an NTAG216: one NDEF message (URI, MediTag MIME, Android
// Application Record) inside an NDEF TLV, followed by a terminator TLV.
// Sizes must match the server's budget in web/src/server/core/ndef.ts (checked by ndef_encoder_test).
import 'dart:convert';
import 'dart:typed_data';

const _tnfWellKnown = 0x01;
const _tnfMedia = 0x02;
const _tnfExternal = 0x04;
const _mb = 0x80, _me = 0x40, _sr = 0x10;

// NFC Forum URI prefix codes; the longest match is stored as one byte.
const _uriPrefixes = {'https://www.': 0x02, 'http://www.': 0x01, 'https://': 0x04, 'http://': 0x03};

class NdefRecordData {
  const NdefRecordData(this.tnf, this.type, this.payload);
  final int tnf;
  final Uint8List type;
  final Uint8List payload;
}

NdefRecordData uriRecord(String uri) {
  for (final MapEntry(key: prefix, value: code) in _uriPrefixes.entries) {
    if (uri.startsWith(prefix)) {
      return NdefRecordData(_tnfWellKnown, ascii.encode('U'), Uint8List.fromList([code, ...utf8.encode(uri.substring(prefix.length))]));
    }
  }
  return NdefRecordData(_tnfWellKnown, ascii.encode('U'), Uint8List.fromList([0x00, ...utf8.encode(uri)]));
}

NdefRecordData mimeRecord(String mimeType, Uint8List payload) => NdefRecordData(_tnfMedia, ascii.encode(mimeType), payload);

NdefRecordData androidAppRecord(String package) =>
    NdefRecordData(_tnfExternal, ascii.encode('android.com:pkg'), Uint8List.fromList(utf8.encode(package)));

Uint8List encodeMessage(List<NdefRecordData> records) {
  final out = BytesBuilder();
  for (var i = 0; i < records.length; i++) {
    final r = records[i];
    final short = r.payload.length < 256;
    var header = r.tnf;
    if (i == 0) header |= _mb;
    if (i == records.length - 1) header |= _me;
    if (short) header |= _sr;
    out.addByte(header);
    out.addByte(r.type.length);
    if (short) {
      out.addByte(r.payload.length);
    } else {
      out.add([(r.payload.length >> 24) & 0xFF, (r.payload.length >> 16) & 0xFF, (r.payload.length >> 8) & 0xFF, r.payload.length & 0xFF]);
    }
    out.add(r.type);
    out.add(r.payload);
  }
  return out.toBytes();
}

/// NDEF message TLV (0x03) plus terminator TLV (0xFE), as stored from page 4 of a Type 2 tag.
Uint8List wrapTlv(Uint8List message) {
  final out = BytesBuilder()..addByte(0x03);
  if (message.length < 0xFF) {
    out.addByte(message.length);
  } else {
    out.add([0xFF, (message.length >> 8) & 0xFF, message.length & 0xFF]);
  }
  out
    ..add(message)
    ..addByte(0xFE);
  return out.toBytes();
}

/// Everything that goes on a MediTag: tag URL first (so phones without the app open the website),
/// then the signed envelope, then the Android Application Record that opens the MediTag app.
Uint8List meditagTagBytes({required String uri, required String mimeType, required Uint8List envelope, required String androidPackage}) =>
    wrapTlv(encodeMessage([uriRecord(uri), mimeRecord(mimeType, envelope), androidAppRecord(androidPackage)]));
