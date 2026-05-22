import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:to_do_app/core/theme/nexus_colors.dart';

class NexusTheme {
  static ThemeData dark() {
    final textTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: NexusColors.background,
      colorScheme: const ColorScheme.dark(
        primary: NexusColors.primary,
        onPrimary: NexusColors.onPrimary,
        primaryContainer: NexusColors.primaryContainer,
        secondary: NexusColors.secondary,
        secondaryContainer: NexusColors.secondaryContainer,
        tertiary: NexusColors.tertiary,
        error: NexusColors.error,
        surface: NexusColors.surface,
        onSurface: NexusColors.onSurface,
        surfaceContainerHighest: NexusColors.surfaceContainerHighest,
        outline: NexusColors.outline,
      ),
      textTheme: textTheme.apply(
        bodyColor: NexusColors.onSurface,
        displayColor: NexusColors.onSurface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: NexusColors.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: NexusColors.surfaceContainer.withValues(alpha: 0.72),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: NexusColors.outlineVariant.withValues(alpha: 0.45)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: NexusColors.outlineVariant.withValues(alpha: 0.45)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: NexusColors.primary),
        ),
      ),
    );
  }
}
