import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:to_do_app/features/profile/data/models/user_profile_model.dart';
import 'package:to_do_app/features/tasks/data/models/category_model.dart';
import 'package:to_do_app/screens/archived/models/archived_task_model.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

String _fmt(DateTime? d) => d?.toIso8601String() ?? '';
String _esc(String? s) => (s ?? '').replaceAll("'", "''");
String _csvField(String? raw) {
  final v = raw ?? '';
  if (v.contains(',') || v.contains('"') || v.contains('\n')) {
    return '"${v.replaceAll('"', '""')}"';
  }
  return v;
}

String _catName(String? id, List<CategoryModel> cats) {
  if (id == null) return '';
  final m = cats.where((c) => c.id == id);
  return m.isNotEmpty ? m.first.name : id;
}

String _assigneeNames(List<String> ids, List<UserProfileModel> users) {
  return ids.map((id) {
    final u = users.where((u) => u.id == id);
    if (u.isEmpty) return id;
    final p = u.first;
    return p.fullName ?? p.username ?? p.email;
  }).join(', ');
}

// ── Format functions ──────────────────────────────────────────────────────────

String archivedTasksToCsv(
  List<ArchivedTask> tasks,
  List<CategoryModel> cats,
  List<UserProfileModel> users,
) {
  final buf = StringBuffer();
  buf.writeln('ID,Title,Description,Status,Priority,Category,Assignees,'
      'Created,Completed,Archived,Due Date,Estimated Minutes');
  for (final t in tasks) {
    final row = [
      t.id,
      t.title,
      t.description,
      t.status,
      t.priority,
      _catName(t.categoryId, cats),
      _assigneeNames(t.assigneeIds, users),
      _fmt(t.createdAt),
      _fmt(t.completedAt),
      _fmt(t.archivedAt),
      _fmt(t.dueDate),
      t.estimatedMinutes?.toString() ?? '',
    ].map(_csvField).join(',');
    buf.writeln(row);
  }
  return buf.toString();
}

String archivedTasksToJson(
  List<ArchivedTask> tasks,
  List<CategoryModel> cats,
  List<UserProfileModel> users,
) {
  final list = tasks.map((t) => {
        'id': t.id,
        'title': t.title,
        'description': t.description,
        'status': t.status,
        'priority': t.priority,
        'category': _catName(t.categoryId, cats),
        'assignees': t.assigneeIds
            .map((id) {
              final u = users.where((u) => u.id == id);
              if (u.isEmpty) return {'id': id};
              final p = u.first;
              return {
                'id': id,
                'name': p.fullName ?? p.username ?? p.email,
                'email': p.email,
              };
            })
            .toList(),
        'created_at': _fmt(t.createdAt),
        'completed_at': _fmt(t.completedAt),
        'archived_at': _fmt(t.archivedAt),
        'due_date': _fmt(t.dueDate),
        'estimated_minutes': t.estimatedMinutes,
        'ai_generated': t.aiGenerated,
        'tags': t.tagIds,
      }).toList();
  return const JsonEncoder.withIndent('  ').convert(list);
}

String archivedTasksToSql(
  List<ArchivedTask> tasks,
  List<CategoryModel> cats,
  List<UserProfileModel> users,
) {
  final buf = StringBuffer();
  buf.writeln('-- Archived tasks export');
  buf.writeln(
      'INSERT INTO archived_tasks (id, title, description, status, priority, '
      'category_id, created_at, completed_at, archived_at, due_date) VALUES');
  for (int i = 0; i < tasks.length; i++) {
    final t = tasks[i];
    final comma = i < tasks.length - 1 ? ',' : ';';
    final due = t.dueDate != null ? "'${_fmt(t.dueDate)}'" : 'NULL';
    final comp = t.completedAt != null ? "'${_fmt(t.completedAt)}'" : 'NULL';
    final arch = t.archivedAt != null ? "'${_fmt(t.archivedAt)}'" : 'NULL';
    final cat = t.categoryId != null ? "'${_esc(t.categoryId)}'" : 'NULL';
    buf.writeln("  ('${_esc(t.id)}', '${_esc(t.title)}', "
        "'${_esc(t.description)}', '${_esc(t.status)}', "
        "'${_esc(t.priority)}', $cat, "
        "'${_fmt(t.createdAt)}', $comp, $arch, $due)$comma");
  }
  return buf.toString();
}

// ── Save to file ──────────────────────────────────────────────────────────────

Future<String?> saveArchivedExportFile(String fileName, String content) async {
  try {
    if (kIsWeb) return null;
    String? dirPath;
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      final dir = await getDownloadsDirectory();
      if (dir != null) dirPath = dir.path;
    }
    dirPath ??= (await getApplicationDocumentsDirectory()).path;
    final file = File('$dirPath/$fileName');
    await file.writeAsString(content);
    return file.absolute.path;
  } catch (e) {
    debugPrint('archive export error: $e');
    return null;
  }
}

// ── Export button with dropdown ───────────────────────────────────────────────

class ArchiveExportButton extends StatefulWidget {
  const ArchiveExportButton({
    required this.tasks,
    required this.categories,
    required this.users,
    super.key,
  });

  final List<ArchivedTask> tasks;
  final List<CategoryModel> categories;
  final List<UserProfileModel> users;

  @override
  State<ArchiveExportButton> createState() => _ArchiveExportButtonState();
}

class _ArchiveExportButtonState extends State<ArchiveExportButton> {
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
              targetAnchor: Alignment.bottomRight,
              followerAnchor: Alignment.topRight,
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
        content: Text('No tasks to export'),
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
          content = archivedTasksToJson(widget.tasks, widget.categories, widget.users);
          ext = 'json';
          break;
        case 'sql':
          content = archivedTasksToSql(widget.tasks, widget.categories, widget.users);
          ext = 'sql';
          break;
        default:
          content = archivedTasksToCsv(widget.tasks, widget.categories, widget.users);
          ext = 'csv';
      }
      final ts = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'archived_tasks_$ts.$ext';
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
        final path = await saveArchivedExportFile(fileName, content);
        if (mounted) _showSuccess(fileName, path, format);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Export error: $e'),
          backgroundColor: DashboardColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSuccess(String fileName, String? filePath, String format) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: DashboardColors.success,
      content: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              filePath != null ? 'Saved to $filePath' : 'Copied as $format',
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    ));
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
