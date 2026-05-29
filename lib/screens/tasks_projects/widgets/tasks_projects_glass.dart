import 'dart:ui';

import 'package:flutter/material.dart';

class TasksProjectsGlass extends StatelessWidget {
  const TasksProjectsGlass({
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.radius = 12,
    this.borderColor,
    this.glowColor,
    this.dashed = false,
    this.fillAlpha = .03,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? borderColor;
  final Color? glowColor;
  final bool dashed;
  final double fillAlpha;

  @override
  Widget build(BuildContext context) {
    final border = borderColor ?? Colors.white.withValues(alpha: .08);

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: fillAlpha),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: border),
            boxShadow:
                glowColor == null
                    ? null
                    : [
                      BoxShadow(
                        color: glowColor!.withValues(alpha: .15),
                        blurRadius: 30,
                      ),
                    ],
          ),
          foregroundDecoration:
              dashed
                  ? BoxDecoration(
                    borderRadius: BorderRadius.circular(radius),
                    border: Border.all(color: border, style: BorderStyle.solid),
                  )
                  : null,
          child: child,
        ),
      ),
    );
  }
}
