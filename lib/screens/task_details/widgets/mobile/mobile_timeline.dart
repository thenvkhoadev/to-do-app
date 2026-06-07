import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:to_do_app/features/tasks/domain/entities/task_board_item.dart';
import 'package:to_do_app/features/tasks/presentation/providers/task_timeline_provider.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class MobileTimeline extends ConsumerWidget {
  const MobileTimeline({required this.item, super.key});
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Timeline',
          style: TextStyle(
            color: DashboardColors.onSurfaceVariant,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        if (sortedTimeline.isEmpty)
          const Text(
            'No activities recorded.',
            style: TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: 12),
          )
        else
          ...List.generate(sortedTimeline.length, (idx) {
            final act = sortedTimeline[idx];
            final agoStr = _ago(act.timestamp);
            final isLast = idx == sortedTimeline.length - 1;

            final Color dotColor = switch (act.action) {
              'create' => DashboardColors.primary,
              'plan' => DashboardColors.secondary,
              'start' || 'resume' => DashboardColors.primary,
              'pause' => DashboardColors.outline,
              'complete' => DashboardColors.success,
              'create_subtask' => DashboardColors.tertiary,
              'delete_subtask' => DashboardColors.error,
              'complete_subtask' => DashboardColors.success,
              'incomplete_subtask' => DashboardColors.outline,
              _ => DashboardColors.primary,
            };

            final titleWidget = RichText(
              text: TextSpan(
                style: const TextStyle(color: DashboardColors.onSurface, fontSize: 14, fontWeight: FontWeight.w500),
                children: [
                  TextSpan(
                    text: act.actorName,
                    style: const TextStyle(color: DashboardColors.primary, fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: ' ${act.detail}'),
                ],
              ),
            );

            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsets.only(top: 4, right: 16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: dotColor,
                      border: Border.all(
                        color: DashboardColors.surface,
                        width: 3,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        titleWidget,
                        const SizedBox(height: 2),
                        Text(
                          agoStr,
                          style: const TextStyle(
                            color: DashboardColors.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
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


