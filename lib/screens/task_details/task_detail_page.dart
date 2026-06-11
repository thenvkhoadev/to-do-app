import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/features/tasks/domain/entities/task.dart';
import 'package:to_do_app/features/tasks/domain/entities/task_board_item.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/ai_suggestion_banner.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';
import 'package:to_do_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:to_do_app/features/profile/data/models/user_profile_model.dart';
import 'package:to_do_app/features/tasks/data/models/tag_model.dart';
import 'package:to_do_app/features/tasks/presentation/providers/tasks_provider.dart';
import 'package:to_do_app/features/tasks/data/models/task_model.dart';
import 'package:to_do_app/features/tasks/presentation/providers/task_timeline_provider.dart';
import 'package:to_do_app/core/utils/description_utils.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/delete_success_dialog.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/task_success_dialog.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/premium_dropdown.dart';
import 'package:to_do_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:to_do_app/features/streak/presentation/providers/streak_providers.dart';
import 'widgets/desktop/desktop_task_header.dart';
import 'widgets/desktop/desktop_hero_stats.dart';
import 'widgets/desktop/desktop_task_description.dart';
import 'widgets/desktop/desktop_subtasks.dart';
import 'widgets/desktop/desktop_attachments.dart';
import 'widgets/desktop/desktop_timeline.dart';
import 'widgets/desktop/desktop_ai_panel.dart';
import 'widgets/desktop/desktop_status_stepper.dart';
import 'widgets/desktop/desktop_focus_forecast.dart';
import 'widgets/mobile/mobile_task_header.dart';
import 'widgets/mobile/mobile_health_score.dart';
import 'widgets/mobile/mobile_status_flow.dart';
import 'widgets/mobile/mobile_info_grid.dart';
import 'widgets/mobile/mobile_focus_forecast.dart';
import 'widgets/mobile/mobile_assignees.dart';
import 'widgets/mobile/mobile_description.dart';
import 'widgets/mobile/mobile_subtasks.dart';
import 'widgets/mobile/mobile_attachments.dart';
import 'widgets/mobile/mobile_timeline.dart';

const _desktopBreakpoint = 1200.0;

final pausedTasksProvider = StateProvider<Set<String>>((ref) => {});

class TaskDetailPage extends ConsumerWidget {
  const TaskDetailPage({
    required this.item,
    required this.onBack,
    super.key,
  });

  final TaskBoardItem item;
  final VoidCallback onBack;

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

