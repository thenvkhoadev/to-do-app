import 'package:flutter/material.dart';
import 'package:to_do_app/constants/dashboard_constants.dart';
import 'package:to_do_app/screens/analytics/desktop/analytics_desktop_layout.dart';
import 'package:to_do_app/screens/analytics/mobile/analytics_mobile_layout.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';
import 'package:to_do_app/widgets/dashboard/dashboard_shared.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({this.embeddedInDashboard = false, super.key});

  final bool embeddedInDashboard;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: DashboardTheme.dark(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final content = embeddedInDashboard || constraints.maxWidth >= DashboardBreakpoints.desktop ? const AnalyticsDesktopLayout() : const AnalyticsMobileLayout();
          if (embeddedInDashboard) return content;
          return DashboardScaffold(child: content);
        },
      ),
    );
  }
}
