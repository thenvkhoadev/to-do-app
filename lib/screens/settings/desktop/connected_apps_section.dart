import 'package:flutter/material.dart';
import 'package:to_do_app/constants/dashboard_constants.dart';
import 'package:to_do_app/screens/settings/data/settings_mock_data.dart';
import 'package:to_do_app/screens/settings/widgets/settings_shared_widgets.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class ConnectedAppsSection extends StatelessWidget {
  const ConnectedAppsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsSectionTitle(
          title: 'Connected Apps',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4), decoration: BoxDecoration(color: DashboardColors.primaryContainer.withValues(alpha: .18), borderRadius: BorderRadius.circular(DashboardRadii.full)), child: const Text('LIVE', style: TextStyle(color: DashboardColors.primary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1))),
              const SizedBox(width: 12),
              const Text('View all', style: TextStyle(color: DashboardColors.primary, fontSize: 12, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
        const SizedBox(height: DashboardSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth < 720 ? 1 : 3;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: SettingsMockData.integrations.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, crossAxisSpacing: DashboardSpacing.md, mainAxisSpacing: DashboardSpacing.md, childAspectRatio: columns == 1 ? 2.4 : .92),
              itemBuilder: (context, index) => IntegrationCard(integration: SettingsMockData.integrations[index]),
            );
          },
        ),
      ],
    );
  }
}
