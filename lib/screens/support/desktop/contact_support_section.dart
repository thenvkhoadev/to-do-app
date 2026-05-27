import 'package:flutter/material.dart';
import 'package:to_do_app/constants/dashboard_constants.dart';
import 'package:to_do_app/screens/support/desktop/ticket_form_card.dart';
import 'package:to_do_app/screens/support/widgets/support_shared_widgets.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';
import 'package:to_do_app/widgets/dashboard/dashboard_shared.dart';

class ContactSupportSection extends StatelessWidget {
  const ContactSupportSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SupportGlowContainer(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 900;
            final intro = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Still need assistance?', style: TextStyle(color: DashboardColors.onSurface, fontSize: 38, height: 1.1, fontWeight: FontWeight.w900, letterSpacing: -.8)),
                SizedBox(height: 16),
                Text('Our specialized human support team and AI agents are standing by to resolve any issue.', style: TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: 17, height: 1.5)),
                SizedBox(height: 26),
                Wrap(spacing: 12, runSpacing: 12, children: [_ContactButton(label: 'AI Chat Support', icon: Icons.chat_rounded, primary: true), _ContactButton(label: 'Community Forum', icon: Icons.forum_rounded)]),
              ],
            );
            if (stacked) return Column(children: [intro, const SizedBox(height: DashboardSpacing.md), const TicketFormCard()]);
            return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [Expanded(child: intro), const SizedBox(width: DashboardSpacing.lg), const Expanded(child: TicketFormCard())]);
          },
        ),
      ),
    );
  }
}

class _ContactButton extends StatelessWidget {
  const _ContactButton({required this.label, required this.icon, this.primary = false});

  final String label;
  final IconData icon;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    if (primary) return GradientButton(label: label, icon: icon);
    return GlassCard(radius: DashboardRadii.full, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: DashboardColors.primary, size: 19), const SizedBox(width: 9), Text(label, style: const TextStyle(color: DashboardColors.onSurface, fontWeight: FontWeight.w900))]));
  }
}
