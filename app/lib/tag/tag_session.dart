import 'dart:async';
import 'dart:typed_data';

import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';

import 'ntag216.dart';
import 'tag_reader.dart';

class _AndroidNfcA implements NfcATransport {
  _AndroidNfcA(this._nfcA);
  final NfcAAndroid _nfcA;

  @override
  Future<Uint8List> transceive(Uint8List command) => _nfcA.transceive(command);
}

/// The tag currently held to the phone: what it says, plus a raw channel for writing.
class HeldTag {
  HeldTag(this.read, this.chip);
  final TagRead read;
  final Ntag216 chip;
}

/// Waits for one tag, runs [action] while it is held, then ends the session.
/// Writing uses raw NFC-A commands, which only Android exposes; on iPhone this throws.
Future<T> withHeldTag<T>(Future<T> Function(HeldTag tag) action) async {
  if (await NfcManager.instance.checkAvailability() != NfcAvailability.enabled) {
    throw TagException('Turn on NFC in your phone settings, then try again.');
  }
  final done = Completer<T>();
  await NfcManager.instance.startSession(
    pollingOptions: {NfcPollingOption.iso14443},
    onDiscovered: (tag) async {
      try {
        final nfcA = NfcAAndroid.from(tag);
        if (nfcA == null) throw TagException('Programming tags needs an Android phone with NFC.');
        await nfcA.setTimeout(1000);
        final result = await action(HeldTag(parseTag(tag), Ntag216(_AndroidNfcA(nfcA))));
        if (!done.isCompleted) done.complete(result);
      } catch (e, st) {
        if (!done.isCompleted) done.completeError(e, st);
      } finally {
        await NfcManager.instance.stopSession();
      }
    },
  );
  return done.future;
}

Future<void> cancelHeldTag() => NfcManager.instance.stopSession();

/// The tag id from a MediTag URL (`https://…/e/<tagId>`), or null for any other tag.
String? tagIdFromUrl(String? url) {
  final match = RegExp(r'/e/([A-Za-z0-9_-]{16})$').firstMatch(url ?? '');
  return match?.group(1);
}
