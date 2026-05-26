import 'dart:ui';

import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  const GlassContainer({required this.child, this.padding = const EdgeInsets.all(20), this.radius = 20, this.glow, this.opacity = .04, super.key});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? glow;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withValues(alpha: .09)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: .22), blurRadius: 24, offset: const Offset(0, 14)),
              if (glow != null) BoxShadow(color: glow!.withValues(alpha: .18), blurRadius: 30),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
