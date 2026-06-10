import 'package:flutter/material.dart';
import 'package:to_do_app/constants/dashboard_constants.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';
import 'package:to_do_app/widgets/dashboard/dashboard_shared.dart';
import 'package:to_do_app/widgets/dashboard/desktop_dashboard_widgets.dart';
import 'package:to_do_app/widgets/dashboard/mobile_dashboard_widgets.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: DashboardTheme.dark(),
      child: DashboardScaffold(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            MediaQuery.sizeOf(context);

            if (width >= DashboardBreakpoints.desktop) {
              return DesktopDashboardLayout(initialIndex: initialIndex);
            }

            return const MobileDashboardLayout();
          },
        ),
      ),
    );
  }
}
