import 'package:flutter/material.dart';
import 'package:to_do_app/theme/auth_theme.dart';
import 'package:to_do_app/widgets/auth/auth_header.dart';
import 'package:to_do_app/widgets/common/glass_card.dart';

class LeftHeroSection extends StatelessWidget {
  const LeftHeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AuthColors.surfaceContainerLowest,
      child: Stack(
        children: [
          const _FocusBackdrop(),
          Padding(
            padding: const EdgeInsets.all(64),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AuthHeader(),
                const Spacer(),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 512),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'THE FUTURE OF DEEP WORK',
                        style: AuthTextStyles.labelCaps.copyWith(
                          color: AuthColors.primary,
                          letterSpacing: 2.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Master your focus with machine intelligence.',
                        style: AuthTextStyles.display,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'NEXUS AI creates a premium command center for high-performing professionals by automating routine work and highlighting what matters most.',
                        style: AuthTextStyles.bodyLarge,
                      ),
                      const SizedBox(height: 32),
                      const _AiSuggestionCard(),
                    ],
                  ),
                ),
                const Spacer(),
                const _StatsRow(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AiSuggestionCard extends StatelessWidget {
  const _AiSuggestionCard();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 16,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AuthColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'AI SUGGESTION',
                style: AuthTextStyles.labelSmall.copyWith(
                  color: AuthColors.primary,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Text('98% MATCH', style: AuthTextStyles.labelCaps),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '"You are most productive now. Postpone the status meeting to prioritize the Architecture Design task."',
            style: AuthTextStyles.bodyMedium.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.6,
      child: Row(
        children: [
          const _StatBlock(value: '12k+', label: 'Focused Users'),
          Container(
            width: 1,
            height: 40,
            margin: const EdgeInsets.symmetric(horizontal: 32),
            color: AuthColors.outlineVariant.withValues(alpha: 0.3),
          ),
          const _StatBlock(value: '40%', label: 'Efficiency Gain'),
        ],
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: AuthTextStyles.headlineMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(label, style: AuthTextStyles.labelSmall),
      ],
    );
  }
}

class _FocusBackdrop extends StatelessWidget {
  const _FocusBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned(
          top: 160,
          left: 120,
          child: _HeroGlow(size: 500, color: Color(0x1AC0C1FF), blur: 120),
        ),
        const Positioned(
          bottom: 140,
          right: 120,
          child: _HeroGlow(size: 400, color: Color(0x1A6F00BE), blur: 100),
        ),
        Positioned.fill(child: CustomPaint(painter: _DotGridPainter())),
      ],
    );
  }
}

class _HeroGlow extends StatelessWidget {
  const _HeroGlow({
    required this.size,
    required this.color,
    required this.blur,
  });

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

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()..color = AuthColors.outlineVariant.withValues(alpha: 0.2);
    for (var x = 0.0; x < size.width; x += 40) {
      for (var y = 0.0; y < size.height; y += 40) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
