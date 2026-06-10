import 'package:flutter/material.dart';
import 'package:to_do_app/features/tasks/presentation/models/filter_state.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class FilterStatusChips extends StatelessWidget {
  const FilterStatusChips({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final Set<TaskStatus> selected;
  final ValueChanged<Set<TaskStatus>> onChanged;

  static const _labels = {
    TaskStatus.all: 'All',
    TaskStatus.todo: 'To-Do',
    TaskStatus.inProgress: 'In Progress',
    TaskStatus.review: 'Review',
    TaskStatus.completed: 'Completed',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _SectionLabel('STATUS'),
            const Spacer(),
            Text(
              '${selected.length} selected',
              style: const TextStyle(
                color: DashboardColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              TaskStatus.values.map((status) {
                final active = selected.contains(status);
                return _TapScale(
                  onTap: () {
                    final next = Set<TaskStatus>.from(selected);
                    active ? next.remove(status) : next.add(status);
                    if (next.isEmpty) next.add(TaskStatus.all);
                    if (status == TaskStatus.all && !active) {
                      onChanged({TaskStatus.all});
                    } else {
                      next.remove(TaskStatus.all);
                      onChanged(next.isEmpty ? {TaskStatus.all} : next);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color:
                          active
                              ? const Color(0xFFC0C1FF)
                              : Colors.white.withValues(alpha: .03),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color:
                            active
                                ? Colors.transparent
                                : Colors.white.withValues(alpha: .08),
                      ),
                    ),
                    child: Text(
                      _labels[status]!,
                      style: TextStyle(
                        color:
                            active
                                ? const Color(0xFF131449)
                                : const Color(0xFFC7C5D0),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
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

class _TapScale extends StatelessWidget {
  const _TapScale({required this.onTap, required this.child});
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: child,
    ),
  );
}