  Future<void> _updateStatus(BuildContext context, WidgetRef ref, TaskBoardItem item, TaskBoardStatus newStatus) async {
    try {
      final tasks = ref.read(userTasksProvider).valueOrNull ?? [];
      final nexusTask = tasks.firstWhere(
        (t) => t.id == item.id,
        orElse: () => throw Exception('Không tìm thấy task trong database'),
      );

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

      final completedNow = nexusTask.status != 'done' && newStatus == TaskBoardStatus.completed;
      final updated = nexusTask.copyWith(
        status: statusStr,
        completedAt: newStatus == TaskBoardStatus.completed ? DateTime.now().toUtc() : null,
      );

      await ref.read(taskRepositoryProvider).updateTask(updated);
      if (completedNow) {
        await ref.read(streakRemoteDataSourceProvider).updateUserStreak('Task Completed');
        if (context.mounted) {
          TaskCompleteSuccessDialog.show(context, item.title);
        }
      }

      final fromStatus = item.status;
      final toStatus = newStatus;
      final isTransitionOfInterest = (fromStatus == TaskBoardStatus.draft && (toStatus == TaskBoardStatus.todo || toStatus == TaskBoardStatus.inProgress)) ||
                                     (fromStatus == TaskBoardStatus.todo && toStatus == TaskBoardStatus.inProgress) ||
                                     (fromStatus == TaskBoardStatus.inProgress && toStatus == TaskBoardStatus.todo);

      if (isTransitionOfInterest && context.mounted) {
        TaskTransitionSuccessDialog.show(context, item.title, fromStatus, toStatus);
      }

      // Handle paused tasks set
      if (newStatus == TaskBoardStatus.todo && item.status == TaskBoardStatus.inProgress) {
        ref.read(pausedTasksProvider.notifier).update((state) => {...state, item.id});
      } else if (newStatus == TaskBoardStatus.inProgress) {
        ref.read(pausedTasksProvider.notifier).update((state) => state.difference({item.id}));
      }

      final userProfile = ref.read(userProfileProvider).valueOrNull;
      final actor = userProfile?.fullName ?? userProfile?.username ?? userProfile?.email ?? 'You';
      String action = 'update_status';
      String detail = 'Task status updated';

      if (newStatus == TaskBoardStatus.completed) {
        action = 'complete';
        detail = 'completed this task';
      } else if (newStatus == TaskBoardStatus.inProgress) {
        final isPaused = ref.read(pausedTasksProvider).contains(item.id);
        action = isPaused ? 'resume' : 'start';
        detail = isPaused ? 'resumed this task' : 'started this task';
      } else if (newStatus == TaskBoardStatus.todo) {
        if (item.status == TaskBoardStatus.inProgress) {
          action = 'pause';
          detail = 'paused this task';
        } else if (item.status == TaskBoardStatus.draft) {
          action = 'plan';
          detail = 'planned this task';
        }
      }

      await ref.read(taskTimelineProvider(item.id).notifier).addActivity(
        actorName: actor,
        action: action,
        detail: detail,
      );

      final showSnackbar = !completedNow && !isTransitionOfInterest;
      if (showSnackbar && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã cập nhật trạng thái sang ${newStatus == TaskBoardStatus.completed ? "Hoàn thành" : newStatus == TaskBoardStatus.inProgress ? "Đang thực hiện" : newStatus == TaskBoardStatus.todo ? "To Do" : newStatus.name}'),
            backgroundColor: DashboardColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi cập nhật trạng thái: $e'),
            backgroundColor: DashboardColors.error,
          ),
        );
      }
    }
  }

  Future<void> _showEditDialog(BuildContext context, WidgetRef ref, TaskBoardItem item) async {
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null || item.userId != user.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn không có quyền sửa công việc này')),
      );
      return;
    }
    try {
      final tasks = ref.read(userTasksProvider).valueOrNull ?? [];
      final nexusTask = tasks.firstWhere(
        (t) => t.id == item.id,
        orElse: () => throw Exception('Không tìm thấy task trong database'),
      );

      final titleController = TextEditingController(text: nexusTask.title);
      final descController = TextEditingController(text: parseDescriptionToPlainText(nexusTask.description));
      final estController = TextEditingController(text: nexusTask.estimatedMinutes?.toString() ?? '');
      String priority = nexusTask.priority.toLowerCase();
      DateTime? dueDate = nexusTask.dueDate;

      if (priority != 'low' && priority != 'medium' && priority != 'high' && priority != 'urgent') {
        priority = 'medium';
      }

      await showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                backgroundColor: DashboardColors.surfaceLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: const BorderSide(color: Colors.white12),
                ),
                title: const Text('Chỉnh sửa công việc', style: TextStyle(color: DashboardColors.onSurface, fontWeight: FontWeight.bold)),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: titleController,
                        style: const TextStyle(color: DashboardColors.onSurface),
                        decoration: const InputDecoration(
                          labelText: 'Tiêu đề',
                          labelStyle: TextStyle(color: DashboardColors.onSurfaceVariant),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white12)),
                          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: DashboardColors.primary)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: descController,
                        maxLines: 3,
                        style: const TextStyle(color: DashboardColors.onSurface),
                        decoration: const InputDecoration(
                          labelText: 'Mô tả',
                          labelStyle: TextStyle(color: DashboardColors.onSurfaceVariant),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white12)),
                          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: DashboardColors.primary)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        dropdownColor: DashboardColors.surfaceLow,
                        initialValue: priority,
                        style: const TextStyle(color: DashboardColors.onSurface),
                        decoration: const InputDecoration(
                          labelText: 'Độ ưu tiên',
                          labelStyle: TextStyle(color: DashboardColors.onSurfaceVariant),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white12)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'low', child: Text('Low')),
                          DropdownMenuItem(value: 'medium', child: Text('Medium')),
                          DropdownMenuItem(value: 'high', child: Text('High')),
                          DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              priority = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: estController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: DashboardColors.onSurface),
                        decoration: const InputDecoration(
                          labelText: 'Thời gian ước tính (phút)',
                          labelStyle: TextStyle(color: DashboardColors.onSurfaceVariant),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white12)),
                          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: DashboardColors.primary)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              dueDate == null
                                  ? 'Chưa chọn hạn chót'
                                  : 'Hạn chót: ${dueDate!.day}/${dueDate!.month}/${dueDate!.year}',
                              style: const TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: 13),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: dueDate ?? DateTime.now(),
                                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                lastDate: DateTime.now().add(const Duration(days: 3650)),
                              );
                              if (picked != null) {
                                setDialogState(() {
                                  dueDate = picked;
                                });
                              }
                            },
                            child: const Text('Chọn ngày', style: TextStyle(color: DashboardColors.primary)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Hủy', style: TextStyle(color: DashboardColors.onSurfaceVariant)),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: DashboardColors.primaryContainer),
                    onPressed: () async {
                      final title = titleController.text.trim();
                      if (title.isEmpty) return;

                      final newDescText = descController.text.trim();
                      final String? finalDescription;
                      if (newDescText == parseDescriptionToPlainText(nexusTask.description)) {
                        finalDescription = nexusTask.description;
                      } else {
                        finalDescription = newDescText.isEmpty ? null : newDescText;
                      }

                      final updated = nexusTask.copyWith(
                        title: title,
                        description: finalDescription,
                        priority: priority,
                        estimatedMinutes: int.tryParse(estController.text),
                        dueDate: dueDate,
                      );

                      final descriptionChanged = nexusTask.description != finalDescription;

                      await ref.read(taskRepositoryProvider).updateTask(updated);

                      if (descriptionChanged) {
                        final userProfile = ref.read(userProfileProvider).valueOrNull;
                        final actor = userProfile?.fullName ?? userProfile?.username ?? userProfile?.email ?? 'You';
                        await ref.read(taskTimelineProvider(item.id).notifier).addActivity(
                          actorName: actor,
                          action: 'update_description',
                          detail: 'updated description',
                        );
                      }

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã cập nhật công việc thành công')),
                        );
                      }
                    },
                    child: const Text('Lưu', style: TextStyle(color: Colors.white)),
                  ),
                ],
              );
            },
          );
        },
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể sửa task này: $e')),
        );
      }
    }
  }

  String _getDuplicateTitle(String title) {
    final match = RegExp(r'\s\((\d+)\)$').firstMatch(title);
    if (match != null) {
      final numStr = match.group(1)!;
      final number = int.parse(numStr) + 1;
      final prefix = title.substring(0, match.start);
      return '$prefix ($number)';
    } else {
      return '$title (1)';
    }
  }

  Future<void> _duplicateTask(BuildContext context, WidgetRef ref, TaskBoardItem item) async {
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null || item.userId != user.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn không có quyền nhân bản công việc này')),
      );
      return;
    }
    try {
      final tasks = ref.read(userTasksProvider).valueOrNull ?? [];
      final nexusTask = tasks.firstWhere(
        (t) => t.id == item.id,
        orElse: () => throw Exception('Không tìm thấy task'),
      );
      final duplicate = nexusTask.copyWith(
        id: '',
        title: _getDuplicateTitle(nexusTask.title),
        status: 'todo',
        completedAt: null,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      );
      await ref.read(taskRepositoryProvider).createTask(duplicate);
      if (context.mounted) {
        TaskDuplicateSuccessDialog.show(context, item.title);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi nhân bản: $e'), backgroundColor: DashboardColors.error),
        );
      }
    }
  }

  Future<void> _archiveTask(BuildContext context, WidgetRef ref, TaskBoardItem item) async {
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null || item.userId != user.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn không có quyền lưu trữ công việc này')),
      );
      return;
    }
    final confirmed = await ArchiveConfirmDialog.show(context, item.title);

    if (confirmed == true && context.mounted) {
      try {
        final tasks = ref.read(userTasksProvider).valueOrNull ?? [];
        final nexusTask = tasks.firstWhere(
          (t) => t.id == item.id,
          orElse: () => throw Exception('Không tìm thấy task'),
        );
        final taskModel = TaskModel(
          id: nexusTask.id,
          userId: nexusTask.userId,
          title: nexusTask.title,
          description: nexusTask.description,
          categoryId: nexusTask.categoryId,
          priority: nexusTask.priority,
          status: nexusTask.status,
          aiGenerated: nexusTask.aiGenerated,
          dueDate: nexusTask.dueDate,
          reminderAt: nexusTask.reminderAt,
          completedAt: nexusTask.completedAt,
          parentTaskId: nexusTask.parentTaskId,
          sortOrder: nexusTask.sortOrder,
          estimatedMinutes: nexusTask.estimatedMinutes,
          createdAt: nexusTask.createdAt,
          updatedAt: nexusTask.updatedAt,
          deletedAt: nexusTask.deletedAt,
          tagIds: nexusTask.tagIds,
          assigneeIds: nexusTask.assigneeIds,
        );
        await ref.read(archivedTaskDataSourceProvider).archiveTask(taskModel);
        await ref.read(taskRepositoryProvider).deleteTask(item.id);
        if (context.mounted) {
          await ArchiveSuccessDialog.show(context, item.title);
          onBack();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi khi lưu trữ: $e'), backgroundColor: DashboardColors.error),
          );
        }
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, TaskBoardItem item) async {
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null || item.userId != user.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn không có quyền xóa công việc này')),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DashboardColors.surfaceLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.white12),
        ),
        title: const Text('Xác nhận xóa', style: TextStyle(color: DashboardColors.onSurface, fontWeight: FontWeight.bold)),
        content: Text('Bạn có chắc chắn muốn xóa công việc "${item.title}" không?', style: const TextStyle(color: DashboardColors.onSurfaceVariant)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy', style: TextStyle(color: DashboardColors.onSurfaceVariant)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: DashboardColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(taskRepositoryProvider).deleteTask(item.id);
        if (context.mounted) {
          DeleteSuccessDialog.show(context);
          onBack();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi khi xóa: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(userTasksProvider);
    final usersAsync = ref.watch(allUsersProvider);
    final tagsAsync = ref.watch(userTagsProvider);

    final taskItem = tasksAsync.when(
      data: (tasks) {
        final nexusTask = tasks.cast<dynamic>().firstWhere(
          (t) => t.id == item.id,
          orElse: () => null,
        );
        if (nexusTask == null) return item;
        final users = usersAsync.valueOrNull ?? [];
        final tags = tagsAsync.valueOrNull ?? [];
        return _mapTaskToBoardItem(nexusTask, users, tags);
      },
      loading: () => item,
      error: (_, __) => item,
    );

    final isPaused = ref.watch(pausedTasksProvider).contains(taskItem.id);
    final user = ref.watch(authControllerProvider).valueOrNull;
    final isCreator = user != null && taskItem.userId == user.id;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width >= _desktopBreakpoint) {
          return _DesktopLayout(
            item: taskItem,
            onBack: onBack,
            onPlanTask: () => _updateStatus(context, ref, taskItem, TaskBoardStatus.todo),
            onStartTask: () => _updateStatus(context, ref, taskItem, TaskBoardStatus.inProgress),
            onPauseTask: () => _updateStatus(context, ref, taskItem, TaskBoardStatus.todo),
            onCompleteTask: () => _updateStatus(context, ref, taskItem, TaskBoardStatus.completed),
            onEditTask: () => _showEditDialog(context, ref, taskItem),
            onDeleteTask: () => _confirmDelete(context, ref, taskItem),
            onDuplicateTask: () => _duplicateTask(context, ref, taskItem),
            onArchiveTask: () => _archiveTask(context, ref, taskItem),
            isPaused: isPaused,
            isCreator: isCreator,
          );
        }
        return _MobileLayout(
          item: taskItem,
          onBack: onBack,
          onPlanTask: () => _updateStatus(context, ref, taskItem, TaskBoardStatus.todo),
          onStartTask: () => _updateStatus(context, ref, taskItem, TaskBoardStatus.inProgress),
          onPauseTask: () => _updateStatus(context, ref, taskItem, TaskBoardStatus.todo),
          onCompleteTask: () => _updateStatus(context, ref, taskItem, TaskBoardStatus.completed),
          onEditTask: () => _showEditDialog(context, ref, taskItem),
          onDeleteTask: () => _confirmDelete(context, ref, taskItem),
          onDuplicateTask: () => _duplicateTask(context, ref, taskItem),
          onArchiveTask: () => _archiveTask(context, ref, taskItem),
          isPaused: isPaused,
          isCreator: isCreator,
        );
      },
    );
  }
}

