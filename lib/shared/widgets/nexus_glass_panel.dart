import 'package:flutter/material.dart';
import 'package:to_do_app/core/theme/nexus_colors.dart';

class NexusGlassPanel extends StatelessWidget {
  const NexusGlassPanel({
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 24,
    this.borderColor,
    this.glowColor,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? borderColor;
  final Color? glowColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: NexusColors.surfaceContainer.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          if (glowColor != null) BoxShadow(color: glowColor!, blurRadius: 42, spreadRadius: 1),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.26),
            blurRadius: 32,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: child,
    );
  }
}
