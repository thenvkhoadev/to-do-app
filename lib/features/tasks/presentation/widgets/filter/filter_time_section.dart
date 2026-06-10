import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/features/tasks/presentation/models/filter_state.dart';
import 'package:to_do_app/features/tasks/presentation/providers/tasks_provider.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/filter/filter_data_helpers.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class FilterTimeSection extends ConsumerWidget {
  const FilterTimeSection({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final Set<TimeFilter> selected;
  final ValueChanged<Set<TimeFilter>> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(userTasksProvider).valueOrNull ?? const [];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: TimeFilter.values.map((filter) {
        final active = selected.contains(filter);
        final count = tasks.where((task) => matchesTimeFilter(task, filter)).length;
        return _FilterChipButton(
          label: '${timeFilterLabel(filter)} ($count)',
          active: active,
          onTap: () {
            final next = Set<TimeFilter>.from(selected);
            active ? next.remove(filter) : next.add(filter);
            onChanged(next);
          },
        );
      }).toList(),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: active ? DashboardColors.secondaryContainer.withValues(alpha: .14) : DashboardColors.surfaceLow,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: active ? DashboardColors.secondary.withValues(alpha: .38) : Colors.white.withValues(alpha: .08)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? DashboardColors.onSurface : DashboardColors.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  );
}
