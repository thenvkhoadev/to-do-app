import 'package:flutter/material.dart';
import 'package:to_do_app/features/tasks/domain/entities/task_board_item.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/ai_suggestion_banner.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/glass_container.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/task_priority_chip.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/task_progress_bar.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class TaskCard extends StatefulWidget {
  const TaskCard({required this.task, this.mobile = false, this.onTap, super.key});

  final TaskBoardItem task;
  final bool mobile;
  final VoidCallback? onTap;

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.task.status == TaskBoardStatus.inProgress && widget.task.aiSuggestion != null;
    final completed = widget.task.completed;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _hovered && !widget.mobile ? -3 : 0, 0),
        child: Opacity(
          opacity: completed ? .62 : 1,
          child: GestureDetector(
            onTap: widget.onTap,
            child: GlassContainer(
              radius: widget.mobile ? 18 : 16,
              padding: EdgeInsets.all(widget.mobile ? 16 : 18),
              glow: active ? DashboardColors.primary : null,
              opacity: active ? .055 : .035,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (active && !widget.mobile) ...[
                    const _ActiveTaskLine(),
                    const SizedBox(width: 12),
                  ],
                  Expanded(child: widget.mobile ? _MobileTaskBody(task: widget.task) : _DesktopTaskBody(task: widget.task)),
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
  const _DesktopTaskBody({required this.task});

  final TaskBoardItem task;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TaskPriorityChip(priority: task.priority),
            const Spacer(),
            if (task.status != TaskBoardStatus.inProgress) ...[
              const Icon(
                Icons.schedule_rounded,
                size: 14,
                color: DashboardColors.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                task.estimate,
                style: const TextStyle(
                  color: DashboardColors.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 14),
        Text(task.title, style: TextStyle(color: task.completed ? DashboardColors.onSurfaceVariant : DashboardColors.onSurface, fontWeight: FontWeight.w800, fontSize: 16, decoration: task.completed ? TextDecoration.lineThrough : null)),
        const SizedBox(height: 8),
        Text(task.description, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: 13, height: 1.45)),
        if (task.aiSuggestion != null) ...[const SizedBox(height: 14), AiSuggestionBanner(text: task.aiSuggestion!, compact: true)],
        const SizedBox(height: 16),
        Row(children: [const Text('Progress', style: TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: 12)), const Spacer(), Text('${(task.progress * 100).round()}%', style: const TextStyle(color: DashboardColors.primary, fontSize: 12, fontWeight: FontWeight.w900))]),
        const SizedBox(height: 8),
        TaskProgressBar(value: task.progress),
        const SizedBox(height: 14),
        Row(children: [_AvatarChip(label: task.assignee), const Spacer(), ...task.tags.take(2).map((tag) => _TagChip(label: tag))]),
      ],
    );
  }
}

class _MobileTaskBody extends StatelessWidget {
  const _MobileTaskBody({required this.task});

  final TaskBoardItem task;

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
              Row(children: [if (task.aiSuggestion != null) const _AiMiniChip(), const SizedBox(width: 6), TaskPriorityChip(priority: task.priority, compact: true)]),
              const SizedBox(height: 8),
              Text(task.title, style: TextStyle(color: DashboardColors.onSurface, fontSize: 16, height: 1.25, fontWeight: FontWeight.w800, decoration: task.completed ? TextDecoration.lineThrough : null)),
              const SizedBox(height: 7),
              Row(children: [const Icon(Icons.schedule_rounded, color: DashboardColors.onSurfaceVariant, size: 14), const SizedBox(width: 4), Text(task.dueLabel ?? task.estimate, style: const TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w700))]),
              if (task.aiSuggestion != null) ...[const SizedBox(height: 12), AiSuggestionBanner(text: task.aiSuggestion!, compact: true)],
            ],
          ),
        ),
      ],
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
        boxShadow: [BoxShadow(color: DashboardColors.primary.withValues(alpha: .45), blurRadius: 12)],
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
      decoration: BoxDecoration(color: done ? DashboardColors.primary.withValues(alpha: .16) : Colors.transparent, borderRadius: BorderRadius.circular(8), border: Border.all(color: done ? DashboardColors.primary : DashboardColors.outlineVariant, width: 2)),
      child: done ? const Icon(Icons.check_rounded, color: DashboardColors.primary, size: 17) : null,
    );
  }
}

class _AiMiniChip extends StatelessWidget {
  const _AiMiniChip();
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4), decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), border: Border.all(color: DashboardColors.primary.withValues(alpha: .3))), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.auto_awesome_rounded, color: DashboardColors.primary, size: 11), SizedBox(width: 3), Text('AI', style: TextStyle(color: DashboardColors.primary, fontSize: 9, fontWeight: FontWeight.w900))]));
}

class _AvatarChip extends StatelessWidget {
  const _AvatarChip({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Container(width: 26, height: 26, alignment: Alignment.center, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: .09), border: Border.all(color: Colors.white.withValues(alpha: .12))), child: Text(label, style: const TextStyle(color: DashboardColors.onSurface, fontSize: 10, fontWeight: FontWeight.w900)));
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(left: 6), child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: DashboardColors.surfaceHighest.withValues(alpha: .55), borderRadius: BorderRadius.circular(7)), child: Text('#$label', style: const TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.w700))));
}
