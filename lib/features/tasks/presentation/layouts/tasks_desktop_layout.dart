import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/features/tasks/domain/entities/task_board_item.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/floating_ai_button.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/tasks_sidebar.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/tasks_topbar.dart';
import 'package:to_do_app/screens/new_tasks/desktop/desktop_layout.dart';
import 'package:to_do_app/screens/settings/settings_screen.dart';
import 'package:to_do_app/screens/support/support_screen.dart';
import 'package:to_do_app/screens/archived/archived_screen.dart';
import 'package:to_do_app/screens/task_details/task_details_desktop_content.dart';
import 'package:to_do_app/screens/tasks_projects/tasks_projects_content.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';
import 'package:to_do_app/features/tasks/presentation/providers/edit_task_provider.dart';
import 'package:to_do_app/features/tasks/presentation/pages/edit_task_page_v2.dart';

class TasksDesktopLayout extends ConsumerStatefulWidget {
  const TasksDesktopLayout({
    this.openNewTask = false,
    this.searchQuery,
    this.initialDetailItem,
    this.onDetailBack,
    super.key,
  });

  final bool openNewTask;
  final String? searchQuery;
  final TaskBoardItem? initialDetailItem;
  final VoidCallback? onDetailBack;

  @override
  ConsumerState<TasksDesktopLayout> createState() => _TasksDesktopLayoutState();
}

class _TasksDesktopLayoutState extends ConsumerState<TasksDesktopLayout> {
  late int _selectedIndex;
  TaskBoardItem? _detailsItem;
  TaskBoardItem? _detailsItemBeforeEdit;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.openNewTask ? 8 : 1;
    _detailsItem = widget.initialDetailItem;
  }

  void _openTaskDetails(TaskBoardItem item) =>
      setState(() => _detailsItem = item);

  void _closeTaskDetails() {
    final cb = widget.onDetailBack;
    if (cb != null) {
      cb();
    } else {
      setState(() => _detailsItem = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editingItem = ref.watch(editingTaskProvider);
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Row(
              children: [
                TasksSidebar(
                  selectedIndex: _selectedIndex,
                  onSelected: (index) {
                    setState(() => _selectedIndex = index);
                    if (_detailsItem != null) _closeTaskDetails();
                    ref.read(editingTaskProvider.notifier).state = null;
                  },
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: editingItem != null
                        ? EditTaskPageV2(
                            key: ValueKey(
                              'task-edit-${editingItem.id}',
                            ),
                            item: editingItem,
                            onBack: () {
                              ref.read(editingTaskProvider.notifier).state = null;
                              if (_detailsItemBeforeEdit != null) {
                                setState(() {
                                  _detailsItem = _detailsItemBeforeEdit;
                                  _detailsItemBeforeEdit = null;
                                });
                              }
                            },
                            onSaveSuccess: (updatedItem) {
                              ref.read(editingTaskProvider.notifier).state = null;
                              setState(() {
                                _detailsItem = updatedItem;
                                _detailsItemBeforeEdit = null;
                              });
                            },
                          )
                        : _detailsItem != null
                            ? TaskDetailsDesktopContent(
                              key: ValueKey(
                                'task-details-${_detailsItem!.title}',
                              ),
                              item: _detailsItem!,
                              onBack: _closeTaskDetails,
                              onEditTask: () {
                                final itemToEdit = _detailsItem;
                                _detailsItemBeforeEdit = _detailsItem;
                                setState(() => _detailsItem = null);
                                ref.read(editingTaskProvider.notifier).state = itemToEdit;
                              },
                            )
                            : _selectedIndex == 1
                            ? TasksProjectsDesktopContent(
                              key: ValueKey(
                                'tasks-projects-${widget.searchQuery ?? ''}',
                              ),
                              searchQuery: widget.searchQuery,
                              onNewTask:
                                  () => setState(() => _selectedIndex = 8),
                              onViewDetails: _openTaskDetails,
                            )
                            : _selectedIndex == 5
                            ? const SettingsScreen(
                              key: ValueKey('tasks-settings'),
                              embeddedInDashboard: true,
                            )
                            : _selectedIndex == 6
                            ? const SupportScreen(
                              key: ValueKey('tasks-support'),
                              embeddedInDashboard: true,
                            )
                            : _selectedIndex == 7
                            ? const ArchivedScreen(
                              key: ValueKey('tasks-archived'),
                            )
                            : _selectedIndex == 8
                            ? NewTasksDesktopLayout(
                              key: const ValueKey('tasks-new-task'),
                              onClose: () => setState(() => _selectedIndex = 1),
                            )
                            : _SidebarSectionPlaceholder(index: _selectedIndex),
                  ),
                ),
              ],
            ),
            if (_detailsItem == null)
              const Positioned(
                right: 28,
                bottom: 28,
                child: FloatingAIButton(),
              ),
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
                boxShadow: [
                  BoxShadow(
                    color: DashboardColors.primary.withValues(alpha: .08),
                    blurRadius: 32,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_icon, color: DashboardColors.primary, size: 42),
                  const SizedBox(height: 16),
                  Text(
                    _title,
                    style: const TextStyle(
                      color: DashboardColors.onSurface,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Sidebar đang giữ nguyên trong Tasks module. Vùng nội dung bên phải đổi theo mục được chọn.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: DashboardColors.onSurfaceVariant,
                      height: 1.5,
                    ),
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
