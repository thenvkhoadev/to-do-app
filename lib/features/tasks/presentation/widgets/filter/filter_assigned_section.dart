import 'package:flutter/material.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class FilterAssignedSection extends StatelessWidget {
  const FilterAssignedSection({
    required this.selectedUserId,
    required this.unassignedOnly,
    required this.onUserChanged,
    required this.onUnassignedChanged,
    super.key,
  });

  final String? selectedUserId;
  final bool unassignedOnly;
  final ValueChanged<String?> onUserChanged;
  final ValueChanged<bool> onUnassignedChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: DashboardColors.surfaceLow,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: .08)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.person_outline_rounded,
                color: DashboardColors.onSurfaceVariant,
                size: 16,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  selectedUserId ?? 'Select assignee...',
                  style: TextStyle(
                    color:
                        selectedUserId == null
                            ? DashboardColors.onSurfaceVariant
                            : DashboardColors.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: DashboardColors.onSurfaceVariant,
                size: 18,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => onUnassignedChanged(!unassignedOnly),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  value: unassignedOnly,
                  onChanged: (value) => onUnassignedChanged(value ?? false),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
              ),
              const SizedBox(width: 10),
              const Text(
                'Unassigned only',
                style: TextStyle(
                  color: DashboardColors.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
