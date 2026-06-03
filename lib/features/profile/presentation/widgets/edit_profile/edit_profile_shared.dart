import 'dart:ui';
import 'package:flutter/material.dart';

class EditProfileColors {
  static const Color background = Color(0xFF080B14);
  static const Color cardBg = Color(0xFF111827);
  static const Color borderTop = Color(0x1EFFFFFF); // rgba(255, 255, 255, 0.12)
  static const Color borderSides = Color(0x0DFFFFFF); // rgba(255, 255, 255, 0.05)
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textOutline = Color(0xFF918F9A);

  static const Color primary = Color(0xFF7C5CFF);
  static const Color secondary = Color(0xFFB388FF);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
}

class EditProfileGlassCard extends StatelessWidget {
  const EditProfileGlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.radius = 24.0,
    this.borderColor,
    this.backgroundColor,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? borderColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: borderColor ?? const Color(0x14FFFFFF), // uniform border with ~0.08 opacity (rgba(255,255,255,0.08))
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class EditProfileGradientButton extends StatelessWidget {
  const EditProfileGradientButton({
    required this.label,
    required this.onTap,
    this.isLoading = false,
    super.key,
  });

  final String label;
  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            EditProfileColors.primary,
            EditProfileColors.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: EditProfileColors.primary.withValues(alpha: 0.25),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            alignment: Alignment.center,
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
