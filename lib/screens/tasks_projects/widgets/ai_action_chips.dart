import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class AiActionChips extends StatelessWidget {
  const AiActionChips({super.key});

  static const _actions = [
    ('Generate Subtasks', Icons.auto_awesome_rounded),
    ('Optimize Workflow', Icons.route_rounded),
    ('Summarize Docs', Icons.summarize_rounded),
    ('Auto Schedule', Icons.event_available_rounded),
    ('Estimate Workload', Icons.query_stats_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: DashboardColors.surfaceLow.withValues(alpha: .36),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: DashboardColors.tertiary.withValues(alpha: .10),
            ),
            boxShadow: [
              BoxShadow(
                color: DashboardColors.primary.withValues(alpha: .07),
                blurRadius: 32,
              ),
              BoxShadow(
                color: DashboardColors.tertiary.withValues(alpha: .05),
                blurRadius: 44,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.bolt_rounded,
                    color: DashboardColors.tertiary,
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'AI ACTIONS',
                    style: TextStyle(
                      color: DashboardColors.onSurface,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    _actions
                        .map(
                          (action) =>
                              _AiActionChip(label: action.$1, icon: action.$2),
                        )
                        .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AiActionChip extends StatelessWidget {
  const _AiActionChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: .35, end: 1),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
        builder:
            (context, value, child) => AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: LinearGradient(
                  colors: [
                    DashboardColors.primary.withValues(alpha: .10),
                    DashboardColors.tertiary.withValues(alpha: .08),
                  ],
                ),
                border: Border.all(
                  color: DashboardColors.tertiary.withValues(
                    alpha: .14 + value * .06,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: DashboardColors.tertiary.withValues(
                      alpha: .06 + value * .04,
                    ),
                    blurRadius: 18,
                  ),
                ],
              ),
              child: child,
            ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: DashboardColors.tertiary, size: 15),
            const SizedBox(width: 7),
            Text(
              label,
              style: const TextStyle(
                color: DashboardColors.onSurface,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
