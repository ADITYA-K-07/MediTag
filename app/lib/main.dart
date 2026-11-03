import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'config.dart';
import 'firebase_options.dart';
import 'screens/citizen_home.dart';
import 'screens/scan_screen.dart';
import 'theme/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
        // The bystander scan screen opens first: no login stands between a stranger and the emergency info.
        home: ScanScreen(
          config: config,
          onOpenAccount: (context) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AccountGate())),
        ),
      );
}
