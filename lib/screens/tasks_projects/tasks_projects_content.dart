import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/features/tasks/domain/entities/task.dart';
import 'package:to_do_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:to_do_app/features/tasks/domain/entities/task_board_item.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/task_column.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/task_card.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/task_detail_panel.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/filter/filter_data_helpers.dart';
import 'package:to_do_app/features/tasks/data/models/task_subtask_model.dart';
import 'package:to_do_app/features/tasks/presentation/models/filter_state.dart';
import 'package:to_do_app/features/tasks/presentation/providers/tasks_provider.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/filter/desktop_filter_panel.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/filter/mobile_filter_sheet.dart';
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
import 'package:to_do_app/screens/tasks_projects/widgets/tasks_premium_filters.dart';
import 'package:to_do_app/features/streak/presentation/providers/streak_providers.dart';

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
  final estimate =
      task.estimatedMinutes != null ? '${task.estimatedMinutes}m' : '';

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
    dueLabel:
        task.dueDate != null
            ? '${task.dueDate!.day}/${task.dueDate!.month}'
            : null,
    dueDate: task.dueDate,
    createdAt: task.createdAt,
    updatedAt: task.updatedAt,
    creatorName: creatorName,
    userId: task.userId,
  );
}

Future<void> _updateTaskStatus(
  WidgetRef ref,
  String taskId,
  TaskBoardStatus newStatus,
) async {
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

  final completedNow = task.status != 'done' && newStatus == TaskBoardStatus.completed;
  final draftToActive = task.status == 'draft' &&
      (newStatus == TaskBoardStatus.todo || newStatus == TaskBoardStatus.inProgress);
  final updated = task.copyWith(
    status: statusStr,
    completedAt:
        newStatus == TaskBoardStatus.completed ? DateTime.now().toUtc() : null,
  );
  await ref.read(taskRepositoryProvider).updateTask(updated);
  if (completedNow) {
    await ref.read(streakRemoteDataSourceProvider).updateUserStreak('Task Completed');
  } else if (draftToActive) {
    await ref.read(streakRemoteDataSourceProvider).updateUserStreak('Task Activated');
  }
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
  TasksFilterState _filters = TasksFilterState.empty;
  FilterState _overlayFilterState = const FilterState();
  bool _showFilterPanel = false;
  Rect? _filterAnchorRect;

  void _selectTask(TaskBoardItem? task) {
    setState(() {
      _selectedTask = task;
      if (task != null) {
        _activeTask = task;
      }
    });
  }

  void _openFilters(Rect anchor) {
    final box = context.findRenderObject() as RenderBox?;
    final localTopLeft = box?.globalToLocal(anchor.topLeft) ?? anchor.topLeft;
    setState(() {
      _filterAnchorRect = localTopLeft & anchor.size;
      _showFilterPanel = true;
    });
  }

  void _applyOverlayFilters(FilterState state) {
    setState(() {
      _overlayFilterState = state;
      _filters = _toTasksFilterState(state);
      _showFilterPanel = false;
    });
  }

  TasksFilterState _toTasksFilterState(FilterState state) {
    final statuses = <TaskBoardStatus>{};
    if (!state.selectedStatuses.contains(TaskStatus.all)) {
      for (final status in state.selectedStatuses) {
        switch (status) {
          case TaskStatus.all:
            break;
          case TaskStatus.todo:
            statuses.add(TaskBoardStatus.todo);
          case TaskStatus.inProgress:
            statuses.add(TaskBoardStatus.inProgress);
          case TaskStatus.review:
            statuses.add(TaskBoardStatus.todo);
          case TaskStatus.completed:
            statuses.add(TaskBoardStatus.completed);
        }
      }
    }

    final priorities =
        state.selectedPriorities.map((priority) {
          return switch (priority) {
            TaskPriority.urgent => TaskBoardPriority.urgent,
            TaskPriority.high => TaskBoardPriority.high,
            TaskPriority.medium => TaskBoardPriority.medium,
            TaskPriority.low => TaskBoardPriority.low,
          };
        }).toSet();

    return TasksFilterState(
      statuses: statuses,
      priorities: priorities,
      categoryIds: state.selectedCategoryIds,
      duePreset: _duePresetFromOverlay(state),
    );
  }

  String? _duePresetFromOverlay(FilterState state) {
    if (state.startDate != null || state.endDate != null) return null;
    return switch (state.datePreset) {
      DateRangePreset.today => 'today',
      DateRangePreset.thisWeek => 'week',
      DateRangePreset.month => null,
      DateRangePreset.custom => null,
    };
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
                    TasksProjectsHeader(
                      onNewTask: widget.onNewTask,
                      filters: _filters,
                      onFiltersChanged:
                          (filters) => setState(() => _filters = filters),
                      onOpenFilters: _openFilters,
                    ),
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
                      filters: _filters,
                      overlayFilterState: _overlayFilterState,
                      onTaskTap: _selectTask,
                      onNewTask: widget.onNewTask,
                      onViewDetails: widget.onViewDetails,
                    ),
                    const SizedBox(height: 32),
                    _ProjectsBottomRail(onNewTask: widget.onNewTask),
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
                final panelWidth =
                    constraints.maxWidth >= 1600
                        ? 520.0
                        : (constraints.maxWidth >= 1200 ? 480.0 : 420.0);
                return AnimatedPositioned(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  top: 0,
                  bottom: 0,
                  right: isPanelOpen ? 0 : -panelWidth,
                  width: panelWidth,
                  child:
                      _activeTask != null
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
              if (_showFilterPanel)
                _DesktopFilterOverlayLayer(
                  constraints: constraints,
                  anchorRect: _filterAnchorRect,
                  initialState: _overlayFilterState,
                  onApply: _applyOverlayFilters,
                  onClose: () => setState(() => _showFilterPanel = false),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _DesktopFilterOverlayLayer extends StatelessWidget {
  const _DesktopFilterOverlayLayer({
    required this.constraints,
    required this.anchorRect,
    required this.initialState,
    required this.onApply,
    required this.onClose,
  });

  final BoxConstraints constraints;
  final Rect? anchorRect;
  final FilterState initialState;
  final ValueChanged<FilterState> onApply;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final overlayWidth =
        constraints.maxWidth >= 1280
            ? 1100.0.clamp(0.0, constraints.maxWidth - 32.0)
            : (constraints.maxWidth * .88).clamp(0.0, 1320.0);
    final anchor =
        anchorRect ?? Rect.fromLTWH(constraints.maxWidth - 220, 64, 120, 44);
    final left = ((constraints.maxWidth - overlayWidth) / 2).clamp(
      24.0,
      constraints.maxWidth - overlayWidth - 24.0,
    );
    final top = anchor.bottom + 16;
    final arrowCenterX = anchor.center.dx.clamp(
      left + 36,
      left + overlayWidth - 36,
    );

    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
      },
      child: Actions(
        actions: {
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) {
              onClose();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onClose,
                  child: Container(color: const Color(0xBF050814)),
                ),
              ),
              Positioned(
                top: anchor.bottom + 2,
                left: arrowCenterX - 10,
                width: 20,
                height: top - anchor.bottom,
                child: const _FilterOverlayConnector(),
              ),
              Positioned(
                top: top,
                left: left,
                width: overlayWidth,
                bottom: 32,
                child: DesktopFilterPanel(
                  initialState: initialState,
                  onApply: onApply,
                  onClose: onClose,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterOverlayConnector extends StatelessWidget {
  const _FilterOverlayConnector();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(painter: _FilterOverlayConnectorPainter()),
    );
  }
}

class _FilterOverlayConnectorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path =
        Path()
          ..moveTo(size.width / 2, 0)
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close();

    canvas.drawShadow(path, const Color(0x66000000), 10, false);
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFA1A1E30), Color(0xF0131420)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: .08),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DesktopKanbanBoard extends ConsumerStatefulWidget {
  const _DesktopKanbanBoard({
    required this.searchQuery,
    required this.filters,
    required this.overlayFilterState,
    this.onTaskTap,
    this.onNewTask,
    this.onViewDetails,
  });

  final String? searchQuery;
  final TasksFilterState filters;
  final FilterState overlayFilterState;
  final ValueChanged<TaskBoardItem>? onTaskTap;
  final VoidCallback? onNewTask;
  final ValueChanged<TaskBoardItem>? onViewDetails;

  @override
  ConsumerState<_DesktopKanbanBoard> createState() =>
      _DesktopKanbanBoardState();
}

class _DesktopKanbanBoardState extends ConsumerState<_DesktopKanbanBoard> {
  bool _matchesFilters(TaskBoardItem item) {
    final f = widget.filters;
    if (f.statuses.isNotEmpty && !f.statuses.contains(item.status)) {
      return false;
    }
    if (f.priorities.isNotEmpty && !f.priorities.contains(item.priority)) {
      return false;
    }
    if (!_matchesDuePreset(item, f.duePreset)) return false;
    final due = item.dueDate;
    final start = widget.overlayFilterState.startDate;
    final end = widget.overlayFilterState.endDate;
    if (start != null &&
        (due == null ||
            due.isBefore(DateTime(start.year, start.month, start.day)))) {
      return false;
    }
    if (end != null &&
        (due == null ||
            due.isAfter(DateTime(end.year, end.month, end.day, 23, 59, 59)))) {
      return false;
    }
    final now = DateTime.now();
    switch (f.quickPreset) {
      case 'today':
        return item.dueDate != null && _sameDay(item.dueDate!, now);
      case 'overdue':
        return item.dueDate != null &&
            item.dueDate!.isBefore(DateTime(now.year, now.month, now.day));
      case 'completed':
        return item.status == TaskBoardStatus.completed;
      case 'high':
        return item.priority == TaskBoardPriority.high ||
            item.priority == TaskBoardPriority.urgent;
      case 'mine':
      case 'all':
      default:
        return true;
    }
  }

  bool _matchesDuePreset(TaskBoardItem item, String? preset) {
    if (preset == null) return true;
    final now = DateTime.now();
    final due = item.dueDate;
    switch (preset) {
      case 'today':
        return due != null && _sameDay(due, now);
      case 'tomorrow':
        return due != null && _sameDay(due, now.add(const Duration(days: 1)));
      case 'week':
        return due != null &&
            due.isBefore(now.add(const Duration(days: 7))) &&
            !due.isBefore(DateTime(now.year, now.month, now.day));
      case 'overdue':
        return due != null &&
            due.isBefore(DateTime(now.year, now.month, now.day));
      case 'none':
        return due == null;
      default:
        return true;
    }
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(userTasksProvider);
    final usersAsync = ref.watch(allUsersProvider);
    final tagsAsync = ref.watch(userTagsProvider);

    return tasksAsync.when(
      loading:
          () => const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 64),
              child: CircularProgressIndicator(),
            ),
          ),
      error:
          (err, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 64),
              child: Text(
                'Error loading tasks: $err',
                style: const TextStyle(color: DashboardColors.error),
              ),
            ),
          ),
      data: (tasks) {
        final users = usersAsync.valueOrNull ?? [];
        final tags = tagsAsync.valueOrNull ?? [];
        final attachmentTaskIds =
            ref.watch(userAttachmentTaskIdsProvider).valueOrNull ?? const <String>{};
        final subtasksByTask =
            ref.watch(userSubtasksByTaskProvider).valueOrNull ??
                const <String, List<TaskSubtaskModel>>{};
        final currentUserId =
            ref.watch(authControllerProvider).valueOrNull?.id;

        final ofs = widget.overlayFilterState;
        final query = (widget.searchQuery ?? '').trim().toLowerCase();

        final filteredTasks = tasks.where((task) {
          // category
          if (ofs.selectedCategoryIds.isNotEmpty &&
              !ofs.selectedCategoryIds.contains(task.categoryId ?? '')) {
            return false;
          }
          // tags
          if (ofs.selectedTagIds.isNotEmpty &&
              !task.tagIds.any((id) => ofs.selectedTagIds.contains(id))) {
            return false;
          }
          // assignees
          if (ofs.selectedAssigneeIds.isNotEmpty &&
              !task.assigneeIds
                  .any((id) => ofs.selectedAssigneeIds.contains(id))) {
            return false;
          }
          // special assignee filters
          if (ofs.assigneeSpecialFilters
              .contains(AssigneeSpecialFilter.unassigned) &&
              task.assigneeIds.isNotEmpty) return false;
          if (ofs.assigneeSpecialFilters
              .contains(AssigneeSpecialFilter.assignedToMe) &&
              currentUserId != null &&
              !task.assigneeIds.contains(currentUserId)) return false;
          if (ofs.assigneeSpecialFilters
              .contains(AssigneeSpecialFilter.createdByMe) &&
              currentUserId != null &&
              task.userId != currentUserId) return false;
          if (ofs.unassignedOnly && task.assigneeIds.isNotEmpty) return false;
          // AI filter
          if (ofs.aiTaskFilter == AiTaskFilter.generated && !task.aiGenerated) {
            return false;
          }
          if (ofs.aiTaskFilter == AiTaskFilter.manual && task.aiGenerated) {
            return false;
          }
          // attachment filter
          if (ofs.attachmentFilter == AttachmentFilter.hasAttachments &&
              !attachmentTaskIds.contains(task.id)) return false;
          if (ofs.attachmentFilter == AttachmentFilter.noAttachments &&
              attachmentTaskIds.contains(task.id)) return false;
          // subtask filters
          final subtasks = subtasksByTask[task.id] ?? const [];
          for (final sf in ofs.selectedSubtaskFilters) {
            if (sf == SubtaskFilter.hasSubtasks && subtasks.isEmpty) {
              return false;
            }
            if (sf == SubtaskFilter.noSubtasks && subtasks.isNotEmpty) {
              return false;
            }
            if (sf == SubtaskFilter.completedSubtasks &&
                (subtasks.isEmpty || subtasks.any((s) => !s.isDone))) {
              return false;
            }
            if (sf == SubtaskFilter.incompleteSubtasks &&
                subtasks.every((s) => s.isDone)) return false;
          }
          // subtask search
          if (ofs.subtaskSearch.trim().isNotEmpty) {
            final q = ofs.subtaskSearch.trim().toLowerCase();
            final taskSubtasks = subtasksByTask[task.id] ?? const [];
            if (!taskSubtasks.any((s) => s.title.toLowerCase().contains(q))) {
              return false;
            }
          }
          // time filters
          for (final tf in ofs.selectedTimeFilters) {
            if (!matchesTimeFilter(task, tf)) return false;
          }
          // smart filters (any match)
          if (ofs.selectedSmartFilters.isNotEmpty) {
            final now = DateTime.now();
            final today = startOfFilterDay(now);
            final recent = now.subtract(const Duration(days: 3));
            final matches = ofs.selectedSmartFilters.any((sf) => switch (sf) {
              SmartFilter.myTasks => currentUserId != null &&
                  (task.assigneeIds.contains(currentUserId) ||
                      task.userId == currentUserId),
              SmartFilter.dueToday =>
                task.dueDate != null && isSameFilterDay(task.dueDate!, today),
              SmartFilter.overdue =>
                task.dueDate != null &&
                    task.dueDate!.isBefore(today) &&
                    task.status != 'done',
              SmartFilter.highPriority =>
                task.priority == 'high' || task.priority == 'urgent',
              SmartFilter.completed => task.status == 'done',
              SmartFilter.recentlyAdded =>
                task.createdAt != null && task.createdAt!.isAfter(recent),
              SmartFilter.aiGenerated => task.aiGenerated,
              SmartFilter.hasAttachments => attachmentTaskIds.contains(task.id),
              SmartFilter.unassigned => task.assigneeIds.isEmpty,
              SmartFilter.archived => task.deletedAt != null,
            });
            if (!matches) return false;
          }
          return true;
        }).toList();

        final boardItems = filteredTasks
            .map((t) => _mapTaskToBoardItem(t, users, tags))
            .where(
              (item) =>
                  query.isEmpty ||
                  item.title.toLowerCase().contains(query) ||
                  item.description.toLowerCase().contains(query),
            )
            .where(_matchesFilters)
            .toList();

        final draftTasks =
            boardItems.where((t) => t.status == TaskBoardStatus.draft).toList();
        final todoTasks =
            boardItems.where((t) => t.status == TaskBoardStatus.todo).toList();
        final inProgressTasks =
            boardItems
                .where((t) => t.status == TaskBoardStatus.inProgress)
                .toList();
        final doneTasks =
            boardItems
                .where((t) => t.status == TaskBoardStatus.completed)
                .toList();

        return LayoutBuilder(
          builder: (context, constraints) {
            // Fit 4 columns + 3 gaps within visible width. Min 240, max 320.
            final colWidth = ((constraints.maxWidth - 60) / 4).clamp(
              240.0,
              320.0,
            );
            return SizedBox(
              height: 600,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: colWidth,
                      child: TaskColumn(
                        column: TaskColumnData(
                          title: 'Draft',
                          status: TaskBoardStatus.draft,
                          tasks: draftTasks,
                        ),
                        onTaskTap: widget.onTaskTap,
                        onViewDetails: widget.onViewDetails,
                        onTaskDropped:
                            (item) => _updateTaskStatus(
                              ref,
                              item.id,
                              TaskBoardStatus.draft,
                            ),
                        onNewTask: widget.onNewTask,
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: colWidth,
                      child: TaskColumn(
                        column: TaskColumnData(
                          title: 'To-Do',
                          status: TaskBoardStatus.todo,
                          tasks: todoTasks,
                        ),
                        onTaskTap: widget.onTaskTap,
                        onViewDetails: widget.onViewDetails,
                        onTaskDropped:
                            (item) => _updateTaskStatus(
                              ref,
                              item.id,
                              TaskBoardStatus.todo,
                            ),
                        onNewTask: widget.onNewTask,
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: colWidth,
                      child: TaskColumn(
                        column: TaskColumnData(
                          title: 'In Propress',
                          status: TaskBoardStatus.inProgress,
                          tasks: inProgressTasks,
                        ),
                        onTaskTap: widget.onTaskTap,
                        onViewDetails: widget.onViewDetails,
                        onTaskDropped:
                            (item) => _updateTaskStatus(
                              ref,
                              item.id,
                              TaskBoardStatus.inProgress,
                            ),
                        onNewTask: widget.onNewTask,
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: colWidth,
                      child: TaskColumn(
                        column: TaskColumnData(
                          title: 'Completed',
                          status: TaskBoardStatus.completed,
                          tasks: doneTasks,
                        ),
                        onTaskTap: widget.onTaskTap,
                        onViewDetails: widget.onViewDetails,
                        onTaskDropped:
                            (item) => _updateTaskStatus(
                              ref,
                              item.id,
                              TaskBoardStatus.completed,
                            ),
                        onNewTask: widget.onNewTask,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class TasksProjectsMobileSliverBody extends ConsumerStatefulWidget {
  const TasksProjectsMobileSliverBody({this.compact = false, super.key});

  final bool compact;

  @override
  ConsumerState<TasksProjectsMobileSliverBody> createState() =>
      _TasksProjectsMobileSliverBodyState();
}

class _TasksProjectsMobileSliverBodyState
    extends ConsumerState<TasksProjectsMobileSliverBody> {
  FilterState _overlayFilterState = const FilterState();
  TasksFilterState _filters = TasksFilterState.empty;

  Future<void> _openFilters(Rect _) async {
    final result = await MobileFilterSheet.show(
      context,
      initialState: _overlayFilterState,
    );
    if (result == null) return;
    setState(() {
      _overlayFilterState = result;
      _filters = _toTasksFilterState(result);
    });
  }

  TasksFilterState _toTasksFilterState(FilterState state) {
    final statuses = <TaskBoardStatus>{};
    if (!state.selectedStatuses.contains(TaskStatus.all)) {
      for (final status in state.selectedStatuses) {
        switch (status) {
          case TaskStatus.all:
            break;
          case TaskStatus.todo:
            statuses.add(TaskBoardStatus.todo);
          case TaskStatus.inProgress:
            statuses.add(TaskBoardStatus.inProgress);
          case TaskStatus.review:
            statuses.add(TaskBoardStatus.todo);
          case TaskStatus.completed:
            statuses.add(TaskBoardStatus.completed);
        }
      }
    }

    return TasksFilterState(
      statuses: statuses,
      priorities:
          state.selectedPriorities.map((priority) {
            return switch (priority) {
              TaskPriority.urgent => TaskBoardPriority.urgent,
              TaskPriority.high => TaskBoardPriority.high,
              TaskPriority.medium => TaskBoardPriority.medium,
              TaskPriority.low => TaskBoardPriority.low,
            };
          }).toSet(),
      categoryIds: state.selectedCategoryIds,
      duePreset: _duePresetFromOverlay(state),
    );
  }

  String? _duePresetFromOverlay(FilterState state) {
    if (state.startDate != null || state.endDate != null) return null;
    return switch (state.datePreset) {
      DateRangePreset.today => 'today',
      DateRangePreset.thisWeek => 'week',
      DateRangePreset.month => null,
      DateRangePreset.custom => null,
    };
  }

  bool _matchesFilters(TaskBoardItem item) {
    if (_filters.statuses.isNotEmpty &&
        !_filters.statuses.contains(item.status)) {
      return false;
    }
    if (_filters.priorities.isNotEmpty &&
        !_filters.priorities.contains(item.priority)) {
      return false;
    }
    if (!_matchesDuePreset(item, _filters.duePreset)) return false;
    final due = item.dueDate;
    final start = _overlayFilterState.startDate;
    final end = _overlayFilterState.endDate;
    if (start != null &&
        (due == null ||
            due.isBefore(DateTime(start.year, start.month, start.day)))) {
      return false;
    }
    if (end != null &&
        (due == null ||
            due.isAfter(DateTime(end.year, end.month, end.day, 23, 59, 59)))) {
      return false;
    }
    return true;
  }

  bool _matchesDuePreset(TaskBoardItem item, String? preset) {
    if (preset == null) return true;
    final now = DateTime.now();
    final due = item.dueDate;
    switch (preset) {
      case 'today':
        return due != null && _sameDay(due, now);
      case 'week':
        return due != null &&
            due.isBefore(now.add(const Duration(days: 7))) &&
            !due.isBefore(DateTime(now.year, now.month, now.day));
      default:
        return true;
    }
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(userTasksProvider);
    final usersAsync = ref.watch(allUsersProvider);
    final tagsAsync = ref.watch(userTagsProvider);

    return SliverPadding(
      padding:
          widget.compact
              ? EdgeInsets.zero
              : const EdgeInsets.fromLTRB(16, 96, 16, 128),
      sliver: SliverToBoxAdapter(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 448),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TasksProjectsHeader(
                  mobile: true,
                  filters: _filters,
                  onOpenFilters: _openFilters,
                ),
                const SizedBox(height: 18),
                const TasksProjectsSmartInsightBanner(compact: true),
                const SizedBox(height: 14),
                const TasksProjectsMiniStatsRow(compact: true),
                const SizedBox(height: 14),
                const TasksProjectsAnalyticsStrip(compact: true),
                const SizedBox(height: 22),
                tasksAsync.when(
                  loading:
                      () => const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                  error:
                      (err, stack) => Center(
                        child: Text(
                          'Error: $err',
                          style: const TextStyle(color: DashboardColors.error),
                        ),
                      ),
                  data: (tasks) {
                    final users = usersAsync.valueOrNull ?? [];
                    final tags = tagsAsync.valueOrNull ?? [];
                    final attachmentTaskIds =
                        ref.watch(userAttachmentTaskIdsProvider).valueOrNull ??
                            const <String>{};
                    final subtasksByTask =
                        ref.watch(userSubtasksByTaskProvider).valueOrNull ??
                            const <String, List<TaskSubtaskModel>>{};
                    final currentUserId =
                        ref.watch(authControllerProvider).valueOrNull?.id;
                    final ofs = _overlayFilterState;

                    final filteredTasks = tasks.where((task) {
                      if (ofs.selectedCategoryIds.isNotEmpty &&
                          !ofs.selectedCategoryIds
                              .contains(task.categoryId ?? '')) return false;
                      if (ofs.selectedTagIds.isNotEmpty &&
                          !task.tagIds
                              .any((id) => ofs.selectedTagIds.contains(id))) {
                        return false;
                      }
                      if (ofs.selectedAssigneeIds.isNotEmpty &&
                          !task.assigneeIds.any(
                              (id) => ofs.selectedAssigneeIds.contains(id))) {
                        return false;
                      }
                      if (ofs.assigneeSpecialFilters
                              .contains(AssigneeSpecialFilter.unassigned) &&
                          task.assigneeIds.isNotEmpty) return false;
                      if (ofs.assigneeSpecialFilters
                              .contains(AssigneeSpecialFilter.assignedToMe) &&
                          currentUserId != null &&
                          !task.assigneeIds.contains(currentUserId)) {
                        return false;
                      }
                      if (ofs.assigneeSpecialFilters
                              .contains(AssigneeSpecialFilter.createdByMe) &&
                          currentUserId != null &&
                          task.userId != currentUserId) return false;
                      if (ofs.unassignedOnly && task.assigneeIds.isNotEmpty) {
                        return false;
                      }
                      if (ofs.aiTaskFilter == AiTaskFilter.generated &&
                          !task.aiGenerated) return false;
                      if (ofs.aiTaskFilter == AiTaskFilter.manual &&
                          task.aiGenerated) return false;
                      if (ofs.attachmentFilter ==
                              AttachmentFilter.hasAttachments &&
                          !attachmentTaskIds.contains(task.id)) return false;
                      if (ofs.attachmentFilter ==
                              AttachmentFilter.noAttachments &&
                          attachmentTaskIds.contains(task.id)) return false;
                      final subtasks = subtasksByTask[task.id] ?? const [];
                      for (final sf in ofs.selectedSubtaskFilters) {
                        if (sf == SubtaskFilter.hasSubtasks &&
                            subtasks.isEmpty) return false;
                        if (sf == SubtaskFilter.noSubtasks &&
                            subtasks.isNotEmpty) return false;
                        if (sf == SubtaskFilter.completedSubtasks &&
                            (subtasks.isEmpty ||
                                subtasks.any((s) => !s.isDone))) return false;
                        if (sf == SubtaskFilter.incompleteSubtasks &&
                            subtasks.every((s) => s.isDone)) return false;
                      }
                      if (ofs.subtaskSearch.trim().isNotEmpty) {
                        final q = ofs.subtaskSearch.trim().toLowerCase();
                        final taskSubtasks =
                            subtasksByTask[task.id] ?? const [];
                        if (!taskSubtasks
                            .any((s) => s.title.toLowerCase().contains(q))) {
                          return false;
                        }
                      }
                      for (final tf in ofs.selectedTimeFilters) {
                        if (!matchesTimeFilter(task, tf)) return false;
                      }
                      return true;
                    }).toList();

                    final boardItems = filteredTasks
                        .map((t) => _mapTaskToBoardItem(t, users, tags))
                        .where(_matchesFilters)
                        .toList();
                    if (boardItems.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Text(
                            'No tasks found',
                            style: TextStyle(
                              color: DashboardColors.onSurfaceVariant,
                            ),
                          ),
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
                            _buildMobileColumn(
                              context,
                              ref,
                              'Draft',
                              TaskBoardStatus.draft,
                              boardItems,
                            ),
                            const SizedBox(width: 16),
                            _buildMobileColumn(
                              context,
                              ref,
                              'To Do',
                              TaskBoardStatus.todo,
                              boardItems,
                            ),
                            const SizedBox(width: 16),
                            _buildMobileColumn(
                              context,
                              ref,
                              'In Progress',
                              TaskBoardStatus.inProgress,
                              boardItems,
                            ),
                            const SizedBox(width: 16),
                            _buildMobileColumn(
                              context,
                              ref,
                              'Completed',
                              TaskBoardStatus.completed,
                              boardItems,
                            ),
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
                  const Expanded(child: TasksProjectsAiAssistantPanel()),
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
                  const Expanded(child: TasksProjectsHeatmap()),
                  const SizedBox(width: 16),
                  const Expanded(child: TasksProjectsActivityTimeline()),
                ],
              ),
              const SizedBox(height: 16),
              TasksProjectsQuickActionDock(
                compact: false,
                onNewTask: onNewTask,
              ),
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
