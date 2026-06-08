import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/features/profile/data/models/user_profile_model.dart';
import 'package:to_do_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:to_do_app/features/tasks/data/models/tag_model.dart';
import 'package:to_do_app/features/tasks/presentation/providers/tasks_provider.dart';
import 'package:to_do_app/screens/archived/models/archived_task_model.dart';
import 'package:to_do_app/screens/archived/widgets/archive_shared_widgets.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

// ── Main drawer ───────────────────────────────────────────────────────────────

class ArchiveDetailDrawer extends ConsumerWidget {
  const ArchiveDetailDrawer({
    required this.task,
    required this.onClose,
    required this.onRestore,
    required this.onDelete,
    super.key,
  });

  final ArchivedTask task;
  final VoidCallback onClose;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(userCategoriesProvider).valueOrNull ?? [];
    final users = ref.watch(allUsersProvider).valueOrNull ?? [];
    final tags = ref.watch(userTagsProvider).valueOrNull ?? [];

    final catName = categories
        .where((c) => c.id == task.categoryId)
        .map((c) => c.name)
        .firstOrNull;

    final assignees = task.assigneeIds
        .map((id) => users.where((u) => u.id == id).firstOrNull)
        .whereType<UserProfileModel>()
        .toList();

    final taskTags = task.tagIds
        .map((id) => tags.where((t) => t.id == id).firstOrNull)
        .whereType<TagModel>()
        .toList();

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          width: 460,
          decoration: BoxDecoration(
            color: DashboardColors.surface.withValues(alpha: .55),
            border: Border(
              left: BorderSide(color: Colors.white.withValues(alpha: .08)),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .45),
                blurRadius: 60,
                offset: const Offset(-12, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              _Header(task: task, onClose: onClose),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _OverviewSection(task: task, catName: catName),
                      const SizedBox(height: 16),
                      if (assignees.isNotEmpty || task.assigneeIds.isEmpty)
                        _AssigneesSection(assignees: assignees),
                      const SizedBox(height: 16),
                      if ((task.description ?? '').isNotEmpty)
                        _DescriptionSection(task: task),
                      if ((task.description ?? '').isNotEmpty)
                        const SizedBox(height: 16),
                      _TimelineSection(task: task),
                      const SizedBox(height: 16),
                      _OrganizationSection(task: task, catName: catName, tags: taskTags),
                      const SizedBox(height: 16),
                      _ArchiveInfoSection(task: task),
                      if (task.aiGenerated) ...[
                        const SizedBox(height: 16),
                        _AiMetadataSection(task: task),
                      ],
                      const SizedBox(height: 16),
                      _MetadataSection(task: task),
                      const SizedBox(height: 24),
                      _ActionsSection(
                        task: task,
                        onRestore: onRestore,
                        onDelete: onDelete,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.task, required this.onClose});
  final ArchivedTask task;
  final VoidCallback onClose;

  String _fmtShort(DateTime? d) {
    if (d == null) return '';
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return 'Archived ${d.day} ${m[d.month-1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      decoration: BoxDecoration(
        color: DashboardColors.surface.withValues(alpha: .5),
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: .08))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: DashboardColors.primary.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: DashboardColors.primary.withValues(alpha: .25)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.archive_rounded, color: DashboardColors.primary, size: 12),
                    SizedBox(width: 5),
                    Text('ARCHIVED', style: TextStyle(color: DashboardColors.primary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  ],
                ),
              ),
              const Spacer(),
              if (task.archivedAt != null)
                Text(
                  _fmtShort(task.archivedAt),
                  style: TextStyle(color: DashboardColors.onSurfaceVariant.withValues(alpha: .7), fontSize: 11),
                ),
              const SizedBox(width: 10),
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: onClose,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 30, height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white.withValues(alpha: .04),
                      border: Border.all(color: Colors.white.withValues(alpha: .08)),
                    ),
                    child: const Icon(Icons.close_rounded, color: DashboardColors.onSurfaceVariant, size: 15),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            task.title,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: DashboardColors.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1.25,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ArchiveStatusChip(task: task),
              ArchivePriorityChip(task: task),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Section container ─────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({required this.icon, required this.label, required this.child});
  final IconData icon;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: .07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Row(
              children: [
                Icon(icon, color: DashboardColors.primary, size: 13),
                const SizedBox(width: 6),
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    color: DashboardColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.fromLTRB(14, 9, 14, 0),
            color: Colors.white.withValues(alpha: .06),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: child,
          ),
        ],
      ),
    );
  }
}

