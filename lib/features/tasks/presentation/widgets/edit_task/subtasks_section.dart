import 'package:flutter/material.dart';
import 'package:to_do_app/features/tasks/data/models/task_subtask_model.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class TaskSubtasksSection extends StatefulWidget {
  const TaskSubtasksSection({
    required this.subtasks,
    required this.onSubtasksChanged,
    super.key,
  });

  final List<TaskSubtaskModel> subtasks;
  final ValueChanged<List<TaskSubtaskModel>> onSubtasksChanged;

  @override
  State<TaskSubtasksSection> createState() => _TaskSubtasksSectionState();
}

class _TaskSubtasksSectionState extends State<TaskSubtasksSection> {
  final _newSubtaskController = TextEditingController();
  bool _isAdding = false;

  void _addSubtask() {
    final title = _newSubtaskController.text.trim();
    if (title.isEmpty) return;
    
    final newSubtask = TaskSubtaskModel(
      id: '', // Empty means new
      taskId: '', // Set by repository
      title: title,
      isDone: false,
      createdAt: DateTime.now().toUtc(),
    );

    widget.onSubtasksChanged([...widget.subtasks, newSubtask]);
    _newSubtaskController.clear();
  }

  void _toggleSubtask(int index, bool val) {
    final updated = [...widget.subtasks];
    updated[index] = updated[index].copyWith(isDone: val);
    widget.onSubtasksChanged(updated);
  }

  void _updateSubtaskTitle(int index, String text) {
    final updated = [...widget.subtasks];
    updated[index] = updated[index].copyWith(title: text);
    widget.onSubtasksChanged(updated);
  }

