import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/features/tasks/data/models/task_subtask_model.dart';
import 'package:to_do_app/features/tasks/presentation/providers/tasks_provider.dart';
import 'package:to_do_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:to_do_app/features/tasks/presentation/providers/task_timeline_provider.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class DesktopSubtasks extends ConsumerStatefulWidget {
  const DesktopSubtasks({required this.taskId, super.key});
  final String taskId;

  @override
  ConsumerState<DesktopSubtasks> createState() => _DesktopSubtasksState();
}

class _DesktopSubtasksState extends ConsumerState<DesktopSubtasks> {
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _toggle(TaskSubtaskModel s, bool val) async {
    try {
      await ref.read(subtaskDataSourceProvider).updateSubtask(s.id, {'is_done': val});
      ref.invalidate(taskSubtasksProvider(widget.taskId));
      final userProfile = ref.read(userProfileProvider).valueOrNull;
      final actor = userProfile?.fullName ?? userProfile?.username ?? userProfile?.email ?? 'You';
      await ref.read(taskTimelineProvider(widget.taskId).notifier).addActivity(
            actorName: actor,
            action: val ? 'complete_subtask' : 'incomplete_subtask',
            detail: val ? 'Subtask "${s.title}" completed' : 'Subtask "${s.title}" marked incomplete',
          );
    } catch (_) {}
  }

  Future<void> _toggleAll(List<TaskSubtaskModel> subtasks, bool checkAll) async {
    try {
      final datasource = ref.read(subtaskDataSourceProvider);
      await Future.wait(subtasks.map((s) => datasource.updateSubtask(s.id, {'is_done': checkAll})));
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

  Future<void> _delete(String id) async {
    try {
      final subtasks = ref.read(taskSubtasksProvider(widget.taskId)).valueOrNull ?? [];
      final s = subtasks.firstWhere((e) => e.id == id, orElse: () => TaskSubtaskModel(id: '', taskId: '', title: 'Subtask', isDone: false));
      await ref.read(subtaskDataSourceProvider).deleteSubtask(id);
      ref.invalidate(taskSubtasksProvider(widget.taskId));
      final userProfile = ref.read(userProfileProvider).valueOrNull;
      final actor = userProfile?.fullName ?? userProfile?.username ?? userProfile?.email ?? 'You';
      await ref.read(taskTimelineProvider(widget.taskId).notifier).addActivity(
            actorName: actor,
            action: 'delete_subtask',
            detail: 'Deleted subtask: "${s.title}"',
          );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(taskSubtasksProvider(widget.taskId));
    return _GlassPanel(
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (e, _) => Text('Error: $e', style: const TextStyle(color: DashboardColors.error)),
        data: (subtasks) {
          final done = subtasks.where((s) => s.isDone).length;
          final allDone = subtasks.isNotEmpty && subtasks.every((s) => s.isDone);
          final anyDone = subtasks.any((s) => s.isDone);
          final isIndeterminate = anyDone && !allDone;

          Widget selectAllBox;
          if (allDone) {
            selectAllBox = Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: DashboardColors.success,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: DashboardColors.success,
                ),
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
            );
          } else if (isIndeterminate) {
            selectAllBox = Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: DashboardColors.success.withValues(alpha: .2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: DashboardColors.success,
                ),
              ),
              child: const Icon(Icons.remove_rounded, color: Colors.white, size: 14),
            );
          } else {
            selectAllBox = Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: DashboardColors.outline,
                ),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Text('Subtasks',
                      style: TextStyle(
                          color: DashboardColors.onSurface,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -.01)),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: DashboardColors.primary.withValues(alpha: .18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$done/${subtasks.length} DONE',
                      style: const TextStyle(
                          color: DashboardColors.primary, fontSize: 10, fontWeight: FontWeight.w900),
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => setState(() => _isAdding = true),
                    icon: const Icon(Icons.add_rounded, size: 16, color: DashboardColors.primary),
                    label: const Text('Add Subtask',
                        style: TextStyle(color: DashboardColors.primary, fontSize: 14)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (subtasks.isNotEmpty) ...[
                Row(
                  children: [
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () => _toggleAll(subtasks, !allDone),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: selectAllBox,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _toggleAll(subtasks, !allDone),
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: Text(
                            allDone ? 'Deselect All' : 'Select All',
                            style: const TextStyle(
                              color: DashboardColors.onSurfaceVariant,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              ...subtasks.map((s) => _SubtaskRow(
                    subtask: s,
                    onToggle: (v) => _toggle(s, v),
                    onDelete: () => _delete(s.id),
                  )),
              if (_isAdding) ...[
                const SizedBox(height: 8),
                _AddSubtaskRow(
                  ctrl: _ctrl,
                  onSubmit: _add,
                  onCancel: () => setState(() {
                    _isAdding = false;
                    _ctrl.clear();
                  }),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SubtaskRow extends StatelessWidget {
  const _SubtaskRow({required this.subtask, required this.onToggle, required this.onDelete});
  final TaskSubtaskModel subtask;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: subtask.isDone
              ? DashboardColors.surfaceLow.withValues(alpha: .6)
              : DashboardColors.surfaceLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: .06)),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => onToggle(!subtask.isDone),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: subtask.isDone ? DashboardColors.success : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: subtask.isDone ? DashboardColors.success : DashboardColors.outline,
                  ),
                ),
                child: subtask.isDone
                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                    : null,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                subtask.title,
                style: TextStyle(
                  color: subtask.isDone
                      ? DashboardColors.onSurfaceVariant
                      : DashboardColors.onSurface,
                  fontSize: 16,
                  decoration: subtask.isDone ? TextDecoration.lineThrough : null,
                  decorationColor: DashboardColors.onSurfaceVariant,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.drag_indicator_rounded,
                  color: DashboardColors.onSurfaceVariant, size: 18),
              onPressed: null,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddSubtaskRow extends StatelessWidget {
  const _AddSubtaskRow({required this.ctrl, required this.onSubmit, required this.onCancel});
  final TextEditingController ctrl;
  final ValueChanged<String> onSubmit;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: DashboardColors.surfaceLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: DashboardColors.primary.withValues(alpha: .3)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: ctrl,
                autofocus: true,
                style: const TextStyle(color: DashboardColors.onSurface, fontSize: 15),
                decoration: const InputDecoration(
                  hintText: 'New subtask...',
                  hintStyle: TextStyle(color: DashboardColors.outline),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onSubmitted: onSubmit,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.check_rounded, color: DashboardColors.primary, size: 18),
              onPressed: () => onSubmit(ctrl.text),
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: DashboardColors.error, size: 18),
              onPressed: onCancel,
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      );
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: .08)),
            ),
            child: child,
          ),
        ),
      );
}
