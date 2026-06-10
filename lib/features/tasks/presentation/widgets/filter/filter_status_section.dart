import 'package:flutter/material.dart';
import 'package:to_do_app/features/tasks/presentation/models/filter_state.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class FilterStatusSection extends StatelessWidget {
  const FilterStatusSection({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final Set<TaskStatus> selected;
  final ValueChanged<Set<TaskStatus>> onChanged;

  static const _items = [
    (TaskStatus.all, 'All'),
    (TaskStatus.todo, 'To-Do'),
    (TaskStatus.inProgress, 'In Progress'),
    (TaskStatus.review, 'Review'),
    (TaskStatus.completed, 'Completed'),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 3.2,
      children:
          _items.map((item) {
            final (status, label) = item;
            final isActive = selected.contains(status);
            return GestureDetector(
              onTap: () {
                final next = Set<TaskStatus>.from(selected);
                isActive ? next.remove(status) : next.add(status);
                if (status == TaskStatus.all && !isActive) {
                  onChanged({TaskStatus.all});
                  return;
                }
                next.remove(TaskStatus.all);
                onChanged(next.isEmpty ? {TaskStatus.all} : next);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color:
                      isActive
                          ? DashboardColors.secondaryContainer.withValues(
                            alpha: .15,
                          )
                          : DashboardColors.surfaceLow,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color:
                        isActive
                            ? DashboardColors.secondary.withValues(alpha: .40)
                            : DashboardColors.outlineVariant.withValues(
                              alpha: .15,
                            ),
                  ),
                ),
                child: Row(
                  children: [
                    if (isActive)
                      const Padding(
                        padding: EdgeInsets.only(right: 6),
                        child: Icon(
                          Icons.check_circle_rounded,
                          color: DashboardColors.secondary,
                          size: 14,
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: DashboardColors.outlineVariant,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    Flexible(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color:
                              isActive
                                  ? DashboardColors.onSurface
                                  : DashboardColors.onSurfaceVariant,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
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
