import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:to_do_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:to_do_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:to_do_app/features/profile/data/models/user_profile_model.dart';
import 'package:to_do_app/features/streak/presentation/providers/streak_providers.dart';
import 'package:to_do_app/features/tasks/data/datasource/attachment_datasource.dart';
import 'package:to_do_app/features/tasks/data/models/task_attachment_model.dart';
import 'package:to_do_app/features/tasks/data/models/tag_model.dart';
import 'package:to_do_app/features/tasks/data/models/category_model.dart';
import 'package:to_do_app/features/tasks/data/models/task_subtask_model.dart';
import 'package:to_do_app/features/tasks/domain/entities/task.dart';
import 'package:to_do_app/features/tasks/domain/entities/task_board_item.dart';
import 'package:to_do_app/features/tasks/presentation/providers/edit_task_provider.dart';
import 'package:to_do_app/features/tasks/presentation/providers/tasks_provider.dart';
import 'package:to_do_app/features/tasks/presentation/providers/task_timeline_provider.dart';
import 'dart:math' show min, cos, sin;
import 'package:to_do_app/theme/dashboard_theme.dart';
import 'package:to_do_app/core/services/app_providers.dart';
import 'package:to_do_app/features/xp/presentation/providers/xp_providers.dart';
import 'package:to_do_app/core/utils/description_utils.dart';

import 'package:to_do_app/features/tasks/presentation/widgets/edit_task/layouts.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/edit_task/overview_cards.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/edit_task/general_info_card.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/edit_task/assignees_section.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/edit_task/subtasks_section.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/edit_task/attachments_section.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/edit_task/ai_analysis_section.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/edit_task/bottom_action_bar.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/edit_task/productivity_booster_card.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/edit_task/focus_timer_card.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/edit_task/achievements_card.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/edit_task/header_section.dart';

class EditTaskPageV2 extends ConsumerStatefulWidget {
  const EditTaskPageV2({
    required this.item,
    this.onBack,
    this.onSaveSuccess,
    super.key,
  });

  final TaskBoardItem item;
  final VoidCallback? onBack;
  final ValueChanged<TaskBoardItem>? onSaveSuccess;

  @override
  ConsumerState<EditTaskPageV2> createState() => _EditTaskPageV2State();
}

class _EditTaskPageV2State extends ConsumerState<EditTaskPageV2> {
  final _titleController = TextEditingController();
  String? _currentDescription;

  bool _initialized = false;
  bool _isSaving = false;

  // Local state for editing fields
  String? _selectedCategoryId;
  String _selectedStatus = 'todo';
  String _selectedPriority = 'medium';
  DateTime? _dueDate;
  List<String> _selectedTagIds = [];
  List<String> _assigneeIds = [];
  List<TaskSubtaskModel> _subtasks = [];
  List<TaskAttachmentModel> _attachments = [];
  final List<TaskAttachmentModel> _deletedAttachments = [];
  final List<PlatformFileInfo> _newAttachments = [];

  // Time picker state
  int _estimateHour = 4;
  int _estimateMinute = 0;
  int _actualHour = 2;
  int _actualMinute = 15;

