import 'package:flutter/material.dart';
import 'package:to_do_app/screens/analytics/data/analytics_mock_data.dart';
import 'package:to_do_app/screens/analytics/widgets/analytics_shared_widgets.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';
import 'package:to_do_app/widgets/dashboard/dashboard_shared.dart';

class MobileChartCard extends StatelessWidget {
  const MobileChartCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const GlassCard(
      glowColor: DashboardColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Deep Work Trend',
                style: TextStyle(
                  color: DashboardColors.onSurface,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(width: 8),
              _PulseDot(),
            ],
          ),
          SizedBox(height: 18),
          SizedBox(
            height: 168,
            child: LineChart(
              points: AnalyticsMockData.focusTrend,
              summary:
                  'Deep work trend rises through Friday and tapers on Sunday.',
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ChartStat(
                  label: 'Peak Session',
                  value: '4h 12m',
                  color: DashboardColors.primary,
                ),
              ),
              _ChartStat(
                label: 'Daily Avg',
                value: '2.8 hrs',
                color: DashboardColors.onSurface,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PulseDot extends StatelessWidget {
  const _PulseDot();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: .55, end: 1),
      duration: const Duration(seconds: 2),
      builder:
          (context, value, child) => Transform.scale(
            scale: value,
            child: Opacity(opacity: value, child: child),
          ),
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: DashboardColors.primary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _ChartStat extends StatelessWidget {
  const _ChartStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: DashboardColors.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
