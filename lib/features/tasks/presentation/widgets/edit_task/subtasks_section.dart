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

class _TaskSubtasksSectionState extends State<TaskSubtasksSection>
    with SingleTickerProviderStateMixin {
  final _newSubtaskController = TextEditingController();
  bool _isAdding = false;
  late AnimationController _badgePulseController;
  late Animation<double> _badgePulse;

  @override
  void initState() {
    super.initState();
    _badgePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _badgePulse = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _badgePulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _newSubtaskController.dispose();
    _badgePulseController.dispose();
    super.dispose();
  }

  void _addSubtask() {
    final title = _newSubtaskController.text.trim();
    if (title.isEmpty) return;
    widget.onSubtasksChanged([
      ...widget.subtasks,
      TaskSubtaskModel(
        id: '',
        taskId: '',
        title: title,
        isDone: false,
        createdAt: DateTime.now().toUtc(),
      ),
    ]);
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
    final items = [...widget.subtasks];
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);
    widget.onSubtasksChanged(items);
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = widget.subtasks.where((s) => s.isDone).length;
    final totalCount = widget.subtasks.length;
    final progress = totalCount > 0 ? completedCount / totalCount : 0.0;
    final pendingCount = totalCount - completedCount;

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
          // ── Header ──────────────────────────────────────────────
          Row(
            children: [
              const Icon(
                Icons.checklist_rounded,
                color: DashboardColors.primary,
                size: 22,
              ),
              const SizedBox(width: 12),
              const Text(
                'Subtasks',
                style: TextStyle(
                  color: DashboardColors.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // Progress label
              if (totalCount > 0) ...[
                Text(
                  '$completedCount/$totalCount',
                  style: const TextStyle(
                    color: DashboardColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 10),
              ],
              // Premium expanded subtask button with badge
              _SubtaskActionButton(
                totalCount: totalCount,
                pendingCount: pendingCount,
                badgePulse: _badgePulse,
              ),
            ],
          ),

          // ── Progress bar ─────────────────────────────────────────
          if (totalCount > 0) ...[
            const SizedBox(height: 16),
            _SubtaskProgressBar(progress: progress),
          ],

          const SizedBox(height: 20),

          // ── Subtask list ─────────────────────────────────────────
          if (widget.subtasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No subtasks yet.',
                  style: TextStyle(
                    color: DashboardColors.onSurfaceVariant.withValues(
                      alpha: 0.4,
                    ),
                    fontSize: 13,
                  ),
                ),
              ),
            )
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: widget.subtasks.length,
              onReorderItem: _onReorder,
              itemBuilder: (context, index) {
                final sub = widget.subtasks[index];
                return TaskSubtaskItem(
                  key: ValueKey(
                    'subtask-${sub.id.isNotEmpty ? sub.id : index}',
                  ),
                  subtask: sub,
                  index: index,
                  onToggle: (val) => _toggleSubtask(index, val),
                  onTitleChanged: (text) => _updateSubtaskTitle(index, text),
                  onDelete: () => _deleteSubtask(index),
                );
              },
            ),

          const SizedBox(height: 12),

          // ── Add subtask ──────────────────────────────────────────
          if (_isAdding)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newSubtaskController,
                    autofocus: true,
                    style: const TextStyle(
                      color: DashboardColors.onSurface,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter subtask title...',
                      hintStyle: TextStyle(
                        color: DashboardColors.onSurfaceVariant.withValues(
                          alpha: 0.3,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.015),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color.fromRGBO(255, 255, 255, 0.06),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: DashboardColors.primary,
                        ),
                      ),
                    ),
                    onSubmitted: (_) {
                      _addSubtask();
                      setState(() => _isAdding = false);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    _addSubtask();
                    setState(() => _isAdding = false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DashboardColors.primaryContainer,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Add',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  onPressed: () => setState(() => _isAdding = false),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: DashboardColors.onSurfaceVariant,
                  ),
                ),
              ],
            )
          else
            _AddSubtaskButton(
              isEmpty: widget.subtasks.isEmpty,
              onTap: () => setState(() => _isAdding = true),
            ),
        ],
      ),
    );
  }
}

// ── Progress bar ──────────────────────────────────────────────────────────────

