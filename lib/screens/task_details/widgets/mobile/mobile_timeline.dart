import 'package:flutter/material.dart';
import 'package:to_do_app/features/tasks/domain/entities/task_board_item.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class MobileTimeline extends StatelessWidget {
  const MobileTimeline({required this.item, super.key});
  final TaskBoardItem item;

  @override
  Widget build(BuildContext context) {
    final createdAgo = item.createdAt != null ? _ago(item.createdAt!) : null;
    final updatedAgo = item.updatedAt != null ? _ago(item.updatedAt!) : null;

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
        if (createdAgo != null)
          _TimelineEvent(
            dotColor: DashboardColors.primary,
            title: 'Task Created',
            time: createdAgo,
          ),
        if (updatedAgo != null) ...[
          const SizedBox(height: 24),
          _TimelineEvent(
            dotColor: DashboardColors.primaryContainer,
            title: 'Last updated · ',
            highlight: item.status.name.toUpperCase(),
            highlightColor: DashboardColors.primary,
            time: updatedAgo,
          ),
        ],
      ],
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

class _TimelineEvent extends StatelessWidget {
  const _TimelineEvent({
    required this.dotColor,
    required this.title,
    required this.time,
    this.highlight,
    this.highlightColor,
  });
  final Color dotColor;
  final String title, time;
  final String? highlight;
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Transform.translate(
          offset: const Offset(-28, 4),
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dotColor,
              border: Border.all(
                color: DashboardColors.surface,
                width: 3,
              ),
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              highlight != null
                  ? RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          color: DashboardColors.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        children: [
                          TextSpan(text: title),
                          TextSpan(
                            text: highlight,
                            style: TextStyle(
                              color: highlightColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Text(
                      title,
                      style: const TextStyle(
                        color: DashboardColors.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
              const SizedBox(height: 2),
              Text(
                time,
                style: const TextStyle(
                  color: DashboardColors.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
