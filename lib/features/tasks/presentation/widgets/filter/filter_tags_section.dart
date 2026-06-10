import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/features/tasks/data/models/tag_model.dart';
import 'package:to_do_app/features/tasks/presentation/providers/tasks_provider.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/filter/filter_data_helpers.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class FilterTagsSection extends ConsumerWidget {
  const FilterTagsSection({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tags = ref.watch(userTagsProvider).valueOrNull ?? const <TagModel>[];
    final tasks = ref.watch(userTasksProvider).valueOrNull ?? const [];
    final counts = <String, int>{};
    for (final task in tasks) {
      for (final tagId in task.tagIds) {
        counts[tagId] = (counts[tagId] ?? 0) + 1;
      }
    }

    if (tags.isEmpty) return const _EmptyMessage('No tags found');

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags.map((tag) {
        final active = selected.contains(tag.id);
        final color = parseFilterColor(tag.color, DashboardColors.secondary);
        return GestureDetector(
          onTap: () {
            final next = Set<String>.from(selected);
            active ? next.remove(tag.id) : next.add(tag.id);
            onChanged(next);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: active ? color.withValues(alpha: .14) : DashboardColors.surfaceLow,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: active ? color.withValues(alpha: .45) : Colors.white.withValues(alpha: .08),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(
                  '#${tag.name} (${counts[tag.id] ?? 0})',
                  style: TextStyle(
                    color: active ? DashboardColors.onSurface : DashboardColors.onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
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

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: DashboardColors.onSurfaceVariant,
      fontSize: 13,
      fontWeight: FontWeight.w600,
    ),
  );
}
