import 'package:flutter/material.dart';
import 'package:to_do_app/constants/dashboard_constants.dart';
import 'package:to_do_app/screens/settings/data/settings_mock_data.dart';
import 'package:to_do_app/screens/settings/widgets/settings_shared_widgets.dart';
import 'package:to_do_app/widgets/dashboard/dashboard_shared.dart';

class MobileNotifications extends StatelessWidget {
  const MobileNotifications({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SettingsSectionTitle(
            title: 'Notifications',
            icon: Icons.notifications_active_rounded,
          ),
          const SizedBox(height: DashboardSpacing.md),
          for (final option in SettingsMockData.notifications) ...[
            ToggleSettingTile(option: option),
            if (option != SettingsMockData.notifications.last)
              const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
