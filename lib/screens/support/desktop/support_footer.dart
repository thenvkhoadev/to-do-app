import 'package:flutter/material.dart';
import 'package:to_do_app/constants/dashboard_constants.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class SupportFooter extends StatelessWidget {
  const SupportFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: DashboardSpacing.lg),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.white.withValues(alpha: .06)))),
      child: const Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 24,
        runSpacing: 18,
        children: [
          Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.task_alt_rounded, color: DashboardColors.primary), SizedBox(width: 8), Text('TaskFlow AI', style: TextStyle(color: DashboardColors.onSurface, fontSize: 18, fontWeight: FontWeight.w900))]),
          Row(mainAxisSize: MainAxisSize.min, children: [Text('Status', style: _FooterStyle()), SizedBox(width: 22), Text('Terms', style: _FooterStyle()), SizedBox(width: 22), Text('Privacy', style: _FooterStyle()), SizedBox(width: 22), Text('Contact', style: _FooterStyle())]),
          Text('© 2024 TaskFlow AI. Precision productivity.', style: TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: 12)),
        ],
      ),
    );
  }
}

class _FooterStyle extends TextStyle {
  const _FooterStyle() : super(color: DashboardColors.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w800);
}
