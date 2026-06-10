import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/features/tasks/presentation/models/filter_state.dart';
import 'package:to_do_app/features/tasks/presentation/providers/tasks_provider.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class FilterAttachmentsSection extends ConsumerWidget {
  const FilterAttachmentsSection({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final AttachmentFilter value;
  final ValueChanged<AttachmentFilter> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(userTasksProvider).valueOrNull ?? const [];
    final attachmentTaskIds = ref.watch(userAttachmentTaskIdsProvider).valueOrNull ?? const <String>{};
    final options = [
      (AttachmentFilter.hasAttachments, 'Has Attachments', tasks.where((task) => attachmentTaskIds.contains(task.id)).length),
      (AttachmentFilter.noAttachments, 'No Attachments', tasks.where((task) => !attachmentTaskIds.contains(task.id)).length),
    ];
    return Row(
      children: options.map((option) {
        final (filter, label, count) = option;
        final active = value == filter;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(active ? AttachmentFilter.all : filter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: active ? DashboardColors.secondaryContainer.withValues(alpha: .14) : DashboardColors.surfaceLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: active ? DashboardColors.secondary.withValues(alpha: .40) : Colors.white.withValues(alpha: .08)),
                ),
                child: Text(
                  '$label ($count)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: active ? DashboardColors.onSurface : DashboardColors.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
