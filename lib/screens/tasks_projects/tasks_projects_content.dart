import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/features/tasks/domain/entities/task.dart';
import 'package:to_do_app/features/tasks/domain/entities/task_board_item.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/task_column.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/task_card.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/task_detail_panel.dart';
import 'package:to_do_app/features/tasks/presentation/providers/tasks_provider.dart';
import 'package:to_do_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:to_do_app/features/profile/data/models/user_profile_model.dart';
import 'package:to_do_app/features/tasks/data/models/tag_model.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';
import 'package:to_do_app/screens/tasks_projects/widgets/tasks_projects_actions.dart';
import 'package:to_do_app/screens/tasks_projects/widgets/tasks_projects_ai_panel.dart';
import 'package:to_do_app/screens/tasks_projects/widgets/tasks_projects_analytics.dart';
import 'package:to_do_app/screens/tasks_projects/widgets/tasks_projects_command_palette.dart';
import 'package:to_do_app/screens/tasks_projects/widgets/tasks_projects_header.dart';
import 'package:to_do_app/screens/tasks_projects/widgets/tasks_projects_insights.dart';

TaskBoardItem _mapTaskToBoardItem(
  NexusTask task,
  List<UserProfileModel> users,
  List<TagModel> tags,
) {
  // 1. Get assignee initials
  String assigneeInitials = 'AI';
  if (task.assigneeIds.isNotEmpty) {
    final assigneeId = task.assigneeIds.first;
    final user = users.firstWhere(
      (u) => u.id == assigneeId,
      orElse: () => UserProfileModel(id: '', email: ''),
    );
    if (user.fullName != null && user.fullName!.trim().isNotEmpty) {
      final names = user.fullName!.trim().split(' ');
      if (names.length >= 2) {
        assigneeInitials = '${names[0][0]}${names[1][0]}'.toUpperCase();
      } else if (names.isNotEmpty && names[0].isNotEmpty) {
        assigneeInitials = names[0][0].toUpperCase();
      }
    } else if (user.username != null && user.username!.isNotEmpty) {
      assigneeInitials = user.username![0].toUpperCase();
    }
  }

  // 2. Get status
  TaskBoardStatus boardStatus;
  switch (task.status) {
    case 'draft':
      boardStatus = TaskBoardStatus.draft;
      break;
    case 'todo':
      boardStatus = TaskBoardStatus.todo;
      break;
    case 'in_progress':
      boardStatus = TaskBoardStatus.inProgress;
      break;
    case 'done':
      boardStatus = TaskBoardStatus.completed;
      break;
    default:
      boardStatus = TaskBoardStatus.todo;
  }

  // 3. Get priority
  TaskBoardPriority boardPriority;
  switch (task.priority) {
    case 'urgent':
      boardPriority = TaskBoardPriority.urgent;
      break;
    case 'high':
      boardPriority = TaskBoardPriority.high;
      break;
    case 'medium':
      boardPriority = TaskBoardPriority.medium;
      break;
    case 'low':
      boardPriority = TaskBoardPriority.low;
      break;
    default:
      boardPriority = TaskBoardPriority.medium;
  }

  // 4. Get tags
  final taskTags = <String>[];
  for (final tagId in task.tagIds) {
    final tag = tags.firstWhere(
      (t) => t.id == tagId,
      orElse: () => TagModel(id: '', name: '', userId: ''),
    );
    if (tag.name.isNotEmpty) {
      taskTags.add(tag.name);
    }
  }

  // 5. Get estimate
  final estimate = task.estimatedMinutes != null ? '${task.estimatedMinutes}m' : '';

  // 6. Get progress
  double progress = 0.0;
  if (task.status == 'done') {
    progress = 1.0;
  } else if (task.status == 'in_progress') {
    progress = 0.5;
  }

  // 7. Get creator name
  String? creatorName;
  final creatorUser = users.firstWhere(
    (u) => u.id == task.userId,
    orElse: () => UserProfileModel(id: '', email: ''),
  );
  if (creatorUser.fullName != null && creatorUser.fullName!.isNotEmpty) {
    creatorName = creatorUser.fullName;
  } else if (creatorUser.username != null && creatorUser.username!.isNotEmpty) {
    creatorName = creatorUser.username;
  } else if (creatorUser.email.isNotEmpty) {
    creatorName = creatorUser.email;
  }

  return TaskBoardItem(
    id: task.id,
    title: task.title,
    description: task.description ?? '',
    status: boardStatus,
    priority: boardPriority,
    estimate: estimate,
    assignee: assigneeInitials,
    progress: progress,
    tags: taskTags,
    completed: task.status == 'done',
    dueLabel: task.dueDate != null ? '${task.dueDate!.day}/${task.dueDate!.month}' : null,
    dueDate: task.dueDate,
    createdAt: task.createdAt,
    updatedAt: task.updatedAt,
    creatorName: creatorName,
    userId: task.userId,
  );
}

