import 'package:flutter/material.dart';
import 'package:to_do_app/constants/dashboard_constants.dart';
import 'package:to_do_app/screens/settings/data/settings_mock_data.dart';
import 'package:to_do_app/screens/settings/widgets/settings_shared_widgets.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class MobileConnectedApps extends StatelessWidget {
  const MobileConnectedApps({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SettingsSectionTitle(title: 'Connected Apps'),
        const SizedBox(height: DashboardSpacing.md),
        SizedBox(
          height: 230,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: SettingsMockData.integrations.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, index) => SizedBox(width: 220, child: IntegrationCard(integration: SettingsMockData.integrations[index])),
          ),
        ),
        const SizedBox(height: 8),
        const Text('Swipe to manage integrations.', style: TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: 12)),
      ],
    );
  }
}
