import 'package:flutter/foundation.dart';

import 'services/tag_scan_service.dart';
import 'services/tier2_repository.dart';
import 'tag_verifier.dart';

enum ReaderView { home, scanning, verified, invalid, tier2Loading, tier2Locked, tier2Record, issueTag, settings }

class ReaderController extends ChangeNotifier {
  ReaderController({required TagScanService scanner, required Tier2Repository tier2Repository})
      : _scanner = scanner,
        _tier2Repository = tier2Repository;

  final TagScanService _scanner;
  final Tier2Repository _tier2Repository;
  ReaderView view = ReaderView.home;
  VerificationResult? verification;
  Tier2Result? tier2;
  String? scanMessage;

  Future<void> scan() async {
    view = ReaderView.scanning;
    verification = null;
    scanMessage = null;
    notifyListeners();
    try {
      verification = await _scanner.scanAndVerify();
      view = verification!.isVerified ? ReaderView.verified : ReaderView.invalid;
    } catch (error) {
      view = ReaderView.home;
      scanMessage = error.toString().replaceFirst('Bad state: ', '');
    }
    notifyListeners();
  }

  Future<void> requestTier2() async {
    final tagId = verification?.payload?.tagId;
    if (tagId == null) return;
    view = ReaderView.tier2Loading;
    notifyListeners();
    tier2 = await _tier2Repository.fetch(tagId);
    view = tier2 is Tier2Record ? ReaderView.tier2Record : ReaderView.tier2Locked;
    notifyListeners();
  }

  void show(ReaderView next) {
    view = next;
    notifyListeners();
  }

  void reset() {
    verification = null;
    tier2 = null;
    scanMessage = null;
    show(ReaderView.home);
  }
}
