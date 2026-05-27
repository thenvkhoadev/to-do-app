import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:to_do_app/constants/dashboard_constants.dart';
import 'package:to_do_app/screens/settings/mobile/mobile_ai_card.dart';
import 'package:to_do_app/screens/settings/mobile/mobile_bottom_navigation.dart';
import 'package:to_do_app/screens/settings/mobile/mobile_connected_apps.dart';
import 'package:to_do_app/screens/settings/mobile/mobile_notifications.dart';
import 'package:to_do_app/screens/settings/mobile/mobile_security_section.dart';
import 'package:to_do_app/screens/settings/widgets/settings_shared_widgets.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';
import 'package:to_do_app/widgets/dashboard/dashboard_shared.dart';

class SettingsMobileLayout extends StatelessWidget {
  const SettingsMobileLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Stack(
      children: [
        Positioned.fill(
          child: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 92)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(DashboardSpacing.md, 0, DashboardSpacing.md, 136),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: const [
                      SettingsHeader(compact: true),
                      SizedBox(height: DashboardSpacing.lg),
                      MobileConnectedApps(),
                      SizedBox(height: DashboardSpacing.md),
                      MobileNotifications(),
                      SizedBox(height: DashboardSpacing.md),
                      MobileSecuritySection(),
                      SizedBox(height: DashboardSpacing.md),
                      MobileAiCard(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const Positioned(top: 0, left: 0, right: 0, child: _SettingsMobileTopBar()),
        Positioned(left: 0, right: 0, bottom: 0, child: SettingsMobileBottomNavigation(bottomInset: bottomInset)),
      ],
    );
  }
}

class _SettingsMobileTopBar extends StatelessWidget {
  const _SettingsMobileTopBar();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
          child: Container(
            height: 66,
            padding: const EdgeInsets.symmetric(horizontal: DashboardSpacing.md),
            decoration: BoxDecoration(color: DashboardColors.surface.withValues(alpha: .48), border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: .08)))),
            child: const Row(children: [ProfileAvatar(radius: 19), SizedBox(width: 12), Expanded(child: Text('Settings', style: TextStyle(color: DashboardColors.primary, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -.5))), SizedBox(width: 8), Icon(Icons.settings_rounded, color: DashboardColors.primary)]),
          ),
        ),
      ),
    );
  }
}