  // Original state tracking for changes detection
  String _initialTitle = '';
  String _initialDesc = '';
  String? _initialCategoryId;
  String _initialStatus = 'todo';
  String _initialPriority = 'medium';
  DateTime? _initialDueDate;
  List<String> _initialTagIds = [];
  List<String> _initialAssigneeIds = [];
  List<TaskSubtaskModel> _initialSubtasks = [];

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_onTextChanged);
    _loadTaskDetailsFromDb();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadTaskDetailsFromDb() async {
    try {
      final subtasks = await ref
          .read(subtaskDataSourceProvider)
          .getSubtasks(widget.item.id);
      final attachments = await ref
          .read(attachmentDataSourceProvider)
          .getAttachments(widget.item.id);
      final tagIds = await ref
          .read(tagDataSourceProvider)
          .getTaskTagIds(widget.item.id);
      final assigneeIds = await ref.read(
        taskAssigneeIdsProvider(widget.item.id).future,
      );

      if (mounted) {
        setState(() {
          _subtasks = subtasks;
          _attachments = attachments;
          _selectedTagIds = tagIds;
          _assigneeIds = assigneeIds;

          _initialSubtasks = List.from(subtasks);
          _initialTagIds = List.from(tagIds);
          _initialAssigneeIds = List.from(assigneeIds);
        });
      }
    } catch (e) {
      debugPrint('Failed to load task details from db: $e');
    }
  }

  void _initializeFields(NexusTask? task) {
    if (_initialized) return;

    if (task != null) {
      _titleController.text = task.title;
      _currentDescription = task.description ?? '';
      _selectedCategoryId = task.categoryId;
      _selectedStatus = task.status;
      _selectedPriority = task.priority;
      _dueDate = task.dueDate;

      if (task.estimatedMinutes != null) {
        _estimateHour = task.estimatedMinutes! ~/ 60;
        _estimateMinute = task.estimatedMinutes! % 60;
      }
    } else {
      _titleController.text = widget.item.title;
      _currentDescription = widget.item.description;
      _dueDate = widget.item.dueDate;

      _selectedStatus = switch (widget.item.status) {
        TaskBoardStatus.draft => 'draft',
        TaskBoardStatus.todo => 'todo',
        TaskBoardStatus.inProgress => 'in_progress',
        TaskBoardStatus.completed => 'done',
      };

      _selectedPriority = switch (widget.item.priority) {
        TaskBoardPriority.urgent => 'urgent',
        TaskBoardPriority.high => 'high',
        TaskBoardPriority.medium => 'medium',
        TaskBoardPriority.low => 'low',
        TaskBoardPriority.done => 'medium',
      };
    }

    _initialTitle = _titleController.text;
    _initialDesc = _currentDescription ?? '';
    _initialCategoryId = _selectedCategoryId;
    _initialStatus = _selectedStatus;
    _initialPriority = _selectedPriority;
    _initialDueDate = _dueDate;

    _initialized = true;
  }

  bool get _hasChanges {
    if (!_initialized) return false;

    if (_titleController.text != _initialTitle) return true;
    if ((_currentDescription ?? '') != _initialDesc) return true;
    if (_selectedCategoryId != _initialCategoryId) return true;
    if (_selectedStatus != _initialStatus) return true;
    if (_selectedPriority != _initialPriority) return true;

    final dateChanged =
        (_dueDate == null && _initialDueDate != null) ||
        (_dueDate != null && _initialDueDate == null) ||
        (_dueDate != null &&
            _initialDueDate != null &&
            !_dueDate!.isAtSameMomentAs(_initialDueDate!));
    if (dateChanged) return true;

    // Check tags
    if (_selectedTagIds.length != _initialTagIds.length) return true;
    for (final tagId in _selectedTagIds) {
      if (!_initialTagIds.contains(tagId)) return true;
    }

    // Check assignees
    if (_assigneeIds.length != _initialAssigneeIds.length) return true;
    for (final id in _assigneeIds) {
      if (!_initialAssigneeIds.contains(id)) return true;
    }

    // Check subtasks
    if (_subtasks.length != _initialSubtasks.length) return true;
    for (int i = 0; i < _subtasks.length; i++) {
      if (_subtasks[i].id != _initialSubtasks[i].id ||
          _subtasks[i].title != _initialSubtasks[i].title ||
          _subtasks[i].isDone != _initialSubtasks[i].isDone) {
        return true;
      }
    }

    // Check attachments
    if (_newAttachments.isNotEmpty || _deletedAttachments.isNotEmpty)
      return true;

    return false;
  }

  Future<void> _deleteAttachment(TaskAttachmentModel attachment) async {
    final client = ref.read(supabaseClientProvider);
    try {
      await client.storage.from('task-attachments').remove([
        attachment.storagePath,
      ]);
    } catch (e) {
      debugPrint('Failed to remove attachment file from storage: $e');
    }
    await client.from('task_attachments').delete().eq('id', attachment.id);
  }

  Future<void> _updateTaskAssignees(
    String taskId,
    List<String> assigneeIds,
  ) async {
    final supabase = ref.read(supabaseClientProvider);
    await supabase.from('task_assignees').delete().eq('task_id', taskId);
    if (assigneeIds.isNotEmpty) {
      final rows =
          assigneeIds
              .map((uid) => {'task_id': taskId, 'user_id': uid})
              .toList();
      await supabase.from('task_assignees').insert(rows);
    }
  }

  Future<void> _saveChanges() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tiêu đề công việc không được bỏ trống!'),
          backgroundColor: DashboardColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final tasks = ref.read(userTasksProvider).valueOrNull ?? [];
      final nexusTask = tasks.firstWhere(
        (t) => t.id == widget.item.id,
        orElse: () => throw Exception('Không tìm thấy task trong database'),
      );

      final estMin = _estimateHour * 60 + _estimateMinute;
      final completedNow =
          _selectedStatus == 'done' && nexusTask.status != 'done';

      final updated = nexusTask.copyWith(
        title: title,
        description: _currentDescription,
        categoryId: _selectedCategoryId,
        status: _selectedStatus,
        priority: _selectedPriority,
        dueDate: _dueDate,
        estimatedMinutes: estMin,
        completedAt: _selectedStatus == 'done' ? DateTime.now().toUtc() : null,
      );

      // 1. Update task basic info
      await ref.read(taskRepositoryProvider).updateTask(updated);

      // 2. Update tags
      await ref
          .read(tagDataSourceProvider)
          .setTaskTags(widget.item.id, _selectedTagIds);

      // 3. Update assignees
      await _updateTaskAssignees(widget.item.id, _assigneeIds);

      // 4. Sync subtasks
      final dbSubtasks = await ref
          .read(subtaskDataSourceProvider)
          .getSubtasks(widget.item.id);
      // Delete missing subtasks
      for (final dbSub in dbSubtasks) {
        if (!_subtasks.any((s) => s.id == dbSub.id)) {
          await ref.read(subtaskDataSourceProvider).deleteSubtask(dbSub.id);
        }
      }
      // Insert/Update current subtasks
      for (final sub in _subtasks) {
        if (sub.id.isEmpty) {
          await ref
              .read(subtaskDataSourceProvider)
              .createSubtask(sub.copyWith(taskId: widget.item.id));
        } else {
          final dbSub = dbSubtasks.firstWhere(
            (s) => s.id == sub.id,
            orElse: () => sub,
          );
          if (dbSub.title != sub.title || dbSub.isDone != sub.isDone) {
            await ref.read(subtaskDataSourceProvider).updateSubtask(sub.id, {
              'title': sub.title,
              'is_done': sub.isDone,
            });
          }
        }
      }

      // 5. Sync attachments
      for (final att in _deletedAttachments) {
        await _deleteAttachment(att);
      }
      if (_newAttachments.isNotEmpty) {
        final user = ref.read(authControllerProvider).valueOrNull;
        if (user != null) {
          await ref
              .read(attachmentDataSourceProvider)
              .uploadAttachments(
                taskId: widget.item.id,
                userId: user.id,
                files: _newAttachments,
              );
        }
      }

      // Timeline log
      final userProfile = ref.read(userProfileProvider).valueOrNull;
      final actor =
          userProfile?.fullName ??
          userProfile?.username ??
          userProfile?.email ??
          'You';
      await ref
          .read(taskTimelineProvider(widget.item.id).notifier)
          .addActivity(
            actorName: actor,
            action: 'edit_task',
            detail: 'modified task details, subtasks, or attachments',
          );

      if (completedNow && !nexusTask.xpAwarded) {
        await ref
            .read(streakRemoteDataSourceProvider)
            .updateUserStreak('Task Completed');
        ref.invalidate(xpLogsProvider);
      }

      // Invalidate relevant providers to force a refresh across the app
      ref.invalidate(userTasksProvider);
      ref.invalidate(userCategoriesProvider);
      ref.invalidate(userTagsProvider);
      ref.invalidate(taskSubtasksProvider(widget.item.id));
      ref.invalidate(taskAttachmentsProvider(widget.item.id));
      ref.invalidate(taskAssigneeIdsProvider(widget.item.id));
      ref.invalidate(taskTagIdsProvider(widget.item.id));
      ref.invalidate(userAttachmentTaskIdsProvider);
      ref.invalidate(userSubtasksByTaskProvider);

      if (mounted) {
        await _showSuccessDialog();

        final users = ref.read(allUsersProvider).valueOrNull ?? [];
        final tags = ref.read(userTagsProvider).valueOrNull ?? [];
        final updatedItem = _mapTaskToBoardItem(updated, users, tags);

        if (widget.onSaveSuccess != null) {
          widget.onSaveSuccess!(updatedItem);
        } else {
          _handleBack();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi lưu thay đổi: $e'),
            backgroundColor: DashboardColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

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
    } else if (creatorUser.username != null &&
        creatorUser.username!.isNotEmpty) {
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
      xpAwarded: task.xpAwarded,
    );
  }

  Future<void> _showSuccessDialog() async {
    if (!mounted) return;
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.65),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final scale = Tween<double>(begin: 0.85, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: const Cubic(0.34, 1.56, 0.64, 1.0),
          ),
        );
        final opacity = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        );

        return GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          behavior: HitTestBehavior.opaque,
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 12.0 * animation.value,
              sigmaY: 12.0 * animation.value,
            ),
            child: ScaleTransition(
              scale: scale,
              child: FadeTransition(
                opacity: opacity,
                child: Dialog(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  insetPadding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Container(
                          width: 300,
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF090D1A,
                            ).withValues(alpha: 0.82),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: const Color(
                                0xFF10B981,
                              ).withValues(alpha: 0.25),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF10B981,
                                ).withValues(alpha: 0.12),
                                blurRadius: 24,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const _SuccessCheckmarkWidget(),
                              const SizedBox(height: 20),
                              const Text(
                                'Cập nhật thành công!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.2,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Mọi thay đổi của công việc đã được đồng bộ hóa thành công.',
                                style: TextStyle(
                                  color: DashboardColors.onSurfaceVariant
                                      .withValues(alpha: 0.7),
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              const _BlinkingTextPrompt(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleBack() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else {
      Navigator.of(context).pop();
    }
    ref.read(editingTaskProvider.notifier).state = null;
  }

  void _handleProfileTap() {
    ref.read(editingTaskProvider.notifier).state = null;
    context.go('/profile');
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: DashboardColors.surfaceLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Colors.white12),
            ),
            title: const Text(
              'Xác nhận xóa',
              style: TextStyle(
                color: DashboardColors.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'Bạn có chắc chắn muốn xóa công việc "${widget.item.title}" không?',
              style: const TextStyle(color: DashboardColors.onSurfaceVariant),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Hủy',
                  style: TextStyle(color: DashboardColors.onSurfaceVariant),
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: DashboardColors.error,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Xóa', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(taskRepositoryProvider).deleteTask(widget.item.id);
        ref.invalidate(userTasksProvider);
        ref.invalidate(userAttachmentTaskIdsProvider);
        ref.invalidate(userSubtasksByTaskProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã xóa công việc thành công'),
              backgroundColor: DashboardColors.success,
            ),
          );
          _handleBack();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Lỗi khi xóa: $e')));
        }
      }
    }
  }

  @override
  void dispose() {
    _titleController.removeListener(_onTextChanged);
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(userTasksProvider).valueOrNull ?? [];
    final nexusTask = tasks.cast<NexusTask?>().firstWhere(
      (t) => t?.id == widget.item.id,
      orElse: () => null,
    );

    _initializeFields(nexusTask);

    final categories = ref.watch(userCategoriesProvider).valueOrNull ?? [];
    final tags = ref.watch(userTagsProvider).valueOrNull ?? [];
    final allUsers = ref.watch(allUsersProvider).valueOrNull ?? [];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;
        final isTablet =
            constraints.maxWidth >= 768 && constraints.maxWidth < 1200;

        final overviewWidget = StaggeredEntrance(
          delayIndex: 1,
          child: TaskOverviewCards(
            priority: _selectedPriority,
            status: _selectedStatus,
            categoryId: _selectedCategoryId,
            categories: categories,
            dueDate: _dueDate,
            subtasks: _subtasks,
            estimateMinutes: _estimateHour * 60 + _estimateMinute,
            actualMinutes: _actualHour * 60 + _actualMinute,
            attachmentsCount: _attachments.length + _newAttachments.length,
            hasDescription:
                parseDescriptionToPlainText(_currentDescription).isNotEmpty,
            tagsCount: _selectedTagIds.length,
            isMobile: isMobile,
          ),
        );

        final generalInfoWidget = StaggeredEntrance(
          delayIndex: 2,
          child: TaskGeneralInfoCard(
            titleController: _titleController,
            taskId: widget.item.id,
            initialDescription: _currentDescription ?? '',
            onDescriptionChanged: (val) {
              setState(() {
                _currentDescription = val;
              });
            },
            estimateHour: _estimateHour,
            estimateMinute: _estimateMinute,
            onEstimateChanged:
                (h, m) => setState(() {
                  _estimateHour = h;
                  _estimateMinute = m;
                }),
            actualHour: _actualHour,
            actualMinute: _actualMinute,
            onActualChanged:
                (h, m) => setState(() {
                  _actualHour = h;
                  _actualMinute = m;
                }),
            categories: categories,
            tags: tags,
            selectedCategoryId: _selectedCategoryId,
            onCategoryChanged:
                (catId) => setState(() => _selectedCategoryId = catId),
            selectedStatus: _selectedStatus,
            onStatusChanged:
                (status) => setState(() => _selectedStatus = status),
            dueDate: _dueDate,
            onDueDateChanged: (date) => setState(() => _dueDate = date),
            selectedTagIds: _selectedTagIds,
            onAddTag: (tid) => setState(() => _selectedTagIds.add(tid)),
            onRemoveTag: (tid) => setState(() => _selectedTagIds.remove(tid)),
            selectedPriority: _selectedPriority,
            onPriorityChanged:
                (newPriority) =>
                    setState(() => _selectedPriority = newPriority),
            onCreateTag: (name, colorHex) async {
              final user = ref.read(authControllerProvider).valueOrNull;
              if (user == null) throw Exception('User is not signed in');
              return ref
                  .read(tagDataSourceProvider)
                  .createTag(
                    TagModel(
                      id: '',
                      userId: user.id,
                      name: name,
                      color: colorHex,
                    ),
                  );
            },
            onCreateCategory: (name, colorHex, iconName) async {
              final user = ref.read(authControllerProvider).valueOrNull;
              if (user == null) throw Exception('User is not signed in');
              return ref
                  .read(categoryDataSourceProvider)
                  .createCategory(
                    CategoryModel(
                      id: '',
                      userId: user.id,
                      name: name,
                      color: colorHex,
                      icon: iconName,
                    ),
                  );
            },
          ),
        );

        final assigneesWidget = StaggeredEntrance(
          delayIndex: 3,
          child: TaskAssigneesSection(
            assigneeIds: _assigneeIds,
            allUsers: allUsers,
            onAddAssignee: (uid) => setState(() => _assigneeIds.add(uid)),
            onRemoveAssignee: (uid) => setState(() => _assigneeIds.remove(uid)),
            isMobile: isMobile,
          ),
        );

        final subtasksWidget = StaggeredEntrance(
          delayIndex: 4,
          child: TaskSubtasksSection(
            subtasks: _subtasks,
            onSubtasksChanged: (list) => setState(() => _subtasks = list),
          ),
        );

        final attachmentsWidget = StaggeredEntrance(
          delayIndex: 5,
          child: TaskAttachmentsSection(
            attachments: _attachments,
            newAttachments: _newAttachments,
            onAddAttachments:
                (list) => setState(() => _newAttachments.addAll(list)),
            onRemoveExistingAttachment:
                (att) => setState(() {
                  _attachments.remove(att);
                  _deletedAttachments.add(att);
                }),
            onRemoveNewAttachment:
                (idx) => setState(() => _newAttachments.removeAt(idx)),
            isMobile: isMobile,
          ),
        );

        final aiAnalysisWidget = StaggeredEntrance(
          delayIndex: 6,
          child: TaskAIAnalysisSection(item: widget.item, isMobile: isMobile),
        );

        final bottomBarWidget =
            _hasChanges
                ? StaggeredEntrance(
                  delayIndex: 7,
                  child: TaskBottomActionBar(
                    onSave: _saveChanges,
                    onCancel: _handleBack,
                    onDelete: _confirmDelete,
                    isMobile: isMobile,
                    isSaving: _isSaving,
                  ),
                )
                : const SizedBox.shrink();

        final healthCard = StaggeredEntrance(
          delayIndex: 4,
          child: TaskHealthCard(item: widget.item, isMobile: isMobile),
        );

        final smartScheduleCard = StaggeredEntrance(
          delayIndex: 6,
          child: TaskSmartScheduleCard(isMobile: isMobile),
        );

        final xpPreviewCard = StaggeredEntrance(
          delayIndex: 5,
          child: _XPPreviewCard(),
        );

        final dependenciesCard = StaggeredEntrance(
          delayIndex: 6,
          child: _DependenciesCard(isMobile: isMobile),
        );

        final activityTimelineCard = StaggeredEntrance(
          delayIndex: 7,
          child: _ActivityTimelineCard(taskId: widget.item.id),
        );

        final productivityBoosterCard = StaggeredEntrance(
          delayIndex: 8,
          child: const TaskProductivityBoosterCard(),
        );

        final focusTimerCard = StaggeredEntrance(
          delayIndex: 9,
          child: const TaskFocusTimerCard(),
        );

        final achievementsCard = StaggeredEntrance(
          delayIndex: 10,
          child: const TaskAchievementsCard(),
        );

        final headerWidget = TaskHeaderSection(
          item: widget.item,
          onBack: _handleBack,
          title: _titleController.text,
          status: _selectedStatus,
          categoryId: _selectedCategoryId,
          tagIds: _selectedTagIds,
          assigneeIds: _assigneeIds,
          aiGenerated: nexusTask?.aiGenerated ?? false,
        );

        if (isMobile) {
          return EditTaskMobileLayout(
            header: headerWidget,
            overview: overviewWidget,
            generalInfo: generalInfoWidget,
            subtasks: subtasksWidget,
            attachments: attachmentsWidget,
            aiAnalysis: aiAnalysisWidget,
            assignees: assigneesWidget,
            bottomBar: bottomBarWidget,
          );
        }

        if (isTablet) {
          return EditTaskTabletLayout(
            header: headerWidget,
            overview: overviewWidget,
            onProfileTap: _handleProfileTap,
            generalInfo: generalInfoWidget,
            subtasks: subtasksWidget,
            attachments: attachmentsWidget,
            aiAnalysis: aiAnalysisWidget,
            assignees: assigneesWidget,
            bottomBar: bottomBarWidget,
            xpPreviewCard: xpPreviewCard,
            dependenciesCard: dependenciesCard,
            activityTimelineCard: activityTimelineCard,
            healthCard: healthCard,
            smartSchedule: smartScheduleCard,
            productivityBoosterCard: productivityBoosterCard,
            focusTimerCard: focusTimerCard,
            achievementsCard: achievementsCard,
          );
        }

        return EditTaskDesktopLayout(
          header: headerWidget,
          overview: overviewWidget,
          onProfileTap: _handleProfileTap,
          generalInfo: generalInfoWidget,
          subtasks: subtasksWidget,
          attachments: attachmentsWidget,
          aiAnalysis: aiAnalysisWidget,
          assignees: assigneesWidget,
          bottomBar: bottomBarWidget,
          xpPreviewCard: xpPreviewCard,
          dependenciesCard: dependenciesCard,
          activityTimelineCard: activityTimelineCard,
          healthCard: healthCard,
          smartSchedule: smartScheduleCard,
          productivityBoosterCard: productivityBoosterCard,
          focusTimerCard: focusTimerCard,
          achievementsCard: achievementsCard,
        );
      },
    );
  }
}

