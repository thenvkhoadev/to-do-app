import 'package:flutter/material.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class SmartProgressTimeline extends StatelessWidget {
  const SmartProgressTimeline({super.key});

  static const _stages = [
    'Created',
    'Research',
    'In Progress',
    'Review',
    'Completed',
  ];
  static const _activeIndex = 2;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: DashboardColors.surfaceLow.withValues(alpha: .42),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: DashboardColors.tertiary.withValues(
                alpha: .12 + value * .08,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: DashboardColors.primary.withValues(alpha: .08),
                blurRadius: 36,
              ),
              BoxShadow(
                color: DashboardColors.tertiary.withValues(
                  alpha: .06 + value * .04,
                ),
                blurRadius: 48,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: DashboardColors.tertiary,
                      boxShadow: [
                        BoxShadow(
                          color: DashboardColors.tertiary.withValues(
                            alpha: .44,
                          ),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'SMART PROGRESS',
                    style: TextStyle(
                      color: DashboardColors.onSurface,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${((_activeIndex + 1) / _stages.length * 100).round()}%',
                    style: const TextStyle(
                      color: DashboardColors.tertiary,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Column(
                children: List.generate(_stages.length, (index) {
                  final completed = index < _activeIndex;
                  final active = index == _activeIndex;
                  final last = index == _stages.length - 1;
                  return _TimelineStage(
                    label: _stages[index],
                    completed: completed,
                    active: active,
                    last: last,
                    animationValue: value,
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TimelineStage extends StatelessWidget {
  const _TimelineStage({
    required this.label,
    required this.completed,
    required this.active,
    required this.last,
    required this.animationValue,
  });

  final String label;
  final bool completed;
  final bool active;
  final bool last;
  final double animationValue;

  @override
  Widget build(BuildContext context) {
    final color =
        active
            ? DashboardColors.tertiary
            : completed
            ? DashboardColors.primary
            : DashboardColors.outlineVariant;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: active ? 18 : 14,
              height: active ? 18 : 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: active || completed ? .95 : .28),
                border: Border.all(
                  color: color.withValues(alpha: active ? .95 : .45),
                  width: active ? 2 : 1,
                ),
                boxShadow:
                    active
                        ? [
                          BoxShadow(
                            color: color.withValues(
                              alpha: .52 * animationValue,
                            ),
                            blurRadius: 22,
                            spreadRadius: 2,
                          ),
                        ]
                        : completed
                        ? [
                          BoxShadow(
                            color: color.withValues(alpha: .22),
                            blurRadius: 12,
                          ),
                        ]
                        : null,
              ),
              child:
                  completed
                      ? const Icon(
                        Icons.check_rounded,
                        size: 10,
                        color: DashboardColors.background,
                      )
                      : null,
            ),
            if (!last)
              AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                width: 2,
                height: 28,
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      color.withValues(alpha: completed || active ? .62 : .18),
                      DashboardColors.outlineVariant.withValues(alpha: .12),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            margin: EdgeInsets.only(bottom: last ? 0 : 14),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color:
                  active
                      ? DashboardColors.tertiary.withValues(alpha: .08)
                      : Colors.white.withValues(alpha: .02),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withValues(alpha: active ? .22 : .08),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color:
                          active || completed
                              ? DashboardColors.onSurface
                              : DashboardColors.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: active ? FontWeight.w900 : FontWeight.w700,
                    ),
                  ),
                ),
                if (active)
                  const Text(
                    'ACTIVE',
                    style: TextStyle(
                      color: DashboardColors.tertiary,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
