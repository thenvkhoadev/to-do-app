import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:to_do_app/screens/archived/models/archived_task_model.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

// ── Glass card ────────────────────────────────────────────────────────────────

class ArchiveGlassCard extends StatelessWidget {
  const ArchiveGlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 20.0,
    this.glowColor,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? glowColor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .03),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withValues(alpha: .08)),
            boxShadow: [
              if (glowColor != null)
                BoxShadow(
                  color: glowColor!.withValues(alpha: .15),
                  blurRadius: 40,
                ),
              BoxShadow(
                color: Colors.black.withValues(alpha: .22),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

// ── KPI card ──────────────────────────────────────────────────────────────────

class ArchiveKpiCard extends StatelessWidget {
  const ArchiveKpiCard({
    required this.label,
    required this.value,
    this.suffix,
    this.trend,
    this.trendPositive = true,
    this.progress,
    super.key,
  });

  final String label;
  final String value;
  final String? suffix;
  final String? trend;
  final bool trendPositive;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return ArchiveGlassCard(
      glowColor: DashboardColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: DashboardColors.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: DashboardColors.primary,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  height: 1,
                  letterSpacing: -1,
                ),
              ),
              if (suffix != null) ...[
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    suffix!,
                    style: const TextStyle(
                      color: DashboardColors.onSurfaceVariant,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              if (trend != null) ...[
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    trend!,
                    style: TextStyle(
                      color: trendPositive
                          ? DashboardColors.success
                          : DashboardColors.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: Colors.white.withValues(alpha: .08),
                valueColor:
                    const AlwaysStoppedAnimation(DashboardColors.primary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Priority chip ─────────────────────────────────────────────────────────────

class ArchivePriorityChip extends StatelessWidget {
  const ArchivePriorityChip({required this.task, super.key});

  final ArchivedTask task;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: task.priorityColor.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: task.priorityColor.withValues(alpha: .28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: task.priorityColor,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            task.priorityLabel,
            style: TextStyle(
              color: task.priorityColor,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Status chip ───────────────────────────────────────────────────────────────

class ArchiveStatusChip extends StatelessWidget {
  const ArchiveStatusChip({required this.task, super.key});

  final ArchivedTask task;

  Color get _color => switch (task.status) {
        'done' => DashboardColors.success,
        'in_progress' => DashboardColors.primary,
        _ => DashboardColors.onSurfaceVariant,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _color.withValues(alpha: .22)),
      ),
      child: Text(
        task.statusLabel,
        style: TextStyle(
          color: _color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ── Date label ────────────────────────────────────────────────────────────────

class ArchiveDateRow extends StatelessWidget {
  const ArchiveDateRow({
    required this.label,
    required this.date,
    super.key,
  });

  final String label;
  final DateTime? date;

  String _fmt(DateTime? d) {
    if (d == null) return '—';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            color: DashboardColors.onSurfaceVariant,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          _fmt(date),
          style: const TextStyle(
            color: DashboardColors.onSurface,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ── Tag chips ─────────────────────────────────────────────────────────────────

class ArchiveTagChips extends StatelessWidget {
  const ArchiveTagChips({required this.tags, super.key});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: tags
          .take(4)
          .map(
            (t) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: DashboardColors.primary.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: DashboardColors.primary.withValues(alpha: .18),
                ),
              ),
              child: Text(
                '#$t',
                style: const TextStyle(
                  color: DashboardColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

// ── Assignee avatars ──────────────────────────────────────────────────────────

class ArchiveAssigneeStack extends StatelessWidget {
  const ArchiveAssigneeStack({required this.assigneeIds, super.key});

  final List<String> assigneeIds;

  @override
  Widget build(BuildContext context) {
    if (assigneeIds.isEmpty) return const SizedBox.shrink();
    final shown = assigneeIds.take(3).toList();
    final extra = assigneeIds.length - shown.length;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: shown.length * 20.0 + 8,
          height: 28,
          child: Stack(
            children: [
              for (int i = 0; i < shown.length; i++)
                Positioned(
                  left: i * 18.0,
                  child: Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: DashboardColors.surfaceHigh,
                      border: Border.all(
                        color: DashboardColors.surface,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      shown[i].isNotEmpty
                          ? shown[i][0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: DashboardColors.onSurface,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (extra > 0)
          Text(
            '+$extra',
            style: const TextStyle(
              color: DashboardColors.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }
}
