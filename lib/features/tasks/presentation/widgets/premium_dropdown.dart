import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/core/services/app_providers.dart';
import 'package:to_do_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:to_do_app/features/tasks/domain/entities/task_board_item.dart';
import 'package:to_do_app/features/tasks/presentation/providers/tasks_provider.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';
import 'package:to_do_app/features/streak/presentation/providers/streak_providers.dart';

// ── Shared glass container ────────────────────────────────────────────────────

class _GlassMenu extends StatelessWidget {
  const _GlassMenu({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          width: 280,
          decoration: BoxDecoration(
            color: const Color(0xFF0A0E1E).withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 50,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

// ── Menu item tile ────────────────────────────────────────────────────────────

class _MenuTile extends StatefulWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    this.color,
    this.trailing,
    this.danger = false,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color? color;
  final Widget? trailing;
  final bool danger;
  final VoidCallback onTap;

  @override
  State<_MenuTile> createState() => _MenuTileState();
}

class _MenuTileState extends State<_MenuTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final fg = widget.danger
        ? DashboardColors.error
        : (widget.color ?? DashboardColors.onSurface);
    final iconColor = widget.danger
        ? DashboardColors.error
        : (widget.color ?? DashboardColors.onSurfaceVariant);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).pop();
          widget.onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: _hovered
                ? (widget.danger
                    ? DashboardColors.error.withValues(alpha: 0.10)
                    : Colors.white.withValues(alpha: 0.06))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: _hovered
                ? Border.all(
                    color: widget.danger
                        ? DashboardColors.error.withValues(alpha: 0.25)
                        : Colors.white.withValues(alpha: 0.06),
                  )
                : null,
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 15, color: iconColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    color: fg,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (widget.trailing != null) widget.trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section divider ───────────────────────────────────────────────────────────

class _MenuDivider extends StatelessWidget {
  const _MenuDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Divider(
        height: 1,
        thickness: 1,
        color: Colors.white.withValues(alpha: 0.06),
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _MenuSection extends StatelessWidget {
  const _MenuSection(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.35),
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ── Show helper ───────────────────────────────────────────────────────────────

Future<void> _showGlassMenu({
  required BuildContext context,
  required Offset offset,
  required Widget menu,
}) async {
  await showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'menu',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (ctx, anim, _) => const SizedBox.shrink(),
    transitionBuilder: (ctx, anim, _, child) {
      final screen = MediaQuery.sizeOf(ctx);
      double left = offset.dx;
      double top = offset.dy;
      if (left + 280 > screen.width) left = screen.width - 296;
      if (top + 480 > screen.height) top = screen.height - 496;

      return Stack(
        children: [
          Positioned(
            left: left,
            top: top,
            child: FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -0.04),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                child: Material(
                  type: MaterialType.transparency,
                  child: menu,
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

// ═══════════════════════════════════════════════════════════════════
// COLUMN MENU
// ═══════════════════════════════════════════════════════════════════

class ColumnPremiumMenu extends ConsumerStatefulWidget {
  const ColumnPremiumMenu({
    required this.column,
    required this.sortType,
    required this.onSortChanged,
    required this.onCollapse,
    required this.onNewTask,
    super.key,
  });

  final TaskColumnData column;
  final String sortType;
  final ValueChanged<String> onSortChanged;
  final VoidCallback onCollapse;
  final VoidCallback onNewTask;

  @override
  ConsumerState<ColumnPremiumMenu> createState() => _ColumnPremiumMenuState();
}

class _ColumnPremiumMenuState extends ConsumerState<ColumnPremiumMenu> {
  bool _assigneeExpanded = false;

  @override
  Widget build(BuildContext context) {
    final count = widget.column.tasks.length;
    final users = ref.watch(allUsersProvider).valueOrNull ?? [];
    final columnTaskIds = widget.column.tasks.map((task) => task.id).toSet();
    final columnAssigneeIds = <String, int>{};
    for (final taskId in columnTaskIds) {
      final ids = ref.watch(taskAssigneeIdsProvider(taskId)).valueOrNull ?? const <String>[];
      for (final id in ids) {
        columnAssigneeIds[id] = (columnAssigneeIds[id] ?? 0) + 1;
      }
    }
    return _GlassMenu(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
            child: Row(
              children: [
                Icon(widget.column.status.displayIcon,
                    size: 14, color: widget.column.status.displayColor),
                const SizedBox(width: 8),
                Text(
                  widget.column.status.displayLabel.toUpperCase(),
                  style: TextStyle(
                    color: widget.column.status.displayColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Text(
                    '$count task${count == 1 ? '' : 's'}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const _MenuDivider(),
          const _MenuSection('Quick Actions'),
          _MenuTile(
            icon: Icons.add_rounded,
            label: 'New Task',
            color: DashboardColors.primary,
            onTap: widget.onNewTask,
          ),
          const _MenuDivider(),
          const _MenuSection('Sort By'),
          _MenuTile(
            icon: Icons.priority_high_rounded,
            label: 'Priority',
            trailing: widget.sortType == 'priority'
                ? const Icon(Icons.check_rounded, size: 13, color: DashboardColors.primary)
                : null,
            color: widget.sortType == 'priority' ? DashboardColors.primary : null,
            onTap: () => widget.onSortChanged(
                widget.sortType == 'priority' ? 'none' : 'priority'),
          ),
          _MenuTile(
            icon: Icons.calendar_month_rounded,
            label: 'Due Date',
            trailing: widget.sortType == 'dueDate'
                ? const Icon(Icons.check_rounded, size: 13, color: DashboardColors.primary)
                : null,
            color: widget.sortType == 'dueDate' ? DashboardColors.primary : null,
            onTap: () => widget.onSortChanged(
                widget.sortType == 'dueDate' ? 'none' : 'dueDate'),
          ),
          // Assignee sort/filter
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => setState(() => _assigneeExpanded = !_assigneeExpanded),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                child: Row(
                  children: [
                    const Icon(Icons.person_outline_rounded,
                        size: 15, color: DashboardColors.onSurfaceVariant),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text('Assignee',
                          style: TextStyle(
                            color: DashboardColors.onSurface,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          )),
                    ),
                    Icon(
                      _assigneeExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 15,
                      color: DashboardColors.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_assigneeExpanded)
            Container(
              margin: const EdgeInsets.fromLTRB(6, 0, 6, 4),
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .03),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: .06)),
              ),
              child: users.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('No users found',
                          style: TextStyle(
                            color: DashboardColors.onSurfaceVariant,
                            fontSize: 12,
                          )),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        children: users.map((user) {
                          final tasksForUser = columnAssigneeIds[user.id] ?? 0;
                          final name = (user.fullName?.trim().isNotEmpty ?? false)
                              ? user.fullName!
                              : (user.username?.trim().isNotEmpty ?? false)
                                  ? user.username!
                                  : user.email;
                          final initial = name.isEmpty ? '?' : name.characters.first.toUpperCase();
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: DashboardColors
                                      .secondaryContainer
                                      .withValues(alpha: .25),
                                  backgroundImage: user.avatarUrl == null
                                      ? null
                                      : NetworkImage(user.avatarUrl!),
                                  child: user.avatarUrl == null
                                      ? Text(initial,
                                          style: const TextStyle(
                                            color: DashboardColors.secondary,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                          ))
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(name,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: DashboardColors.onSurface,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      )),
                                ),
                                Text('($tasksForUser)',
                                    style: const TextStyle(
                                      color: DashboardColors.onSurfaceVariant,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    )),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
            ),
          const _MenuDivider(),
          const _MenuSection('Column'),
          _MenuTile(
            icon: Icons.view_column_rounded,
            label: 'Collapse Column',
            onTap: widget.onCollapse,
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

/// Show the column menu at [offset].
void showColumnMenu({
  required BuildContext context,
  required Offset offset,
  required TaskColumnData column,
  required String sortType,
  required ValueChanged<String> onSortChanged,
  required VoidCallback onCollapse,
  required VoidCallback onNewTask,
}) {
  _showGlassMenu(
    context: context,
    offset: offset,
    menu: ColumnPremiumMenu(
      column: column,
      sortType: sortType,
      onSortChanged: onSortChanged,
      onCollapse: onCollapse,
      onNewTask: onNewTask,
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════
// TASK CARD MENU
// ═══════════════════════════════════════════════════════════════════

class TaskCardPremiumMenu extends ConsumerWidget {
  const TaskCardPremiumMenu({
    required this.task,
    required this.isCreator,
    required this.onEdit,
    required this.onDelete,
    required this.onDuplicate,
    this.onOpenPage,
    super.key,
  });

  final TaskBoardItem task;
  final bool isCreator;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;
  final VoidCallback? onOpenPage;

  String _statusLabel(TaskBoardStatus s) {
    switch (s) {
      case TaskBoardStatus.draft: return 'Draft';
      case TaskBoardStatus.todo: return 'To-Do';
      case TaskBoardStatus.inProgress: return 'In Progress';
      case TaskBoardStatus.completed: return 'Completed';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDraft = task.status == TaskBoardStatus.draft;
    final isCompleted = task.status == TaskBoardStatus.completed;
    final isInProgress = task.status == TaskBoardStatus.inProgress;

    return _GlassMenu(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: task.priorityColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: task.priorityColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        task.priorityLabel.toUpperCase(),
                        style: TextStyle(
                          color: task.priorityColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _statusLabel(task.status),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const _MenuDivider(),
          // Primary actions
          const _MenuSection('Actions'),
          _MenuTile(
            icon: Icons.open_in_new_rounded,
            label: 'Open Task Page',
            color: DashboardColors.primary,
            onTap: () => onOpenPage?.call(),
          ),
          if (isCreator)
            _MenuTile(
              icon: Icons.edit_rounded,
              label: 'Edit Task',
              onTap: onEdit,
            ),
          _MenuTile(
            icon: Icons.copy_rounded,
            label: 'Duplicate Task',
            onTap: onDuplicate,
          ),
          const _MenuDivider(),
          // Assignee
          const _MenuSection('Assignee'),
          _AssigneeTile(task: task),
          const _MenuDivider(),
          // Workflow
          const _MenuSection('Workflow'),
          if (isDraft)
            _MenuTile(
              icon: Icons.rocket_launch_rounded,
              label: 'Start Task',
              onTap: () => _updateStatus(context, ref, 'todo'),
            ),
          if (isInProgress)
            _MenuTile(
              icon: Icons.check_circle_outline_rounded,
              label: 'Mark Complete',
              color: DashboardColors.success,
              onTap: () => _updateStatus(context, ref, 'done'),
            ),
          if (isCompleted)
            _MenuTile(
              icon: Icons.replay_rounded,
              label: 'Reopen Task',
              onTap: () => _updateStatus(context, ref, 'todo'),
            ),
          ..._moveTargets(task.status).map(
            (target) => _MenuTile(
              icon: target.icon,
              label: 'Move to ${target.label}',
              onTap: () => _updateStatus(context, ref, target.status),
            ),
          ),
          const _MenuDivider(),
          // Danger
          if (isCreator) ...[
            _MenuTile(
              icon: Icons.delete_rounded,
              label: 'Delete Task',
              danger: true,
              onTap: onDelete,
            ),
          ],
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  List<({String status, String label, IconData icon})> _moveTargets(
    TaskBoardStatus current,
  ) {
    final targets = <({TaskBoardStatus boardStatus, String status, String label, IconData icon})>[
      (boardStatus: TaskBoardStatus.draft, status: 'draft', label: 'Draft', icon: Icons.edit_note_rounded),
      (boardStatus: TaskBoardStatus.todo, status: 'todo', label: 'To-Do', icon: Icons.radio_button_unchecked_rounded),
      (boardStatus: TaskBoardStatus.inProgress, status: 'in_progress', label: 'In Progress', icon: Icons.play_circle_outline_rounded),
      (boardStatus: TaskBoardStatus.completed, status: 'done', label: 'Completed', icon: Icons.check_circle_outline_rounded),
    ];
    return targets
        .where((target) => target.boardStatus != current)
        .map((target) => (
              status: target.status,
              label: target.label,
              icon: target.icon,
            ))
        .toList();
  }

  Future<void> _updateStatus(BuildContext context, WidgetRef ref, String status) async {
    try {
      final tasks = ref.read(userTasksProvider).valueOrNull ?? [];
      final nexus = tasks.firstWhere((t) => t.id == task.id,
          orElse: () => throw Exception('Task not found'));
      final completedNow = nexus.status != 'done' && status == 'done';
      final draftToActive = nexus.status == 'draft' && (status == 'todo' || status == 'in_progress');
      final updated = nexus.copyWith(status: status);
      await ref.read(taskRepositoryProvider).updateTask(updated);
      if (completedNow) {
        await ref.read(streakRemoteDataSourceProvider).updateUserStreak('Task Completed');
      } else if (draftToActive) {
        await ref.read(streakRemoteDataSourceProvider).updateUserStreak('Task Activated');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  }
}

/// Show the task card menu at [offset].
void showTaskCardMenu({
  required BuildContext context,
  required Offset offset,
  required TaskBoardItem task,
  required bool isCreator,
  required VoidCallback onEdit,
  required VoidCallback onDelete,
  required VoidCallback onDuplicate,
  VoidCallback? onOpenPage,
}) {
  _showGlassMenu(
    context: context,
    offset: offset,
    menu: TaskCardPremiumMenu(
      task: task,
      isCreator: isCreator,
      onEdit: onEdit,
      onDelete: onDelete,
      onDuplicate: onDuplicate,
      onOpenPage: onOpenPage,
    ),
  );
}

// ── Assignee tile inside task card menu ───────────────────────────────────────

class _AssigneeTile extends ConsumerStatefulWidget {
  const _AssigneeTile({required this.task});
  final TaskBoardItem task;

  @override
  ConsumerState<_AssigneeTile> createState() => _AssigneeTileState();
}

class _AssigneeTileState extends ConsumerState<_AssigneeTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(allUsersProvider).valueOrNull ?? [];
    final assigneeIds =
        ref.watch(taskAssigneeIdsProvider(widget.task.id)).valueOrNull ??
            const <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              child: Row(
                children: [
                  const Icon(Icons.person_add_alt_1_rounded,
                      size: 15, color: DashboardColors.onSurfaceVariant),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      assigneeIds.isEmpty
                          ? 'Assign To...'
                          : '${assigneeIds.length} assignee${assigneeIds.length > 1 ? 's' : ''}',
                      style: const TextStyle(
                        color: DashboardColors.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 15,
                    color: DashboardColors.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_expanded)
          Container(
            margin: const EdgeInsets.fromLTRB(6, 0, 6, 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .03),
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: Colors.white.withValues(alpha: .06)),
            ),
            child: users.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('No users found',
                        style: TextStyle(
                          color: DashboardColors.onSurfaceVariant,
                          fontSize: 12,
                        )),
                  )
                : Column(
                    children: users.map((user) {
                      final isAssigned = assigneeIds.contains(user.id);
                      final name =
                          (user.fullName?.trim().isNotEmpty ?? false)
                              ? user.fullName!
                              : (user.username?.trim().isNotEmpty ?? false)
                                  ? user.username!
                                  : user.email;
                      final initial = name.isEmpty
                          ? '?'
                          : name.characters.first.toUpperCase();
                      return MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => _toggle(
                              context, ref, user.id, isAssigned),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: DashboardColors
                                      .secondaryContainer
                                      .withValues(alpha: .25),
                                  backgroundImage: user.avatarUrl == null
                                      ? null
                                      : NetworkImage(user.avatarUrl!),
                                  child: user.avatarUrl == null
                                      ? Text(initial,
                                          style: const TextStyle(
                                            color: DashboardColors.secondary,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                          ))
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(name,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: isAssigned
                                            ? DashboardColors.secondary
                                            : DashboardColors.onSurface,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      )),
                                ),
                                if (isAssigned)
                                  const Icon(Icons.check_rounded,
                                      size: 14,
                                      color: DashboardColors.secondary),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
      ],
    );
  }

  Future<void> _toggle(BuildContext context, WidgetRef ref,
      String userId, bool isAssigned) async {
    try {
      final supabase = ref.read(supabaseClientProvider);
      if (isAssigned) {
        await supabase
            .from('task_assignees')
            .delete()
            .eq('task_id', widget.task.id)
            .eq('user_id', userId);
      } else {
        await supabase.from('task_assignees').upsert(
          {'task_id': widget.task.id, 'user_id': userId},
          onConflict: 'task_id,user_id',
        );
      }
      ref.invalidate(taskAssigneeIdsProvider(widget.task.id));
      setState(() {});
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  }
}
