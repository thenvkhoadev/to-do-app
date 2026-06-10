import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/features/tasks/presentation/models/filter_state.dart';
import 'package:to_do_app/features/tasks/presentation/providers/tasks_provider.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class FilterAiSection extends ConsumerWidget {
  const FilterAiSection({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final AiTaskFilter value;
  final ValueChanged<AiTaskFilter> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(userTasksProvider).valueOrNull ?? const [];
    final options = [
      (AiTaskFilter.all, 'All Tasks', tasks.length),
      (AiTaskFilter.generated, 'AI Generated', tasks.where((task) => task.aiGenerated).length),
      (AiTaskFilter.manual, 'Manual Tasks', tasks.where((task) => !task.aiGenerated).length),
    ];
    return Row(
      children: options.map((option) {
        final (filter, label, count) = option;
        final active = value == filter;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(filter),
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
