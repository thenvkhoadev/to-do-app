import 'package:flutter/material.dart';
import 'package:to_do_app/constants/dashboard_constants.dart';
import 'package:to_do_app/screens/support/mobile/ai_chat_button.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';
import 'package:to_do_app/widgets/dashboard/dashboard_shared.dart';

class MobileSupportActions extends StatelessWidget {
  const MobileSupportActions({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AIChatButton(),
        SizedBox(height: DashboardSpacing.sm),
        GlassCard(
          radius: DashboardRadii.lg,
          padding: EdgeInsets.all(18),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.mail_rounded, color: DashboardColors.onSurface), SizedBox(width: 10), Text('Email Support', style: TextStyle(color: DashboardColors.onSurface, fontWeight: FontWeight.w900))]),
        ),
      ],
    );
  }
}
