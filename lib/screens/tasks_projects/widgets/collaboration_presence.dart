import 'package:flutter/material.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class CollaborationPresence extends StatelessWidget {
  const CollaborationPresence({super.key});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: DashboardColors.surfaceLow.withValues(alpha: .42),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: DashboardColors.primary.withValues(
                alpha: .10 + value * .10,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: DashboardColors.primary.withValues(alpha: .08),
                blurRadius: 34,
              ),
              BoxShadow(
                color: DashboardColors.tertiary.withValues(
                  alpha: .05 + value * .05,
                ),
                blurRadius: 46,
              ),
            ],
          ),
          child: Row(
            children: [
              const _StackedAvatars(),
              const SizedBox(width: 14),
              const Expanded(child: _PresenceCopy()),
              _TypingDots(animationValue: value),
            ],
          ),
        );
      },
    );
  }
}

class _StackedAvatars extends StatelessWidget {
  const _StackedAvatars();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 82,
      height: 42,
      child: Stack(
        clipBehavior: Clip.none,
        children: const [
          _PresenceAvatar(left: 0, label: 'A', color: DashboardColors.primary),
          _PresenceAvatar(
            left: 24,
            label: 'K',
            color: DashboardColors.secondary,
          ),
          _PresenceAvatar(
            left: 48,
            label: 'M',
            color: DashboardColors.tertiary,
          ),
        ],
      ),
    );
  }
}

class _PresenceAvatar extends StatelessWidget {
  const _PresenceAvatar({
    required this.left,
    required this.label,
    required this.color,
  });

  final double left;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: 4,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: DashboardColors.background,
            child: CircleAvatar(
              radius: 15,
              backgroundColor: color.withValues(alpha: .20),
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          Positioned(
            right: -1,
            bottom: -1,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: .35, end: 1),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder:
                  (context, value, _) => AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF7CFFB2),
                      border: Border.all(
                        color: DashboardColors.background,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF7CFFB2,
                          ).withValues(alpha: .40 * value),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PresenceCopy extends StatelessWidget {
  const _PresenceCopy();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Live collaboration',
          style: TextStyle(
            color: DashboardColors.onSurface,
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: .2,
          ),
        ),
        SizedBox(height: 4),
        Text(
          '3 active users • 8 live viewers',
          style: TextStyle(
            color: DashboardColors.onSurfaceVariant,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Alex is typing...',
          style: TextStyle(
            color: DashboardColors.tertiary,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _TypingDots extends StatelessWidget {
  const _TypingDots({required this.animationValue});

  final double animationValue;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (index) {
        final opacity = (.35 + animationValue * .65 - index * .14).clamp(
          .25,
          1.0,
        );
        return AnimatedContainer(
          duration: Duration(milliseconds: 180 + index * 40),
          margin: const EdgeInsets.only(left: 4),
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: DashboardColors.tertiary.withValues(alpha: opacity),
            boxShadow: [
              BoxShadow(
                color: DashboardColors.tertiary.withValues(alpha: .22),
                blurRadius: 10,
              ),
            ],
          ),
        );
      }),
    );
  }
}
