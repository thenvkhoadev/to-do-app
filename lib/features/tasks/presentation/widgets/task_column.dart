import 'package:flutter/material.dart';
import 'package:to_do_app/features/tasks/domain/entities/task_board_item.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/task_card.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class TaskColumn extends StatelessWidget {
  const TaskColumn({required this.column, this.onTaskTap, super.key});

  final TaskColumnData column;
  final ValueChanged<TaskBoardItem>? onTaskTap;

  @override
  Widget build(BuildContext context) {
    final active = column.status == TaskBoardStatus.inProgress;
    return SizedBox(
      width: 330,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 14),
            child: Row(
              children: [
                Text(column.title.toUpperCase(), style: TextStyle(color: active ? DashboardColors.primary : DashboardColors.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                const SizedBox(width: 8),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: active ? DashboardColors.primary.withValues(alpha: .16) : DashboardColors.surfaceHighest, borderRadius: BorderRadius.circular(999)), child: Text('${column.tasks.length}', style: TextStyle(color: active ? DashboardColors.primary : DashboardColors.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w900))),
                const Spacer(),
                const Icon(Icons.more_horiz_rounded, color: DashboardColors.onSurfaceVariant),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.only(right: 2, bottom: 18),
              itemCount: column.tasks.length + (column.status == TaskBoardStatus.todo ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                if (index >= column.tasks.length) return const _AddTaskTile();
                final task = column.tasks[index];
                return TaskCard(task: task, onTap: () => onTaskTap?.call(task));
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AddTaskTile extends StatelessWidget {
  const _AddTaskTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: DashboardColors.outlineVariant.withValues(alpha: .45), style: BorderStyle.solid)),
      child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_rounded, color: DashboardColors.onSurfaceVariant, size: 20), SizedBox(width: 8), Text('Add Task', style: TextStyle(color: DashboardColors.onSurfaceVariant, fontWeight: FontWeight.w700))]),
    );
  }
}
