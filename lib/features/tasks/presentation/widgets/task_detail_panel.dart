import 'package:flutter/material.dart';
import 'package:to_do_app/features/tasks/domain/entities/task_board_item.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/glass_container.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/task_priority_chip.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class TaskDetailPanel extends StatelessWidget {
  const TaskDetailPanel({required this.task, super.key});

  final TaskBoardItem task;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      width: 420,
      decoration: BoxDecoration(
        color: DashboardColors.surfaceLow.withValues(alpha: .56),
        border: Border(
          left: BorderSide(color: Colors.white.withValues(alpha: .09)),
        ),
      ),
      child: SafeArea(
        left: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      TaskPriorityChip(priority: task.priority),
                      const SizedBox(width: 8),
                      _StatusChip(label: task.status.name.toUpperCase()),
                      const Spacer(),
                      const Icon(
                        Icons.close_rounded,
                        color: DashboardColors.onSurfaceVariant,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    task.title,
                    style: const TextStyle(
                      color: DashboardColors.onSurface,
                      fontSize: 26,
                      height: 1.18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: Colors.white.withValues(alpha: .07), height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _PanelSection(
                    title: 'Description',
                    child: Text(
                      task.description,
                      style: const TextStyle(
                        color: DashboardColors.onSurface,
                        fontSize: 15,
                        height: 1.55,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _PanelSection(
                    title: 'AI Suggested Subtasks',
                    badge: 'Calculated by NEXUS AI',
                    child: Column(
                      children: const [
                        _Subtask(label: 'Audit current card blur values'),
                        _Subtask(label: 'Standardize backdrop-filter values'),
                        _Subtask(
                          label: 'Update theme surface tokens',
                          done: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _PanelSection(
                    title: 'Attachments',
                    child: const Row(
                      children: [
                        Expanded(
                          child: _Attachment(
                            icon: Icons.image_rounded,
                            title: 'Style_Guide_V2.fig',
                            size: '4.2 MB',
                            color: DashboardColors.primary,
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: _Attachment(
                            icon: Icons.picture_as_pdf_rounded,
                            title: 'Research.pdf',
                            size: '1.1 MB',
                            color: DashboardColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: GlassContainer(
                radius: 999,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: const Row(
                  children: [
                    CircleAvatar(
                      radius: 15,
                      backgroundColor: DashboardColors.surfaceHighest,
                      child: Text(
                        'A',
                        style: TextStyle(
                          color: DashboardColors.onSurface,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Write a comment...',
                        style: TextStyle(
                          color: DashboardColors.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.send_rounded,
                      color: DashboardColors.primary,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: DashboardColors.primary.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: DashboardColors.primary,
        fontSize: 10,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _PanelSection extends StatelessWidget {
  const _PanelSection({required this.title, required this.child, this.badge});
  final String title;
  final Widget child;
  final String? badge;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: DashboardColors.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          if (badge != null) ...[
            const Spacer(),
            Text(
              badge!,
              style: const TextStyle(
                color: DashboardColors.primary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
      const SizedBox(height: 12),
      GlassContainer(
        radius: 16,
        padding: const EdgeInsets.all(14),
        child: child,
      ),
    ],
  );
}

class _Subtask extends StatelessWidget {
  const _Subtask({required this.label, this.done = false});
  final String label;
  final bool done;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color:
                done
                    ? DashboardColors.primary.withValues(alpha: .14)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: done ? DashboardColors.primary : DashboardColors.outline,
            ),
          ),
          child:
              done
                  ? const Icon(
                    Icons.check_rounded,
                    color: DashboardColors.primary,
                    size: 14,
                  )
                  : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color:
                  done
                      ? DashboardColors.onSurfaceVariant
                      : DashboardColors.onSurface,
              decoration: done ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
      ],
    ),
  );
}

class _Attachment extends StatelessWidget {
  const _Attachment({
    required this.icon,
    required this.title,
    required this.size,
    required this.color,
  });
  final IconData icon;
  final String title;
  final String size;
  final Color color;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color),
      ),
      const SizedBox(height: 10),
      Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: DashboardColors.onSurface,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
      Text(
        size,
        style: const TextStyle(
          color: DashboardColors.onSurfaceVariant,
          fontSize: 10,
        ),
      ),
    ],
  );
}
