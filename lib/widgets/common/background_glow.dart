import 'package:flutter/material.dart';
import 'package:to_do_app/theme/auth_theme.dart';

class BackgroundGlow extends StatelessWidget {
  const BackgroundGlow({super.key, required this.isDesktop});

  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Stack(
      children: [
        const Positioned.fill(child: ColoredBox(color: AuthColors.background)),
        if (isDesktop) ...[
          Positioned(
            top: -size.height * 0.12,
            right: -size.width * 0.04,
            child: const _GlowOrb(
              size: 400,
              color: Color(0x0DDDB7FF),
              blur: 120,
            ),
          ),
          Positioned(
            bottom: 0,
            left: size.width * 0.5,
            right: 0,
            child: const _BottomBeam(),
          ),
        ] else ...[
          const Positioned(
            top: -120,
            left: -120,
            child: _GlowOrb(size: 360, color: Color(0x1AC0C1FF), blur: 120),
          ),
          const Positioned(
            bottom: -110,
            right: -100,
            child: _GlowOrb(size: 320, color: Color(0x1A6F00BE), blur: 100),
          ),
          const Positioned(
            left: 80,
            right: 80,
            bottom: 0,
            child: _BottomBeam(),
          ),
        ],
      ],
    );
  }
}

class FloatingGlowOrb extends StatelessWidget {
  const FloatingGlowOrb({
    super.key,
    required this.size,
    required this.color,
    required this.blur,
  });

  final double size;
  final Color color;
  final double blur;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(seconds: 6),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        final offset = 18 * (value <= 0.5 ? value : 1 - value);
        return Transform.translate(offset: Offset(0, -offset), child: child);
      },
      onEnd: () {},
      child: _GlowOrb(size: size, color: color, blur: blur),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color, required this.blur});

  final double size;
  final Color color;
  final double blur;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color, blurRadius: blur, spreadRadius: blur / 3),
        ],
      ),
    );
  }
}

class _BottomBeam extends StatelessWidget {
  const _BottomBeam();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            AuthColors.primary.withValues(alpha: 0.4),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}
