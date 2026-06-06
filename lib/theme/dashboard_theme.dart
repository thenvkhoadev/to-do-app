import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardColors {
  const DashboardColors._();

  static const background = Color(0xFF0D1322);
  static const surface = Color(0xFF0D1322);
  static const surfaceLowest = Color(0xFF080E1D);
  static const surfaceLow = Color(0xFF151B2B);
  static const surfaceContainer = Color(0xFF191F2F);
  static const surfaceHigh = Color(0xFF242A3A);
  static const surfaceHighest = Color(0xFF2F3445);
  static const onSurface = Color(0xFFDDE2F8);
  static const onSurfaceVariant = Color(0xFFC7C4D7);
  static const outline = Color(0xFF908FA0);
  static const outlineVariant = Color(0xFF464554);
  static const primary = Color(0xFFC0C1FF);
  static const primaryContainer = Color(0xFF8083FF);
  static const onPrimary = Color(0xFF1000A9);
  static const onPrimaryContainer = Color(0xFF0D0096);
  static const secondary = Color(0xFFDDB7FF);
  static const secondaryContainer = Color(0xFF6F00BE);
  static const tertiary = Color(0xFFADC6FF);
  static const tertiaryContainer = Color(0xFF4D8EFF);
  static const error = Color(0xFFFFB4AB);
  static const warning = Color(0xFFF59E0B);
  static const success = Color(0xFF22C55E);
}

class DashboardTheme {
  const DashboardTheme._();

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: DashboardColors.primary,
      brightness: Brightness.dark,
      primary: DashboardColors.primary,
      onPrimary: DashboardColors.onPrimary,
      secondary: DashboardColors.secondary,
      tertiary: DashboardColors.tertiary,
      surface: DashboardColors.surface,
      onSurface: DashboardColors.onSurface,
      error: DashboardColors.error,
    );

    final textTheme = GoogleFonts.interTextTheme(
      ThemeData.dark().textTheme,
    ).apply(
      bodyColor: DashboardColors.onSurface,
      displayColor: DashboardColors.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: DashboardColors.background,
      textTheme: textTheme.copyWith(
        displayLarge: GoogleFonts.interTight(
          fontSize: 48,
          height: 1.1,
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
          color: DashboardColors.onSurface,
        ),
        headlineMedium: GoogleFonts.interTight(
          fontSize: 28,
          height: 1.2,
          fontWeight: FontWeight.w700,
          color: DashboardColors.onSurface,
        ),
        titleLarge: GoogleFonts.interTight(
          fontSize: 20,
          height: 1.3,
          fontWeight: FontWeight.w700,
          color: DashboardColors.onSurface,
        ),
        labelSmall: GoogleFonts.jetBrainsMono(
          fontSize: 12,
          height: 1,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
          color: DashboardColors.onSurfaceVariant,
        ),
      ),
      iconTheme: const IconThemeData(color: DashboardColors.onSurfaceVariant),
    );
  }
}
