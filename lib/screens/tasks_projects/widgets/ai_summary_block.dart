import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class AiSummaryBlock extends StatelessWidget {
  const AiSummaryBlock({super.key});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(1.2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [
                DashboardColors.secondary.withValues(alpha: .22 + value * .10),
                DashboardColors.tertiary.withValues(alpha: .18),
                Colors.white.withValues(alpha: .04),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: DashboardColors.secondary.withValues(alpha: .10 + value * .06),
                blurRadius: 34,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: DashboardColors.tertiary.withValues(alpha: .08),
                blurRadius: 52,
              ),
            ],
          ),
          child: child,
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: DashboardColors.surfaceLow.withValues(alpha: .48),
              borderRadius: BorderRadius.circular(23),
              border: Border.all(color: Colors.white.withValues(alpha: .06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _AiSummaryHeader(),
                SizedBox(height: 16),
                _AiSummaryMetric(label: 'Estimated completion', value: '4h 20m'),
                SizedBox(height: 9),
                _AiSummaryMetric(label: 'Risk level', value: 'Medium'),
                SizedBox(height: 9),
                _AiSummaryMetric(label: 'Suggested focus window', value: '2PM - 5PM'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AiSummaryHeader extends StatelessWidget {
  const _AiSummaryHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                DashboardColors.secondary.withValues(alpha: .28),
                DashboardColors.tertiary.withValues(alpha: .18),
              ],
            ),
            border: Border.all(color: DashboardColors.tertiary.withValues(alpha: .24)),
            boxShadow: [BoxShadow(color: DashboardColors.tertiary.withValues(alpha: .16), blurRadius: 20)],
          ),
          child: const Icon(Icons.auto_awesome_rounded, color: DashboardColors.tertiary, size: 18),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'AI Summary',
            style: TextStyle(color: DashboardColors.onSurface, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: .2),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: DashboardColors.tertiary.withValues(alpha: .10),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: DashboardColors.tertiary.withValues(alpha: .20)),
          ),
          child: const Text('AI', style: TextStyle(color: DashboardColors.tertiary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
        ),
      ],
    );
  }
}

class _AiSummaryMetric extends StatelessWidget {
  const _AiSummaryMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(label, style: const TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w600))),
      Text(value, style: const TextStyle(color: DashboardColors.onSurface, fontSize: 12, fontWeight: FontWeight.w900)),
    ],
  );
}