// ── Entry Animations ─────────────────────────────────────────────────────────

class StaggeredEntrance extends StatefulWidget {
  const StaggeredEntrance({
    required this.child,
    required this.delayIndex,
    super.key,
  });

  final Widget child;
  final int delayIndex;

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: 50 * widget.delayIndex), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(position: _slideAnimation, child: widget.child),
    );
  }
}

// ── Additional Static/Preview Desktop Cards (XP, Dependencies, Activity) ────

class _XPPreviewCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 255, 255, 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color.fromRGBO(255, 255, 255, 0.08)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DashboardColors.primary.withValues(alpha: 0.05),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(
                Icons.military_tech_rounded,
                color: DashboardColors.primary,
                size: 22,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: DashboardColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'LVL 6 SPECIALIST',
                  style: TextStyle(
                    color: DashboardColors.primary,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'CURRENT XP',
                style: TextStyle(
                  color: DashboardColors.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '950 / 1100',
                style: TextStyle(
                  color: DashboardColors.onSurface,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.86,
              child: Container(
                decoration: BoxDecoration(
                  color: DashboardColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Reward +100 XP will trigger Level 7!',
            style: TextStyle(
              color: DashboardColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _DependenciesCard extends StatelessWidget {
  const _DependenciesCard({required this.isMobile});
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 255, 255, 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color.fromRGBO(255, 255, 255, 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.account_tree_rounded,
                color: DashboardColors.primary,
                size: 22,
              ),
              SizedBox(width: 12),
              Text(
                'Dependencies',
                style: TextStyle(
                  color: DashboardColors.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'PARENT TASKS (BLOCKING THIS)',
            style: TextStyle(
              color: DashboardColors.onSurfaceVariant,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: DashboardColors.surfaceLow,
              border: Border.all(
                color: DashboardColors.error.withValues(alpha: 0.25),
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lock_rounded,
                  color: DashboardColors.error,
                  size: 16,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Security Audit Phase 1',
                        style: TextStyle(
                          color: DashboardColors.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Due Oct 22 · High Priority',
                        style: TextStyle(
                          color: DashboardColors.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: DashboardColors.error.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'OVERDUE',
                    style: TextStyle(
                      color: DashboardColors.error,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'CHILD TASKS (WAITING ON THIS)',
            style: TextStyle(
              color: DashboardColors.onSurfaceVariant,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: DashboardColors.surfaceLow,
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.pending_actions_rounded,
                  color: DashboardColors.primary,
                  size: 16,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'QA Stress Testing',
                        style: TextStyle(
                          color: DashboardColors.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Due Oct 28 · Medium Priority',
                        style: TextStyle(
                          color: DashboardColors.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityTimelineCard extends ConsumerWidget {
  const _ActivityTimelineCard({required this.taskId});
  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timelineAsync = ref.watch(taskTimelineProvider(taskId));

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 255, 255, 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color.fromRGBO(255, 255, 255, 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ACTIVITY TIMELINE',
            style: TextStyle(
              color: DashboardColors.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 24),
          Builder(
            builder: (context) {
              final activities = timelineAsync;
              if (activities.isEmpty) {
                return const Text(
                  'No recent activity.',
                  style: TextStyle(color: Colors.white24, fontSize: 12),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: min(activities.length, 3),
                itemBuilder: (context, idx) {
                  final act = activities[idx];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: DashboardColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${act.actorName} ${act.detail}',
                                style: const TextStyle(
                                  color: DashboardColors.onSurface,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Today, 09:12 AM', // Mock timestamp for visual alignment
                                style: TextStyle(
                                  color: DashboardColors.onSurfaceVariant
                                      .withValues(alpha: 0.4),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SuccessCheckmarkPainter extends CustomPainter {
  final double circleScale;
  final double checkmarkProgress;
  final double rippleProgress;
  final double particleProgress;

  _SuccessCheckmarkPainter({
    required this.circleScale,
    required this.checkmarkProgress,
    required this.rippleProgress,
    required this.particleProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = 32.0;

    // 1. Draw expanding ripples/halos (behind the main circle)
    if (rippleProgress > 0) {
      final ripplePaint =
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0
            ..color = const Color(
              0xFF10B981,
            ).withValues(alpha: (1.0 - rippleProgress) * 0.4);

      // Inner ripple
      final radius1 = baseRadius * (1.0 + rippleProgress * 0.6);
      canvas.drawCircle(center, radius1, ripplePaint);

      // Outer ripple
      if (rippleProgress > 0.3) {
        final ripplePaint2 =
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.0
              ..color = const Color(
                0xFF10B981,
              ).withValues(alpha: (1.0 - rippleProgress) * 0.2);
        final radius2 = baseRadius * (1.0 + rippleProgress * 1.3);
        canvas.drawCircle(center, radius2, ripplePaint2);
      }
    }

    // 2. Draw bursting particles
    if (particleProgress > 0) {
      final particlePaint =
          Paint()
            ..style = PaintingStyle.fill
            ..color = const Color(
              0xFF34D399,
            ).withValues(alpha: (1.0 - particleProgress) * 0.8);

      final numParticles = 8;
      final distance = baseRadius * (1.1 + particleProgress * 1.5);
      for (int i = 0; i < numParticles; i++) {
        final angle =
            (i * 2 * 3.141592653589793) / numParticles +
            (particleProgress * 0.2);
        final px = center.dx + distance * cos(angle);
        final py = center.dy + distance * sin(angle);
        final radius = 3.0 * (1.0 - particleProgress * 0.5);
        canvas.drawCircle(Offset(px, py), radius, particlePaint);
      }
    }

    // 3. Draw the main background circle
    if (circleScale > 0) {
      final bgPaint =
          Paint()
            ..style = PaintingStyle.fill
            ..color = const Color(
              0xFF10B981,
            ).withValues(alpha: 0.12 * circleScale);

      final borderPaint =
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = const Color(
              0xFF10B981,
            ).withValues(alpha: 0.35 * circleScale);

      // Shadow/Glow
      final glowPaint =
          Paint()
            ..style = PaintingStyle.fill
            ..color = const Color(
              0xFF10B981,
            ).withValues(alpha: 0.2 * circleScale)
            ..imageFilter = ImageFilter.blur(sigmaX: 10, sigmaY: 10);

      canvas.drawCircle(center, baseRadius * circleScale, glowPaint);
      canvas.drawCircle(center, baseRadius * circleScale, bgPaint);
      canvas.drawCircle(center, baseRadius * circleScale, borderPaint);
    }

    // 4. Draw the drawing checkmark
    if (checkmarkProgress > 0) {
      final checkPaint =
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.5
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..color = const Color(0xFF10B981);

      final w = size.width;
      final h = size.height;
      final p0 = Offset(0.35 * w, 0.50 * h);
      final p1 = Offset(0.47 * w, 0.62 * h);
      final p2 = Offset(0.68 * w, 0.38 * h);

      final path = Path();
      if (checkmarkProgress <= 0.36) {
        final t = checkmarkProgress / 0.36;
        final current = Offset.lerp(p0, p1, t)!;
        path.moveTo(p0.dx, p0.dy);
        path.lineTo(current.dx, current.dy);
      } else {
        final t = (checkmarkProgress - 0.36) / 0.64;
        final current = Offset.lerp(p1, p2, t)!;
        path.moveTo(p0.dx, p0.dy);
        path.lineTo(p1.dx, p1.dy);
        path.lineTo(current.dx, current.dy);
      }
      canvas.drawPath(path, checkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SuccessCheckmarkPainter oldDelegate) {
    return oldDelegate.circleScale != circleScale ||
        oldDelegate.checkmarkProgress != checkmarkProgress ||
        oldDelegate.rippleProgress != rippleProgress ||
        oldDelegate.particleProgress != particleProgress;
  }
}

class _SuccessCheckmarkWidget extends StatefulWidget {
  const _SuccessCheckmarkWidget();

  @override
  State<_SuccessCheckmarkWidget> createState() =>
      _SuccessCheckmarkWidgetState();
}

class _SuccessCheckmarkWidgetState extends State<_SuccessCheckmarkWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _circleScale;
  late Animation<double> _checkmarkProgress;
  late Animation<double> _rippleProgress;
  late Animation<double> _particleProgress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _circleScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.elasticOut),
      ),
    );

    _checkmarkProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.8, curve: Curves.easeInOut),
      ),
    );

    _rippleProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _particleProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(120, 120),
          painter: _SuccessCheckmarkPainter(
            circleScale: _circleScale.value,
            checkmarkProgress: _checkmarkProgress.value,
            rippleProgress: _rippleProgress.value,
            particleProgress: _particleProgress.value,
          ),
        );
      },
    );
  }
}

class _BlinkingTextPrompt extends StatefulWidget {
  const _BlinkingTextPrompt();

  @override
  State<_BlinkingTextPrompt> createState() => _BlinkingTextPromptState();
}

class _BlinkingTextPromptState extends State<_BlinkingTextPrompt>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _opacity = Tween<double>(
      begin: 0.25,
      end: 0.75,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: const Text(
        'Chạm bất kỳ đâu để quay lại',
        style: TextStyle(
          color: DashboardColors.onSurfaceVariant,
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
