import 'package:flutter/material.dart';
import 'package:to_do_app/features/tasks/domain/entities/task_board_item.dart';

class TaskPriorityChip extends StatelessWidget {
  const TaskPriorityChip({required this.priority, this.compact = false, super.key});

  final TaskBoardPriority priority;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ghost = TaskBoardItem(
      id: '',
      title: '',
      description: '',
      status: TaskBoardStatus.todo,
      priority: priority,
      estimate: '',
      assignee: '',
      progress: 0,
      tags: const [],
    );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 4 : 5),
      decoration: BoxDecoration(
        color: ghost.priorityColor.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ghost.priorityColor.withValues(alpha: .3)),
      ),
      child: Text(
        compact ? ghost.priorityLabel.split(' ').first.toUpperCase() : ghost.priorityLabel.toUpperCase(),
        style: TextStyle(color: ghost.priorityColor, fontSize: compact ? 9 : 10, fontWeight: FontWeight.w900, letterSpacing: .8),
      ),
    );
  }
}
