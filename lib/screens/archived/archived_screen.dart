import 'package:flutter/material.dart';
import 'package:to_do_app/screens/archived/desktop/desktop_archived_view.dart';
import 'package:to_do_app/screens/archived/mobile/mobile_archived_view.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class ArchivedScreen extends StatelessWidget {
  const ArchivedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: DashboardTheme.dark(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 1200) {
            return const DesktopArchivedView();
          }
          return const MobileArchivedView();
        },
      ),
    );
  }
}
