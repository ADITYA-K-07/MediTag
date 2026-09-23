import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'reader_controller.dart';
import 'nfc_writer.dart';
import 'services/tag_scan_service.dart';
import 'services/tag_issuer.dart';
import 'services/tier2_repository.dart';
import 'theme/tokens.dart';
import 'widgets/mt_components.dart';

part 'features/access/access_portal.dart';
part 'features/citizen/citizen_flow.dart';
part 'features/doctor/doctor_flow.dart';
part 'features/reader/reader_flow.dart';

const _issuerPublicKey = String.fromEnvironment('MEDITAG_PUBLIC_KEY');

void main() {
  final config = ApiConfig.fromEnvironment();
  runApp(
    MediTagApp(
      controller: ReaderController(
        scanner: NfcTagScanService(publicKeyBase64: _issuerPublicKey),
        tier2Repository: Tier2Repository(config),
      ),
      publicKeyBase64: _issuerPublicKey,
      apiConfig: config,
    ),
  );
}

enum AppSurface { portal, reader, citizen, doctor }

class MediTagApp extends StatefulWidget {
  const MediTagApp({
    super.key,
    required this.controller,
    this.publicKeyBase64 = '',
    this.initialSurface = AppSurface.portal,
    this.apiConfig = const ApiConfig(baseUrl: '', clinicianToken: ''),
  });
  final ReaderController controller;
  final String publicKeyBase64;
  final AppSurface initialSurface;
  final ApiConfig apiConfig;

  @override
  State<MediTagApp> createState() => _MediTagAppState();
}

class _MediTagAppState extends State<MediTagApp> {
  late AppSurface _surface = widget.initialSurface;

  void _openDoctorScanner() {
    widget.controller.reset();
    setState(() => _surface = AppSurface.reader);
    widget.controller.scan();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'MediTag',
    theme: MTTokens.theme(),
    home: switch (_surface) {
      AppSurface.portal => _AccessPortal(
        onSelect: (surface) => setState(() => _surface = surface),
      ),
      AppSurface.reader => ReaderFlow(
        controller: widget.controller,
        publicKeyBase64: widget.publicKeyBase64,
        apiConfig: widget.apiConfig,
        onExit: () => setState(() => _surface = AppSurface.portal),
      ),
      AppSurface.citizen => _CitizenLogin(
        onExit: () => setState(() => _surface = AppSurface.portal),
      ),
      AppSurface.doctor => _DoctorLogin(
        onExit: () => setState(() => _surface = AppSurface.portal),
        onScan: _openDoctorScanner,
      ),
    },
  );
}
