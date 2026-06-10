import 'package:flutter/material.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class FilterCategoriesList extends StatelessWidget {
  const FilterCategoriesList({
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
      'Core AI Infrastructure',
      Icons.psychology_rounded,
      Color(0xFFE1DFFF),
      Color(0x1AE1DFFF),
    ),
    (
      'infra',
      'Infrastructure',
      'Cloud & Datastores',
      Icons.storage_rounded,
      Color(0xFFB4EBFF),
      Color(0x1AB4EBFF),
    ),
    (
      'productivity',
      'Productivity',
      'Workflow Automation',
      Icons.speed_rounded,
      DashboardColors.success,
      Color(0x1A22C55E),
    ),
    (
      'security',
      'Security',
      'Encryption & Privacy',
      Icons.security_rounded,
      DashboardColors.error,
      Color(0x1AEF4444),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('CATEGORIES'),
        const SizedBox(height: 16),
        for (final item in _items)
          _CategoryTile(item: item, selected: selected, onChanged: onChanged),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.item,
    required this.selected,
    required this.onChanged,
  });

  final (String, String, String, IconData, Color, Color) item;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    final (id, name, subtitle, icon, iconColor, iconBg) = item;
    final active = selected.contains(id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
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
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  active
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
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: DashboardColors.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
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
                    active ? next.remove(id) : next.add(id);
                    onChanged(next);
                  },
                  fillColor: WidgetStateProperty.resolveWith(
                    (states) =>
                        states.contains(WidgetState.selected)
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
