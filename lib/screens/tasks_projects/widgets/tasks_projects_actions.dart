import 'package:flutter/material.dart';
import 'package:to_do_app/screens/tasks_projects/tasks_projects_models.dart';
import 'package:to_do_app/screens/tasks_projects/widgets/tasks_projects_glass.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class TasksProjectsQuickActionDock extends StatelessWidget {
  const TasksProjectsQuickActionDock({this.compact = false, this.onNewTask, super.key});

  final bool compact;
  final VoidCallback? onNewTask;

  @override
  Widget build(BuildContext context) {
    return TasksProjectsGlass(
      padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 12, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: tasksProjectQuickActions.map((action) => Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: TasksProjectsQuickActionButton(action: action, compact: compact, onTap: action.label == 'New Task' ? onNewTask : null))).toList(),
        ),
      ),
    );
  }
}

class TasksProjectsQuickActionButton extends StatefulWidget {
  const TasksProjectsQuickActionButton({required this.action, this.compact = false, this.onTap, super.key});

  final TasksProjectQuickAction action;
  final bool compact;
  final VoidCallback? onTap;

  @override
  State<TasksProjectsQuickActionButton> createState() => _TasksProjectsQuickActionButtonState();
}

class _TasksProjectsQuickActionButtonState extends State<TasksProjectsQuickActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final action = widget.action;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedScale(
        scale: _hovered ? 1.08 : 1,
        duration: const Duration(milliseconds: 160),
        child: Tooltip(
          message: action.label,
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
            height: 44,
            padding: EdgeInsets.symmetric(horizontal: widget.compact ? 11 : 14),
            decoration: BoxDecoration(color: action.accent.withValues(alpha: _hovered ? .18 : .10), borderRadius: BorderRadius.circular(999), border: Border.all(color: action.accent.withValues(alpha: _hovered ? .36 : .18)), boxShadow: _hovered ? [BoxShadow(color: action.accent.withValues(alpha: .22), blurRadius: 18)] : null),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(action.icon, color: action.accent, size: 18),
                if (!widget.compact) ...[
                  const SizedBox(width: 8),
                  Text(action.label, style: const TextStyle(color: DashboardColors.onSurface, fontSize: 12, fontWeight: FontWeight.w800)),
                ],
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }
}
