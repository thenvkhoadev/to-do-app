import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/features/tasks/presentation/providers/tasks_provider.dart';
import 'package:to_do_app/screens/tasks_projects/tasks_projects_models.dart';
import 'package:to_do_app/screens/tasks_projects/widgets/tasks_projects_glass.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class TasksProjectsSmartInsightBanner extends StatelessWidget {
  const TasksProjectsSmartInsightBanner({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return TasksProjectsGlass(
      padding: EdgeInsets.all(compact ? 16 : 20),
      glowColor: DashboardColors.primary,
      child: Stack(
        children: [
          const Positioned.fill(child: _InsightShimmer()),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: compact ? 42 : 52,
                height: compact ? 42 : 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      tasksProjectInsight.accent.withValues(alpha: .28),
                      DashboardColors.secondary.withValues(alpha: .16),
                    ],
                  ),
                ),
                child: Icon(
                  tasksProjectInsight.icon,
                  color: tasksProjectInsight.accent,
                  size: compact ? 22 : 26,
                ),
              ),
              SizedBox(width: compact ? 12 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tasksProjectInsight.label,
                      style: const TextStyle(
                        color: DashboardColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tasksProjectInsight.title,
                      style: TextStyle(
                        color: DashboardColors.onSurface,
                        fontSize: compact ? 18 : 22,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tasksProjectInsight.message,
                      maxLines: compact ? 3 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: DashboardColors.onSurfaceVariant,
                        fontSize: compact ? 13 : 14,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              if (!compact) ...[
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: DashboardColors.primary.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: DashboardColors.primary.withValues(alpha: .22),
                    ),
                  ),
                  child: Text(
                    tasksProjectInsight.confidence,
                    style: const TextStyle(
                      color: DashboardColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class TasksProjectsMiniStatsRow extends ConsumerWidget {
  const TasksProjectsMiniStatsRow({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(userTasksProvider).valueOrNull ?? const [];
    final completed = tasks.where((task) => task.status == 'done').length;
    final aiTasks = tasks.where((task) => task.aiGenerated).length;
    final active = tasks.where((task) => task.status != 'done').length;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final overdue = tasks.where((task) {
      final due = task.dueDate;
      return due != null && due.isBefore(today) && task.status != 'done';
    }).length;
    final stats = [
      TasksProjectStat(
        label: 'Tasks Completed',
        value: '$completed',
        delta: '${tasks.length} total',
        icon: Icons.task_alt_rounded,
        accent: DashboardColors.primary,
      ),
      TasksProjectStat(
        label: 'Active Tasks',
        value: '$active',
        delta: overdue > 0 ? '$overdue overdue' : 'on track',
        icon: Icons.bolt_rounded,
        accent: DashboardColors.secondary,
      ),
      TasksProjectStat(
        label: 'AI Assisted Tasks',
        value: '$aiTasks',
        delta: tasks.isEmpty ? '0%' : '${((aiTasks / tasks.length) * 100).round()}%',
        icon: Icons.psychology_rounded,
        accent: DashboardColors.tertiary,
      ),
      TasksProjectStat(
        label: 'High Priority',
        value: '${tasks.where((task) => task.priority == 'high' || task.priority == 'urgent').length}',
        delta: 'live',
        icon: Icons.account_tree_rounded,
        accent: DashboardColors.tertiaryContainer,
      ),
    ];
    if (compact) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children:
              stats
                  .map(
                    (stat) => Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: SizedBox(
                        width: 164,
                        child: TasksProjectsMiniStatCard(
                          stat: stat,
                          compact: true,
                        ),
                      ),
                    ),
                  )
                  .toList(),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final tight = constraints.maxWidth < 820;
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children:
              stats
                  .map(
                    (stat) => SizedBox(
                      width:
                          tight
                              ? (constraints.maxWidth - 14) / 2
                              : (constraints.maxWidth - 42) / 4,
                      child: TasksProjectsMiniStatCard(stat: stat),
                    ),
                  )
                  .toList(),
        );
      },
    );
  }
}

class TasksProjectsMiniStatCard extends StatelessWidget {
  const TasksProjectsMiniStatCard({
    required this.stat,
    this.compact = false,
    super.key,
  });

  final TasksProjectStat stat;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return TasksProjectsGlass(
      padding: EdgeInsets.all(compact ? 14 : 16),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: stat.accent.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(stat.icon, color: stat.accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat.value,
                  style: const TextStyle(
                    color: DashboardColors.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  stat.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: DashboardColors.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Text(
            stat.delta,
            style: TextStyle(
              color: stat.accent,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightShimmer extends StatelessWidget {
  const _InsightShimmer();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: -1, end: 1),
      duration: const Duration(seconds: 3),
      curve: Curves.easeInOut,
      builder:
          (context, value, _) => Transform.translate(
            offset: Offset(value * 420, 0),
            child: Container(
              width: 90,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.white.withValues(alpha: .035),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
    );
  }
}
