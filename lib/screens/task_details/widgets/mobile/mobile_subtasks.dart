import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/features/tasks/data/models/task_subtask_model.dart';
import 'package:to_do_app/features/tasks/presentation/providers/tasks_provider.dart';
import 'package:to_do_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:to_do_app/features/tasks/presentation/providers/task_timeline_provider.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';
import 'package:to_do_app/features/streak/presentation/providers/streak_providers.dart';

class MobileSubtasks extends ConsumerStatefulWidget {
  const MobileSubtasks({required this.taskId, super.key});
  final String taskId;

  @override
  ConsumerState<MobileSubtasks> createState() => _MobileSubtasksState();
}

class _MobileSubtasksState extends ConsumerState<MobileSubtasks> {
  final _ctrl = TextEditingController();
  bool _isAdding = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _add(String title) async {
    if (title.trim().isEmpty) return;
    try {
      await ref.read(subtaskDataSourceProvider).createSubtask(
            TaskSubtaskModel(id: '', taskId: widget.taskId, title: title.trim(), isDone: false),
          );
      ref.invalidate(taskSubtasksProvider(widget.taskId));
      await ref.read(streakRemoteDataSourceProvider).updateUserStreak('Subtask Created');
      final userProfile = ref.read(userProfileProvider).valueOrNull;
      final actor = userProfile?.fullName ?? userProfile?.username ?? userProfile?.email ?? 'You';
      await ref.read(taskTimelineProvider(widget.taskId).notifier).addActivity(
            actorName: actor,
            action: 'create_subtask',
            detail: 'Added subtask: "${title.trim()}"',
          );
      _ctrl.clear();
      setState(() => _isAdding = false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _toggle(TaskSubtaskModel s, bool val) async {
    try {
      final completedNow = val && !s.isDone;
      await ref.read(subtaskDataSourceProvider).updateSubtask(s.id, {'is_done': val});
      if (completedNow) {
        await ref.read(streakRemoteDataSourceProvider).updateUserStreak('Subtask Completed');
      }
      ref.invalidate(taskSubtasksProvider(widget.taskId));
      final userProfile = ref.read(userProfileProvider).valueOrNull;
      final actor = userProfile?.fullName ?? userProfile?.username ?? userProfile?.email ?? 'You';
      await ref.read(taskTimelineProvider(widget.taskId).notifier).addActivity(
            actorName: actor,
            action: val ? 'complete_subtask' : 'incomplete_subtask',
            detail: val ? 'Subtask "${s.title}" completed' : 'Subtask "${s.title}" marked incomplete',
          );
      // XP award/deduct is handled by DB trigger trg_handle_subtask_xp.
    } catch (_) {}
  }

  Future<void> _toggleAll(List<TaskSubtaskModel> subtasks, bool checkAll) async {
    try {
      final completesAny = checkAll && subtasks.any((s) => !s.isDone);
      final datasource = ref.read(subtaskDataSourceProvider);
      await Future.wait(subtasks.map((s) => datasource.updateSubtask(s.id, {'is_done': checkAll})));
      if (completesAny) {
        await ref.read(streakRemoteDataSourceProvider).updateUserStreak('Subtask Completed');
      }
      ref.invalidate(taskSubtasksProvider(widget.taskId));
      final userProfile = ref.read(userProfileProvider).valueOrNull;
      final actor = userProfile?.fullName ?? userProfile?.username ?? userProfile?.email ?? 'You';
      await ref.read(taskTimelineProvider(widget.taskId).notifier).addActivity(
            actorName: actor,
            action: checkAll ? 'complete_subtask' : 'incomplete_subtask',
            detail: checkAll ? 'All subtasks marked completed' : 'All subtasks marked incomplete',
          );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(taskSubtasksProvider(widget.taskId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        async.when(
          loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          error: (e, _) => Text('$e', style: const TextStyle(color: DashboardColors.error, fontSize: 12)),
          data: (subtasks) {
            final done = subtasks.where((s) => s.isDone).length;
            final allDone = subtasks.isNotEmpty && subtasks.every((s) => s.isDone);
            final anyDone = subtasks.any((s) => s.isDone);
            final isIndeterminate = anyDone && !allDone;

            Widget selectAllBox;
            if (allDone) {
              selectAllBox = const Icon(
                Icons.check_circle_rounded,
                color: DashboardColors.success,
                size: 22,
              );
            } else if (isIndeterminate) {
              selectAllBox = const Icon(
                Icons.remove_circle_rounded,
                color: DashboardColors.success,
                size: 22,
              );
            } else {
              selectAllBox = Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: DashboardColors.primary, width: 2),
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Subtasks ($done/${subtasks.length})',
                      style: const TextStyle(
                        color: DashboardColors.onSurfaceVariant,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => setState(() => _isAdding = true),
                      child: Row(
                        children: const [
                          Icon(Icons.add_rounded, color: DashboardColors.primary, size: 14),
                          SizedBox(width: 2),
                          Text('Add Task',
                              style: TextStyle(color: DashboardColors.primary, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (subtasks.isNotEmpty) ...[
                  _GlassCard(
                    highlight: false,
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => _toggleAll(subtasks, !allDone),
                          child: selectAllBox,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _toggleAll(subtasks, !allDone),
                            child: Text(
                              allDone ? 'Deselect All' : 'Select All',
                              style: const TextStyle(
                                color: DashboardColors.onSurfaceVariant,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                ...subtasks.map((s) => _SubtaskItem(
                      subtask: s,
                      onToggle: (v) => _toggle(s, v),
                    )),
                if (_isAdding)
                  _AddRow(
                    ctrl: _ctrl,
                    onSubmit: _add,
                    onCancel: () => setState(() {
                      _isAdding = false;
                      _ctrl.clear();
                    }),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _SubtaskItem extends StatelessWidget {
  const _SubtaskItem({required this.subtask, required this.onToggle});
  final TaskSubtaskModel subtask;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) => _GlassCard(
        highlight: !subtask.isDone,
        child: Row(
          children: [
            GestureDetector(
              onTap: () => onToggle(!subtask.isDone),
              child: subtask.isDone
                  ? const Icon(Icons.check_circle_rounded,
                      color: DashboardColors.success, size: 22)
                  : Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: DashboardColors.primary, width: 2),
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                subtask.title,
                style: TextStyle(
                  color: subtask.isDone
                      ? DashboardColors.onSurfaceVariant
                      : DashboardColors.onSurface,
                  fontSize: 15,
                  decoration: subtask.isDone ? TextDecoration.lineThrough : null,
                  decorationColor: DashboardColors.onSurfaceVariant,
                ),
              ),
            ),
            const Icon(Icons.drag_indicator_rounded,
                color: Color(0x33C7C5D0), size: 18),
          ],
        ),
      );
}

class _AddRow extends StatelessWidget {
  const _AddRow({required this.ctrl, required this.onSubmit, required this.onCancel});
  final TextEditingController ctrl;
  final ValueChanged<String> onSubmit;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: _GlassCard(
          highlight: true,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: ctrl,
                  autofocus: true,
                  style: const TextStyle(color: DashboardColors.onSurface, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'New subtask…',
                    hintStyle: TextStyle(color: DashboardColors.outline),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onSubmitted: onSubmit,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.check_rounded, color: DashboardColors.primary, size: 16),
                onPressed: () => onSubmit(ctrl.text),
                padding: const EdgeInsets.all(2),
                constraints: const BoxConstraints(),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: DashboardColors.error, size: 16),
                onPressed: onCancel,
                padding: const EdgeInsets.all(2),
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      );
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child, this.highlight = false});
  final Widget child;
  final bool highlight;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: highlight
                  ? DashboardColors.surfaceContainer
                  : Colors.white.withValues(alpha: .03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: .08)),
            ),
            child: child,
          ),
        ),
      );
}
