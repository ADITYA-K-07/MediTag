import 'package:flutter/material.dart';

import 'config.dart';
import 'screens/scan_screen.dart';
import 'theme/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = await AppConfig.load();
  runApp(MediTagApp(config: config));
}

class MediTagApp extends StatelessWidget {
  const MediTagApp({super.key, required this.config});

  final AppConfig config;

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'MediTag',
        theme: buildTheme(),
        debugShowCheckedModeBanner: false,
        home: ScanScreen(config: config),
      );
}
