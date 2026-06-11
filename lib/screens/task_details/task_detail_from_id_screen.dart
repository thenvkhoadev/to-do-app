import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:to_do_app/features/tasks/domain/entities/task_board_item.dart';
import 'package:to_do_app/features/tasks/presentation/layouts/tasks_desktop_layout.dart';
import 'package:to_do_app/features/tasks/presentation/providers/tasks_provider.dart';
import 'package:to_do_app/screens/task_details/task_detail_page.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';
import 'package:to_do_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:to_do_app/features/profile/data/models/user_profile_model.dart';

class TaskDetailFromIdScreen extends ConsumerWidget {
  const TaskDetailFromIdScreen({required this.taskId, super.key});
  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(userTasksProvider);

    return Theme(
      data: DashboardTheme.dark(),
      child: Scaffold(
        backgroundColor: DashboardColors.background,
        body: tasksAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorState(onBack: () => context.pop()),
          data: (tasks) {
            final nexusTask = tasks.cast<dynamic>().firstWhere(
              (t) => t.id == taskId,
              orElse: () => null,
            );
            if (nexusTask == null) {
              return _NotFoundState(onBack: () => context.pop());
            }
            final allUsers = ref.watch(allUsersProvider).valueOrNull ?? [];
            final item = _toTaskBoardItem(nexusTask, allUsers);
            return LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 1100) {
                  return TasksDesktopLayout(
                    initialDetailItem: item,
                    onDetailBack: () => context.pop(),
                  );
                }
                return TaskDetailPage(
                  item: item,
                  onBack: () => context.pop(),
                );
              },
            );
          },
        ),
      ),
    );
  }

  TaskBoardItem _toTaskBoardItem(dynamic t, List<UserProfileModel> allUsers) {
    TaskBoardStatus status;
    switch ((t.status as String).toLowerCase()) {
      case 'in_progress':
      case 'inprogress':
        status = TaskBoardStatus.inProgress;
        break;
      case 'completed':
      case 'done':
        status = TaskBoardStatus.completed;
        break;
      case 'draft':
        status = TaskBoardStatus.draft;
        break;
      default:
        status = TaskBoardStatus.todo;
    }

    TaskBoardPriority priority;
    switch ((t.priority as String).toLowerCase()) {
      case 'urgent':
        priority = TaskBoardPriority.urgent;
        break;
      case 'high':
        priority = TaskBoardPriority.high;
        break;
      case 'low':
        priority = TaskBoardPriority.low;
        break;
      default:
        priority = TaskBoardPriority.medium;
    }

    final estMin = t.estimatedMinutes as int?;
    final estimate = estMin != null
        ? estMin >= 60
            ? '${estMin ~/ 60}h${estMin % 60 > 0 ? ' ${estMin % 60}m' : ''}'
            : '${estMin}m'
        : '–';

    String resolvedAssigneeName = 'Unassigned';
    final assigneeIds = (t.assigneeIds as List?)?.cast<String>() ?? [];
    if (assigneeIds.isNotEmpty) {
      final assigneeId = assigneeIds.first;
      final user = allUsers.firstWhere(
        (u) => u.id == assigneeId,
        orElse: () => UserProfileModel(id: '', email: ''),
      );
      if (user.fullName != null && user.fullName!.trim().isNotEmpty) {
        resolvedAssigneeName = user.fullName!;
      } else if (user.username != null && user.username!.isNotEmpty) {
        resolvedAssigneeName = user.username!;
      } else if (user.email.isNotEmpty) {
        resolvedAssigneeName = user.email;
      }
    }
    
    String? resolvedCreatorName;
    final userId = t.userId as String?;
    if (userId != null && userId.isNotEmpty) {
      final creatorUser = allUsers.firstWhere(
        (u) => u.id == userId,
        orElse: () => UserProfileModel(id: '', email: ''),
      );
      if (creatorUser.fullName != null && creatorUser.fullName!.trim().isNotEmpty) {
        resolvedCreatorName = creatorUser.fullName;
      } else if (creatorUser.username != null && creatorUser.username!.isNotEmpty) {
        resolvedCreatorName = creatorUser.username;
      } else if (creatorUser.email.isNotEmpty) {
        resolvedCreatorName = creatorUser.email;
      }
    }

    return TaskBoardItem(
      id: t.id as String,
      title: t.title as String,
      description: (t.description as String?) ?? '',
      status: status,
      priority: priority,
      estimate: estimate,
      assignee: resolvedAssigneeName,
      progress: status == TaskBoardStatus.completed ? 1.0 : (status == TaskBoardStatus.inProgress ? 0.5 : 0.0),
      tags: const [],
      dueDate: t.dueDate as DateTime?,
      createdAt: t.createdAt as DateTime?,
      updatedAt: t.updatedAt as DateTime?,
      userId: userId,
      creatorName: resolvedCreatorName,
      xpAwarded: (t.xpAwarded as bool?) ?? false,
    );
  }
}

class _NotFoundState extends StatelessWidget {
  const _NotFoundState({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off_rounded, color: DashboardColors.onSurfaceVariant, size: 56),
          const SizedBox(height: 16),
          const Text(
            'Task Not Found',
            style: TextStyle(color: DashboardColors.onSurface, fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'This task may have been deleted.',
            style: TextStyle(color: DashboardColors.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Back to Calendar'),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, color: DashboardColors.error, size: 56),
          const SizedBox(height: 16),
          const Text(
            'Failed to load task',
            style: TextStyle(color: DashboardColors.onSurface, fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Back to Calendar'),
          ),
        ],
      ),
    );
  }
}
