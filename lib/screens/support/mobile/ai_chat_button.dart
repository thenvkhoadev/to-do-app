import 'package:flutter/material.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class AIChatButton extends StatelessWidget {
  const AIChatButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [DashboardColors.primary, DashboardColors.primaryContainer]), borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: DashboardColors.primary.withValues(alpha: .26), blurRadius: 30)]),
      child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.auto_awesome_rounded, color: DashboardColors.onPrimary), SizedBox(width: 10), Text('Chat with AI Assistant', style: TextStyle(color: DashboardColors.onPrimary, fontWeight: FontWeight.w900))]),
    );
  }
}
