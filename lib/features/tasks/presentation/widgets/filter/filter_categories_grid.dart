import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/features/tasks/data/models/category_model.dart';
import 'package:to_do_app/features/tasks/presentation/providers/tasks_provider.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/filter/filter_data_helpers.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class FilterCategoriesGrid extends ConsumerWidget {
  const FilterCategoriesGrid({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(userCategoriesProvider).valueOrNull ?? const <CategoryModel>[];
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
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.3,
            children:
                categories.map((category) {
                  final active = selected.contains(category.id);
                  final color = parseFilterColor(category.color);
                  return Material(
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
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: active
                              ? DashboardColors.secondaryContainer.withValues(alpha: .10)
                              : Colors.white.withValues(alpha: .03),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: active
                                ? DashboardColors.secondary.withValues(alpha: .30)
                                : Colors.white.withValues(alpha: .08),
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
                                color: active ? DashboardColors.secondary : color,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    category.name,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: DashboardColors.onSurface,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    '${counts[category.id] ?? 0} tasks',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: DashboardColors.onSurfaceVariant,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
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
      fontSize: 12,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
    ),
  );
}