// ── Desktop layout ─────────────────────────────────────────────────────────

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({
    required this.item,
    required this.onBack,
    required this.onPlanTask,
    required this.onStartTask,
    required this.onPauseTask,
    required this.onCompleteTask,
    required this.onEditTask,
    required this.onDeleteTask,
    required this.onDuplicateTask,
    required this.onArchiveTask,
    required this.isPaused,
    required this.isCreator,
  });

  final TaskBoardItem item;
  final VoidCallback onBack;
  final VoidCallback onPlanTask;
  final VoidCallback onStartTask;
  final VoidCallback onPauseTask;
  final VoidCallback onCompleteTask;
  final VoidCallback onEditTask;
  final VoidCallback onDeleteTask;
  final VoidCallback onDuplicateTask;
  final VoidCallback onArchiveTask;
  final bool isPaused;
  final bool isCreator;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: DashboardColors.background,
      child: Column(
        children: [
          DesktopTaskHeader(
            item: item,
            onBack: onBack,
            onPlanTask: onPlanTask,
            onStartTask: onStartTask,
            onPauseTask: onPauseTask,
            onCompleteTask: onCompleteTask,
            onEditTask: onEditTask,
            onDeleteTask: onDeleteTask,
            onDuplicateTask: onDuplicateTask,
            onArchiveTask: onArchiveTask,
            isPaused: isPaused,
            isCreator: isCreator,
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 1100;
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(40, 32, 40, 80),
                  child: wide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 7,
                              child: _DesktopLeftColumn(item: item),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              flex: 3,
                              child: _DesktopRightColumn(item: item),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _DesktopLeftColumn(item: item),
                            const SizedBox(height: 24),
                            _DesktopRightColumn(item: item),
                          ],
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopLeftColumn extends StatelessWidget {
  const _DesktopLeftColumn({required this.item});
  final TaskBoardItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DesktopHeroStats(item: item),
        const SizedBox(height: 24),
        DesktopTaskDescription(item: item),
        if (item.aiSuggestion != null) ...[
          const SizedBox(height: 16),
          _AiSuggestionSection(text: item.aiSuggestion!),
        ],
        const SizedBox(height: 24),
        DesktopSubtasks(taskId: item.id),
        const SizedBox(height: 24),
        DesktopAttachments(taskId: item.id),
        const SizedBox(height: 24),
        DesktopTimeline(item: item),
      ],
    );
  }
}

