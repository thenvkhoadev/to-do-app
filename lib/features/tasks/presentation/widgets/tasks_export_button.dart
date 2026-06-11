import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:to_do_app/features/tasks/domain/entities/task_board_item.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';
import 'export_success_dialog.dart';

// ── Helpers for Active Tasks Export ───────────────────────────────────────────

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

// ── TasksExportButton ──────────────────────────────────────────────────────────

class TasksExportButton extends StatefulWidget {
  const TasksExportButton({
    required this.tasks,
    super.key,
  });

  final List<TaskBoardItem> tasks;

  @override
  State<TasksExportButton> createState() => _TasksExportButtonState();
}

class _TasksExportButtonState extends State<TasksExportButton> {
  bool _loading = false;
  final _layerLink = LayerLink();
  OverlayEntry? _overlay;
  bool _open = false;

  void _toggleMenu() => _open ? _closeMenu() : _openMenu();

  void _closeMenu() {
    _overlay?.remove();
    _overlay = null;
    _open = false;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _overlay?.remove();
    _overlay = null;
    super.dispose();
  }

  void _openMenu() {
    _overlay = OverlayEntry(
      builder: (_) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _closeMenu,
        child: Stack(
          children: [
            Positioned.fill(child: Container(color: Colors.transparent)),
            CompositedTransformFollower(
              link: _layerLink,
              targetAnchor: Alignment.bottomLeft,
              followerAnchor: Alignment.topLeft,
              offset: const Offset(0, 6),
              child: Material(
                color: Colors.transparent,
                child: _ExportMenu(
                  onSelect: (fmt) {
                    _closeMenu();
                    _export(fmt);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
    Overlay.of(context).insert(_overlay!);
    setState(() => _open = true);
  }

  Future<void> _export(String format) async {
    if (widget.tasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Không có công việc nào để xuất'),
        backgroundColor: DashboardColors.error,
      ));
      return;
    }
    setState(() => _loading = true);
    try {
      late String content;
      late String ext;
      switch (format) {
        case 'json':
          content = _tasksToJson(widget.tasks);
          ext = 'json';
          break;
        case 'sql':
          content = _tasksToSql(widget.tasks);
          ext = 'sql';
          break;
        default:
          content = _tasksToCsv(widget.tasks);
          ext = 'csv';
      }
      final ts = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'active_tasks_$ts.$ext';
      await Clipboard.setData(ClipboardData(text: content));
      
      if (kIsWeb) {
        final b64 = base64Encode(utf8.encode(content));
        final mime = format == 'json'
            ? 'application/json'
            : format == 'sql' ? 'application/sql' : 'text/csv';
        await launchUrl(Uri.parse('data:$mime;base64,$b64'),
            mode: LaunchMode.externalApplication);
        if (mounted) _showSuccess(fileName, null, format);
      } else {
        final path = await _saveToFile(fileName, content);
        if (mounted) _showSuccess(fileName, path, format);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Lỗi khi xuất file: $e'),
          backgroundColor: DashboardColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSuccess(String fileName, String? filePath, String format) {
    if (filePath != null) {
      ExportSuccessDialog.show(context, widget.tasks.length, format, fileName, filePath);
    } else {
      CopySuccessDialog.show(context, widget.tasks.length, format);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: _loading ? null : _toggleMenu,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .07),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: .12)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _loading
                    ? const SizedBox(
                        width: 14, height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: DashboardColors.onSurface))
                    : const Icon(Icons.download_rounded, size: 14, color: DashboardColors.onSurface),
                const SizedBox(width: 6),
                const Text('Export',
                    style: TextStyle(color: DashboardColors.onSurface, fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: _open ? 0.5 : 0,
                  duration: const Duration(milliseconds: 150),
                  child: const Icon(Icons.expand_more_rounded, size: 14, color: DashboardColors.onSurface),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Export menu panel ─────────────────────────────────────────────────────────

class _ExportMenu extends StatelessWidget {
  const _ExportMenu({required this.onSelect});
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    const opts = [
      (icon: Icons.table_chart_rounded, label: 'Excel / CSV', fmt: 'csv', color: Color(0xFF22C55E)),
      (icon: Icons.data_object_rounded, label: 'JSON', fmt: 'json', color: Color(0xFF5B8CFF)),
      (icon: Icons.storage_rounded, label: 'SQL', fmt: 'sql', color: Color(0xFFFFB020)),
    ];
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: .08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .4),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: DefaultTextStyle(
        style: const TextStyle(decoration: TextDecoration.none),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: Row(
                children: [
                  Icon(Icons.download_rounded, size: 14, color: DashboardColors.onSurfaceVariant),
                  SizedBox(width: 6),
                  Text(
                    'Export Tasks',
                    style: TextStyle(
                      color: DashboardColors.onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
            Container(height: 1, color: Colors.white.withValues(alpha: .06)),
            const SizedBox(height: 4),
            ...opts.map((o) => _ExportMenuItem(
                  icon: o.icon,
                  label: o.label,
                  color: o.color,
                  onTap: () => onSelect(o.fmt),
                )),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

class _ExportMenuItem extends StatefulWidget {
  const _ExportMenuItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_ExportMenuItem> createState() => _ExportMenuItemState();
}

class _ExportMenuItemState extends State<_ExportMenuItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: _hover ? widget.color.withValues(alpha: .08) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 16, color: widget.color),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
