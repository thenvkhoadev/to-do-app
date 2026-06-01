import 'package:flutter/material.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class TaskFilterChips extends StatelessWidget {
  const TaskFilterChips({this.desktop = false, super.key});

  final bool desktop;

  @override
  Widget build(BuildContext context) {
    final labels =
        desktop
            ? ['Work', 'Personal', 'Deep Work']
            : ['All', 'Work', 'Personal', 'Deep Work'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _FilterChip(
                label: labels[i],
                selected: i == 0,
                ai: labels[i] == 'Deep Work',
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    this.selected = false,
    this.ai = false,
  });
  final String label;
  final bool selected;
  final bool ai;
  @override
  Widget build(BuildContext context) {
    final color =
        selected
            ? DashboardColors.primary
            : ai
            ? DashboardColors.secondary
            : DashboardColors.onSurfaceVariant;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
      decoration: BoxDecoration(
        color:
            selected
                ? DashboardColors.primary.withValues(alpha: .16)
                : DashboardColors.surfaceHigh.withValues(alpha: .45),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: selected || ai ? .35 : .12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (ai) ...[
            Icon(Icons.auto_awesome_rounded, color: color, size: 14),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