// ── Overview ──────────────────────────────────────────────────────────────────

class _OverviewSection extends StatelessWidget {
  const _OverviewSection({required this.task, required this.catName});
  final ArchivedTask task;
  final String? catName;

  @override
  Widget build(BuildContext context) {
    return _Section(
      icon: Icons.dashboard_rounded,
      label: 'Overview',
      child: Column(
        children: [
          _GridRow(label: 'Priority', child: ArchivePriorityChip(task: task)),
          const SizedBox(height: 10),
          _GridRow(label: 'Status', child: ArchiveStatusChip(task: task)),
          const SizedBox(height: 10),
          _GridRow(
            label: 'Category',
            child: Text(
              catName ?? 'Uncategorized',
              style: const TextStyle(color: DashboardColors.onSurface, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          if (task.estimatedLabel.isNotEmpty) ...[
            const SizedBox(height: 10),
            _GridRow(
              label: 'Estimate',
              child: Text(
                task.estimatedLabel,
                style: const TextStyle(color: DashboardColors.onSurface, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
          const SizedBox(height: 10),
          _GridRow(
            label: 'Progress',
            child: Text(
              task.status == 'done' ? '100%' : (task.status == 'in_progress' ? '50%' : '0%'),
              style: TextStyle(
                color: task.status == 'done' ? DashboardColors.success : DashboardColors.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GridRow extends StatelessWidget {
  const _GridRow({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

// ── Assignees ─────────────────────────────────────────────────────────────────

class _AssigneesSection extends StatelessWidget {
  const _AssigneesSection({required this.assignees});
  final List<UserProfileModel> assignees;

  @override
  Widget build(BuildContext context) {
    return _Section(
      icon: Icons.group_rounded,
      label: 'Assignees',
      child: assignees.isEmpty
          ? Row(
              children: const [
                Icon(Icons.person_outline_rounded, size: 16, color: DashboardColors.onSurfaceVariant),
                SizedBox(width: 6),
                Text('Unassigned', style: TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            )
          : Column(
              children: assignees.map((u) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _AssigneeRow(user: u),
              )).toList(),
            ),
    );
  }
}

class _AssigneeRow extends StatelessWidget {
  const _AssigneeRow({required this.user});
  final UserProfileModel user;

  String get _initials {
    final name = (user.fullName ?? user.username ?? user.email).trim();
    if (name.isEmpty) return '?';
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0][0].toUpperCase();
  }

  Color get _color {
    const palette = [
      Color(0xFF7C5CFF), Color(0xFF5B8CFF), Color(0xFF22C55E),
      Color(0xFFFFB020), Color(0xFFFF6B6B), Color(0xFF06B6D4), Color(0xFFA855F7),
    ];
    final hash = user.id.codeUnits.fold(0, (a, b) => a + b);
    return palette[hash % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final url = user.avatarUrl?.trim() ?? '';
    return Row(
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: .12), width: 1),
          ),
          child: ClipOval(
            child: url.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _fallback(),
                    placeholder: (_, __) => _fallback(),
                  )
                : _fallback(),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                (user.fullName ?? user.username ?? user.email).trim(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: DashboardColors.onSurface, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              if (user.email.isNotEmpty)
                Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: DashboardColors.onSurfaceVariant.withValues(alpha: .8), fontSize: 11),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _fallback() => Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [_color, _color.withValues(alpha: .7)]),
        ),
        child: Text(_initials, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
      );
}

// ── Description ───────────────────────────────────────────────────────────────

class _DescriptionSection extends StatelessWidget {
  const _DescriptionSection({required this.task});
  final ArchivedTask task;

  @override
  Widget build(BuildContext context) {
    return _Section(
      icon: Icons.notes_rounded,
      label: 'Description',
      child: Text(
        task.description!,
        style: TextStyle(
          color: DashboardColors.onSurfaceVariant.withValues(alpha: .9),
          fontSize: 13,
          height: 1.6,
        ),
      ),
    );
  }
}

// ── Timeline ──────────────────────────────────────────────────────────────────

class _TimelineSection extends StatelessWidget {
  const _TimelineSection({required this.task});
  final ArchivedTask task;

  String _fmt(DateTime? d) {
    if (d == null) return 'None';
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${m[d.month-1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final events = <(IconData, String, DateTime?, Color)>[
      (Icons.add_circle_outline_rounded, 'Created', task.createdAt, DashboardColors.primary),
      (Icons.update_rounded, 'Updated', task.updatedAt, DashboardColors.secondary),
      (Icons.check_circle_outline_rounded, 'Completed', task.completedAt, DashboardColors.success),
      (Icons.archive_rounded, 'Archived', task.archivedAt, DashboardColors.primary),
      (Icons.event_rounded, 'Due Date', task.dueDate, const Color(0xFFFFB020)),
      (Icons.notifications_active_rounded, 'Reminder', task.reminderAt, const Color(0xFFFF6B6B)),
    ];

    return _Section(
      icon: Icons.timeline_rounded,
      label: 'Timeline',
      child: Column(
        children: List.generate(events.length, (i) {
          final (icon, label, date, color) = events[i];
          final isLast = i == events.length - 1;
          return _TimelineRow(
            icon: icon,
            label: label,
            value: _fmt(date),
            color: color,
            isActive: date != null,
            isLast: isLast,
          );
        }),
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isActive,
    required this.isLast,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isActive;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 22, height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? color.withValues(alpha: .15) : Colors.white.withValues(alpha: .04),
                  border: Border.all(
                    color: isActive ? color.withValues(alpha: .4) : Colors.white.withValues(alpha: .1),
                  ),
                ),
                child: Icon(icon, size: 11, color: isActive ? color : DashboardColors.onSurfaceVariant),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1,
                    color: Colors.white.withValues(alpha: .08),
                    margin: const EdgeInsets.symmetric(vertical: 2),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12, top: 1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: isActive ? DashboardColors.onSurface : DashboardColors.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      color: DashboardColors.onSurfaceVariant.withValues(alpha: isActive ? .9 : .6),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
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

// ── Organization ──────────────────────────────────────────────────────────────

class _OrganizationSection extends StatelessWidget {
  const _OrganizationSection({
    required this.task,
    required this.catName,
    required this.tags,
  });
  final ArchivedTask task;
  final String? catName;
  final List<TagModel> tags;

  @override
  Widget build(BuildContext context) {
    return _Section(
      icon: Icons.account_tree_rounded,
      label: 'Organization',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GridRow(
            label: 'Category',
            child: Text(
              catName ?? 'Uncategorized',
              style: const TextStyle(color: DashboardColors.onSurface, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 10),
          _GridRow(
            label: 'Tags',
            child: tags.isEmpty
                ? const Text('None', style: TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: 13))
                : Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: tags.map((t) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: DashboardColors.primary.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: DashboardColors.primary.withValues(alpha: .25)),
                      ),
                      child: Text(
                        t.name,
                        style: const TextStyle(color: DashboardColors.primary, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    )).toList(),
                  ),
          ),
          if (task.parentTaskId != null) ...[
            const SizedBox(height: 10),
            _GridRow(
              label: 'Parent',
              child: Text(
                'Has parent task',
                style: const TextStyle(color: DashboardColors.onSurface, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Archive Information ───────────────────────────────────────────────────────

class _ArchiveInfoSection extends StatelessWidget {
  const _ArchiveInfoSection({required this.task});
  final ArchivedTask task;

  String _ago(DateTime? d) {
    if (d == null) return '—';
    final diff = DateTime.now().difference(d);
    if (diff.inDays > 0) return '${diff.inDays} day${diff.inDays > 1 ? "s" : ""} ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  String _taskAge() {
    if (task.createdAt == null || task.archivedAt == null) return '—';
    final d = task.archivedAt!.difference(task.createdAt!).inDays;
    return '$d day${d != 1 ? "s" : ""}';
  }

  @override
  Widget build(BuildContext context) {
    final reason = task.aiGenerated ? 'Auto Archive' : 'Manual Archive';
    return _Section(
      icon: Icons.inventory_2_rounded,
      label: 'Archive Information',
      child: Column(
        children: [
          _GridRow(
            label: 'Reason',
            child: Text(reason, style: const TextStyle(color: DashboardColors.onSurface, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 10),
          _GridRow(
            label: 'Duration',
            child: Text(_ago(task.archivedAt), style: const TextStyle(color: DashboardColors.onSurface, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 10),
          _GridRow(
            label: 'Task Age',
            child: Text(_taskAge(), style: const TextStyle(color: DashboardColors.onSurface, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ── AI Metadata ───────────────────────────────────────────────────────────────

class _AiMetadataSection extends StatelessWidget {
  const _AiMetadataSection({required this.task});
  final ArchivedTask task;

  @override
  Widget build(BuildContext context) {
    return _Section(
      icon: Icons.auto_awesome_rounded,
      label: 'AI Metadata',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    DashboardColors.primary.withValues(alpha: .2),
                    DashboardColors.secondary.withValues(alpha: .2),
                  ]),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: DashboardColors.primary.withValues(alpha: .3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 11, color: DashboardColors.primary),
                    SizedBox(width: 4),
                    Text('AI Generated', style: TextStyle(color: DashboardColors.primary, fontSize: 11, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'This task was created by AI Assistant',
            style: TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ── Metadata ──────────────────────────────────────────────────────────────────

class _MetadataSection extends StatelessWidget {
  const _MetadataSection({required this.task});
  final ArchivedTask task;

  @override
  Widget build(BuildContext context) {
    return _Section(
      icon: Icons.data_object_rounded,
      label: 'Metadata',
      child: Column(
        children: [
          _MetaRow(label: 'Task ID', value: task.id),
          const SizedBox(height: 8),
          _MetaRow(label: 'Sort Order', value: task.sortOrder.toString()),
          if (task.estimatedMinutes != null) ...[
            const SizedBox(height: 8),
            _MetaRow(label: 'Estimated', value: '${task.estimatedMinutes} mins'),
          ],
        ],
      ),
    );
  }
}

class _MetaRow extends StatefulWidget {
  const _MetaRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  State<_MetaRow> createState() => _MetaRowState();
}

class _MetaRowState extends State<_MetaRow> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.value));
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(widget.label, style: const TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: Text(
            widget.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: DashboardColors.onSurface, fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'monospace'),
          ),
        ),
        GestureDetector(
          onTap: _copy,
          child: Icon(
            _copied ? Icons.check_rounded : Icons.copy_rounded,
            size: 13,
            color: _copied ? DashboardColors.success : DashboardColors.onSurfaceVariant.withValues(alpha: .5),
          ),
        ),
      ],
    );
  }
}

// ── Actions ───────────────────────────────────────────────────────────────────

class _ActionsSection extends StatelessWidget {
  const _ActionsSection({
    required this.task,
    required this.onRestore,
    required this.onDelete,
  });
  final ArchivedTask task;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ActionBtn(
          label: 'Restore Task',
          icon: Icons.restore_rounded,
          color: DashboardColors.primary,
          filled: true,
          onTap: onRestore,
        ),
        const SizedBox(height: 8),
        _ActionBtn(
          label: 'Delete Permanently',
          icon: Icons.delete_forever_rounded,
          color: DashboardColors.error,
          filled: false,
          onTap: onDelete,
        ),
      ],
    );
  }
}

class _ActionBtn extends StatefulWidget {
  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.filled,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Color color;
  final bool filled;
  final VoidCallback onTap;

  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn> {
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
          height: 44,
          decoration: BoxDecoration(
            color: widget.filled
                ? widget.color.withValues(alpha: _hover ? .22 : .14)
                : widget.color.withValues(alpha: _hover ? .08 : .04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.color.withValues(alpha: widget.filled ? .4 : .25),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: widget.color, size: 16),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
