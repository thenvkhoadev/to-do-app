import 'package:flutter/material.dart';
import 'package:to_do_app/screens/analytics/widgets/analytics_shared_widgets.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class MobileFocusScore extends StatelessWidget {
  const MobileFocusScore({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        FocusGauge(value: .84, size: 196, label: 'Focus Score'),
        SizedBox(height: 18),
        Text.rich(
          TextSpan(text: 'You maintained ', children: [TextSpan(text: 'Deep Work', style: TextStyle(color: DashboardColors.primary, fontWeight: FontWeight.w900)), TextSpan(text: ' for 12% longer than last week.')]),
          textAlign: TextAlign.center,
          style: TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: 15, height: 1.5),
        ),
      ],
    );
  }
}
