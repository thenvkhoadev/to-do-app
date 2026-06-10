import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/features/tasks/domain/entities/task_board_item.dart';
import 'package:to_do_app/features/tasks/presentation/providers/tasks_provider.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

// ── Shared glass container ────────────────────────────────────────────────────

class _GlassMenu extends StatelessWidget {
  const _GlassMenu({required this.child, this.width = 280});
  final Widget child;
  final double width;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          width: width,
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

class ColumnPremiumMenu extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final count = column.tasks.length;
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
                Icon(column.status.displayIcon,
                    size: 14, color: column.status.displayColor),
                const SizedBox(width: 8),
                Text(
                  column.status.displayLabel.toUpperCase(),
                  style: TextStyle(
                    color: column.status.displayColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08)),
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
          // Quick Actions
          const _MenuSection('Quick Actions'),
          _MenuTile(
            icon: Icons.add_rounded,
            label: 'New Task',
            color: DashboardColors.primary,
            onTap: onNewTask,
          ),
          const _MenuDivider(),
          // Sort
          const _MenuSection('Sort By'),
          _MenuTile(
            icon: Icons.priority_high_rounded,
            label: 'Priority',
            trailing: sortType == 'priority'
                ? const Icon(Icons.check_rounded,
                    size: 13, color: DashboardColors.primary)
                : null,
            color: sortType == 'priority' ? DashboardColors.primary : null,
            onTap: () => onSortChanged(sortType == 'priority' ? 'none' : 'priority'),
          ),
          _MenuTile(
            icon: Icons.calendar_month_rounded,
            label: 'Due Date',
            trailing: sortType == 'dueDate'
                ? const Icon(Icons.check_rounded,
                    size: 13, color: DashboardColors.primary)
                : null,
            color: sortType == 'dueDate' ? DashboardColors.primary : null,
            onTap: () => onSortChanged(sortType == 'dueDate' ? 'none' : 'dueDate'),
          ),
          _MenuTile(
            icon: Icons.person_outline_rounded,
            label: 'Assignee',
            onTap: () {},
          ),
          const _MenuDivider(),
          // Column Controls
          const _MenuSection('Column'),
          _MenuTile(
            icon: Icons.view_column_rounded,
            label: 'Collapse Column',
            onTap: onCollapse,
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
      final updated = nexus.copyWith(status: status);
      await ref.read(taskRepositoryProvider).updateTask(updated);
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
