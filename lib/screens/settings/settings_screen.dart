import 'package:flutter/material.dart';
import 'package:to_do_app/screens/settings/desktop/settings_desktop_layout.dart';
import 'package:to_do_app/screens/settings/mobile/settings_mobile_layout.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';
import 'package:to_do_app/widgets/dashboard/dashboard_shared.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({this.embeddedInDashboard = false, super.key});

  final bool embeddedInDashboard;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: DashboardTheme.dark(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final content = constraints.maxWidth >= 1100 ? const SettingsDesktopLayout() : const SettingsMobileLayout();
          if (embeddedInDashboard) return content;
          return DashboardScaffold(child: content);
        },
      ),
    );
  }
}
