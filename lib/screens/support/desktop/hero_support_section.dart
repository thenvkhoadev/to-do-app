import 'package:flutter/material.dart';
import 'package:to_do_app/constants/dashboard_constants.dart';
import 'package:to_do_app/screens/support/widgets/support_shared_widgets.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class HeroSupportSection extends StatelessWidget {
  const HeroSupportSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(top: -120, child: Container(width: 620, height: 320, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: DashboardColors.primary.withValues(alpha: .14), blurRadius: 120, spreadRadius: 40)]))),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 64),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(color: DashboardColors.primary.withValues(alpha: .10), borderRadius: BorderRadius.circular(DashboardRadii.full), border: Border.all(color: DashboardColors.primary.withValues(alpha: .22))),
                child: Row(mainAxisSize: MainAxisSize.min, children: const [Icon(Icons.auto_awesome_rounded, color: DashboardColors.primary, size: 17), SizedBox(width: 8), Text('INTELLIGENT SUPPORT', style: TextStyle(color: DashboardColors.primary, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.4))]),
              ),
              const SizedBox(height: 24),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: const Text('How can we help you achieve flow today?', textAlign: TextAlign.center, style: TextStyle(color: DashboardColors.onSurface, fontSize: 48, height: 1.08, fontWeight: FontWeight.w900, letterSpacing: -1.2)),
              ),
              const SizedBox(height: 30),
              ConstrainedBox(constraints: const BoxConstraints(maxWidth: 760), child: const SupportSearchBar()),
            ],
          ),
        ),
      ],
    );
  }
}
