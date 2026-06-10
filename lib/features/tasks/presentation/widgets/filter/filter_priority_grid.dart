import 'package:flutter/material.dart';
import 'package:to_do_app/features/tasks/presentation/models/filter_state.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class FilterPriorityGrid extends StatelessWidget {
  const FilterPriorityGrid({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final Set<TaskPriority> selected;
  final ValueChanged<Set<TaskPriority>> onChanged;

  static const _config = [
    (TaskPriority.urgent, 'Urgent', DashboardColors.error, Color(0x1AEF4444)),
    (TaskPriority.high, 'High', DashboardColors.warning, Color(0x1AF59E0B)),
    (TaskPriority.medium, 'Medium', Color(0xFFE1DFFF), Color(0x1AE1DFFF)),
    (TaskPriority.low, 'Low', Color(0xFFC7C5D0), Color(0x0AFFFFFF)),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('PRIORITY'),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 3.5,
          children:
              _config.map((item) {
                final (priority, label, dotColor, activeBg) = item;
                final active = selected.contains(priority);
                return Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      final next = Set<TaskPriority>.from(selected);
                      active ? next.remove(priority) : next.add(priority);
                      onChanged(next);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: active ? activeBg : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              active
                                  ? dotColor.withValues(alpha: .50)
                                  : const Color(
                                    0xFF46464F,
                                  ).withValues(alpha: .30),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: dotColor,
                              shape: BoxShape.circle,
                              boxShadow:
                                  priority == TaskPriority.urgent
                                      ? [
                                        BoxShadow(
                                          color: dotColor.withValues(
                                            alpha: .60,
                                          ),
                                          blurRadius: 10,
                                        ),
                                      ]
                                      : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            label,
                            style: const TextStyle(
                              color: DashboardColors.onSurface,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: Color(0xFFC7C5D0),
      fontSize: 14,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.12,
    ),
  );
}
