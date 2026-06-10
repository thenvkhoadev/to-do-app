import 'package:flutter/material.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class _CategoryOption {
  const _CategoryOption(
    this.id,
    this.name,
    this.subtitle,
    this.dot,
    this.count,
  );

  final String id;
  final String name;
  final String subtitle;
  final Color dot;
  final int count;
}

class FilterCategoriesSection extends StatefulWidget {
  const FilterCategoriesSection({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  @override
  State<FilterCategoriesSection> createState() =>
      _FilterCategoriesSectionState();
}

class _FilterCategoriesSectionState extends State<FilterCategoriesSection> {
  String _search = '';

  static const _categories = [
    _CategoryOption(
      'neural',
      'Neural Engine',
      'Core AI Infrastructure',
      Color(0xFF818CF8),
      4,
    ),
    _CategoryOption(
      'ui',
      'UI Systems',
      'Interface & Experience',
      Color(0xFF60A5FA),
      3,
    ),
    _CategoryOption(
      'pipeline',
      'Data Pipeline',
      'Data & Analytics',
      Color(0xFF34D399),
      2,
    ),
    _CategoryOption(
      'integrations',
      'Integrations',
      'Third-party Services',
      Color(0xFFFBBF24),
      1,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final filtered =
        _categories
            .where(
              (category) =>
                  category.name.toLowerCase().contains(_search.toLowerCase()),
            )
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
        for (final category in filtered)
          _CategoryRow(
            category: category,
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
    required this.checked,
    required this.onTap,
  });

  final _CategoryOption category;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color:
            checked ? Colors.white.withValues(alpha: .03) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color:
              checked
                  ? Colors.white.withValues(alpha: .15)
                  : Colors.transparent,
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
              (states) =>
                  states.contains(WidgetState.selected)
                      ? DashboardColors.secondary
                      : Colors.transparent,
            ),
            checkColor: DashboardColors.onPrimary,
            side: const BorderSide(
              color: DashboardColors.outlineVariant,
              width: 1.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: category.dot,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: const TextStyle(
                    color: DashboardColors.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  category.subtitle,
                  style: const TextStyle(
                    color: DashboardColors.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: DashboardColors.surfaceHigh,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                '${category.count}',
                style: const TextStyle(
                  color: DashboardColors.onSurface,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
