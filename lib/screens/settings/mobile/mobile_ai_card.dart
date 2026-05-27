import 'package:flutter/material.dart';
import 'package:to_do_app/constants/dashboard_constants.dart';
import 'package:to_do_app/screens/settings/desktop/appearance_panel.dart';
import 'package:to_do_app/screens/settings/desktop/help_support_panel.dart';
import 'package:to_do_app/screens/settings/widgets/settings_shared_widgets.dart';

class MobileAiCard extends StatelessWidget {
  const MobileAiCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppearancePanel(),
        SizedBox(height: DashboardSpacing.md),
        AiOptimizationCard(),
        SizedBox(height: DashboardSpacing.md),
        HelpSupportPanel(),
      ],
    );
  }
}
