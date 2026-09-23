import 'package:flutter/material.dart';

/// The only home for MediTag's visual constants.
abstract final class MTTokens {
  static const inkBrand = Color(0xFF191A2E);
  static const periwinkle = Color(0xFF6B85F0);
  static const mint = Color(0xFF2FAE6A);
  static const amber = Color(0xFFE5B54E);
  static const clay = Color(0xFFE29448);
  static const orchid = Color(0xFFC77BEE);
  static const criticalRed = Color(0xFFD64545);
  static const accentBlue = Color(0xFF7F98F5);

  // Kept in lock-step with the public website's canvas and panels.
  static const surface = Color(0xFFE4EBFC);
  static const surfaceDim = Color(0xFFCBD8FB);
  static const surfaceSoft = Color(0xFFEEF2FD);
  static const card = Color(0xFFFFFFFF);
  static const cardMuted = Color(0xFFF4F6FD);
  static const container = Color(0xFFE6EBFA);
  static const containerHigh = Color(0xFFDCE3FB);
  static const darkPanel = Color(0xFF272A40);
  static const onDarkMuted = Color(0xFFC4C8D8);
  static const line = Color(0xFFE2E6F4);
  static const ink = Color(0xFF1B1D2E);
  static const inkMuted = Color(0xFF5A6076);
  static const inkFaint = Color(0xFF5F6478);

  static const navyWash = Color(0xFFE6EBFA);
  static const orchidWash = Color(0xFFF5E8FC);
  static const amberWash = Color(0xFFFFF3D8);
  static const blueWash = Color(0xFFE5EEFF);
  static const clayWash = Color(0xFFFCEBDD);
  static const mintWash = Color(0xFFE1F5EA);
  static const criticalWash = Color(0xFFFBE4E4);

  static const radiusSm = Radius.circular(10);
  static const radiusMd = Radius.circular(16);
  static const radiusLg = Radius.circular(28);
  static const radiusXl = Radius.circular(34);
  static const pill = BorderRadius.all(Radius.circular(100));
  static const shapeSm = BorderRadius.all(radiusSm);
  static const shapeMd = BorderRadius.all(radiusMd);
  static const shapeLg = BorderRadius.all(radiusLg);
  static const shapeXl = BorderRadius.all(radiusXl);

  static const level1 = [
    BoxShadow(
      color: Color(0x0F191A2E),
      offset: Offset(0, 8),
      blurRadius: 24,
      spreadRadius: -10,
    ),
    BoxShadow(
      color: Color(0x0A191A2E),
      offset: Offset(0, 2),
      blurRadius: 6,
      spreadRadius: -2,
    ),
  ];
  static const level2 = [
    BoxShadow(
      color: Color(0x1F191A2E),
      offset: Offset(0, 12),
      blurRadius: 28,
      spreadRadius: -10,
    ),
  ];
  static const level3 = [
    BoxShadow(
      color: Color(0x24191A2E),
      offset: Offset(0, 14),
      blurRadius: 40,
      spreadRadius: -12,
    ),
    BoxShadow(
      color: Color(0x0F191A2E),
      offset: Offset(0, 2),
      blurRadius: 8,
      spreadRadius: -2,
    ),
  ];
  static const focusGlow = [
    BoxShadow(color: Color(0x2E6B85F0), spreadRadius: 3),
  ];

  static const curve = Cubic(0.215, 0.61, 0.355, 1);
  static const fast = Duration(milliseconds: 140);
  static const medium = Duration(milliseconds: 260);
  static const slow = Duration(milliseconds: 360);

  static const displayXl = TextStyle(
    fontFamily: 'DMSans',
    fontSize: 48,
    height: 56 / 48,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.96,
    color: ink,
  );
  static const headlineXl = TextStyle(
    fontFamily: 'DMSans',
    fontSize: 36,
    height: 42 / 36,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.25,
    color: ink,
  );
  static const headlineLg = TextStyle(
    fontFamily: 'DMSans',
    fontSize: 24,
    height: 32 / 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.24,
    color: ink,
  );
  static const headlineMd = TextStyle(
    fontFamily: 'Inter',
    fontSize: 20,
    height: 28 / 20,
    fontWeight: FontWeight.w600,
    color: ink,
  );
  static const labelCaps = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.6,
    color: inkMuted,
  );
  static const monoData = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w500,
    fontFeatures: [FontFeature.tabularFigures()],
    color: inkMuted,
  );
  static const statNumber = TextStyle(
    fontFamily: 'Inter',
    fontSize: 30,
    height: 38 / 30,
    fontWeight: FontWeight.w700,
    fontFeatures: [FontFeature.tabularFigures()],
    color: ink,
  );

  static ThemeData theme() => ThemeData(
    useMaterial3: true,
    fontFamily: 'Inter',
    scaffoldBackgroundColor: surface,
    colorScheme: const ColorScheme.light(
      primary: inkBrand,
      onPrimary: card,
      secondary: periwinkle,
      onSecondary: inkBrand,
      surface: surface,
      onSurface: ink,
      error: criticalRed,
    ),
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    focusColor: Colors.transparent,
    navigationBarTheme: const NavigationBarThemeData(height: 72, elevation: 0),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: inkBrand,
      contentTextStyle: TextStyle(color: card, fontFamily: 'Inter'),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: shapeMd),
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: ink, fontSize: 16, height: 1.45),
      bodySmall: TextStyle(color: inkMuted, fontSize: 14, height: 1.4),
    ),
  );
}
