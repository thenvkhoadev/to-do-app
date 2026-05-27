import 'package:flutter/material.dart';
import 'package:to_do_app/constants/dashboard_constants.dart';
import 'package:to_do_app/screens/settings/data/settings_mock_data.dart';
import 'package:to_do_app/screens/settings/widgets/settings_shared_widgets.dart';
import 'package:to_do_app/widgets/dashboard/dashboard_shared.dart';

class MobileSecuritySection extends StatelessWidget {
  const MobileSecuritySection({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SettingsSectionTitle(title: 'Account Security', icon: Icons.security_rounded),
          const SizedBox(height: DashboardSpacing.md),
          for (final action in SettingsMockData.security) ...[
            SecurityActionCard(action: action),
            if (action != SettingsMockData.security.last) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
