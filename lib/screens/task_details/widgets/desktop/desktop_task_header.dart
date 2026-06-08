import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:to_do_app/features/tasks/domain/entities/task_board_item.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class DesktopTaskHeader extends StatelessWidget {
  const DesktopTaskHeader({
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
    super.key,
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
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          decoration: BoxDecoration(
            color: DashboardColors.surface.withValues(alpha: .42),
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: .08)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Breadcrumb
              Row(
                children: [
                  GestureDetector(
                    onTap: onBack,
                    child: const Text(
                      'Projects',
                      style: TextStyle(
                        color: DashboardColors.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: .05,
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(Icons.chevron_right_rounded,
                        size: 14, color: DashboardColors.onSurfaceVariant),
                  ),
                  const Text(
                    'UI Systems',
                    style: TextStyle(
                      color: DashboardColors.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(Icons.chevron_right_rounded,
                        size: 14, color: DashboardColors.onSurfaceVariant),
                  ),
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: DashboardColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Title row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: DashboardColors.onSurfaceVariant),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      item.title,
                      style: const TextStyle(
                        color: DashboardColors.onSurface,
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -.64,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Draft badge
                  _HeaderBadge(
                    label: item.status.name.toUpperCase(),
                    bgColor: DashboardColors.surfaceHigh.withValues(alpha: .5),
                    textColor: DashboardColors.onSurfaceVariant,
                    borderColor: Colors.white.withValues(alpha: .08),
                  ),
                  const SizedBox(width: 12),
                  // Priority badge
                  _HeaderBadge(
                    label: item.priorityLabel.toUpperCase(),
                    bgColor: item.priorityColor.withValues(alpha: .10),
                    textColor: item.priorityColor,
                    borderColor: item.priorityColor.withValues(alpha: .25),
                    icon: Icons.priority_high_rounded,
                  ),
                  const SizedBox(width: 20),
                  // Action buttons
                  if (item.status == TaskBoardStatus.draft) ...[
                    _ActionButton(
                      label: 'Plan Task',
                      icon: Icons.assignment_turned_in_rounded,
                      filled: true,
                      onTap: onPlanTask,
                    ),
                  ] else if (item.status == TaskBoardStatus.todo) ...[
                    _ActionButton(
                      label: isPaused ? 'Resume Task' : 'Start Task',
                      icon: Icons.play_arrow_rounded,
                      filled: true,
                      onTap: onStartTask,
                    ),
                  ] else if (item.status == TaskBoardStatus.inProgress) ...[
                    _ActionButton(
                      label: 'Pause Task',
                      icon: Icons.pause_rounded,
                      filled: false,
                      onTap: onPauseTask,
                      textColor: DashboardColors.primary,
                    ),
                  ] else if (item.status == TaskBoardStatus.completed) ...[
                    _ActionButton(
                      label: 'Completed',
                      icon: Icons.check_circle_rounded,
                      filled: true,
                      onTap: () {},
                      backgroundColor: DashboardColors.success.withValues(alpha: .2),
                      textColor: DashboardColors.success,
                    ),
                  ],
                  const SizedBox(width: 8),
                  _IconActionButton(
                    icon: Icons.check_circle_outline_rounded,
                    color: item.status == TaskBoardStatus.completed
                        ? DashboardColors.success
                        : DashboardColors.onSurfaceVariant,
                    onTap: item.status != TaskBoardStatus.completed ? onCompleteTask : null,
                  ),
                  if (isCreator) ...[
                    const SizedBox(width: 8),
                    _IconActionButton(
                      icon: Icons.edit_outlined,
                      onTap: onEditTask,
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      color: DashboardColors.surfaceLow,
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.white12),
                      ),
                      onSelected: (val) {
                        if (val == 'delete') {
                          onDeleteTask();
                        } else if (val == 'duplicate') {
                          onDuplicateTask();
                        } else if (val == 'archive') {
                          onArchiveTask();
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem<String>(
                          value: 'duplicate',
                          child: Row(
                            children: [
                              Icon(Icons.copy_rounded, size: 16, color: DashboardColors.onSurfaceVariant),
                              SizedBox(width: 8),
                              Text('Nhân bản', style: TextStyle(color: DashboardColors.onSurface)),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'archive',
                          child: Row(
                            children: [
                              Icon(Icons.archive_rounded, size: 16, color: DashboardColors.onSurfaceVariant),
                              SizedBox(width: 8),
                              Text('Lưu trữ', style: TextStyle(color: DashboardColors.onSurface)),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_rounded, size: 16, color: DashboardColors.error),
                              SizedBox(width: 8),
                              Text('Xóa công việc', style: TextStyle(color: DashboardColors.error)),
                            ],
                          ),
                        ),
                      ],
                      child: const _IconActionButton(icon: Icons.more_horiz_rounded),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge({
    required this.label,
    required this.bgColor,
    required this.textColor,
    required this.borderColor,
    this.icon,
  });
  final String label;
  final Color bgColor, textColor, borderColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: textColor, size: 13),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: .8,
              ),
            ),
          ],
        ),
      );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
    this.backgroundColor,
    this.textColor,
  });
  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: backgroundColor ?? (filled ? DashboardColors.primary : Colors.transparent),
            borderRadius: BorderRadius.circular(10),
            border: (filled || backgroundColor != null) ? null : Border.all(color: Colors.white.withValues(alpha: .08)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  color: textColor ?? (filled ? DashboardColors.onPrimary : DashboardColors.onSurface),
                  size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: textColor ?? (filled ? DashboardColors.onPrimary : DashboardColors.onSurface),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: .01,
                ),
              ),
            ],
          ),
        ),
      );
}

class _IconActionButton extends StatelessWidget {
  const _IconActionButton({
    required this.icon,
    this.onTap,
    this.color,
  });
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .03),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: .08)),
              ),
              child: Icon(icon, color: color ?? DashboardColors.onSurfaceVariant, size: 20),
            ),
          ),
        ),
      );
}
