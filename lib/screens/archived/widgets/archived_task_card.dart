import 'package:flutter/material.dart';
import 'package:to_do_app/screens/archived/models/archived_task_model.dart';
import 'package:to_do_app/screens/archived/widgets/archive_shared_widgets.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class ArchivedTaskCard extends StatefulWidget {
  const ArchivedTaskCard({
    required this.task,
    required this.onView,
    required this.onRestore,
    required this.onDelete,
    super.key,
  });

  final ArchivedTask task;
  final VoidCallback onView;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  @override
  State<ArchivedTaskCard> createState() => _ArchivedTaskCardState();
}

class _ArchivedTaskCardState extends State<ArchivedTaskCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.task;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onView,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, _hover ? -2 : 0, 0),
          child: ArchiveGlassCard(
            padding: const EdgeInsets.all(20),
            radius: 22,
            glowColor: _hover ? DashboardColors.primary : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(task: t),
                const SizedBox(height: 12),
                if ((t.description ?? '').trim().isNotEmpty) ...[
                  Text(
                    t.description!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: DashboardColors.onSurfaceVariant,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ArchivePriorityChip(task: t),
                    ArchiveStatusChip(task: t),
                    if (t.aiGenerated) const _AiBadge(),
                    if (t.estimatedLabel.isNotEmpty)
                      _MetaChip(
                        icon: Icons.schedule_rounded,
                        label: t.estimatedLabel,
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                _DatesGrid(task: t),
                if (t.tagIds.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ArchiveTagChips(tags: t.tagIds),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    ArchiveAssigneeStack(assigneeIds: t.assigneeIds),
                    const Spacer(),
                    if (t.dueDate != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.event_available_rounded,
                            size: 13,
                            color: DashboardColors.onSurfaceVariant
                                .withValues(alpha: .8),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Due ${_short(t.dueDate)}',
                            style: const TextStyle(
                              color: DashboardColors.onSurfaceVariant,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                _Actions(
                  onView: widget.onView,
                  onRestore: widget.onRestore,
                  onDelete: widget.onDelete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _short(DateTime? d) {
    if (d == null) return '—';
    return '${d.day}/${d.month}';
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.task});
  final ArchivedTask task;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            task.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: DashboardColors.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              height: 1.3,
              letterSpacing: -0.2,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: DashboardColors.surfaceHigh.withValues(alpha: .55),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white.withValues(alpha: .12)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.archive_rounded,
                  size: 11, color: DashboardColors.onSurfaceVariant),
              SizedBox(width: 4),
              Text(
                'ARCHIVED',
                style: TextStyle(
                  color: DashboardColors.onSurfaceVariant,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DatesGrid extends StatelessWidget {
  const _DatesGrid({required this.task});
  final ArchivedTask task;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: .05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ArchiveDateRow(label: 'Created', date: task.createdAt),
          const SizedBox(height: 4),
          ArchiveDateRow(label: 'Completed', date: task.completedAt),
          const SizedBox(height: 4),
          ArchiveDateRow(label: 'Archived', date: task.archivedAt),
        ],
      ),
    );
  }
}

class _AiBadge extends StatelessWidget {
  const _AiBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DashboardColors.primary.withValues(alpha: .25),
            DashboardColors.secondary.withValues(alpha: .25),
          ],
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: DashboardColors.primary.withValues(alpha: .35)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_rounded, size: 11, color: DashboardColors.primary),
          SizedBox(width: 4),
          Text(
            'AI Generated',
            style: TextStyle(
              color: DashboardColors.primary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .04),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: .08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: DashboardColors.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: DashboardColors.onSurfaceVariant,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.onView,
    required this.onRestore,
    required this.onDelete,
  });

  final VoidCallback onView;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Btn(
            label: 'View',
            icon: Icons.visibility_outlined,
            onTap: onView,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _Btn(
            label: 'Restore',
            icon: Icons.restore_rounded,
            color: DashboardColors.primary,
            filled: true,
            onTap: onRestore,
          ),
        ),
        const SizedBox(width: 8),
        _IconBtn(
          icon: Icons.delete_outline_rounded,
          color: DashboardColors.error,
          onTap: onDelete,
        ),
      ],
    );
  }
}

class _Btn extends StatelessWidget {
  const _Btn({
    required this.label,
    required this.icon,
    required this.onTap,
    this.color,
    this.filled = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final c = color ?? DashboardColors.onSurfaceVariant;
    return Material(
      color: filled ? c.withValues(alpha: .14) : Colors.white.withValues(alpha: .04),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: filled
                  ? c.withValues(alpha: .35)
                  : Colors.white.withValues(alpha: .08),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: c),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: c,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: .04),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: .08)),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}
