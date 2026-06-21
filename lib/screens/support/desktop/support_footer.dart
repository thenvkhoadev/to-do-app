import 'package:flutter/material.dart';
import 'package:to_do_app/constants/dashboard_constants.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';
import 'package:to_do_app/widgets/auth/privacy_policy_dialog.dart';

class SupportFooter extends StatelessWidget {
  const SupportFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: DashboardSpacing.lg),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: .06)),
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 24,
        runSpacing: 18,
        children: [
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.task_alt_rounded, color: DashboardColors.primary),
              SizedBox(width: 8),
              Text(
                'NEXUS AI',
                style: TextStyle(
                  color: DashboardColors.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Status', style: _FooterStyle()),
              const SizedBox(width: 22),
              const Text('Terms', style: _FooterStyle()),
              const SizedBox(width: 22),
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    barrierColor: Colors.black.withOpacity(0.72),
                    builder: (context) => const PrivacyPolicyDialog(),
                  );
                },
                child: const MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Text('Privacy', style: _FooterStyle()),
                ),
              ),
              const SizedBox(width: 22),
              const Text('Contact', style: _FooterStyle()),
            ],
          ),
          const Text(
            '© 2024 NEXUS AI. Precision productivity.',
            style: TextStyle(
              color: DashboardColors.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterStyle extends TextStyle {
  const _FooterStyle()
    : super(
        color: DashboardColors.onSurfaceVariant,
        fontSize: 12,
        fontWeight: FontWeight.w800,
      );
}
