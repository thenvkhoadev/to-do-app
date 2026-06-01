import 'package:flutter/material.dart';
import 'package:to_do_app/constants/dashboard_constants.dart';
import 'package:to_do_app/screens/support/desktop/support_desktop_content.dart';
import 'package:to_do_app/screens/support/mobile/support_mobile_content.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';
import 'package:to_do_app/widgets/dashboard/dashboard_shared.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({this.embeddedInDashboard = false, super.key});

  final bool embeddedInDashboard;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: DashboardTheme.dark(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final content =
              constraints.maxWidth >= DashboardBreakpoints.mobile
                  ? const SupportDesktopContent()
                  : const SupportMobileContent();
          if (embeddedInDashboard) return content;
          return DashboardScaffold(child: content);
        },
      ),
    );
  }
}
