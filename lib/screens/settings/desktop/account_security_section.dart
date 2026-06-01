import 'package:flutter/material.dart';
import 'package:to_do_app/constants/dashboard_constants.dart';
import 'package:to_do_app/screens/settings/data/settings_mock_data.dart';
import 'package:to_do_app/screens/settings/widgets/settings_shared_widgets.dart';
import 'package:to_do_app/widgets/dashboard/dashboard_shared.dart';

class AccountSecuritySection extends StatelessWidget {
  const AccountSecuritySection({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SettingsSectionTitle(
            title: 'Account Security',
            icon: Icons.security_rounded,
          ),
          const SizedBox(height: DashboardSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns = constraints.maxWidth >= 620;
              if (!twoColumns) {
                return Column(
                  children: [
                    for (final action in SettingsMockData.security) ...[
                      SecurityActionCard(action: action),
                      if (action != SettingsMockData.security.last)
                        const SizedBox(height: 12),
                    ],
                  ],
                );
              }
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: SettingsMockData.security.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 3.3,
                ),
                itemBuilder:
                    (context, index) => SecurityActionCard(
                      action: SettingsMockData.security[index],
                    ),
              );
            },
          ),
        ],
      ),
    );
  }
}
