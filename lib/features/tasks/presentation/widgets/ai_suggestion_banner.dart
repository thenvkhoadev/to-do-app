import 'package:flutter/material.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class AiSuggestionBanner extends StatelessWidget {
  const AiSuggestionBanner({required this.text, this.compact = false, super.key});

  final String text;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 10 : 12),
      decoration: BoxDecoration(
        color: DashboardColors.primary.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DashboardColors.primary.withValues(alpha: .16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome_rounded, color: DashboardColors.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: compact ? 12 : 13, height: 1.35, fontStyle: FontStyle.italic))),
        ],
      ),
    );
  }
}
