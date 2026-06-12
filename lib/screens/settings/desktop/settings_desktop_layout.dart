import 'package:flutter/material.dart';
import 'package:to_do_app/constants/dashboard_constants.dart';
import 'package:to_do_app/screens/settings/desktop/account_security_section.dart';
import 'package:to_do_app/screens/settings/desktop/ai_optimization_panel.dart';
import 'package:to_do_app/screens/settings/desktop/appearance_panel.dart';
import 'package:to_do_app/screens/settings/desktop/connected_apps_section.dart';
import 'package:to_do_app/screens/settings/desktop/help_support_panel.dart';
import 'package:to_do_app/screens/settings/desktop/notifications_section.dart';
import 'package:to_do_app/screens/settings/widgets/settings_shared_widgets.dart';
import 'package:to_do_app/widgets/dashboard/desktop_dashboard_widgets.dart';

class SettingsDesktopLayout extends StatelessWidget {
  const SettingsDesktopLayout({super.key});

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
                      child: const _SettingsDesktopContent(),
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

class _SettingsDesktopContent extends StatelessWidget {
  const _SettingsDesktopContent();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 1050;
        final main = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            SettingsHeader(),
            SizedBox(height: DashboardSpacing.lg),
            ConnectedAppsSection(),
            SizedBox(height: DashboardSpacing.lg),
            NotificationsSection(),
            SizedBox(height: DashboardSpacing.md),
            AccountSecuritySection(),
          ],
        );
        final side = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            AppearancePanel(),
            SizedBox(height: DashboardSpacing.md),
            AiOptimizationPanel(),
            SizedBox(height: DashboardSpacing.md),
            HelpSupportPanel(),
          ],
        );

        if (stacked) {
          return Column(
            children: [main, const SizedBox(height: DashboardSpacing.md), side],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 8, child: main),
            const SizedBox(width: DashboardSpacing.md),
            Expanded(flex: 4, child: side),
          ],
        );
      },
    );
  }
}
