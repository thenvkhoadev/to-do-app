import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginColors {
  static const Color background = Color(0xFF0D1322);
  static const Color surface = Color(0xFF191F2F);
  static const Color primary = Color(0xFFE1DFFF);
  static const Color secondary = Color(0xFFC0C1FF);
  static const Color tertiary = Color(0xFFFEE089);
  static const Color onSurface = Color(0xFFDDE2F7);
  static const Color onSurfaceVariant = Color(0xFFC7C5D0);
  static const Color outline = Color(0xFF918F9A);
  static const Color glassStroke = Color(0x1FFFFFFF); // rgba(255, 255, 255, 0.12)
  static const Color successGreen = Color(0xFFE4F222);
}

TextStyle getLoginGeistStyle({
  required double fontSize,
  required FontWeight fontWeight,
  Color? color,
  double? height,
  double? letterSpacing,
}) {
  try {
    return GoogleFonts.getFont(
      'Geist',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? LoginColors.onSurface,
      height: height,
      letterSpacing: letterSpacing,
    );
  } catch (_) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? LoginColors.onSurface,
      height: height,
      letterSpacing: letterSpacing,
    );
  }
}

TextStyle getLoginGeistMonoStyle({
  required double fontSize,
  required FontWeight fontWeight,
  Color? color,
  double? height,
  double? letterSpacing,
}) {
  try {
    return GoogleFonts.getFont(
      'Geist Mono',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? LoginColors.onSurface,
      height: height,
      letterSpacing: letterSpacing,
    );
  } catch (_) {
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? LoginColors.onSurface,
      height: height,
      letterSpacing: letterSpacing,
    );
  }
}
