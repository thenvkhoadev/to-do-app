import 'package:flutter/material.dart';
import 'package:to_do_app/screens/analytics/data/analytics_mock_data.dart';
import 'package:to_do_app/screens/analytics/widgets/analytics_shared_widgets.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class MobileAiInsight extends StatelessWidget {
  const MobileAiInsight({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('AI Insights', style: TextStyle(color: DashboardColors.onSurface, fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        InsightCard(insight: AnalyticsMockData.insights[0]),
        const SizedBox(height: 12),
        InsightCard(insight: AnalyticsMockData.insights[1]),
      ],
    );
  }
}