class _SubtaskProgressBar extends StatelessWidget {
  const _SubtaskProgressBar({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Stack(
        children: [
          Container(
            height: 4,
            width: double.infinity,
            color: Colors.white.withValues(alpha: 0.06),
          ),
          FractionallySizedBox(
            widthFactor: progress.clamp(0.0, 1.0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              height: 4,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFA78BFA), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.45),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Premium Subtask Action Button ─────────────────────────────────────────────

class _SubtaskActionButton extends StatefulWidget {
  const _SubtaskActionButton({
    required this.totalCount,
    required this.pendingCount,
    required this.badgePulse,
  });

  final int totalCount;
  final int pendingCount;
  final Animation<double> badgePulse;

  @override
  State<_SubtaskActionButton> createState() => _SubtaskActionButtonState();
}

class _SubtaskActionButtonState extends State<_SubtaskActionButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final hasPending = widget.pendingCount > 0;

    return MouseRegion(
      onEnter:
          (_) => WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _hovered = true);
          }),
      onExit:
          (_) => WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _hovered = false);
          }),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: const Cubic(0.22, 1, 0.36, 1),
              transform: Matrix4.translationValues(
                0,
                _hovered && !_pressed ? -2 : 0,
                0,
              ),
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                gradient:
                    _hovered
                        ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color.fromRGBO(99, 102, 241, 0.15),
                            Color.fromRGBO(168, 85, 247, 0.15),
                          ],
                        )
                        : null,
                color:
                    _hovered ? null : const Color.fromRGBO(255, 255, 255, 0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      _hovered
                          ? const Color(0xFF8B5CF6).withValues(alpha: 0.35)
                          : const Color.fromRGBO(255, 255, 255, 0.08),
                ),
                boxShadow:
                    _hovered
                        ? [
                          BoxShadow(
                            color: const Color(
                              0xFF8B5CF6,
                            ).withValues(alpha: 0.25),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ]
                        : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedRotation(
                    turns: _hovered ? 5 / 360 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.checklist_rounded,
                      size: 18,
                      color: _hovered ? Colors.white : const Color(0xFFA1A1AA),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Subtasks',
                    style: TextStyle(
                      color: _hovered ? Colors.white : const Color(0xFFE4E4E7),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (widget.totalCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${widget.totalCount}',
                        style: const TextStyle(
                          color: Color(0xFFC4B5FD),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Pending badge
            if (hasPending)
              Positioned(
                top: -6,
                right: -6,
                child: AnimatedBuilder(
                  animation: widget.badgePulse,
                  builder:
                      (context, child) => Opacity(
                        opacity: widget.badgePulse.value,
                        child: child,
                      ),
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        widget.pendingCount > 9
                            ? "9+"
                            : '${widget.pendingCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Add Subtask Button ────────────────────────────────────────────────────────

class _AddSubtaskButton extends StatefulWidget {
  const _AddSubtaskButton({required this.isEmpty, required this.onTap});
  final bool isEmpty;
  final VoidCallback onTap;

  @override
  State<_AddSubtaskButton> createState() => _AddSubtaskButtonState();
}

class _AddSubtaskButtonState extends State<_AddSubtaskButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter:
          (_) => WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _hovered = true);
          }),
      onExit:
          (_) => WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _hovered = false);
          }),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: CustomPaint(
          painter: DashedBorderPainter(
            color:
                widget.isEmpty
                    ? DashboardColors.primary.withValues(
                      alpha: _hovered ? 0.5 : 0.3,
                    )
                    : Colors.white.withValues(alpha: _hovered ? 0.25 : 0.15),
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.isEmpty
                      ? Icons.add_circle_outline_rounded
                      : Icons.add_task_rounded,
                  color:
                      widget.isEmpty
                          ? DashboardColors.primary
                          : DashboardColors.onSurfaceVariant,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.isEmpty ? "Add first subtask" : "Add Subtask",
                  style: TextStyle(
                    color:
                        widget.isEmpty
                            ? DashboardColors.primary
                            : DashboardColors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Subtask Item ──────────────────────────────────────────────────────────────

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
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.subtask.title);
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) widget.onTitleChanged(_titleController.text);
    });
  }

  @override
  void didUpdateWidget(covariant TaskSubtaskItem old) {
    super.didUpdateWidget(old);
    if (old.subtask.title != widget.subtask.title && !_focusNode.hasFocus) {
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
    return MouseRegion(
      onEnter:
          (_) => WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _hovered = true);
          }),
      onExit:
          (_) => WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _hovered = false);
          }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color:
              _hovered
                  ? Colors.white.withValues(alpha: 0.03)
                  : Colors.white.withValues(alpha: 0.015),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                _hovered
                    ? const Color(0xFF8B5CF6).withValues(alpha: 0.2)
                    : const Color.fromRGBO(255, 255, 255, 0.06),
          ),
        ),
        child: Row(
          children: [
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
            const SizedBox(width: 6),
            Expanded(
              child: TextField(
                controller: _titleController,
                focusNode: _focusNode,
                style: TextStyle(
                  color:
                      widget.subtask.isDone
                          ? DashboardColors.onSurfaceVariant
                          : DashboardColors.onSurface,
                  fontSize: 14,
                  decoration:
                      widget.subtask.isDone ? TextDecoration.lineThrough : null,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
                onSubmitted: widget.onTitleChanged,
              ),
            ),
            AnimatedOpacity(
              opacity: _hovered ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 150),
              child: IconButton(
                onPressed: widget.onDelete,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 17,
                  color: Color(0xFFFF6B6B),
                ),
                hoverColor: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(6),
              ),
            ),
            ReorderableDragStartListener(
              index: widget.index,
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(
                  Icons.drag_indicator_rounded,
                  color: _hovered ? Colors.white38 : Colors.white12,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dashed Border Painter ─────────────────────────────────────────────────────

class DashedBorderPainter extends CustomPainter {
  const DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.0,
    this.gap = 5.0,
  });
  final Color color;
  final double strokeWidth;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke;
    final path =
        Path()..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, size.width, size.height),
            const Radius.circular(16),
          ),
        );
    canvas.drawPath(_dashed(path), paint);
  }

  Path _dashed(Path source) {
    final dashed = Path();
    for (final metric in source.computeMetrics()) {
      var distance = 0.0;
      var draw = true;
      while (distance < metric.length) {
        if (draw) {
          dashed.addPath(
            metric.extractPath(distance, distance + gap),
            Offset.zero,
          );
        }
        distance += gap;
        draw = !draw;
      }
    }
    return dashed;
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
