import 'package:flutter/material.dart';
import 'package:to_do_app/constants/dashboard_constants.dart';
import 'package:to_do_app/screens/analytics/desktop/analytics_dashboard.dart';
import 'package:to_do_app/widgets/dashboard/desktop_dashboard_widgets.dart';

class AnalyticsDesktopLayout extends StatelessWidget {
  const AnalyticsDesktopLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const DesktopTopbar(),
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(DashboardSpacing.lg),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: DashboardSpacing.desktopMaxWidth,
                      ),
                      child: const AnalyticsDashboard(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
