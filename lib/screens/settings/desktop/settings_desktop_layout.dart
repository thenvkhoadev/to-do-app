import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:to_do_app/constants/dashboard_constants.dart';
import 'package:to_do_app/screens/settings/desktop/account_security_section.dart';
import 'package:to_do_app/screens/settings/desktop/ai_optimization_panel.dart';
import 'package:to_do_app/screens/settings/desktop/appearance_panel.dart';
import 'package:to_do_app/screens/settings/desktop/connected_apps_section.dart';
import 'package:to_do_app/screens/settings/desktop/help_support_panel.dart';
import 'package:to_do_app/screens/settings/desktop/notifications_section.dart';
import 'package:to_do_app/widgets/dashboard/dashboard_enhancement_widgets.dart';
import 'package:to_do_app/screens/settings/widgets/settings_shared_widgets.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';
import 'package:to_do_app/widgets/dashboard/dashboard_shared.dart';

class SettingsDesktopLayout extends StatelessWidget {
  const SettingsDesktopLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _SettingsDesktopTopbar(),
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

class _SettingsDesktopTopbar extends StatelessWidget {
  const _SettingsDesktopTopbar();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
        child: Container(
          height: 66,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            color: DashboardColors.surface.withValues(alpha: .5),
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: .08)),
            ),
          ),
          child: Row(
            children: const [
              Text(
                'Settings',
                style: TextStyle(
                  color: DashboardColors.primary,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(width: 12),
              Text(
                '/ Dashboard',
                style: TextStyle(
                  color: DashboardColors.onSurfaceVariant,
                  fontSize: 15,
                ),
              ),
              Spacer(),
              _TopIcon(icon: Icons.notifications_none_rounded, badge: true),
              SizedBox(width: 12),
              _TopIcon(icon: Icons.bolt_rounded),
              SizedBox(width: 12),
              XPLevelCard(),
              SizedBox(width: 12),
              ProfileAvatar(),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopIcon extends StatelessWidget {
  const _TopIcon({required this.icon, this.badge = false});

  final IconData icon;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {},
            child: SizedBox(
              width: 42,
              height: 42,
              child: Icon(icon, color: DashboardColors.onSurface),
            ),
          ),
        ),
        if (badge)
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: DashboardColors.error,
              ),
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
