import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:to_do_app/features/tasks/domain/entities/task_board_item.dart';
import 'package:to_do_app/features/tasks/presentation/providers/task_timeline_provider.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class DesktopTimeline extends ConsumerWidget {
  const DesktopTimeline({required this.item, super.key});
  final TaskBoardItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider).valueOrNull;
    final actorName = userProfile?.fullName ?? userProfile?.username ?? userProfile?.email ?? 'You';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(taskTimelineProvider(item.id).notifier).seedInitialEvents(item, actorName);
    });

    final timeline = ref.watch(taskTimelineProvider(item.id));
    final sortedTimeline = List<TaskActivity>.from(timeline)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

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
          if (sortedTimeline.isEmpty)
            const Text(
              'No activities recorded.',
              style: TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: 13),
            )
          else
            ...List.generate(sortedTimeline.length, (idx) {
              final act = sortedTimeline[idx];
              final agoStr = _ago(act.timestamp);
              final isLast = idx == sortedTimeline.length - 1;

              final (IconData, Color) iconInfo = switch (act.action) {
                'create' => (Icons.add_rounded, DashboardColors.primary),
                'plan' => (Icons.assignment_turned_in_rounded, DashboardColors.secondary),
                'start' || 'resume' => (Icons.play_arrow_rounded, DashboardColors.primary),
                'pause' => (Icons.pause_rounded, DashboardColors.outline),
                'complete' => (Icons.check_circle_outline_rounded, DashboardColors.success),
                'create_subtask' => (Icons.playlist_add_rounded, DashboardColors.tertiary),
                'delete_subtask' => (Icons.playlist_remove_rounded, DashboardColors.error),
                'complete_subtask' => (Icons.check_box_outlined, DashboardColors.success),
                'incomplete_subtask' => (Icons.check_box_outline_blank_rounded, DashboardColors.outline),
                _ => (Icons.info_outline_rounded, DashboardColors.primary),
              };

              final titleWidget = RichText(
                text: TextSpan(
                  style: const TextStyle(color: DashboardColors.onSurface, fontSize: 14),
                  children: [
                    TextSpan(
                      text: act.actorName,
                      style: const TextStyle(color: DashboardColors.primary, fontWeight: FontWeight.w700),
                    ),
                    TextSpan(text: ' ${act.detail}'),
                  ],
                ),
              );

              return _TimelineItem(
                color: iconInfo.$2,
                icon: iconInfo.$1,
                titleWidget: titleWidget,
                subtitle: agoStr,
                hasBorder: !isLast,
              );
            }),
        ],
      ),
    );
  }

  static String _ago(DateTime dt) {
    final diff = DateTime.now().toUtc().difference(dt.toUtc());
    if (diff.isNegative) return 'Just now';
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
    required this.titleWidget,
  });

  final Color color;
  final IconData icon;
  final String subtitle;
  final bool hasBorder;
  final Widget titleWidget;

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
                titleWidget,
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
