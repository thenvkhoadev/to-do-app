import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/features/tasks/domain/entities/task_board_item.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/ai_suggestion_banner.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/glass_container.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/task_priority_chip.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/task_progress_bar.dart';
import 'package:to_do_app/features/tasks/presentation/providers/tasks_provider.dart';
import 'package:to_do_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:to_do_app/features/profile/data/models/user_profile_model.dart';
import 'package:to_do_app/features/tasks/data/models/tag_model.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';
import 'package:to_do_app/core/utils/description_utils.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/delete_success_dialog.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/task_success_dialog.dart';
import 'package:to_do_app/features/tasks/presentation/providers/task_timeline_provider.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/premium_dropdown.dart';
import 'package:to_do_app/features/auth/presentation/providers/auth_provider.dart';

class TaskCard extends ConsumerStatefulWidget {
  const TaskCard({
    required this.task,
    this.mobile = false,
    this.onTap,
    this.onViewDetails,
    this.selected = false,
    this.onSelectedChanged,
    super.key,
  });

  final TaskBoardItem task;
  final bool mobile;
  final VoidCallback? onTap;
  final VoidCallback? onViewDetails;
  final bool selected;
  final ValueChanged<bool?>? onSelectedChanged;

  @override
  ConsumerState<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends ConsumerState<TaskCard> {
  bool _hovered = false;

  void _showContextMenu(BuildContext context, Offset globalPosition) {
    final user = ref.read(authControllerProvider).valueOrNull;
    final isCreator = user != null && widget.task.userId == user.id;
    showTaskCardMenu(
      context: context,
      offset: globalPosition,
      task: widget.task,
      isCreator: isCreator,
      onEdit: _showEditDialog,
      onDelete: _confirmDelete,
      onDuplicate: _duplicateTask,
      onOpenPage: widget.onViewDetails ?? widget.onTap,
    );
  }

  void _handleMenuAction(String action) {
    if (action.startsWith('__open_menu__:')) {
      final parts = action.substring('__open_menu__:'.length).split(',');
      if (parts.length == 2) {
        final dx = double.tryParse(parts[0]) ?? 0;
        final dy = double.tryParse(parts[1]) ?? 0;
        _showContextMenu(context, Offset(dx, dy));
      }
      return;
    }
    if (action == 'view') widget.onTap?.call();
  }

  Future<void> _confirmDelete() async {
    final confirmed = await DeleteConfirmDialog.show(context, widget.task.title);

    if (confirmed == true && mounted) {
      try {
        await ref.read(taskRepositoryProvider).deleteTask(widget.task.id);
        if (mounted) {
          DeleteSuccessDialog.show(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi khi xóa: $e')),
          );
        }
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

  Future<void> _duplicateTask() async {
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null || widget.task.userId != user.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn không có quyền nhân bản công việc này')),
      );
      return;
    }
    try {
      final tasks = ref.read(userTasksProvider).valueOrNull ?? [];
      final nexusTask = tasks.firstWhere(
        (t) => t.id == widget.task.id,
        orElse: () => throw Exception('Không tìm thấy task'),
      );
      final now = DateTime.now().toUtc();
      final duplicate = nexusTask.copyWith(
        id: '',
        title: _getDuplicateTitle(nexusTask.title),
        status: 'todo',
        completedAt: null,
        createdAt: now,
        updatedAt: now,
      );
      await ref.read(taskRepositoryProvider).createTask(duplicate);
      if (mounted) {
        TaskDuplicateSuccessDialog.show(context, widget.task.title);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi nhân bản: $e')),
        );
      }
    }
  }

  Future<void> _showEditDialog() async {
    try {
      final tasks = ref.read(userTasksProvider).valueOrNull ?? [];
      final nexusTask = tasks.firstWhere(
        (t) => t.id == widget.task.id,
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
                        await ref.read(taskTimelineProvider(widget.task.id).notifier).addActivity(
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể sửa task này: $e')),
        );
      }
    }
  }

  String _getInitials(UserProfileModel user) {
    final name = user.fullName ?? user.username ?? user.email;
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  Color _getUserColor(String userId) {
    final colors = [
      DashboardColors.primary,
      DashboardColors.secondary,
      DashboardColors.tertiary,
      DashboardColors.outline,
    ];
    final index = userId.hashCode.abs() % colors.length;
    return colors[index];
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final isCreator = user != null && widget.task.userId == user.id;

    final active =
        widget.task.status == TaskBoardStatus.inProgress &&
        widget.task.aiSuggestion != null;
    final completed = widget.task.completed;


    final allUsers = ref.watch(allUsersProvider).valueOrNull ?? [];
    final assignees = <UserProfileModel>[];

    final assigneeIdsAsync = ref.watch(taskAssigneeIdsProvider(widget.task.id));
    assigneeIdsAsync.whenOrNull(
      data: (uids) {
        for (final uid in uids) {
          final user = allUsers.firstWhere(
            (u) => u.id == uid,
            orElse: () => UserProfileModel(id: uid, email: ''),
          );
          if (user.fullName != null || user.username != null || user.email.isNotEmpty) {
            assignees.add(user);
          }
        }
      },
    );

    // Fallback if the database has no assignees yet or is loading/offline, but the task has assignee initials
    if (assignees.isEmpty && widget.task.assignee.isNotEmpty) {
      assignees.add(UserProfileModel(
        id: 'fallback',
        email: '',
        fullName: widget.task.assignee,
      ));
    }

    final tagIdsAsync = ref.watch(taskTagIdsProvider(widget.task.id));
    final allTags = ref.watch(userTagsProvider).valueOrNull ?? [];
    final taskTags = <String>[];
    tagIdsAsync.whenOrNull(
      data: (tids) {
        for (final tid in tids) {
          final tag = allTags.firstWhere(
            (t) => t.id == tid,
            orElse: () => TagModel(id: '', name: '', userId: ''),
          );
          if (tag.name.isNotEmpty) {
            taskTags.add(tag.name);
          }
        }
      },
    );
    final subtasksAsync = ref.watch(taskSubtasksProvider(widget.task.id));
    double? progressValue;
    if (widget.task.completed || widget.task.status == TaskBoardStatus.completed) {
      progressValue = 1.0;
    } else {
      subtasksAsync.when(
        data: (subtasks) {
          if (subtasks.isNotEmpty) {
            final doneCount = subtasks.where((s) => s.isDone).length;
            progressValue = doneCount / subtasks.length;
          } else {
            progressValue = null;
          }
        },
        loading: () => progressValue = null,
        error: (_, __) => progressValue = null,
      );
    }
    final displayTags = taskTags.isEmpty && tagIdsAsync.isLoading ? widget.task.tags : taskTags;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(
          0,
          _hovered && !widget.mobile ? -3 : 0,
          0,
        ),
        child: Opacity(
          opacity: completed ? .62 : 1,
          child: GestureDetector(
            onTap: widget.onTap,
            onSecondaryTapDown: (details) => _showContextMenu(context, details.globalPosition),
            child: GlassContainer(
              radius: widget.mobile ? 18 : 16,
              padding: EdgeInsets.all(widget.mobile ? 16 : 18),
              glow: active ? DashboardColors.primary : null,
              opacity: active ? .055 : .035,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.onSelectedChanged != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 2, right: 6),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: widget.selected,
                          onChanged: widget.onSelectedChanged,
                          activeColor: DashboardColors.primary,
                          checkColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (active && !widget.mobile) ...[
                    const _ActiveTaskLine(),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: widget.mobile
                        ? _MobileTaskBody(
                            task: widget.task,
                            onMenuSelected: _handleMenuAction,
                            assignees: assignees,
                            getInitials: _getInitials,
                            getUserColor: _getUserColor,
                            tags: displayTags,
                            isCreator: isCreator,
                          )
                        : _DesktopTaskBody(
                            task: widget.task,
                            onMenuSelected: _handleMenuAction,
                            assignees: assignees,
                            getInitials: _getInitials,
                            getUserColor: _getUserColor,
                            tags: displayTags,
                            progress: progressValue,
                            isCreator: isCreator,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopTaskBody extends StatelessWidget {
  const _DesktopTaskBody({
    required this.task,
    required this.onMenuSelected,
    required this.assignees,
    required this.getInitials,
    required this.getUserColor,
    required this.tags,
    required this.progress,
    required this.isCreator,
  });

  final TaskBoardItem task;
  final ValueChanged<String> onMenuSelected;
  final List<UserProfileModel> assignees;
  final String Function(UserProfileModel) getInitials;
  final Color Function(String) getUserColor;
  final List<String> tags;
  final double? progress;
  final bool isCreator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            TaskPriorityChip(priority: task.priority),
            const Spacer(),
            _TaskContextMenuButton(onSelected: onMenuSelected, isCreator: isCreator),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          task.title,
          style: TextStyle(
            color: DashboardColors.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            decoration: task.completed ? TextDecoration.lineThrough : null,
            decorationColor: DashboardColors.onSurfaceVariant,
          ),
        ),
        if (task.plainTextDescription.isNotEmpty) ...[
          const SizedBox(height: 6),
          buildRichTextDescription(
            task.description,
            const TextStyle(
              color: DashboardColors.onSurfaceVariant,
              fontSize: 13,
              height: 1.45,
            ),
            maxLines: 2,
          ),
        ],
        if (task.aiSuggestion != null) ...[
          const SizedBox(height: 14),
          AiSuggestionBanner(text: task.aiSuggestion!, compact: true),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            const Text(
              'Progress',
              style: TextStyle(
                color: DashboardColors.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            const Spacer(),
            Text(
              progress != null
                  ? '${(progress! * 100).round()}%'
                  : 'No subtasks available',
              style: TextStyle(
                color: progress != null
                    ? DashboardColors.primary
                    : DashboardColors.onSurfaceVariant,
                fontSize: 12,
                fontWeight: progress != null ? FontWeight.w900 : FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TaskProgressBar(value: progress ?? 0.0),
        const SizedBox(height: 14),
        Row(
          children: [
            _buildAssigneesRow(assignees, getInitials, getUserColor),
            const Spacer(),
            ...tags.take(2).map((tag) => _TagChip(label: tag)),
          ],
        ),
      ],
    );
  }
}

class _MobileTaskBody extends StatelessWidget {
  const _MobileTaskBody({
    required this.task,
    required this.onMenuSelected,
    required this.assignees,
    required this.getInitials,
    required this.getUserColor,
    required this.tags,
    required this.isCreator,
  });

  final TaskBoardItem task;
  final ValueChanged<String> onMenuSelected;
  final List<UserProfileModel> assignees;
  final String Function(UserProfileModel) getInitials;
  final Color Function(String) getUserColor;
  final List<String> tags;
  final bool isCreator;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TaskCheckbox(done: task.completed),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (task.aiSuggestion != null) const _AiMiniChip(),
                  const SizedBox(width: 6),
                  TaskPriorityChip(priority: task.priority, compact: true),
                  const Spacer(),
                  _TaskContextMenuButton(onSelected: onMenuSelected, isCreator: isCreator),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                task.title,
                style: TextStyle(
                  color: DashboardColors.onSurface,
                  fontSize: 16,
                  height: 1.25,
                  fontWeight: FontWeight.w800,
                  decoration: task.completed ? TextDecoration.lineThrough : null,
                ),
              ),
              const SizedBox(height: 7),
              Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    color: DashboardColors.onSurfaceVariant,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    task.dueLabel ?? task.estimate,
                    style: const TextStyle(
                      color: DashboardColors.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              if (task.aiSuggestion != null) ...[
                const SizedBox(height: 12),
                AiSuggestionBanner(text: task.aiSuggestion!, compact: true),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildAssigneesRow(assignees, getInitials, getUserColor),
                  const Spacer(),
                  ...tags.take(2).map((tag) => _TagChip(label: tag)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Widget _buildAssigneesRow(
  List<UserProfileModel> assignees,
  String Function(UserProfileModel) getInitials,
  Color Function(String) getUserColor,
) {
  if (assignees.isEmpty) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24),
      ),
      child: const Icon(Icons.person_add_alt_1_rounded, size: 12, color: Colors.white38),
    );
  }

  final double width = 26.0 + (assignees.length - 1) * 18.0;
  return SizedBox(
    width: width,
    height: 26,
    child: Stack(
      children: List.generate(assignees.length, (index) {
        final user = assignees[index];
        final initials = getInitials(user);
        final color = getUserColor(user.id);
        final hasImage = user.avatarUrl != null && user.avatarUrl!.isNotEmpty;

        return Positioned(
          left: index * 18.0,
          child: Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: DashboardColors.background,
            ),
            padding: const EdgeInsets.all(1.0),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: .18),
              ),
              clipBehavior: Clip.antiAlias,
              child: hasImage
                  ? Image.network(
                      user.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: Text(
                          initials,
                          style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        initials,
                        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900),
                      ),
                    ),
            ),
          ),
        );
      }),
    ),
  );
}

class _TaskContextMenuButton extends StatelessWidget {
  const _TaskContextMenuButton({required this.onSelected, required this.isCreator});
  final ValueChanged<String> onSelected;
  final bool isCreator;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) => onSelected('__open_menu__:${details.globalPosition.dx},${details.globalPosition.dy}'),
      child: const Padding(
        padding: EdgeInsets.all(4),
        child: Icon(
          Icons.more_horiz_rounded,
          size: 18,
          color: DashboardColors.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _ActiveTaskLine extends StatelessWidget {
  const _ActiveTaskLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      height: 128,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [DashboardColors.primary, DashboardColors.secondary],
        ),
        boxShadow: [
          BoxShadow(
            color: DashboardColors.primary.withValues(alpha: .45),
            blurRadius: 12,
          ),
        ],
      ),
    );
  }
}

class _TaskCheckbox extends StatelessWidget {
  const _TaskCheckbox({required this.done});
  final bool done;
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: done ? DashboardColors.primary.withValues(alpha: .16) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: done ? DashboardColors.primary : DashboardColors.outlineVariant,
          width: 2,
        ),
      ),
      child: done
          ? const Icon(
              Icons.check_rounded,
              color: DashboardColors.primary,
              size: 17,
            )
          : null,
    );
  }
}

class _AiMiniChip extends StatelessWidget {
  const _AiMiniChip();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: DashboardColors.primary.withValues(alpha: .3)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              color: DashboardColors.primary,
              size: 11,
            ),
            SizedBox(width: 3),
            Text(
              'AI',
              style: TextStyle(
                color: DashboardColors.primary,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: DashboardColors.surfaceHighest.withValues(alpha: .55),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            '#$label',
            style: const TextStyle(
              color: DashboardColors.onSurfaceVariant,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
}
