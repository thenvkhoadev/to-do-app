import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/features/tasks/data/models/category_model.dart';
import 'package:to_do_app/features/tasks/presentation/providers/tasks_provider.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/filter/filter_data_helpers.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class FilterCategoriesSection extends ConsumerStatefulWidget {
  const FilterCategoriesSection({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  @override
  ConsumerState<FilterCategoriesSection> createState() =>
      _FilterCategoriesSectionState();
}

class _FilterCategoriesSectionState
    extends ConsumerState<FilterCategoriesSection> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(userCategoriesProvider).valueOrNull ?? const <CategoryModel>[];
    final tasks = ref.watch(userTasksProvider).valueOrNull ?? const [];
    final counts = <String, int>{};
    for (final task in tasks) {
      final categoryId = task.categoryId;
      if (categoryId == null) continue;
      counts[categoryId] = (counts[categoryId] ?? 0) + 1;
    }
    final filtered = categories
        .where((category) => category.name.toLowerCase().contains(_search.toLowerCase()))
        .toList();

    return Column(
      children: [
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: DashboardColors.surfaceLow,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: .08)),
          ),
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Icon(
                  Icons.search_rounded,
                  color: DashboardColors.onSurfaceVariant,
                  size: 16,
                ),
              ),
              Expanded(
                child: TextField(
                  onChanged: (value) => setState(() => _search = value),
                  style: const TextStyle(
                    color: DashboardColors.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Search categories...',
                    hintStyle: TextStyle(
                      color: DashboardColors.onSurfaceVariant,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (filtered.isEmpty)
          const _EmptyFilterMessage('No categories found')
        else
          for (final category in filtered)
            _CategoryRow(
              category: category,
              count: counts[category.id] ?? 0,
              checked: widget.selected.contains(category.id),
              onTap: () {
                final next = Set<String>.from(widget.selected);
                widget.selected.contains(category.id)
                    ? next.remove(category.id)
                    : next.add(category.id);
                widget.onChanged(next);
              },
            ),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.count,
    required this.checked,
    required this.onTap,
  });

  final CategoryModel category;
  final int count;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = parseFilterColor(category.color);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: checked ? Colors.white.withValues(alpha: .03) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: checked ? Colors.white.withValues(alpha: .15) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Checkbox(
              value: checked,
              onChanged: (_) => onTap(),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              fillColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? DashboardColors.secondary
                    : Colors.transparent,
              ),
              checkColor: DashboardColors.onPrimary,
              side: const BorderSide(
                color: DashboardColors.outlineVariant,
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(width: 8),
            Icon(filterIconFromName(category.icon), color: color, size: 16),
            const SizedBox(width: 8),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                category.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: DashboardColors.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '($count)',
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
  }
}

class _EmptyFilterMessage extends StatelessWidget {
  const _EmptyFilterMessage(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Text(
      text,
      style: const TextStyle(
        color: DashboardColors.onSurfaceVariant,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
