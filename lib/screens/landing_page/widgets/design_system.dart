import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LandingColors {
  static const Color background = Color(0xFF0D1322);
  static const Color surface = Color(0xFF191F2F);
  static const Color primary = Color(0xFFE1DFFF);
  static const Color secondary = Color(0xFFC0C1FF);
  static const Color tertiary = Color(0xFFFEE089);
  static const Color textPrimary = Color(0xFFDDE2F7);
  static const Color textSecondary = Color(0xFFC7C5D0);
  static const Color success = Color(0xFFE4F222);
  static const Color errorRed = Color(0xFFFF3B30);
  static const Color glassBorder = Color(0x1FFFFFFF); // rgba(255,255,255,0.12)
  static const Color glassBg = Color(0x66191F2F); // rgba(25,31,47,0.4)
  static const Color surfaceContainerLow = Color(0xFF151B2B);
  static const Color surfaceContainerLowest = Color(0xFF080E1D);
  static const Color surfaceVariant = Color(0xFF2F3445);
}

TextStyle getLandingGeistStyle({
  required double fontSize,
  required FontWeight fontWeight,
  Color? color,
  double? height,
  double? letterSpacing,
  FontStyle fontStyle = FontStyle.normal,
}) {
  try {
    return GoogleFonts.getFont(
      'Geist',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? LandingColors.textPrimary,
      height: height,
      letterSpacing: letterSpacing,
      fontStyle: fontStyle,
    );
  } catch (_) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? LandingColors.textPrimary,
      height: height,
      letterSpacing: letterSpacing,
      fontStyle: fontStyle,
    );
  }
}

TextStyle getLandingGeistMonoStyle({
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
      color: color ?? LandingColors.textPrimary,
      height: height,
      letterSpacing: letterSpacing,
    );
  } catch (_) {
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? LandingColors.textPrimary,
      height: height,
      letterSpacing: letterSpacing,
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final Color? borderColor;
  final Color? bgColor;
  final EdgeInsetsGeometry? padding;
  final List<BoxShadow>? boxShadow;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 24.0,
    this.blur = 30.0,
    this.borderColor,
    this.bgColor,
    this.padding,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: blur,
          sigmaY: blur,
        ),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: bgColor ?? LandingColors.glassBg,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor ?? LandingColors.glassBorder,
              width: 1.0,
            ),
            boxShadow: boxShadow ??
                [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.37),
                    blurRadius: 32.0,
                    offset: const Offset(0, 8),
                  ),
                ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class PressableScale extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const PressableScale({super.key, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isPressed = ValueNotifier<bool>(false);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => isPressed.value = true,
        onTapUp: (_) => isPressed.value = false,
        onTapCancel: () => isPressed.value = false,
        onTap: onTap,
        child: ValueListenableBuilder<bool>(
          valueListenable: isPressed,
          builder: (context, pressed, child) {
            return AnimatedScale(
              scale: pressed ? 0.96 : 1.0,
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOut,
              child: child,
            );
          },
          child: child,
        ),
      ),
    );
  }
}

class HoverBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, bool isHovered) builder;

  const HoverBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    final isHovered = ValueNotifier<bool>(false);
    return MouseRegion(
      onEnter: (_) => isHovered.value = true,
      onExit: (_) => isHovered.value = false,
      child: ValueListenableBuilder<bool>(
        valueListenable: isHovered,
        builder: (context, hovered, _) {
          return builder(context, hovered);
        },
      ),
    );
  }
}
