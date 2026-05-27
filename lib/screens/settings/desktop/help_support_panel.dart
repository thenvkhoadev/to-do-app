import 'package:flutter/material.dart';
import 'package:to_do_app/constants/dashboard_constants.dart';
import 'package:to_do_app/screens/settings/data/settings_mock_data.dart';
import 'package:to_do_app/screens/settings/widgets/settings_shared_widgets.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';
import 'package:to_do_app/widgets/dashboard/dashboard_shared.dart';

class HelpSupportPanel extends StatelessWidget {
  const HelpSupportPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Help & Support', style: TextStyle(color: DashboardColors.onSurface, fontSize: 21, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          for (final link in SettingsMockData.support) SupportLinkTile(link: link),
          const SizedBox(height: DashboardSpacing.md),
          Container(height: 1, color: Colors.white.withValues(alpha: .06)),
          const SizedBox(height: DashboardSpacing.md),
          const Text('TaskFlow AI v2.4.1-stable', textAlign: TextAlign.center, style: TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.1)),
        ],
      ),
    );
  }
}
