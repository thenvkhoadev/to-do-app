import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:to_do_app/features/tasks/domain/entities/task_board_item.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class MobileInfoGrid extends StatelessWidget {
  const MobileInfoGrid({required this.item, super.key});
  final TaskBoardItem item;

  static String _month(int m) => const [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ][m];

  static String _timeLeft(DateTime due) {
    final diff = due.difference(DateTime.now());
    if (diff.isNegative) return 'Overdue';
    if (diff.inDays > 0) return '${diff.inDays}d left';
    if (diff.inHours > 0) return '${diff.inHours}h left';
    return '${diff.inMinutes}m left';
  }

  static String _timeLeftShort(DateTime due) {
    final diff = due.difference(DateTime.now());
    if (diff.isNegative) return 'Overdue';
    if (diff.inDays > 0) return '${diff.inDays}d ${diff.inHours % 24}h';
    if (diff.inHours > 0) return '${diff.inHours}h';
    return '${diff.inMinutes}m';
  }

  static double _progress(DateTime due) {
    final total = due.difference(due.subtract(const Duration(days: 7)));
    final elapsed = DateTime.now().difference(due.subtract(const Duration(days: 7)));
    final p = elapsed.inSeconds / total.inSeconds;
    return p.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final dueStr = item.dueDate != null
        ? '${item.dueDate!.day.toString().padLeft(2, '0')} '
            '${_month(item.dueDate!.month)} '
            '${item.dueDate!.year}'
        : '—';
    final dueLabel = item.dueDate != null ? _timeLeft(item.dueDate!) : '—';
    final timeLeftStr = item.dueDate != null ? _timeLeftShort(item.dueDate!) : '—';
    final timeProgress = item.dueDate != null ? _progress(item.dueDate!) : 0.0;

    return Row(
      children: [
        Expanded(
          child: _InfoCard(
            icon: Icons.calendar_today_rounded,
            label: 'Due Date',
            value: dueStr,
            sub: dueLabel,
            subColor: DashboardColors.error,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _TimeLeftCard(
            label: 'Time Left',
            value: timeLeftStr,
            progress: timeProgress,
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
    required this.subColor,
  });
  final IconData icon;
  final String label, value, sub;
  final Color subColor;

  @override
  Widget build(BuildContext context) => _GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: DashboardColors.onSurfaceVariant, size: 16),
                const SizedBox(width: 6),
                Text(label,
                    style: const TextStyle(
                        color: DashboardColors.onSurfaceVariant, fontSize: 11)),
              ],
            ),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(
                    color: DashboardColors.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(sub,
                style: TextStyle(
                    color: subColor, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

class _TimeLeftCard extends StatelessWidget {
  const _TimeLeftCard({
    required this.label,
    required this.value,
    required this.progress,
  });
  final String label, value;
  final double progress;

  @override
  Widget build(BuildContext context) => _GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.schedule_rounded,
                    color: DashboardColors.onSurfaceVariant, size: 16),
                SizedBox(width: 6),
                Text('Time Left',
                    style: TextStyle(
                        color: DashboardColors.onSurfaceVariant, fontSize: 11)),
              ],
            ),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(
                    color: DashboardColors.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: Colors.white.withValues(alpha: .10),
                valueColor: const AlwaysStoppedAnimation(DashboardColors.primary),
              ),
            ),
          ],
        ),
      );
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .03),
              borderRadius: BorderRadius.circular(24),
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: .12)),
                left: BorderSide(color: Colors.white.withValues(alpha: .05)),
                right: BorderSide(color: Colors.white.withValues(alpha: .05)),
                bottom: BorderSide(color: Colors.white.withValues(alpha: .05)),
              ),
            ),
            child: child,
          ),
        ),
      );
}
