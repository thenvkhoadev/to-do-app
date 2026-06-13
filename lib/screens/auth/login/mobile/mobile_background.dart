import 'package:flutter/material.dart';
import 'package:to_do_app/shared/widgets/stitch_shader_background.dart';

class MobileBackground extends StatelessWidget {
  final Widget child;
  const MobileBackground({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // WebGL-style pulsing space shader background
        const Positioned.fill(
          child: StitchShaderBackground(),
        ),
        // Content on top
        Positioned.fill(
          child: child,
        ),
      ],
    );
  }
}
