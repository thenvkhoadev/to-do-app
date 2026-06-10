import 'package:flutter/material.dart';
import 'package:to_do_app/screens/tasks_projects/widgets/tasks_premium_filters.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class TasksProjectsHeader extends StatelessWidget {
  const TasksProjectsHeader({
    this.mobile = false,
    this.onNewTask,
    this.filters = TasksFilterState.empty,
    this.onFiltersChanged,
    super.key,
  });

  final bool mobile;
  final VoidCallback? onNewTask;
  final TasksFilterState filters;
  final ValueChanged<TasksFilterState>? onFiltersChanged;

  void _openFilters(BuildContext context, Offset offset) {
    final cb = onFiltersChanged;
    if (cb == null) return;
    showTasksFilterMenu(
      context: context,
      offset: offset,
      state: filters,
      onChanged: cb,
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = Text(
      'Active Projects',
      style: TextStyle(
        color: DashboardColors.onSurface,
        fontSize: mobile ? 24 : 32,
        fontWeight: FontWeight.w600,
        letterSpacing: mobile ? 0 : -.3,
        height: 1.2,
      ),
    );
    final subtitle = Text(
      'Focusing on 12 high-impact tasks today.',
      style: TextStyle(
        color: DashboardColors.onSurfaceVariant,
        fontSize: mobile ? 14 : 16,
        height: 1.5,
      ),
    );

    if (mobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          title,
          const SizedBox(height: 4),
          subtitle,
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _HeaderButton(
                  label: filters.count > 0 ? 'Filter (${filters.count})' : 'Filter',
                  icon: Icons.filter_list_rounded,
                  onTapDown: (offset) => _openFilters(context, offset),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _HeaderButton(
                  label: 'New Task',
                  icon: Icons.add_rounded,
                  gradient: true,
                  onTap: onNewTask,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [title, const SizedBox(height: 4), subtitle],
          ),
        ),
        const SizedBox(width: 24),
        _HeaderButton(
          label: filters.count > 0 ? 'Filter (${filters.count})' : 'Filter',
          icon: Icons.filter_list_rounded,
          onTapDown: (offset) => _openFilters(context, offset),
        ),
        const SizedBox(width: 12),
        _HeaderButton(
          label: 'New Task',
          icon: Icons.add_rounded,
          gradient: true,
          onTap: onNewTask,
        ),
      ],
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.label,
    required this.icon,
    this.gradient = false,
    this.onTap,
    this.onTapDown,
  });

  final String label;
  final IconData icon;
  final bool gradient;
  final VoidCallback? onTap;
  final ValueChanged<Offset>? onTapDown;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        decoration: BoxDecoration(
          gradient:
              gradient
                  ? const LinearGradient(
                    colors: [
                      DashboardColors.primaryContainer,
                      DashboardColors.secondaryContainer,
                    ],
                  )
                  : null,
          color: gradient ? null : Colors.white.withValues(alpha: .03),
          borderRadius: BorderRadius.circular(999),
          border:
              gradient
                  ? null
                  : Border.all(color: Colors.white.withValues(alpha: .1)),
          boxShadow:
              gradient
                  ? [
                    BoxShadow(
                      color: DashboardColors.primary.withValues(alpha: .15),
                      blurRadius: 30,
                    ),
                  ]
                  : null,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          onTapDown: onTapDown == null ? null : (details) => onTapDown!(details.globalPosition),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: gradient ? Colors.white : DashboardColors.onSurface,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: gradient ? Colors.white : DashboardColors.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
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
