import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meditag/config.dart';
import 'package:meditag/main.dart';
import 'package:meditag/tag/envelope.dart';

AppConfig demoConfig() {
  final vectors = jsonDecode(File('../schema/test-vectors.json').readAsStringSync()) as Map<String, dynamic>;
  final cases = (vectors['cases'] as List<dynamic>).cast<Map<String, dynamic>>();
  Uint8List envelope(String name) => hexToBytes(cases.firstWhere((c) => c['name'] == name)['envelopeHex'] as String);
  return AppConfig({1: hexToBytes(vectors['publicKeyHex'] as String)}, DemoTags(envelope('valid'), envelope('tampered-blood-group')));
}

Future<void> tapDemo(WidgetTester tester, String label) async {
  await tester.scrollUntilVisible(find.text(label), 200, scrollable: find.byType(Scrollable).first);
  await tester.tap(find.text(label));
}

void main() {
  testWidgets('demo genuine tag shows the verified emergency card', (tester) async {
    await tester.pumpWidget(MediTagApp(config: demoConfig()));
    expect(find.text('No login needed'), findsOneWidget);

    await tapDemo(tester, 'Genuine tag');
    await tester.pump();
    expect(find.text('Tag found'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 950));
    await tester.pumpAndSettle();
    expect(find.text('Verified MediTag'), findsOneWidget);
    expect(find.text('Rahul Sharma'), findsOneWidget);
    expect(find.text('B+'), findsOneWidget);
    expect(find.text('Call Mother'), findsOneWidget);
  });

  testWidgets('demo tampered tag is flagged unverified, and Back returns home', (tester) async {
    await tester.pumpWidget(MediTagApp(config: demoConfig()));
    await tapDemo(tester, 'Tampered tag');
    await tester.pump(const Duration(milliseconds: 950));
    await tester.pumpAndSettle();
    expect(find.text('Unverified tag'), findsOneWidget);
    expect(find.text('O+'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text("Medical info that speaks when you can't."), findsOneWidget);
  });
}
