import 'package:flutter/material.dart';
import 'package:to_do_app/features/tasks/data/mock/mock_task_repository.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/floating_ai_button.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/task_column.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/task_detail_panel.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/task_filter_chips.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/tasks_sidebar.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/tasks_topbar.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class TasksDesktopLayout extends StatefulWidget {
  const TasksDesktopLayout({super.key});

  @override
  State<TasksDesktopLayout> createState() => _TasksDesktopLayoutState();
}

class _TasksDesktopLayoutState extends State<TasksDesktopLayout> {
  int _selectedIndex = 1;

  @override
  Widget build(BuildContext context) {
    final repository = const MockTaskRepository();
    final columns = repository.board();
    final selectedTask = columns[1].tasks.first;

    return LayoutBuilder(
      builder: (context, constraints) {
        final showDetailPanel = constraints.maxWidth >= 1500;

        return Stack(
          children: [
            Row(
              children: [
                TasksSidebar(
                  selectedIndex: _selectedIndex,
                  onSelected: (index) => setState(() => _selectedIndex = index),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: _selectedIndex == 1
                        ? Column(
                            key: const ValueKey('tasks-board'),
                            children: [
                              const TasksTopbar(),
                              const _BoardToolbar(),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(32, 0, 24, 28),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: ListView.separated(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: columns.length,
                                          separatorBuilder: (_, __) => const SizedBox(width: 24),
                                          itemBuilder: (context, index) => TaskColumn(column: columns[index]),
                                        ),
                                      ),
                                      if (showDetailPanel) ...[
                                        const SizedBox(width: 24),
                                        TaskDetailPanel(task: selectedTask),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : _SidebarSectionPlaceholder(index: _selectedIndex),
                  ),
                ),
              ],
            ),
            const Positioned(right: 28, bottom: 28, child: FloatingAIButton()),
          ],
        );
      },
    );
  }
}

class _SidebarSectionPlaceholder extends StatelessWidget {
  const _SidebarSectionPlaceholder({required this.index});

  final int index;

  String get _title => switch (index) {
    0 => 'Dashboard',
    2 => 'Intelligence',
    3 => 'Calendar',
    4 => 'Analytics',
    5 => 'Settings',
    6 => 'Support',
    _ => 'Tasks',
  };

  IconData get _icon => switch (index) {
    0 => Icons.dashboard_rounded,
    2 => Icons.psychology_rounded,
    3 => Icons.calendar_month_rounded,
    4 => Icons.query_stats_rounded,
    5 => Icons.settings_rounded,
    6 => Icons.help_outline_rounded,
    _ => Icons.assignment_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      key: ValueKey('sidebar-section-$index'),
      children: [
        const TasksTopbar(),
        Expanded(
          child: Center(
            child: Container(
              width: 520,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .04),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withValues(alpha: .09)),
                boxShadow: [BoxShadow(color: DashboardColors.primary.withValues(alpha: .08), blurRadius: 32)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_icon, color: DashboardColors.primary, size: 42),
                  const SizedBox(height: 16),
                  Text(_title, style: const TextStyle(color: DashboardColors.onSurface, fontSize: 28, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),
                  const Text(
                    'Sidebar đang giữ nguyên trong Tasks module. Vùng nội dung bên phải đổi theo mục được chọn.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: DashboardColors.onSurfaceVariant, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BoardToolbar extends StatelessWidget {
  const _BoardToolbar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(color: DashboardColors.surfaceLowest.withValues(alpha: .28)),
      child: const Row(
        children: [
          Text('Active Board', style: TextStyle(color: DashboardColors.onSurface, fontSize: 24, fontWeight: FontWeight.w900)),
          SizedBox(width: 24),
          TaskFilterChips(desktop: true),
          Spacer(),
          _ToolbarButton(icon: Icons.filter_list_rounded, label: 'Filter'),
          SizedBox(width: 10),
          _ToolbarButton(icon: Icons.sort_rounded, label: 'Sort'),
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: .1))),
      child: Row(children: [Icon(icon, color: DashboardColors.onSurfaceVariant, size: 18), const SizedBox(width: 7), Text(label, style: const TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w800))]),
    );
  }
}
