import 'package:flutter/material.dart';
import 'package:to_do_app/core/theme/nexus_colors.dart';

class NexusBackground extends StatelessWidget {
  const NexusBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: ColoredBox(color: NexusColors.background)),
        Positioned(
          top: -160,
          left: -120,
          child: _GlowOrb(size: 420, color: NexusColors.primaryContainer.withValues(alpha: 0.22)),
        ),
        Positioned(
          right: -140,
          top: MediaQuery.sizeOf(context).height * 0.18,
          child: _GlowOrb(size: 360, color: NexusColors.secondary.withValues(alpha: 0.12)),
        ),
        Positioned.fill(child: CustomPaint(painter: _GridPainter())),
        Positioned.fill(child: child),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: 120, spreadRadius: 70)],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.025)
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 42) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 42) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
