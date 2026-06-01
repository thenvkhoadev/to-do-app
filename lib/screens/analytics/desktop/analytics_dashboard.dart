import 'package:flutter/material.dart';
import 'package:to_do_app/constants/dashboard_constants.dart';
import 'package:to_do_app/screens/analytics/data/analytics_mock_data.dart';
import 'package:to_do_app/screens/analytics/desktop/ai_insights_panel.dart';
import 'package:to_do_app/screens/analytics/desktop/analytics_sidebar_panel.dart';
import 'package:to_do_app/screens/analytics/desktop/category_breakdown.dart';
import 'package:to_do_app/screens/analytics/desktop/focus_score_card.dart';
import 'package:to_do_app/screens/analytics/desktop/productivity_chart.dart';
import 'package:to_do_app/screens/analytics/widgets/analytics_shared_widgets.dart';

class AnalyticsDashboard extends StatelessWidget {
  const AnalyticsDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 1050;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AnalyticsHeader(),
            const SizedBox(height: DashboardSpacing.lg),
            _KpiGrid(compact: compact),
            const SizedBox(height: DashboardSpacing.md),
            if (compact)
              const Column(
                children: [
                  AnalyticsFocusScoreCard(),
                  SizedBox(height: DashboardSpacing.md),
                  ProductivityChart(),
                  SizedBox(height: DashboardSpacing.md),
                  CategoryBreakdown(),
                  SizedBox(height: DashboardSpacing.md),
                  AiInsightsPanel(),
                  SizedBox(height: DashboardSpacing.md),
                  AnalyticsSidebarPanel(),
                ],
              )
            else
              const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: Column(
                      children: [
                        AnalyticsFocusScoreCard(),
                        SizedBox(height: DashboardSpacing.md),
                        AnalyticsSidebarPanel(),
                      ],
                    ),
                  ),
                  SizedBox(width: DashboardSpacing.md),
                  Expanded(
                    flex: 8,
                    child: Column(
                      children: [
                        ProductivityChart(),
                        SizedBox(height: DashboardSpacing.md),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: CategoryBreakdown()),
                            SizedBox(width: DashboardSpacing.md),
                            Expanded(child: AiInsightsPanel()),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: AnalyticsMockData.metrics.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: compact ? 2 : 4,
        crossAxisSpacing: DashboardSpacing.md,
        mainAxisSpacing: DashboardSpacing.md,
        childAspectRatio: compact ? 1.65 : 1.45,
      ),
      itemBuilder:
          (context, index) =>
              MetricCard(metric: AnalyticsMockData.metrics[index]),
    );
  }
}
