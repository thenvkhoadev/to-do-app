import 'package:flutter/material.dart';
import 'package:to_do_app/screens/analytics/data/analytics_mock_data.dart';
import 'package:to_do_app/screens/analytics/widgets/analytics_shared_widgets.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';
import 'package:to_do_app/widgets/dashboard/dashboard_shared.dart';

class AiInsightsPanel extends StatelessWidget {
  const AiInsightsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedHoverCard(
      glowColor: DashboardColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.flare_rounded, color: DashboardColors.primary),
              SizedBox(width: 8),
              Text(
                'AI Recommendations',
                style: TextStyle(
                  color: DashboardColors.onSurface,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          for (final insight in AnalyticsMockData.insights) ...[
            InsightCard(insight: insight),
            if (insight != AnalyticsMockData.insights.last)
              const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