  void _deleteSubtask(int index) {
    final updated = [...widget.subtasks];
    updated.removeAt(index);
    widget.onSubtasksChanged(updated);
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      final items = [...widget.subtasks];
      final item = items.removeAt(oldIndex);
      items.insert(newIndex, item);
      widget.onSubtasksChanged(items);
    });
  }

  @override
  void dispose() {
    _newSubtaskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = widget.subtasks.where((s) => s.isDone).length;
    final totalCount = widget.subtasks.length;
    final progress = totalCount > 0 ? completedCount / totalCount : 0.0;
    final progressPercent = (progress * 100).round();

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 255, 255, 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color.fromRGBO(255, 255, 255, 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.checklist_rounded, color: DashboardColors.primary, size: 22),
                  SizedBox(width: 12),
                  Text(
                    'Subtasks',
                    style: TextStyle(
                      color: DashboardColors.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    '$progressPercent% COMPLETED',
                    style: const TextStyle(
                      color: DashboardColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 100,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: progress.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: DashboardColors.primary,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: DashboardColors.primary.withValues(alpha: 0.4),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Reorderable subtasks list
          if (widget.subtasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No subtasks created yet.',
                  style: TextStyle(color: DashboardColors.onSurfaceVariant.withValues(alpha: 0.4), fontSize: 13),
                ),
              ),
            )
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.subtasks.length,
              onReorderItem: _onReorder,
              itemBuilder: (context, index) {
                final sub = widget.subtasks[index];
                final subKey = ValueKey('subtask-${sub.id.isNotEmpty ? sub.id : index}');
                
                return TaskSubtaskItem(
                  key: subKey,
                  subtask: sub,
                  index: index,
                  onToggle: (val) => _toggleSubtask(index, val),
                  onTitleChanged: (text) => _updateSubtaskTitle(index, text),
                  onDelete: () => _deleteSubtask(index),
                );
              },
            ),
          const SizedBox(height: 16),

          // Add subtask row
          _isAdding
              ? Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newSubtaskController,
                        autofocus: true,
                        style: const TextStyle(color: DashboardColors.onSurface, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Enter subtask title...',
                          hintStyle: TextStyle(color: DashboardColors.onSurfaceVariant.withValues(alpha: 0.3)),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.015),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Color.fromRGBO(255, 255, 255, 0.06)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: DashboardColors.primary),
                          ),
                        ),
                        onSubmitted: (_) {
                          _addSubtask();
                          setState(() => _isAdding = false);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        _addSubtask();
                        setState(() => _isAdding = false);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DashboardColors.primaryContainer,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => setState(() => _isAdding = false),
                      icon: const Icon(Icons.close_rounded, color: DashboardColors.onSurfaceVariant),
                    ),
                  ],
                )
              : InkWell(
                  onTap: () => setState(() => _isAdding = true),
                  borderRadius: BorderRadius.circular(16),
                  child: CustomPaint(
                    painter: DashedBorderPainter(
                      color: widget.subtasks.isEmpty
                          ? DashboardColors.primary.withValues(alpha: 0.3)
                          : const Color.fromRGBO(255, 255, 255, 0.15),
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            widget.subtasks.isEmpty ? Icons.add_circle_outline_rounded : Icons.add_task_rounded,
                            color: widget.subtasks.isEmpty ? DashboardColors.primary : DashboardColors.onSurfaceVariant,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.subtasks.isEmpty ? 'Add new subtask' : 'Add Subtask',
                            style: TextStyle(
                              color: widget.subtasks.isEmpty ? DashboardColors.primary : DashboardColors.onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  DashedBorderPainter({required this.color, this.strokeWidth = 1.0, this.gap = 5.0});
  final Color color;
  final double strokeWidth;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    
    final path = Path();
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(16),
    );
    path.addRRect(rect);
    
    canvas.drawPath(_buildDashedPath(path, gap), paint);
  }

  Path _buildDashedPath(Path source, double gap) {
    final dashed = Path();
    for (final metric in source.computeMetrics()) {
      var distance = 0.0;
      var draw = true;
      while (distance < metric.length) {
        final length = draw ? gap : gap;
        if (draw) {
          dashed.addPath(
            metric.extractPath(distance, distance + length),
            Offset.zero,
          );
        }
        distance += length;
        draw = !draw;
      }
    }
    return dashed;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TaskSubtaskItem extends StatefulWidget {
  const TaskSubtaskItem({
    required this.subtask,
    required this.index,
    required this.onToggle,
    required this.onTitleChanged,
    required this.onDelete,
    super.key,
  });

  final TaskSubtaskModel subtask;
  final int index;
  final ValueChanged<bool> onToggle;
  final ValueChanged<String> onTitleChanged;
  final VoidCallback onDelete;

  @override
  State<TaskSubtaskItem> createState() => _TaskSubtaskItemState();
}

class _TaskSubtaskItemState extends State<TaskSubtaskItem> {
  late TextEditingController _titleController;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.subtask.title);
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        widget.onTitleChanged(_titleController.text);
      }
    });
  }

  @override
  void didUpdateWidget(covariant TaskSubtaskItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.subtask.title != widget.subtask.title && !_focusNode.hasFocus) {
      _titleController.text = widget.subtask.title;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.015),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color.fromRGBO(255, 255, 255, 0.06)),
      ),
      child: Row(
        children: [
          // Checkbox
          Checkbox(
            value: widget.subtask.isDone,
            activeColor: DashboardColors.primary,
            checkColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
            onChanged: (val) {
              if (val != null) widget.onToggle(val);
            },
          ),
          const SizedBox(width: 8),

          // Inline Title Field
          Expanded(
            child: TextField(
              controller: _titleController,
              focusNode: _focusNode,
              style: TextStyle(
                color: widget.subtask.isDone ? DashboardColors.onSurfaceVariant : DashboardColors.onSurface,
                fontSize: 14,
                decoration: widget.subtask.isDone ? TextDecoration.lineThrough : null,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              onSubmitted: (val) {
                widget.onTitleChanged(val);
              },
            ),
          ),
          
          // Action button
          IconButton(
            onPressed: widget.onDelete,
            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.white30),
            hoverColor: Colors.white12,
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(8),
          ),
          
          // Drag handle
          ReorderableDragStartListener(
            index: widget.index,
            child: const Icon(
              Icons.drag_indicator_rounded,
              color: Colors.white24,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
