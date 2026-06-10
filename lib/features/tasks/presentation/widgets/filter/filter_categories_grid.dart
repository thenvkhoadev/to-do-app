import 'package:flutter/material.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class FilterCategoriesGrid extends StatelessWidget {
  const FilterCategoriesGrid({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  static const _items = [
    (
      'neural',
      'Neural Engine',
      Icons.psychology_rounded,
      DashboardColors.primary,
      Color(0x33321ED2),
    ),
    (
      'infra',
      'Infrastructure',
      Icons.hub_rounded,
      Color(0xFFC7C5D0),
      Color(0xFF292A2B),
    ),
    (
      'productivity',
      'Productivity',
      Icons.flare_rounded,
      Color(0xFFC7C5D0),
      Color(0xFF292A2B),
    ),
    (
      'security',
      'Security',
      Icons.shield_rounded,
      Color(0xFFC7C5D0),
      Color(0xFF292A2B),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('CATEGORIES'),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.3,
          children:
              _items.map((item) {
                final (id, label, icon, iconColor, iconBg) = item;
                final active = selected.contains(id);
                return Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      final next = Set<String>.from(selected);
                      active ? next.remove(id) : next.add(id);
                      onChanged(next);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            active
                                ? DashboardColors.secondaryContainer.withValues(
                                  alpha: .10,
                                )
                                : Colors.white.withValues(alpha: .03),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              active
                                  ? DashboardColors.secondary.withValues(
                                    alpha: .30,
                                  )
                                  : Colors.white.withValues(alpha: .08),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: iconBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              icon,
                              color:
                                  active
                                      ? DashboardColors.secondary
                                      : iconColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              label,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: DashboardColors.onSurface,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
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
