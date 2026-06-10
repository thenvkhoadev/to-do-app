import 'package:flutter/material.dart';
import 'package:to_do_app/features/tasks/presentation/models/filter_state.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class FilterPriorityTabs extends StatelessWidget {
  const FilterPriorityTabs({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final Set<TaskPriority> selected;
  final ValueChanged<Set<TaskPriority>> onChanged;

  static const _labels = ['Urgent', 'High', 'Medium', 'Low'];
  static const _priorities = [
    TaskPriority.urgent,
    TaskPriority.high,
    TaskPriority.medium,
    TaskPriority.low,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('PRIORITY'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF0D0E0F),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: .08)),
          ),
          child: Row(
            children: List.generate(_labels.length, (i) {
              final active = selected.contains(_priorities[i]);
              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      final next = Set<TaskPriority>.from(selected);
                      active
                          ? next.remove(_priorities[i])
                          : next.add(_priorities[i]);
                      onChanged(next);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color:
                            active
                                ? Colors.white.withValues(alpha: .03)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            active
                                ? Border.all(
                                  color: Colors.white.withValues(alpha: .08),
                                )
                                : null,
                      ),
                      child: Center(
                        child: Text(
                          _labels[i],
                          style: TextStyle(
                            color:
                                active
                                    ? DashboardColors.onSurface
                                    : const Color(0xFFC7C5D0),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
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
      fontSize: 12,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
    ),
  );
}
