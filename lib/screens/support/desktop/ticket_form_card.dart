import 'package:flutter/material.dart';
import 'package:to_do_app/constants/dashboard_constants.dart';
import 'package:to_do_app/screens/support/data/support_mock_data.dart';
import 'package:to_do_app/screens/support/widgets/support_shared_widgets.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';
import 'package:to_do_app/widgets/dashboard/dashboard_shared.dart';

class TicketFormCard extends StatelessWidget {
  const TicketFormCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Submit a Ticket',
            style: TextStyle(
              color: DashboardColors.onSurface,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: DashboardSpacing.md),
          _CompactIssueSelector(),
          SizedBox(height: 16),
          SupportTextField(
            label: 'Description',
            hint: 'Tell us what is happening...',
            maxLines: 3,
          ),
          SizedBox(height: 18),
          GradientButton(
            label: 'Submit Ticket',
            icon: Icons.send_rounded,
            expanded: true,
          ),
        ],
      ),
    );
  }
}

class _CompactIssueSelector extends StatefulWidget {
  const _CompactIssueSelector();

  @override
  State<_CompactIssueSelector> createState() => _CompactIssueSelectorState();
}

class _CompactIssueSelectorState extends State<_CompactIssueSelector> {
  var _selected = SupportMockData.ticketCategories.first;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DashboardColors.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: .10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ISSUE CATEGORY',
            style: TextStyle(
              color: DashboardColors.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in SupportMockData.ticketCategories)
                _IssueChip(
                  label: item,
                  selected: item == _selected,
                  onTap: () => setState(() => _selected = item),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IssueChip extends StatelessWidget {
  const _IssueChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color:
          selected
              ? DashboardColors.primary.withValues(alpha: .16)
              : Colors.white.withValues(alpha: .05),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 160),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color:
                  selected
                      ? DashboardColors.primary.withValues(alpha: .42)
                      : Colors.white.withValues(alpha: .06),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const Icon(
                  Icons.check_rounded,
                  color: DashboardColors.primary,
                  size: 14,
                ),
                const SizedBox(width: 5),
              ],
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color:
                        selected
                            ? DashboardColors.primary
                            : DashboardColors.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
