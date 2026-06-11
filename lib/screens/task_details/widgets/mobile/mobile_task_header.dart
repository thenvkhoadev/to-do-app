import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:to_do_app/features/tasks/domain/entities/task_board_item.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/premium_dropdown.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class MobileTaskHeader extends StatelessWidget {
  const MobileTaskHeader({
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
    return Stack(
      children: [
        // Hero gradient background
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 280),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0x66321ED2), Color(0xFF121315), Color(0xFF121315)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                right: 0,
                child: Opacity(
                  opacity: .15,
                  child: const Icon(Icons.auto_awesome_rounded,
                      size: 120, color: DashboardColors.primary),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 72, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _Pill(
                          label: item.status.name.toUpperCase(),
                          bg: Colors.white.withValues(alpha: .05),
                          border: Colors.white.withValues(alpha: .08),
                          textColor: DashboardColors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        _Pill(
                          label: item.priorityLabel.toUpperCase(),
                          bg: DashboardColors.warning.withValues(alpha: .10),
                          border: DashboardColors.warning.withValues(alpha: .30),
                          textColor: DashboardColors.warning,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: DashboardColors.onSurface,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -.56,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _HeroButton(
                            label: item.status == TaskBoardStatus.inProgress
                                ? 'Pause Task'
                                : (item.status == TaskBoardStatus.completed
                                    ? 'Completed'
                                    : (item.status == TaskBoardStatus.draft
                                        ? 'Plan Task'
                                        : (isPaused ? 'Resume Task' : 'Start Task'))),
                            icon: item.status == TaskBoardStatus.inProgress
                                ? Icons.pause_rounded
                                : (item.status == TaskBoardStatus.completed
                                    ? Icons.check_circle_rounded
                                    : (item.status == TaskBoardStatus.draft
                                        ? Icons.assignment_turned_in_rounded
                                        : Icons.play_arrow_rounded)),
                            color: item.status == TaskBoardStatus.completed
                                ? DashboardColors.success.withValues(alpha: .2)
                                : (item.status == TaskBoardStatus.inProgress
                                    ? DashboardColors.surfaceContainer
                                    : DashboardColors.primaryContainer),
                            textColor: item.status == TaskBoardStatus.completed
                                ? DashboardColors.success
                                : (item.status == TaskBoardStatus.inProgress
                                    ? DashboardColors.primary
                                    : DashboardColors.onPrimary),
                            onTap: item.status == TaskBoardStatus.inProgress
                                ? onPauseTask
                                : (item.status == TaskBoardStatus.completed
                                    ? () {}
                                    : (item.status == TaskBoardStatus.draft ? onPlanTask : onStartTask)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _GlassIconBtn(
                          icon: Icons.check_circle_outline_rounded,
                          color: item.status == TaskBoardStatus.completed
                              ? DashboardColors.success
                              : DashboardColors.onSurface,
                          onTap: item.status != TaskBoardStatus.completed
                              ? onCompleteTask
                              : null,
                        ),
                        if (isCreator) ...[
                          const SizedBox(width: 8),
                          _GlassIconBtn(
                            icon: Icons.edit_outlined,
                            onTap: onEditTask,
                          ),
                          const SizedBox(width: 8),
                          Builder(
                            builder: (btnContext) {
                              final menuKey = GlobalKey();
                              return GestureDetector(
                                onTap: () {
                                  showTaskDetailsOptionMenu(
                                    context: context,
                                    triggerKey: menuKey,
                                    onDuplicate: onDuplicateTask,
                                    onArchive: onArchiveTask,
                                    onDelete: onDeleteTask,
                                  );
                                },
                                child: _GlassIconBtn(key: menuKey, icon: Icons.more_horiz_rounded),
                              );
                            }
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.bg,
    required this.border,
    required this.textColor,
  });
  final String label;
  final Color bg, border, textColor;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: .8,
          ),
        ),
      );
}

class _HeroButton extends StatelessWidget {
  const _HeroButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.color,
    this.textColor,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: color ?? DashboardColors.primaryContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: textColor ?? DashboardColors.onPrimary, size: 22),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: textColor ?? DashboardColors.onPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
}

class _GlassIconBtn extends StatelessWidget {
  const _GlassIconBtn({
    required this.icon,
    this.onTap,
    this.color,
    super.key,
  });
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .03),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: .12),
                  width: .5,
                ),
              ),
              child: Icon(icon, color: color ?? DashboardColors.onSurface, size: 22),
            ),
          ),
        ),
      );
}
