import 'package:flutter/material.dart';
import 'package:to_do_app/constants/dashboard_constants.dart';
import 'package:to_do_app/screens/analytics/widgets/analytics_shared_widgets.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';
import 'package:to_do_app/widgets/dashboard/dashboard_shared.dart';

class AnalyticsFocusScoreCard extends StatelessWidget {
  const AnalyticsFocusScoreCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedHoverCard(
      glowColor: DashboardColors.primary,
      child: Column(
        children: [
          const Row(children: [SectionTitle(label: 'Focus Efficiency', icon: Icons.radio_button_checked_rounded, color: DashboardColors.primary), Spacer(), Icon(Icons.more_vert_rounded, color: DashboardColors.onSurfaceVariant)]),
          const SizedBox(height: 24),
          const FocusGauge(value: .78, size: 238),
          const SizedBox(height: 22),
          Row(
            children: const [
              Expanded(child: _MiniStat(label: 'Concentration', value: '8.4/10', color: DashboardColors.primary)),
              SizedBox(width: 12),
              Expanded(child: _MiniStat(label: 'Consistency', value: 'High', color: DashboardColors.secondary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: .045), borderRadius: BorderRadius.circular(DashboardRadii.md), border: Border.all(color: Colors.white.withValues(alpha: .06))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label.toUpperCase(), style: const TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: .8)), const SizedBox(height: 6), Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900))]),
    );
  }
}
