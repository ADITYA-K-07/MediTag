import 'package:flutter/material.dart';

import 'tokens.dart';

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: MtColors.mintStrong,
    primary: MtColors.mintStrong,
    surface: MtColors.surface,
    onSurface: MtColors.ink,
    error: MtColors.roseStrong,
  );
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: MtColors.background,
    useMaterial3: true,
    textTheme: const TextTheme(
      headlineSmall: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: MtColors.ink),
      titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: MtColors.ink, letterSpacing: -0.2),
      titleMedium: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: MtColors.ink),
      bodyMedium: TextStyle(fontSize: 15, color: MtColors.ink),
      bodySmall: TextStyle(fontSize: 13, color: MtColors.inkMuted),
      labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1, color: MtColors.inkMuted),
    ),
  );
}

/// Soft coloured glow used instead of gradients or heavy shadows.
List<BoxShadow> glow(Color color, {double ring = 6, double blur = 28}) => [
      BoxShadow(color: color.withValues(alpha: 0.12), spreadRadius: ring),
      BoxShadow(color: color.withValues(alpha: 0.22), blurRadius: blur, offset: const Offset(0, 10)),
    ];
