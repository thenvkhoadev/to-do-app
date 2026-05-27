import 'package:flutter/material.dart';
import 'package:to_do_app/constants/dashboard_constants.dart';
import 'package:to_do_app/screens/analytics/data/analytics_mock_data.dart';
import 'package:to_do_app/screens/analytics/widgets/analytics_shared_widgets.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';
import 'package:to_do_app/widgets/dashboard/dashboard_shared.dart';

class CategoryBreakdown extends StatelessWidget {
  const CategoryBreakdown({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedHoverCard(
      glowColor: DashboardColors.secondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Task Velocity', style: TextStyle(color: DashboardColors.onSurface, fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          const Text('Output density by work category', style: TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: 12)),
          const SizedBox(height: 24),
          for (final item in AnalyticsMockData.velocity) ...[
            ProgressBarCard(category: item),
            if (item != AnalyticsMockData.velocity.last) const SizedBox(height: 17),
          ],
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: DashboardColors.primary.withValues(alpha: .06), borderRadius: BorderRadius.circular(DashboardRadii.md), border: Border.all(color: DashboardColors.primary.withValues(alpha: .12))),
            child: const Text('Design Systems has the highest velocity. Protect this category during morning sprint windows.', style: TextStyle(color: DashboardColors.onSurfaceVariant, height: 1.45, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
