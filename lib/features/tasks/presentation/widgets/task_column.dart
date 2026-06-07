import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:to_do_app/features/tasks/domain/entities/task_board_item.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/task_card.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/delete_success_dialog.dart';
import 'package:to_do_app/features/tasks/presentation/widgets/export_success_dialog.dart';
import 'package:to_do_app/features/tasks/presentation/providers/tasks_provider.dart';
import 'package:to_do_app/features/auth/presentation/providers/auth_provider.dart';
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
  final Set<String> _selectedTaskIds = {};

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

    // Filter selection to only keep tasks currently in the column
    final sortedTaskIds = sortedTasks.map((t) => t.id).toSet();
    _selectedTaskIds.retainAll(sortedTaskIds);

    final selectedTasks = sortedTasks.where((t) => _selectedTaskIds.contains(t.id)).toList();

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
                const SizedBox(width: 8),
                if (originalTasks.isNotEmpty)
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: Checkbox(
                      value: originalTasks.isNotEmpty && _selectedTaskIds.length == originalTasks.length,
                      tristate: _selectedTaskIds.isNotEmpty && _selectedTaskIds.length < originalTasks.length,
                      activeColor: DashboardColors.primary,
                      checkColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _selectedTaskIds.addAll(originalTasks.map((t) => t.id));
                          } else {
                            _selectedTaskIds.clear();
                          }
                        });
                      },
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
          // Batch actions toolbar (Only visible if there are selected tasks)
          if (_selectedTaskIds.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
              child: Row(
                children: [
                  _buildCopyMenu(context, selectedTasks),
                  const SizedBox(width: 8),
                  _buildExportMenu(context, selectedTasks),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_sweep_rounded,
                      color: DashboardColors.error,
                      size: 20,
                    ),
                    tooltip: 'Xóa các công việc đã chọn',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _handleDeleteSelected(context, selectedTasks),
                  ),
                ],
              ),
            ),
          ],
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
                  child: sortedTasks.isEmpty
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Spacer(),
                            Opacity(
                              opacity: 0.25,
                              child: Icon(
                                _getColumnEmptyIcon(widget.column.status),
                                size: 44,
                                color: DashboardColors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'No tasks available',
                              style: TextStyle(
                                color: DashboardColors.onSurfaceVariant.withValues(alpha: 0.45),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            if (widget.column.status == TaskBoardStatus.todo) ...[
                              _AddTaskTile(
                                onTap: () => widget.onNewTask?.call(),
                              ),
                              const SizedBox(height: 18),
                            ],
                          ],
                        )
                      : ListView.separated(
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
                            final isSelected = _selectedTaskIds.contains(task.id);
                            return Draggable<TaskBoardItem>(
                              data: task,
                              feedback: Material(
                                color: Colors.transparent,
                                child: SizedBox(
                                  width: 328,
                                  child: TaskCard(
                                    task: task,
                                    selected: isSelected,
                                  ),
                                ),
                              ),
                              childWhenDragging: Opacity(
                                opacity: 0.35,
                                child: TaskCard(
                                  task: task,
                                  selected: isSelected,
                                ),
                              ),
                              child: TaskCard(
                                task: task,
                                selected: isSelected,
                                onSelectedChanged: (bool? val) {
                                  setState(() {
                                    if (val == true) {
                                      _selectedTaskIds.add(task.id);
                                    } else {
                                      _selectedTaskIds.remove(task.id);
                                    }
                                  });
                                },
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

  Widget _buildCopyMenu(BuildContext context, List<TaskBoardItem> tasks) {
    return PopupMenuButton<String>(
      tooltip: 'Copy all tasks',
      offset: const Offset(0, 32),
      color: const Color(0xFF161B26),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.white12),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Copy',
              style: TextStyle(
                color: DashboardColors.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: DashboardColors.onSurfaceVariant,
              size: 16,
            ),
          ],
        ),
      ),
      onSelected: (value) => _handleCopy(context, value, tasks),
      itemBuilder: (context) => [
        const PopupMenuItem<String>(
          value: 'csv',
          child: Text('Copy as CSV', style: TextStyle(color: DashboardColors.onSurface, fontSize: 13)),
        ),
        const PopupMenuItem<String>(
          value: 'sql',
          child: Text('Copy as SQL', style: TextStyle(color: DashboardColors.onSurface, fontSize: 13)),
        ),
        const PopupMenuItem<String>(
          value: 'json',
          child: Text('Copy as JSON', style: TextStyle(color: DashboardColors.onSurface, fontSize: 13)),
        ),
      ],
    );
  }

  Widget _buildExportMenu(BuildContext context, List<TaskBoardItem> tasks) {
    return PopupMenuButton<String>(
      tooltip: 'Export all tasks',
      offset: const Offset(0, 32),
      color: const Color(0xFF161B26),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.white12),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Export',
              style: TextStyle(
                color: DashboardColors.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: DashboardColors.onSurfaceVariant,
              size: 16,
            ),
          ],
        ),
      ),
      onSelected: (value) => _handleExport(context, value, tasks),
      itemBuilder: (context) => [
        const PopupMenuItem<String>(
          value: 'csv',
          child: Text('Export as CSV', style: TextStyle(color: DashboardColors.onSurface, fontSize: 13)),
        ),
        const PopupMenuItem<String>(
          value: 'sql',
          child: Text('Export as SQL', style: TextStyle(color: DashboardColors.onSurface, fontSize: 13)),
        ),
        const PopupMenuItem<String>(
          value: 'json',
          child: Text('Export as JSON', style: TextStyle(color: DashboardColors.onSurface, fontSize: 13)),
        ),
      ],
    );
  }

  void _handleCopy(BuildContext context, String format, List<TaskBoardItem> tasks) {
    if (tasks.isEmpty) return;
    String formattedText = '';
    switch (format) {
      case 'csv':
        formattedText = _tasksToCsv(tasks);
        break;
      case 'sql':
        formattedText = _tasksToSql(tasks);
        break;
      case 'json':
        formattedText = _tasksToJson(tasks);
        break;
    }
    Clipboard.setData(ClipboardData(text: formattedText));
    if (context.mounted) {
      CopySuccessDialog.show(context, tasks.length, format);
    }
  }

  Future<void> _handleExport(BuildContext context, String format, List<TaskBoardItem> tasks) async {
    if (tasks.isEmpty) return;
    String formattedText = '';
    String extension = format;
    switch (format) {
      case 'csv':
        formattedText = _tasksToCsv(tasks);
        break;
      case 'sql':
        formattedText = _tasksToSql(tasks);
        break;
      case 'json':
        formattedText = _tasksToJson(tasks);
        break;
    }
    
    final columnName = widget.column.title.toLowerCase().replaceAll(' ', '_');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '${columnName}_tasks_export_$timestamp.$extension';
    
    Clipboard.setData(ClipboardData(text: formattedText));

    if (kIsWeb) {
      try {
        final bytes = utf8.encode(formattedText);
        final base64Data = base64Encode(bytes);
        final mimeType = format == 'json' ? 'application/json' : (format == 'sql' ? 'application/sql' : 'text/csv');
        final url = 'data:$mimeType;base64,$base64Data';
        final uri = Uri.parse(url);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        
        if (context.mounted) {
          ExportSuccessDialog.show(context, tasks.length, format, fileName, null);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Không thể tải xuống file: $e. Nội dung đã được sao chép vào clipboard!'),
              backgroundColor: DashboardColors.error,
            ),
          );
        }
      }
    } else {
      final filePath = await _saveToFile(fileName, formattedText);
      if (context.mounted) {
        if (filePath != null) {
          ExportSuccessDialog.show(context, tasks.length, format, fileName, filePath);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Lỗi khi ghi file. Nội dung đã được sao chép vào clipboard!'),
              backgroundColor: DashboardColors.error,
            ),
          );
        }
      }
    }
  }

  Future<String?> _saveToFile(String fileName, String content) async {
    try {
      if (kIsWeb) return null;
      
      String? dirPath;
      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        final dir = await getDownloadsDirectory();
        if (dir != null) dirPath = dir.path;
      }
      if (dirPath == null) {
        final dir = await getApplicationDocumentsDirectory();
        dirPath = dir.path;
      }
      
      final file = File('$dirPath/$fileName');
      await file.writeAsString(content);
      return file.absolute.path;
    } catch (e) {
      debugPrint('Error saving file: $e');
      return null;
    }
  }

  Future<void> _handleDeleteSelected(BuildContext context, List<TaskBoardItem> tasks) async {
    if (tasks.isEmpty) return;

    final user = ref.read(authControllerProvider).valueOrNull;
    final ownedTasks = tasks.where((t) => user != null && t.userId == user.id).toList();

    if (ownedTasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn không có quyền xóa các công việc này (chỉ người tạo mới được xóa)')),
      );
      return;
    }
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F131E),
        title: const Text('Xác nhận xóa đã chọn', style: TextStyle(color: DashboardColors.onSurface)),
        content: Text(
          'Bạn có chắc chắn muốn xóa ${ownedTasks.length} công việc đã chọn (do bạn tạo) trong cột "${widget.column.title}" không? Hành động này không thể hoàn tác.',
          style: const TextStyle(color: DashboardColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy', style: TextStyle(color: DashboardColors.onSurfaceVariant)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: DashboardColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final count = ownedTasks.length;
        final idsToDelete = ownedTasks.map((t) => t.id).toList();
        
        setState(() {
          _selectedTaskIds.removeAll(idsToDelete);
        });

        for (final id in idsToDelete) {
          await ref.read(taskRepositoryProvider).deleteTask(id);
        }
        if (context.mounted) {
          DeleteAllSuccessDialog.show(context, count);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi khi xóa: $e')),
          );
        }
      }
    }
  }

  String _tasksToCsv(List<TaskBoardItem> tasks) {
    final buffer = StringBuffer();
    buffer.writeln('ID,Title,Description,Status,Priority,Due Date,Creator');
    for (final t in tasks) {
      final fields = [
        t.id,
        t.title,
        t.description,
        t.status.name,
        t.priority.name,
        t.dueDate != null ? t.dueDate!.toIso8601String() : '',
        t.creatorName ?? '',
      ];
      final csvLine = fields.map((f) {
        final val = f.toString();
        if (val.contains(',') || val.contains('"') || val.contains('\n') || val.contains('\r')) {
          return '"${val.replaceAll('"', '""')}"';
        }
        return val;
      }).join(',');
      buffer.writeln(csvLine);
    }
    return buffer.toString();
  }

  String _tasksToSql(List<TaskBoardItem> tasks) {
    final buffer = StringBuffer();
    for (final t in tasks) {
      final id = t.id.replaceAll("'", "''");
      final title = t.title.replaceAll("'", "''");
      final description = t.description.replaceAll("'", "''");
      final status = t.status.name;
      final priority = t.priority.name;
      final dueDate = t.dueDate != null ? t.dueDate!.toIso8601String() : 'NULL';
      final dueDateVal = dueDate == 'NULL' ? 'NULL' : "'$dueDate'";
      
      buffer.writeln(
        "INSERT INTO tasks (id, title, description, status, priority, due_date) VALUES ('$id', '$title', '$description', '$status', '$priority', $dueDateVal);"
      );
    }
    return buffer.toString();
  }

  String _tasksToJson(List<TaskBoardItem> tasks) {
    final list = tasks.map((t) => {
      'id': t.id,
      'title': t.title,
      'description': t.description,
      'status': t.status.name,
      'priority': t.priority.name,
      'dueDate': t.dueDate?.toIso8601String(),
      'creatorName': t.creatorName,
    }).toList();
    return const JsonEncoder.withIndent('  ').convert(list);
  }

  IconData _getColumnEmptyIcon(TaskBoardStatus status) {
    switch (status) {
      case TaskBoardStatus.draft:
        return Icons.edit_note_rounded;
      case TaskBoardStatus.todo:
        return Icons.checklist_rounded;
      case TaskBoardStatus.inProgress:
        return Icons.hourglass_empty_rounded;
      case TaskBoardStatus.completed:
        return Icons.task_alt_rounded;
    }
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
