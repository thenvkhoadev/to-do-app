import 'package:flutter/material.dart';
import 'package:to_do_app/constants/dashboard_constants.dart';
import 'package:to_do_app/screens/settings/widgets/settings_shared_widgets.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';
import 'package:to_do_app/widgets/dashboard/dashboard_shared.dart';

class AppearancePanel extends StatelessWidget {
  const AppearancePanel({super.key});

  @override
  Widget build(BuildContext context) {
    return const GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Appearance',
            style: TextStyle(
              color: DashboardColors.onSurface,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: DashboardSpacing.md),
          AppearanceOptionTile(
            title: 'Dark Mode',
            icon: Icons.dark_mode_rounded,
            selected: true,
          ),
          SizedBox(height: 10),
          AppearanceOptionTile(
            title: 'Light Mode',
            icon: Icons.light_mode_rounded,
            selected: false,
          ),
        ],
      ),
    );
  }
}
