import 'package:flutter/material.dart';
import 'package:to_do_app/features/tasks/presentation/models/filter_state.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class FilterPrioritySection extends StatelessWidget {
  const FilterPrioritySection({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final Set<TaskPriority> selected;
  final ValueChanged<Set<TaskPriority>> onChanged;

  static const _items = [
    (TaskPriority.urgent, 'Urgent', DashboardColors.error),
    (TaskPriority.high, 'High', DashboardColors.warning),
    (TaskPriority.medium, 'Medium', DashboardColors.secondary),
    (TaskPriority.low, 'Low', DashboardColors.tertiary),
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
            final (priority, label, dotColor) = item;
            final isActive = selected.contains(priority);
            return GestureDetector(
              onTap: () {
                final next = Set<TaskPriority>.from(selected);
                isActive ? next.remove(priority) : next.add(priority);
                onChanged(next);
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
                          ? dotColor.withValues(alpha: .08)
                          : DashboardColors.surfaceLow,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color:
                        isActive
                            ? dotColor.withValues(alpha: .35)
                            : DashboardColors.outlineVariant.withValues(
                              alpha: .15,
                            ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: dotColor,
                        boxShadow:
                            priority == TaskPriority.urgent
                                ? [
                                  BoxShadow(
                                    color: dotColor.withValues(alpha: .60),
                                    blurRadius: 6,
                                  ),
                                ]
                                : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      label,
                      style: const TextStyle(
                        color: DashboardColors.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            isActive
                                ? dotColor.withValues(alpha: .20)
                                : Colors.transparent,
                        border: Border.all(
                          color:
                              isActive
                                  ? dotColor.withValues(alpha: .60)
                                  : DashboardColors.outlineVariant,
                          width: 1.5,
                        ),
                      ),
                      child:
                          isActive
                              ? Icon(Icons.circle, size: 6, color: dotColor)
                              : null,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }
}
