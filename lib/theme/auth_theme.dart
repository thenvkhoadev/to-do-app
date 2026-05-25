import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthColors {
  static const tertiaryFixed = Color(0xFFD8E2FF);
  static const secondaryContainer = Color(0xFF6F00BE);
  static const secondary = Color(0xFFDDB7FF);
  static const primary = Color(0xFFC0C1FF);
  static const outline = Color(0xFF908FA0);
  static const surfaceContainer = Color(0xFF191F2F);
  static const surfaceContainerLow = Color(0xFF151B2B);
  static const primaryContainer = Color(0xFF8083FF);
  static const outlineVariant = Color(0xFF464554);
  static const onBackground = Color(0xFFDDE2F8);
  static const onSurfaceVariant = Color(0xFFC7C4D7);
  static const onSurface = Color(0xFFDDE2F8);
  static const surface = Color(0xFF0D1322);
  static const background = Color(0xFF0D1322);
  static const surfaceContainerLowest = Color(0xFF080E1D);
  static const onPrimaryContainer = Color(0xFF0D0096);
}

class AuthSpacing {
  static const unit = 8.0;
  static const stackSm = 8.0;
  static const stackMd = 16.0;
  static const gutter = 24.0;
  static const containerMargin = 32.0;
  static const stackLg = 32.0;
}

class AuthBreakpoints {
  static const mobile = 768.0;
  static const desktop = 1200.0;
}

class AuthTextStyles {
  static TextStyle get display => GoogleFonts.inter(
        fontSize: 48,
        height: 1.1,
        letterSpacing: -0.96,
        fontWeight: FontWeight.w700,
        color: AuthColors.onSurface,
      );

  static TextStyle get headlineLarge => GoogleFonts.inter(
        fontSize: 32,
        height: 1.2,
        letterSpacing: -0.32,
        fontWeight: FontWeight.w600,
        color: AuthColors.onSurface,
      );

  static TextStyle get headlineMobile => GoogleFonts.inter(
        fontSize: 24,
        height: 1.2,
        fontWeight: FontWeight.w600,
        color: AuthColors.onSurface,
      );

  static TextStyle get headlineMedium => GoogleFonts.inter(
        fontSize: 24,
        height: 1.3,
        fontWeight: FontWeight.w500,
        color: AuthColors.onSurface,
      );

  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 18,
        height: 1.6,
        fontWeight: FontWeight.w400,
        color: AuthColors.onSurfaceVariant,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 16,
        height: 1.5,
        fontWeight: FontWeight.w400,
        color: AuthColors.onSurface,
      );

  static TextStyle get labelSmall => GoogleFonts.inter(
        fontSize: 12,
        height: 1.4,
        fontWeight: FontWeight.w500,
        color: AuthColors.onSurfaceVariant,
      );

  static TextStyle get labelCaps => GoogleFonts.jetBrainsMono(
        fontSize: 12,
        height: 1,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w500,
        color: AuthColors.onSurfaceVariant,
      );
}

class AuthTheme {
  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AuthColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AuthColors.primary,
        onPrimary: AuthColors.onPrimaryContainer,
        primaryContainer: AuthColors.primaryContainer,
        secondary: AuthColors.secondary,
        secondaryContainer: AuthColors.secondaryContainer,
        surface: AuthColors.surface,
        onSurface: AuthColors.onSurface,
        outline: AuthColors.outline,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: AuthColors.onSurface,
        displayColor: AuthColors.onSurface,
      ),
    );
  }
}
