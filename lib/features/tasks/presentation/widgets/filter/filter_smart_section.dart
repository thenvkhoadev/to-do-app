import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:to_do_app/features/tasks/presentation/models/filter_state.dart';
import 'package:to_do_app/features/tasks/presentation/providers/tasks_provider.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/filter/filter_data_helpers.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class FilterSmartSection extends ConsumerWidget {
  const FilterSmartSection({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final Set<SmartFilter> selected;
  final ValueChanged<Set<SmartFilter>> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(userTasksProvider).valueOrNull ?? const [];
    final attachmentTaskIds = ref.watch(userAttachmentTaskIdsProvider).valueOrNull ?? const <String>{};
    final currentUserId = ref.watch(authControllerProvider).valueOrNull?.id;
    final now = DateTime.now();
    final today = startOfFilterDay(now);
    final recentlyAddedThreshold = now.subtract(const Duration(days: 3));

    int countFor(SmartFilter filter) {
      return tasks.where((task) {
        return switch (filter) {
          SmartFilter.myTasks => currentUserId != null &&
              (task.assigneeIds.contains(currentUserId) || task.userId == currentUserId),
          SmartFilter.dueToday => task.dueDate != null && isSameFilterDay(task.dueDate!, today),
          SmartFilter.overdue => task.dueDate != null &&
              task.dueDate!.isBefore(today) &&
              task.status != 'done',
          SmartFilter.highPriority => task.priority == 'high' || task.priority == 'urgent',
          SmartFilter.completed => task.status == 'done',
          SmartFilter.recentlyAdded => task.createdAt != null && task.createdAt!.isAfter(recentlyAddedThreshold),
          SmartFilter.aiGenerated => task.aiGenerated,
          SmartFilter.hasAttachments => attachmentTaskIds.contains(task.id),
          SmartFilter.unassigned => task.assigneeIds.isEmpty,
          SmartFilter.archived => task.deletedAt != null,
        };
      }).length;
    }

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: SmartFilter.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final filter = SmartFilter.values[index];
          final active = selected.contains(filter);
          return GestureDetector(
            onTap: () {
              final next = Set<SmartFilter>.from(selected);
              active ? next.remove(filter) : next.add(filter);
              onChanged(next);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: active
                    ? DashboardColors.primary.withValues(alpha: .16)
                    : DashboardColors.surfaceLow,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: active
                      ? DashboardColors.primary.withValues(alpha: .35)
                      : Colors.white.withValues(alpha: .08),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    smartFilterLabel(filter),
                    style: TextStyle(
                      color: active ? DashboardColors.primary : DashboardColors.onSurface,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${countFor(filter)})',
                    style: const TextStyle(
                      color: DashboardColors.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