Future<void> _updateTaskStatus(WidgetRef ref, String taskId, TaskBoardStatus newStatus) async {
  final tasksAsync = ref.read(userTasksProvider);
  final taskList = tasksAsync.valueOrNull ?? [];
  final taskIndex = taskList.indexWhere((t) => t.id == taskId);
  if (taskIndex == -1) return;
  final task = taskList[taskIndex];

  String statusStr;
  switch (newStatus) {
    case TaskBoardStatus.draft:
      statusStr = 'draft';
      break;
    case TaskBoardStatus.todo:
      statusStr = 'todo';
      break;
    case TaskBoardStatus.inProgress:
      statusStr = 'in_progress';
      break;
    case TaskBoardStatus.completed:
      statusStr = 'done';
      break;
  }

  final updated = task.copyWith(
    status: statusStr,
    completedAt: newStatus == TaskBoardStatus.completed ? DateTime.now().toUtc() : null,
  );
  await ref.read(taskRepositoryProvider).updateTask(updated);
}

class TasksProjectsDesktopContent extends ConsumerStatefulWidget {
  const TasksProjectsDesktopContent({
    this.onNewTask,
    this.onViewDetails,
    this.searchQuery,
    super.key,
  });

  final VoidCallback? onNewTask;
  final ValueChanged<TaskBoardItem>? onViewDetails;
  final String? searchQuery;

  @override
  ConsumerState<TasksProjectsDesktopContent> createState() =>
      _TasksProjectsDesktopContentState();
}

class _TasksProjectsDesktopContentState
    extends ConsumerState<TasksProjectsDesktopContent> {
  TaskBoardItem? _selectedTask;
  TaskBoardItem? _activeTask;

  void _selectTask(TaskBoardItem? task) {
    setState(() {
      _selectedTask = task;
      if (task != null) {
        _activeTask = task;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isPanelOpen = _selectedTask != null;
    return TasksProjectsCommandScope(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 1180;
          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(32, 32, 32, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TasksProjectsHeader(onNewTask: widget.onNewTask),
                    const SizedBox(height: 18),
                    const TasksProjectsSmartInsightBanner(),
                    const SizedBox(height: 14),
                    const TasksProjectsMiniStatsRow(),
                    if (!wide) ...[
                      const SizedBox(height: 14),
                      const TasksProjectsAnalyticsStrip(),
                    ],
                    const SizedBox(height: 18),
                    _DesktopKanbanBoard(
                      searchQuery: widget.searchQuery,
                      onTaskTap: _selectTask,
                      onNewTask: widget.onNewTask,
                    ),
                    const SizedBox(height: 32),
                    _ProjectsBottomRail(
                      onNewTask: widget.onNewTask,
                    ),
                  ],
                ),
              ),
              if (isPanelOpen)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => _selectTask(null),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 250),
                      builder: (context, value, child) {
                        return BackdropFilter(
                          filter: ImageFilter.blur(
                            sigmaX: 5.0 * value,
                            sigmaY: 5.0 * value,
                          ),
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.35 * value),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              (() {
                final panelWidth = constraints.maxWidth >= 1600
                    ? 520.0
                    : (constraints.maxWidth >= 1200 ? 480.0 : 420.0);
                return AnimatedPositioned(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  top: 0,
                  bottom: 0,
                  right: isPanelOpen ? 0 : -panelWidth,
                  width: panelWidth,
                  child: _activeTask != null
                      ? TaskDetailPanel(
                          task: _activeTask!,
                          onClose: () => _selectTask(null),
                          onViewDetails: () {
                            final task = _activeTask!;
                            _selectTask(null);
                            widget.onViewDetails?.call(task);
                          },
                        )
                      : const SizedBox.shrink(),
                );
              }()),
            ],
          );
        },
      ),
    );
  }
}

class _DesktopKanbanBoard extends ConsumerStatefulWidget {
  const _DesktopKanbanBoard({
    required this.searchQuery,
    this.onTaskTap,
    this.onNewTask,
  });

  final String? searchQuery;
  final ValueChanged<TaskBoardItem>? onTaskTap;
  final VoidCallback? onNewTask;

  @override
  ConsumerState<_DesktopKanbanBoard> createState() => _DesktopKanbanBoardState();
}

class _DesktopKanbanBoardState extends ConsumerState<_DesktopKanbanBoard> {
  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(userTasksProvider);
    final usersAsync = ref.watch(allUsersProvider);
    final tagsAsync = ref.watch(userTagsProvider);

