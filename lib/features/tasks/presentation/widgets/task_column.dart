import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/features/tasks/domain/entities/task_board_item.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/task_card.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class TaskColumn extends ConsumerStatefulWidget {
  const TaskColumn({
    required this.column,
    this.onTaskTap,
    this.onTaskDropped,
    this.onNewTask,
    super.key,
  });

  final TaskColumnData column;
  final ValueChanged<TaskBoardItem>? onTaskTap;
  final ValueChanged<TaskBoardItem>? onTaskDropped;
  final VoidCallback? onNewTask;

  @override
  ConsumerState<TaskColumn> createState() => _TaskColumnState();
}

class _TaskColumnState extends ConsumerState<TaskColumn> {
  bool _isCollapsed = false;
  String _sortType = 'none'; // 'none', 'priority', 'dueDate'

  int _priorityWeight(TaskBoardPriority p) {
    switch (p) {
      case TaskBoardPriority.urgent:
        return 4;
      case TaskBoardPriority.high:
        return 3;
      case TaskBoardPriority.medium:
        return 2;
      case TaskBoardPriority.low:
        return 1;
      case TaskBoardPriority.done:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.column.status == TaskBoardStatus.inProgress;

    if (_isCollapsed) {
      return GestureDetector(
        onTap: () => setState(() => _isCollapsed = false),
        child: Container(
          width: 60,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: DashboardColors.surfaceLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: active
                      ? DashboardColors.primary.withValues(alpha: .16)
                      : DashboardColors.surfaceHighest,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${widget.column.tasks.length}',
                  style: TextStyle(
                    color: active ? DashboardColors.primary : DashboardColors.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: RotatedBox(
                  quarterTurns: 1,
                  child: Center(
                    child: Text(
                      widget.column.title.toUpperCase(),
                      style: TextStyle(
                        color: active ? DashboardColors.primary : DashboardColors.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, color: DashboardColors.onSurfaceVariant),
                onPressed: () => setState(() => _isCollapsed = false),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      );
    }

    final originalTasks = widget.column.tasks;
    List<TaskBoardItem> sortedTasks = List<TaskBoardItem>.from(originalTasks);

    if (_sortType == 'priority') {
      sortedTasks.sort((a, b) {
        final pA = _priorityWeight(a.priority);
        final pB = _priorityWeight(b.priority);
        return pB.compareTo(pA); // Highest priority first
      });
    } else if (_sortType == 'dueDate') {
      sortedTasks.sort((a, b) {
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });
    }

    return SizedBox(
      width: 330,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 14),
            child: Row(
              children: [
                Text(
                  widget.column.title.toUpperCase(),
                  style: TextStyle(
                    color: active ? DashboardColors.primary : DashboardColors.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: active
                        ? DashboardColors.primary.withValues(alpha: .16)
                        : DashboardColors.surfaceHighest,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${widget.column.tasks.length}',
                    style: TextStyle(
                      color: active ? DashboardColors.primary : DashboardColors.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_horiz_rounded,
                    color: DashboardColors.onSurfaceVariant,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: DashboardColors.surfaceLow,
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.white12),
                  ),
                  onSelected: (value) {
                    if (value == 'add') {
                      widget.onNewTask?.call();
                    } else if (value == 'sort_priority') {
                      setState(() {
                        _sortType = _sortType == 'priority' ? 'none' : 'priority';
                      });
                    } else if (value == 'sort_due') {
                      setState(() {
                        _sortType = _sortType == 'dueDate' ? 'none' : 'dueDate';
                      });
                    } else if (value == 'collapse') {
                      setState(() {
                        _isCollapsed = true;
                      });
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem<String>(
                      value: 'add',
                      child: Row(
                        children: [
                          Icon(Icons.add_circle_outline_rounded, size: 16, color: DashboardColors.onSurfaceVariant),
                          SizedBox(width: 8),
                          Text('Thêm công việc mới', style: TextStyle(color: DashboardColors.onSurface)),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'sort_priority',
                      child: Row(
                        children: [
                          Icon(
                            _sortType == 'priority' ? Icons.check_rounded : Icons.sort_rounded,
                            size: 16,
                            color: _sortType == 'priority' ? DashboardColors.primary : DashboardColors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Sắp xếp theo độ ưu tiên',
                            style: TextStyle(
                              color: _sortType == 'priority' ? DashboardColors.primary : DashboardColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'sort_due',
                      child: Row(
                        children: [
                          Icon(
                            _sortType == 'dueDate' ? Icons.check_rounded : Icons.calendar_month_rounded,
                            size: 16,
                            color: _sortType == 'dueDate' ? DashboardColors.primary : DashboardColors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Sắp xếp theo hạn chót',
                            style: TextStyle(
                              color: _sortType == 'dueDate' ? DashboardColors.primary : DashboardColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'collapse',
                      child: Row(
                        children: [
                          Icon(Icons.view_column_rounded, size: 16, color: DashboardColors.onSurfaceVariant),
                          SizedBox(width: 8),
                          Text('Thu gọn cột', style: TextStyle(color: DashboardColors.onSurface)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: DragTarget<TaskBoardItem>(
              onWillAcceptWithDetails: (details) =>
                  details.data.status != widget.column.status,
              onAcceptWithDetails: (details) {
                widget.onTaskDropped?.call(details.data);
              },
              builder: (context, candidateData, rejectedData) {
                final isOver = candidateData.isNotEmpty;
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: isOver
                        ? DashboardColors.primary.withValues(alpha: 0.05)
                        : Colors.transparent,
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.only(right: 2, bottom: 18),
                    itemCount:
                        sortedTasks.length +
                        (widget.column.status == TaskBoardStatus.todo ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      if (index >= sortedTasks.length) {
                        return _AddTaskTile(
                          onTap: () => widget.onNewTask?.call(),
                        );
                      }
                      final task = sortedTasks[index];
                      return Draggable<TaskBoardItem>(
                        data: task,
                        feedback: Material(
                          color: Colors.transparent,
                          child: SizedBox(
                            width: 328,
                            child: TaskCard(task: task),
                          ),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.35,
                          child: TaskCard(task: task),
                        ),
                        child: TaskCard(
                          task: task,
                          onTap: () => widget.onTaskTap?.call(task),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AddTaskTile extends StatelessWidget {
  const _AddTaskTile({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: DashboardColors.outlineVariant.withValues(alpha: .45),
            style: BorderStyle.solid,
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_rounded,
              color: DashboardColors.onSurfaceVariant,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              'Add Task',
              style: TextStyle(
                color: DashboardColors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
