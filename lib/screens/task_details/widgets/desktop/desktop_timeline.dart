import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:to_do_app/features/tasks/domain/entities/task_board_item.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class DesktopTimeline extends StatelessWidget {
  const DesktopTimeline({required this.item, super.key});
  final TaskBoardItem item;

  @override
  Widget build(BuildContext context) {
    final createdAgo = item.createdAt != null ? _ago(item.createdAt!) : null;
    final updatedAgo = item.updatedAt != null ? _ago(item.updatedAt!) : null;

    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Activity Timeline',
            style: TextStyle(
              color: DashboardColors.onSurface,
              fontSize: 24,
              fontWeight: FontWeight.w600,
              letterSpacing: -.01,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 32),
          _TimelineItem(
            color: DashboardColors.primary,
            icon: Icons.add_rounded,
            title: item.creatorName ?? item.assignee,
            titleSuffix: ' created this task',
            subtitle: createdAgo ?? '—',
            hasBorder: updatedAgo != null,
          ),
          if (updatedAgo != null)
            _TimelineItem(
              color: DashboardColors.surfaceHighest,
              icon: Icons.edit_rounded,
              titleWidget: RichText(
                text: TextSpan(
                  style: const TextStyle(color: DashboardColors.onSurface, fontSize: 14),
                  children: [
                    const TextSpan(text: 'Task updated · '),
                    TextSpan(
                      text: item.status.name.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              subtitle: updatedAgo,
              hasBorder: false,
            ),
        ],
      ),
    );
  }

  static String _ago(DateTime dt) {
    final diff = DateTime.now().toUtc().difference(dt.toUtc());
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.color,
    required this.icon,
    required this.subtitle,
    required this.hasBorder,
    this.title,
    this.titleSuffix,
    this.titleWidget,
  });

  final Color color;
  final IconData icon;
  final String subtitle;
  final bool hasBorder;
  final String? title;
  final String? titleSuffix;
  final Widget? titleWidget;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    border: Border.all(
                      color: DashboardColors.background,
                      width: 3,
                    ),
                    boxShadow: color == DashboardColors.primary
                        ? [BoxShadow(color: DashboardColors.primary.withValues(alpha: .35), blurRadius: 10)]
                        : null,
                  ),
                  child: Icon(icon, size: 12, color: Colors.white),
                ),
                if (hasBorder)
                  Container(
                    width: 2,
                    height: 40,
                    color: Colors.white.withValues(alpha: .08),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titleWidget ??
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                            color: DashboardColors.onSurface, fontSize: 14),
                        children: [
                          TextSpan(
                            text: title ?? '',
                            style: const TextStyle(
                                color: DashboardColors.primary,
                                fontWeight: FontWeight.w700),
                          ),
                          TextSpan(text: titleSuffix ?? ''),
                        ],
                      ),
                    ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                      color: DashboardColors.onSurfaceVariant, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: .08)),
            ),
            child: child,
          ),
        ),
      );
}