    return tasksAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 64),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 64),
          child: Text('Error loading tasks: $err', style: const TextStyle(color: DashboardColors.error)),
        ),
      ),
      data: (tasks) {
        final users = usersAsync.valueOrNull ?? [];
        final tags = tagsAsync.valueOrNull ?? [];

        final query = (widget.searchQuery ?? '').trim().toLowerCase();
        final boardItems = tasks
            .map((t) => _mapTaskToBoardItem(t, users, tags))
            .where((item) =>
                query.isEmpty ||
                item.title.toLowerCase().contains(query) ||
                item.description.toLowerCase().contains(query))
            .toList();

        final draftTasks = boardItems.where((t) => t.status == TaskBoardStatus.draft).toList();
        final todoTasks = boardItems.where((t) => t.status == TaskBoardStatus.todo).toList();
        final inProgressTasks = boardItems.where((t) => t.status == TaskBoardStatus.inProgress).toList();
        final doneTasks = boardItems.where((t) => t.status == TaskBoardStatus.completed).toList();

        return SizedBox(
          height: 600,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TaskColumn(
                  column: TaskColumnData(
                    title: 'Draft',
                    status: TaskBoardStatus.draft,
                    tasks: draftTasks,
                  ),
                  onTaskTap: widget.onTaskTap,
                  onTaskDropped: (item) => _updateTaskStatus(ref, item.id, TaskBoardStatus.draft),
                  onNewTask: widget.onNewTask,
                ),
                const SizedBox(width: 20),
                TaskColumn(
                  column: TaskColumnData(
                    title: 'To Do',
                    status: TaskBoardStatus.todo,
                    tasks: todoTasks,
                  ),
                  onTaskTap: widget.onTaskTap,
                  onTaskDropped: (item) => _updateTaskStatus(ref, item.id, TaskBoardStatus.todo),
                  onNewTask: widget.onNewTask,
                ),
                const SizedBox(width: 20),
                TaskColumn(
                  column: TaskColumnData(
                    title: 'In Progress',
                    status: TaskBoardStatus.inProgress,
                    tasks: inProgressTasks,
                  ),
                  onTaskTap: widget.onTaskTap,
                  onTaskDropped: (item) => _updateTaskStatus(ref, item.id, TaskBoardStatus.inProgress),
                  onNewTask: widget.onNewTask,
                ),
                const SizedBox(width: 20),
                TaskColumn(
                  column: TaskColumnData(
                    title: 'Completed',
                    status: TaskBoardStatus.completed,
                    tasks: doneTasks,
                  ),
                  onTaskTap: widget.onTaskTap,
                  onTaskDropped: (item) => _updateTaskStatus(ref, item.id, TaskBoardStatus.completed),
                  onNewTask: widget.onNewTask,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class TasksProjectsMobileSliverBody extends ConsumerWidget {
  const TasksProjectsMobileSliverBody({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(userTasksProvider);
    final usersAsync = ref.watch(allUsersProvider);
    final tagsAsync = ref.watch(userTagsProvider);

    return SliverPadding(
      padding:
          compact
              ? EdgeInsets.zero
              : const EdgeInsets.fromLTRB(16, 96, 16, 128),
      sliver: SliverToBoxAdapter(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 448),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const TasksProjectsHeader(mobile: true),
                const SizedBox(height: 18),
                const TasksProjectsSmartInsightBanner(compact: true),
                const SizedBox(height: 14),
                const TasksProjectsMiniStatsRow(compact: true),
                const SizedBox(height: 14),
                const TasksProjectsAnalyticsStrip(compact: true),
                const SizedBox(height: 22),
                tasksAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: DashboardColors.error))),
                  data: (tasks) {
                    final users = usersAsync.valueOrNull ?? [];
                    final tags = tagsAsync.valueOrNull ?? [];
                    final boardItems = tasks.map((t) => _mapTaskToBoardItem(t, users, tags)).toList();
                    if (boardItems.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Text('No tasks found', style: TextStyle(color: DashboardColors.onSurfaceVariant)),
                        ),
                      );
                    }
                    return SizedBox(
                      height: 520,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildMobileColumn(context, ref, 'Draft', TaskBoardStatus.draft, boardItems),
                            const SizedBox(width: 16),
                            _buildMobileColumn(context, ref, 'To Do', TaskBoardStatus.todo, boardItems),
                            const SizedBox(width: 16),
                            _buildMobileColumn(context, ref, 'In Progress', TaskBoardStatus.inProgress, boardItems),
                            const SizedBox(width: 16),
                            _buildMobileColumn(context, ref, 'Completed', TaskBoardStatus.completed, boardItems),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileColumn(
    BuildContext context,
    WidgetRef ref,
    String title,
    TaskBoardStatus status,
    List<TaskBoardItem> items,
  ) {
    final filtered = items.where((t) => t.status == status).toList();
    return SizedBox(
      width: 280,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: DashboardColors.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final task = filtered[index];
                return TaskCard(task: task, mobile: true);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectsBottomRail extends StatelessWidget {
  const _ProjectsBottomRail({this.onNewTask});

  final VoidCallback? onNewTask;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        if (wide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: TasksProjectsAiAssistantPanel(),
                  ),
                  const SizedBox(width: 16),
                  const SizedBox(
                    width: 320,
                    child: TasksProjectsCircularAnalytics(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: TasksProjectsHeatmap(),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: TasksProjectsActivityTimeline(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TasksProjectsQuickActionDock(compact: false, onNewTask: onNewTask),
            ],
          );
        } else {
          return Column(
            children: [
              const TasksProjectsAiAssistantPanel(),
              const SizedBox(height: 14),
              const TasksProjectsCircularAnalytics(),
              const SizedBox(height: 14),
              const TasksProjectsHeatmap(),
              const SizedBox(height: 14),
              const TasksProjectsActivityTimeline(),
              const SizedBox(height: 14),
              TasksProjectsQuickActionDock(compact: true, onNewTask: onNewTask),
            ],
          );
        }
      },
    );
  }
}