class _DesktopRightColumn extends StatelessWidget {
  const _DesktopRightColumn({required this.item});
  final TaskBoardItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const DesktopAiPanel(),
        const SizedBox(height: 24),
        DesktopStatusStepper(status: item.status),
        const SizedBox(height: 24),
        DesktopFocusForecast(item: item),
      ],
    );
  }
}

// ── Mobile layout ───────────────────────────────────────────────────────────

class _MobileLayout extends StatelessWidget {
  const _MobileLayout({
    required this.item,
    required this.onBack,
    required this.onPlanTask,
    required this.onStartTask,
    required this.onPauseTask,
    required this.onCompleteTask,
    required this.onEditTask,
    required this.onDeleteTask,
    required this.onDuplicateTask,
    required this.onArchiveTask,
    required this.isPaused,
    required this.isCreator,
  });

  final TaskBoardItem item;
  final VoidCallback onBack;
  final VoidCallback onPlanTask;
  final VoidCallback onStartTask;
  final VoidCallback onPauseTask;
  final VoidCallback onCompleteTask;
  final VoidCallback onEditTask;
  final VoidCallback onDeleteTask;
  final VoidCallback onDuplicateTask;
  final VoidCallback onArchiveTask;
  final bool isPaused;
  final bool isCreator;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DashboardColors.surface,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Top AppBar
              SliverAppBar(
                pinned: true,
                backgroundColor: DashboardColors.surface.withValues(alpha: .85),
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: DashboardColors.onSurface),
                  onPressed: onBack,
                ),
                title: const Text(
                  'Task Detail',
                  style: TextStyle(
                    color: DashboardColors.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -.01,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.share_rounded,
                        color: DashboardColors.onSurface),
                    onPressed: () {},
                  ),
                  if (isCreator)
                    Builder(
                      builder: (btnContext) {
                        return GestureDetector(
                          onTap: () {
                            final renderBox = btnContext.findRenderObject() as RenderBox?;
                            if (renderBox != null) {
                              final position = renderBox.localToGlobal(Offset.zero);
                              showTaskDetailsOptionMenu(
                                context: context,
                                offset: Offset(position.dx, position.dy + renderBox.size.height + 6),
                                onDuplicate: onDuplicateTask,
                                onArchive: onArchiveTask,
                                onDelete: onDeleteTask,
                              );
                            }
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Icon(Icons.more_vert_rounded,
                                color: DashboardColors.onSurface),
                          ),
                        );
                      }
                    ),
                ],
              ),
              // Hero header (full-width, no padding)
              SliverToBoxAdapter(
                child: MobileTaskHeader(
                  item: item,
                  onBack: onBack,
                  onPlanTask: onPlanTask,
                  onStartTask: onStartTask,
                  onPauseTask: onPauseTask,
                  onCompleteTask: onCompleteTask,
                  onEditTask: onEditTask,
                  onDeleteTask: onDeleteTask,
                  onDuplicateTask: onDuplicateTask,
                  onArchiveTask: onArchiveTask,
                  isPaused: isPaused,
                  isCreator: isCreator,
                ),
              ),
              // All content sections with padding
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Transform.translate(
                      offset: const Offset(0, -32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          MobileHealthScore(score: 92, probability: 87),
                          const SizedBox(height: 16),
                          MobileStatusFlow(status: item.status),
                          const SizedBox(height: 16),
                          MobileInfoGrid(item: item),
                          const SizedBox(height: 16),
                          const MobileFocusForecast(),
                          const SizedBox(height: 24),
                          MobileAssignees(item: item),
                          const SizedBox(height: 24),
                          MobileDescription(item: item),
                          if (item.aiSuggestion != null) ...[
                            const SizedBox(height: 16),
                            _AiSuggestionSection(text: item.aiSuggestion!),
                          ],
                          const SizedBox(height: 24),
                          MobileSubtasks(taskId: item.id),
                          const SizedBox(height: 24),
                          MobileAttachments(taskId: item.id),
                          const SizedBox(height: 24),
                          MobileTimeline(item: item),
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
          // FAB
          Positioned(
            bottom: 88,
            right: 16,
            child: GestureDetector(
              onTap: item.status == TaskBoardStatus.draft
                  ? onPlanTask
                  : (item.status == TaskBoardStatus.todo
                      ? onStartTask
                      : (item.status == TaskBoardStatus.inProgress ? onPauseTask : null)),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: item.status == TaskBoardStatus.completed
                      ? DashboardColors.success
                      : DashboardColors.primaryContainer,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: (item.status == TaskBoardStatus.completed ? DashboardColors.success : DashboardColors.primary)
                          .withValues(alpha: .25),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  item.status == TaskBoardStatus.completed
                      ? Icons.check_rounded
                      : (item.status == TaskBoardStatus.inProgress
                          ? Icons.pause_rounded
                          : (item.status == TaskBoardStatus.draft
                              ? Icons.assignment_turned_in_rounded
                              : Icons.play_arrow_rounded)),
                  color: DashboardColors.onPrimary,
                  size: 28,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiSuggestionSection extends StatelessWidget {
  const _AiSuggestionSection({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return AiSuggestionBanner(text: text);
  }
}
