import 'package:flutter/material.dart';
import 'package:to_do_app/screens/analytics/data/analytics_mock_data.dart';
import 'package:to_do_app/screens/analytics/widgets/analytics_shared_widgets.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';
import 'package:to_do_app/widgets/dashboard/dashboard_shared.dart';

class MobileCategoryCard extends StatelessWidget {
  const MobileCategoryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Top Categories', style: TextStyle(color: DashboardColors.onSurface, fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 18),
          for (final category in AnalyticsMockData.categories) ...[
            ProgressBarCard(category: category),
            if (category != AnalyticsMockData.categories.last) const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}
