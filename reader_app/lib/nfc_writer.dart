import 'dart:async';
import 'dart:typed_data';

import 'package:nfc_manager/ndef_record.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';

/// Writes one MediTag binary payload as one raw NDEF record.
///
/// The writer deliberately does not lock the tag. A demo tag can be replaced
/// during review, while a production issuance flow should add an explicit
/// administrative lock step later.
class NfcWriter {
  Future<void> writePayload(Uint8List payload) async {
    final availability = await NfcManager.instance.checkAvailability();
    if (availability != NfcAvailability.enabled) {
      throw StateError('NFC is unavailable. Enable it, then try again.');
    }

    final result = Completer<void>();
    await NfcManager.instance.startSession(
      pollingOptions: {NfcPollingOption.iso14443},
      onDiscovered: (tag) async {
        try {
          final ndef = Ndef.from(tag);
          if (ndef == null) {
            throw StateError('This tag is not NDEF-compatible.');
          }
          if (!ndef.isWritable) {
            throw StateError('This tag is not writable.');
          }

          final message = NdefMessage(
            records: [
              NdefRecord(
                typeNameFormat: TypeNameFormat.unknown,
                type: Uint8List(0),
                identifier: Uint8List(0),
                payload: payload,
              ),
            ],
          );
          if (message.byteLength > ndef.maxSize) {
            throw StateError(
              'Tag capacity is ${ndef.maxSize} bytes; MediTag needs ${message.byteLength}.',
            );
          }
          await ndef.write(message: message);
          if (!result.isCompleted) result.complete();
        } catch (error, stackTrace) {
          if (!result.isCompleted) result.completeError(error, stackTrace);
        } finally {
          await NfcManager.instance.stopSession();
        }
      },
    );
    return result.future;
  }
}
