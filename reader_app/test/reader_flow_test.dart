import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meditag_reader/main.dart';
import 'package:meditag_reader/protocol.dart';
import 'package:meditag_reader/reader_controller.dart';
import 'package:meditag_reader/services/tag_scan_service.dart';
import 'package:meditag_reader/services/tier2_repository.dart';
import 'package:meditag_reader/tag_verifier.dart';

class _FakeScanner implements TagScanService {
  _FakeScanner(this.result);
  final VerificationResult result;
  @override
  Future<VerificationResult> scanAndVerify() async => result;
}

VerificationResult _verified() => VerificationResult.verified(Tier1Payload.decode(Uint8List.fromList([
      1, 8, 0, 17, 0, 1, 0x98, 0x76, 0x54, 0x32, 0x10, 0, 0, 3, 233,
    ])));

ReaderController _controller(VerificationResult result) => ReaderController(
      scanner: _FakeScanner(result),
      tier2Repository: Tier2Repository(const ApiConfig(baseUrl: '', clinicianToken: '')),
    );

void main() {
  testWidgets('access portal exposes citizen, doctor, and emergency-reader surfaces', (tester) async {
    await tester.pumpWidget(MediTagApp(controller: _controller(_verified())));
    expect(find.text('Citizen'), findsOneWidget);
    expect(find.text('Doctor'), findsOneWidget);
    expect(find.text('Read a MediTag'), findsOneWidget);
    await tester.tap(find.text('Citizen'));
    await tester.pumpAndSettle();
    expect(find.text('Citizen sign in'), findsOneWidget);
  });

  testWidgets('valid NFC verification reveals the Tier 1 emergency profile', (tester) async {
    await tester.pumpWidget(MediTagApp(controller: _controller(_verified()), initialSurface: AppSurface.reader));
    expect(find.text('Tap a MediTag to read it'), findsOneWidget);
    await tester.tap(find.text('Start scan'));
    await tester.pump();
    expect(find.text('Emergency profile'), findsOneWidget);
    expect(find.text('Verified offline'), findsOneWidget);
    expect(find.text('O-'), findsOneWidget);
  });

  testWidgets('invalid verification has an urgent, distinct warning', (tester) async {
    await tester.pumpWidget(MediTagApp(controller: _controller(const VerificationResult.invalid('Signature check failed — do not trust this tag.')), initialSurface: AppSurface.reader));
    await tester.tap(find.text('Start scan'));
    await tester.pump();
    expect(find.text('Tag cannot be trusted'), findsOneWidget);
    expect(find.text('Signature invalid — do not trust this tag'), findsOneWidget);
  });

  testWidgets('issue form requires input before displaying its destructive-write confirmation', (tester) async {
    await tester.pumpWidget(MediTagApp(controller: _controller(_verified()), initialSurface: AppSurface.reader));
    await tester.tap(find.text('Issue a tag'));
    await tester.pumpAndSettle();
    expect(find.text('Issue a MediTag'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), '1001');
    await tester.enterText(find.byType(TextFormField).at(1), '+91 98765 43210');
    await tester.pump();
    await tester.tap(find.text('Review tag write'));
    await tester.pumpAndSettle();
    expect(find.text('Confirm tag write'), findsOneWidget);
    expect(find.textContaining('will not write to NFC hardware'), findsOneWidget);
  });
}
