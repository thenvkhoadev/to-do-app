import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/features/tasks/data/models/category_model.dart';
import 'package:to_do_app/features/tasks/presentation/providers/tasks_provider.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/filter/filter_data_helpers.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class FilterCategoriesList extends ConsumerWidget {
  const FilterCategoriesList({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories =
        ref.watch(userCategoriesProvider).valueOrNull ?? const <CategoryModel>[];
    final tasks = ref.watch(userTasksProvider).valueOrNull ?? const [];
    final counts = <String, int>{};
    for (final task in tasks) {
      final categoryId = task.categoryId;
      if (categoryId == null) continue;
      counts[categoryId] = (counts[categoryId] ?? 0) + 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('CATEGORIES'),
        const SizedBox(height: 16),
        if (categories.isEmpty)
          const Text(
            'No categories found',
            style: TextStyle(
              color: DashboardColors.onSurfaceVariant,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          )
        else
          for (final category in categories)
            _CategoryTile(
              category: category,
              count: counts[category.id] ?? 0,
              selected: selected,
              onChanged: onChanged,
            ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.count,
    required this.selected,
    required this.onChanged,
  });

  final CategoryModel category;
  final int count;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    final active = selected.contains(category.id);
    final color = parseFilterColor(category.color);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            final next = Set<String>.from(selected);
            active ? next.remove(category.id) : next.add(category.id);
            onChanged(next);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: active
                  ? Colors.white.withValues(alpha: .03)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF46464F).withValues(alpha: .20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    filterIconFromName(category.icon),
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: const TextStyle(
                          color: DashboardColors.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$count tasks',
                        style: const TextStyle(
                          color: Color(0xFFC7C5D0),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Checkbox(
                  value: active,
                  onChanged: (_) {
                    final next = Set<String>.from(selected);
                    active ? next.remove(category.id) : next.add(category.id);
                    onChanged(next);
                  },
                  fillColor: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.selected)
                        ? const Color(0xFFE1DFFF)
                        : Colors.transparent,
                  ),
                  checkColor: const Color(0xFF131449),
                  side: const BorderSide(color: Color(0xFF46464F), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
