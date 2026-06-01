import 'package:flutter/material.dart';
import 'package:to_do_app/constants/dashboard_constants.dart';
import 'package:to_do_app/screens/analytics/data/analytics_mock_data.dart';
import 'package:to_do_app/screens/analytics/models/analytics_models.dart';
import 'package:to_do_app/screens/analytics/widgets/analytics_shared_widgets.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';
import 'package:to_do_app/widgets/dashboard/dashboard_shared.dart';

class AnalyticsSidebarPanel extends StatelessWidget {
  const AnalyticsSidebarPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedHoverCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Category Breakdown',
            style: TextStyle(
              color: DashboardColors.onSurface,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 20),
          for (final item in AnalyticsMockData.categories) ...[
            ProgressBarCard(category: item),
            if (item != AnalyticsMockData.categories.last)
              const SizedBox(height: 18),
          ],
          const SizedBox(height: 26),
          Container(height: 1, color: Colors.white.withValues(alpha: .07)),
          const SizedBox(height: 22),
          const Text(
            'Timeline',
            style: TextStyle(
              color: DashboardColors.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          for (final activity in AnalyticsMockData.activities)
            _ActivityRow(activity: activity),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.activity});

  final AnalyticsActivity activity;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: activity.color.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(DashboardRadii.sm),
            ),
            child: Icon(activity.icon, color: activity.color, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: const TextStyle(
                    color: DashboardColors.onSurface,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  activity.time,
                  style: const TextStyle(
                    color: DashboardColors.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
