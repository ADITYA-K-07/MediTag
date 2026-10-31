import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:nfc_manager/ndef_record.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:nfc_manager/nfc_manager_ios.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';

const meditagMimeType = 'application/vnd.meditag.v1';

class TagRead {
  TagRead({required this.uid, this.envelope, this.url});

  /// Chip UID as upper-case hex; doctors send it as proof they tapped this tag.
  final String uid;

  /// The signed envelope from the MediTag MIME record.
  final Uint8List? envelope;

  /// The tag's URI record, e.g. `https://meditag.app/e/<tagId>`.
  final String? url;
}

// NFC Forum URI record prefix codes (the subset MediTag writes).
const _uriPrefixes = {0: '', 1: 'http://www.', 2: 'https://www.', 3: 'http://', 4: 'https://'};

String _hex(Uint8List bytes) => bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join().toUpperCase();

TagRead parseTag(NfcTag tag) {
  final uid = NfcTagAndroid.from(tag)?.id ?? MiFareIos.from(tag)?.identifier ?? Uint8List(0);
  Uint8List? envelope;
  String? url;
  for (final record in Ndef.from(tag)?.cachedMessage?.records ?? const <NdefRecord>[]) {
    final type = ascii.decode(record.type, allowInvalid: true);
    if (record.typeNameFormat == TypeNameFormat.media && type == meditagMimeType) {
      envelope = record.payload;
    } else if (record.typeNameFormat == TypeNameFormat.wellKnown && type == 'U' && record.payload.isNotEmpty) {
      url = (_uriPrefixes[record.payload.first] ?? '') + utf8.decode(record.payload.sublist(1), allowMalformed: true);
    }
  }
  return TagRead(uid: _hex(uid), envelope: envelope, url: url);
}

class TagReader {
  Future<bool> get available async => await NfcManager.instance.checkAvailability() == NfcAvailability.enabled;

  /// Reads one tag. On iOS this shows the system NFC sheet.
  Future<TagRead> readOne() {
    final done = Completer<TagRead>();
    NfcManager.instance.startSession(
      pollingOptions: {NfcPollingOption.iso14443},
      alertMessageIos: 'Hold your iPhone near the MediTag',
      onDiscovered: (tag) async {
        final read = parseTag(tag);
        await NfcManager.instance.stopSession(alertMessageIos: 'MediTag read');
        if (!done.isCompleted) done.complete(read);
      },
      onSessionErrorIos: (error) {
        if (!done.isCompleted) done.completeError(Exception(error.message));
      },
    );
    return done.future;
  }

  Future<void> cancel() => NfcManager.instance.stopSession();
}
