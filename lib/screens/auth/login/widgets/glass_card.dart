import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:to_do_app/screens/auth/login/theme/login_theme.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({
    required this.child,
    this.radius = 28.0,
    this.padding,
    super.key,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30.0, sigmaY: 30.0),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: const Color(0x990D1322), // rgba(13, 19, 34, 0.6)
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: LoginColors.glassStroke,
              width: 1.0,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
