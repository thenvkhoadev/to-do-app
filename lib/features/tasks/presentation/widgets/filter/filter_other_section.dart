import 'package:flutter/material.dart';
import 'package:to_do_app/features/tasks/presentation/models/filter_state.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class FilterOtherSection extends StatelessWidget {
  const FilterOtherSection({
    required this.state,
    required this.onChanged,
    super.key,
  });

  final FilterState state;
  final ValueChanged<FilterState> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = [
      _OtherOption(
        'Has subtasks',
        'Tasks with subtasks',
        state.hasSubtasks,
        (value) => state.copyWith(hasSubtasks: value),
      ),
      _OtherOption(
        'Missing subtasks',
        'Tasks without subtasks',
        state.missingSubtasks,
        (value) => state.copyWith(missingSubtasks: value),
      ),
      _OtherOption(
        'Overdue',
        'Past due tasks',
        state.overdue,
        (value) => state.copyWith(overdue: value),
      ),
      _OtherOption(
        'Blocked',
        'Currently blocked tasks',
        state.blocked,
        (value) => state.copyWith(blocked: value),
      ),
    ];

    return Row(
      children:
          items.map((item) {
            return Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: DashboardColors.surfaceLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .08),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              color: DashboardColors.onSurface,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            item.subtitle,
                            style: const TextStyle(
                              color: DashboardColors.onSurfaceVariant,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Transform.scale(
                      scale: .8,
                      child: Switch(
                        value: item.enabled,
                        onChanged: (value) => onChanged(item.copy(value)),
                        activeThumbColor: DashboardColors.secondary,
                        activeTrackColor: DashboardColors.secondaryContainer
                            .withValues(alpha: .30),
                        inactiveThumbColor: DashboardColors.outlineVariant,
                        inactiveTrackColor: DashboardColors.surfaceHigh,
                        trackOutlineColor: WidgetStateProperty.all(
                          Colors.transparent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }
}

class _OtherOption {
  const _OtherOption(this.title, this.subtitle, this.enabled, this.copy);

  final String title;
  final String subtitle;
  final bool enabled;
  final FilterState Function(bool) copy;
}
