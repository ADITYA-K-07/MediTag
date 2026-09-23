import 'dart:async';
import 'dart:typed_data';

import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';

class NfcReader {
  Future<Uint8List> scanOne() async {
    if (await NfcManager.instance.checkAvailability() !=
        NfcAvailability.enabled) {
      throw StateError('NFC is unavailable. Enable it, then try again.');
    }
    final result = Completer<Uint8List>();
    await NfcManager.instance.startSession(
      pollingOptions: {NfcPollingOption.iso14443},
      onDiscovered: (tag) async {
        try {
          final ndef = Ndef.from(tag);
          if (ndef == null || ndef.cachedMessage == null) {
            throw StateError('This is not an NDEF-compatible NFC tag.');
          }
          final records = ndef.cachedMessage!.records;
          if (records.length != 1) {
            throw StateError('Expected one MediTag NDEF record.');
          }
          result.complete(Uint8List.fromList(records.single.payload));
        } catch (error, stackTrace) {
          result.completeError(error, stackTrace);
        } finally {
          await NfcManager.instance.stopSession();
        }
      },
    );
    return result.future;
  }
}
