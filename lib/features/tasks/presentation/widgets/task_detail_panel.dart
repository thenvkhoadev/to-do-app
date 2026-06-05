import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:to_do_app/features/tasks/data/models/task_subtask_model.dart';
import 'package:to_do_app/features/tasks/domain/entities/task_board_item.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/glass_container.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/task_priority_chip.dart';
import 'package:to_do_app/features/tasks/presentation/providers/tasks_provider.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class TaskDetailPanel extends ConsumerStatefulWidget {
  const TaskDetailPanel({
    required this.task,
    this.onClose,
    this.onViewDetails,
    super.key,
  });

  final TaskBoardItem task;
  final VoidCallback? onClose;
  final VoidCallback? onViewDetails;

  @override
  ConsumerState<TaskDetailPanel> createState() => _TaskDetailPanelState();
}

class _TaskDetailPanelState extends ConsumerState<TaskDetailPanel> {
  @override
  void initState() {
    super.initState();
    // Force fresh fetch every time panel opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(taskAttachmentsProvider(widget.task.id));
    });
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      width: 420,
      decoration: const BoxDecoration(
        color: DashboardColors.background,
        border: Border(
          left: BorderSide(color: Colors.white12),
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
                      IconButton(
                        onPressed: widget.onClose,
                        icon: const Icon(
                          Icons.close_rounded,
                          color: DashboardColors.onSurfaceVariant,
                        ),
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
                  _SubtaskSection(taskId: task.id),
                  const SizedBox(height: 24),
                  _buildAttachmentsSection(context, ref),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.onViewDetails != null) ...[
                    FilledButton.icon(
                      onPressed: widget.onViewDetails,
                      style: FilledButton.styleFrom(
                        backgroundColor: DashboardColors.primaryContainer,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: const Text(
                        'View Details',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  GlassContainer(
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentsSection(BuildContext context, WidgetRef ref) {
    final attachmentsAsync = ref.watch(taskAttachmentsProvider(widget.task.id));

    return _PanelSection(
      title: 'Attachments',
      badge: null,
      trailing: IconButton(
        icon: const Icon(Icons.refresh_rounded,
            size: 16, color: DashboardColors.onSurfaceVariant),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        tooltip: 'Refresh attachments',
        onPressed: () => ref.invalidate(taskAttachmentsProvider(widget.task.id)),
      ),
      child: attachmentsAsync.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        error: (err, stack) => Text(
          'Error loading attachments: $err',
          style: const TextStyle(color: DashboardColors.error, fontSize: 12),
        ),
        data: (attachments) {
          if (attachments.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No attachments',
                style: TextStyle(
                  color: DashboardColors.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              return Wrap(
                spacing: 10,
                runSpacing: 14,
                children: attachments.map((att) {
                  final ext = att.fileName.split('.').last.toUpperCase();
                  final sizeStr = '$ext Document';
                  final isImage = att.mimeType.startsWith('image/');
                  final isPdf = att.mimeType == 'application/pdf';
                  debugPrint('Attachment: ${att.fileName} mimeType=${att.mimeType} isImage=$isImage url=${att.fileUrl}');

                  return SizedBox(
                    width: (constraints.maxWidth - 10) / 2,
                    child: _Attachment(
                      icon: isImage
                          ? Icons.image_rounded
                          : isPdf
                              ? Icons.picture_as_pdf_rounded
                              : Icons.insert_drive_file_rounded,
                      title: att.fileName,
                      size: sizeStr,
                      color: isImage
                          ? DashboardColors.primary
                          : isPdf
                              ? DashboardColors.secondary
                              : DashboardColors.tertiary,
                      imageUrl: isImage ? att.fileUrl : null,
                    ),
                  );
                }).toList(),
              );
            },
          );
        },
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
  const _PanelSection({required this.title, required this.child, this.badge, this.trailing});
  final String title;
  final Widget child;
  final String? badge;
  final Widget? trailing;
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
          if (badge != null || trailing != null) const Spacer(),
          if (badge != null)
            Text(
              badge!,
              style: const TextStyle(
                color: DashboardColors.primary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          if (trailing != null) trailing!,
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

class _SubtaskSection extends ConsumerStatefulWidget {
  const _SubtaskSection({required this.taskId});
  final String taskId;

  @override
  ConsumerState<_SubtaskSection> createState() => _SubtaskSectionState();
}

class _SubtaskSectionState extends ConsumerState<_SubtaskSection> {
  final _textController = TextEditingController();
  bool _isAdding = false;
  bool _isGenerating = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _addSubtask(String title) async {
    if (title.trim().isEmpty) return;
    try {
      final subtask = TaskSubtaskModel(
        id: '',
        taskId: widget.taskId,
        title: title.trim(),
        isDone: false,
      );
      await ref.read(subtaskDataSourceProvider).createSubtask(subtask);
      ref.invalidate(taskSubtasksProvider(widget.taskId));
      _textController.clear();
      setState(() {
        _isAdding = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add subtask: $e')),
      );
    }
  }

  Future<void> _toggleSubtask(TaskSubtaskModel subtask, bool value) async {
    try {
      await ref
          .read(subtaskDataSourceProvider)
          .updateSubtask(subtask.id, {'is_done': value});
      ref.invalidate(taskSubtasksProvider(widget.taskId));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update subtask: $e')),
      );
    }
  }

  Future<void> _deleteSubtask(String id) async {
    try {
      await ref.read(subtaskDataSourceProvider).deleteSubtask(id);
      ref.invalidate(taskSubtasksProvider(widget.taskId));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete subtask: $e')),
      );
    }
  }

  Future<void> _generateWithAi() async {
    setState(() {
      _isGenerating = true;
    });
    await Future.delayed(const Duration(milliseconds: 1200));
    try {
      final suggested = [
        'Review architecture guidelines',
        'Write integration test suite',
        'Verify schema compatibility',
      ];
      final datasource = ref.read(subtaskDataSourceProvider);
      final subtasks = suggested
          .map((t) => TaskSubtaskModel(
                id: '',
                taskId: widget.taskId,
                title: t,
                isDone: false,
              ))
          .toList();
      await datasource.insertMultipleSubtasks(subtasks);
      ref.invalidate(taskSubtasksProvider(widget.taskId));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate subtasks: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtasksAsync = ref.watch(taskSubtasksProvider(widget.taskId));

    return _PanelSection(
      title: 'Subtasks',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isGenerating)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 1.5),
            )
          else
            TextButton.icon(
              onPressed: _generateWithAi,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.auto_awesome_rounded, size: 14, color: DashboardColors.primary),
              label: const Text(
                'Generate with AI',
                style: TextStyle(
                  color: DashboardColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
      child: subtasksAsync.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        error: (err, stack) => Text(
          'Error: $err',
          style: const TextStyle(color: DashboardColors.error, fontSize: 12),
        ),
        data: (subtasks) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (subtasks.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No subtasks',
                    style: TextStyle(
                      color: DashboardColors.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                )
              else
                ...subtasks.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => _toggleSubtask(item, !item.isDone),
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: item.isDone
                                    ? DashboardColors.primary.withValues(alpha: .14)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: item.isDone ? DashboardColors.primary : DashboardColors.outline,
                                ),
                              ),
                              child: item.isDone
                                  ? const Icon(
                                      Icons.check_rounded,
                                      color: DashboardColors.primary,
                                      size: 14,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              color: item.isDone
                                  ? DashboardColors.onSurfaceVariant
                                  : DashboardColors.onSurface,
                              decoration: item.isDone ? TextDecoration.lineThrough : null,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 16),
                          color: DashboardColors.outline.withValues(alpha: .5),
                          onPressed: () => _deleteSubtask(item.id),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  );
                }),
              const SizedBox(height: 4),
              if (_isAdding)
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        autofocus: true,
                        style: const TextStyle(fontSize: 14, color: DashboardColors.onSurface),
                        decoration: const InputDecoration(
                          hintText: 'Enter subtask...',
                          border: InputBorder.none,
                          hintStyle: TextStyle(color: DashboardColors.outline),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 4),
                        ),
                        onSubmitted: _addSubtask,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.check_rounded, color: DashboardColors.primary, size: 18),
                      onPressed: () => _addSubtask(_textController.text),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: DashboardColors.error, size: 18),
                      onPressed: () {
                        setState(() {
                          _isAdding = false;
                          _textController.clear();
                        });
                      },
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                    ),
                  ],
                )
              else
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isAdding = true;
                    });
                  },
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Row(
                      children: const [
                        Icon(Icons.add_rounded, color: DashboardColors.outline, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Add another subtask...',
                          style: TextStyle(
                            color: DashboardColors.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Attachment extends StatelessWidget {
  const _Attachment({
    required this.icon,
    required this.title,
    required this.size,
    required this.color,
    this.imageUrl,
  });
  final IconData icon;
  final String title;
  final String size;
  final Color color;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null) {
      return GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(16),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      color: Colors.black87,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: InteractiveViewer(
                      child: CachedNetworkImage(
                        imageUrl: imageUrl!,
                        fit: BoxFit.contain,
                        errorWidget: (_, __, ___) => Container(
                          padding: const EdgeInsets.all(24),
                          color: DashboardColors.surfaceLow,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icon, color: color, size: 48),
                              const SizedBox(height: 12),
                              Text(
                                title,
                                style: const TextStyle(
                                  color: DashboardColors.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                        placeholder: (_, __) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: CircleAvatar(
                      backgroundColor: Colors.black45,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 100,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .08),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint('Error loading attachment image: $error\nURL: $imageUrl');
                        return Center(
                          child: Icon(icon, color: color, size: 28),
                        );
                      },
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.85),
                              Colors.black.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                        padding: const EdgeInsets.fromLTRB(8, 16, 8, 4),
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  size,
                  style: const TextStyle(
                    color: DashboardColors.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 100,
          width: double.infinity,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: .05),
            ),
          ),
          child: Center(
            child: Icon(icon, color: color, size: 36),
          ),
        ),
        const SizedBox(height: 8),
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
}
