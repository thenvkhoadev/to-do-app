import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/constants/dashboard_constants.dart';
import 'package:to_do_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:to_do_app/features/xp/domain/xp_leveling.dart' as leveling;
import 'package:to_do_app/theme/dashboard_theme.dart';
import 'package:to_do_app/widgets/dashboard/dashboard_shared.dart';
import 'package:to_do_app/widgets/dashboard/dashboard_stats_provider.dart';

class DashboardCard extends StatelessWidget {
  const DashboardCard({
    required this.title,
    required this.child,
    this.icon,
    this.color = DashboardColors.primary,
    this.actions,
    this.padding = const EdgeInsets.all(DashboardSpacing.lg),
    super.key,
  });

  final String title;
  final Widget child;
  final IconData? icon;
  final Color color;
  final List<Widget>? actions;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return AnimatedHoverCard(
      glowColor: color,
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SectionTitle(label: title, icon: icon, color: color),
              const Spacer(),
              if (actions != null) ...actions!,
            ],
          ),
          const SizedBox(height: DashboardSpacing.md),
          child,
        ],
      ),
    );
  }
}

class MetricTile extends StatelessWidget {
  const MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    this.color = DashboardColors.primary,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(DashboardRadii.lg),
        border: Border.all(color: color.withValues(alpha: .18)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: .12), blurRadius: 22),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                color: DashboardColors.onSurface,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: DashboardColors.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class ProgressWidget extends StatelessWidget {
  const ProgressWidget({
    required this.label,
    required this.value,
    this.color = DashboardColors.primary,
    super.key,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: DashboardColors.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${(value * 100).round()}%',
                style: TextStyle(color: color, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value),
            duration: const Duration(milliseconds: 850),
            curve: Curves.easeOutCubic,
            builder: (context, animated, _) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(DashboardRadii.full),
                child: Stack(
                  children: [
                    Container(
                      height: 10,
                      color: Colors.white.withValues(alpha: .07),
                    ),
                    FractionallySizedBox(
                      widthFactor: animated,
                      child: AnimatedContainer(
                        duration: DashboardDurations.normal,
                        height: 10,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [color, DashboardColors.secondary],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: .35),
                              blurRadius: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class AchievementBadge extends StatelessWidget {
  const AchievementBadge({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: DashboardColors.primary.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(DashboardRadii.lg),
        border: Border.all(
          color: DashboardColors.primary.withValues(alpha: .20),
        ),
        boxShadow: [
          BoxShadow(
            color: DashboardColors.primary.withValues(alpha: .12),
            blurRadius: 24,
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: DashboardColors.onSurface,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class ProjectHealthCard extends StatelessWidget {
  const ProjectHealthCard({
    required this.name,
    required this.progress,
    required this.status,
    required this.color,
    super.key,
  });

  final String name;
  final double progress;
  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .04),
        borderRadius: BorderRadius.circular(DashboardRadii.lg),
        border: Border.all(color: Colors.white.withValues(alpha: .08)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: color.withValues(alpha: .18),
            child: Text(
              name.characters.first,
              style: TextStyle(color: color, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          color: DashboardColors.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _StatusBadge(label: status, color: color),
                  ],
                ),
                const SizedBox(height: 10),
                _MiniProgress(value: progress, color: color),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class QuickActionCard extends StatefulWidget {
  const QuickActionCard({
    required this.icon,
    required this.label,
    this.color = DashboardColors.primary,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  State<QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<QuickActionCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(DashboardRadii.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(DashboardRadii.md),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: DashboardDurations.normal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: _hovered ? .14 : .07),
              borderRadius: BorderRadius.circular(DashboardRadii.md),
              border: Border.all(color: widget.color.withValues(alpha: .16)),
              boxShadow:
                  _hovered
                      ? [
                        BoxShadow(
                          color: widget.color.withValues(alpha: .18),
                          blurRadius: 20,
                        ),
                      ]
                      : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, color: widget.color, size: 22),
                const SizedBox(height: 7),
                Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: DashboardColors.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AIAssistantWidget extends StatelessWidget {
  const AIAssistantWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      child: GlassCard(
        radius: DashboardRadii.lg,
        padding: const EdgeInsets.all(18),
        glowColor: DashboardColors.secondary,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SectionTitle(
              label: 'Nexus Copilot',
              icon: Icons.auto_awesome_rounded,
              color: DashboardColors.secondary,
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                _AssistantChip('Quick Ask AI'),
                _AssistantChip('Generate Task'),
                _AssistantChip('Summarize Notes'),
                _AssistantChip('Create Schedule'),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 4, 6, 4),
              decoration: BoxDecoration(
                color: DashboardColors.surfaceLow,
                borderRadius: BorderRadius.circular(DashboardRadii.full),
                border: Border.all(color: Colors.white.withValues(alpha: .08)),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: TextField(
                      style: TextStyle(color: DashboardColors.onSurface),
                      cursorColor: DashboardColors.primary,
                      decoration: InputDecoration(
                        hintText: 'Ask Nexus AI...',
                        hintStyle: TextStyle(
                          color: DashboardColors.onSurfaceVariant,
                          fontSize: 13,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          DashboardColors.primaryContainer,
                          DashboardColors.secondaryContainer,
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssistantChip extends StatelessWidget {
  const _AssistantChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(DashboardRadii.full),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: DashboardColors.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class AIInsightsPanel extends ConsumerWidget {
  const AIInsightsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);
    return DashboardCard(
      title: 'AI Insights',
      icon: Icons.insights_rounded,
      color: DashboardColors.secondary,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: MetricTile(
                  icon: Icons.trending_up_rounded,
                  label: 'Completed Tasks',
                  value: '${stats.completedTasks}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MetricTile(
                  icon: Icons.track_changes_rounded,
                  label: 'Focus Score',
                  value: '${stats.focusScore}%',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: MetricTile(
                  icon: Icons.work_history_rounded,
                  label: 'Focus Hours',
                  value: '${stats.focusHours}h',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MetricTile(
                  icon: Icons.local_fire_department_rounded,
                  label: 'Current Streak',
                  value: '${stats.streakDays}d',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const GradientButton(
            label: 'View Report',
            icon: Icons.article_rounded,
            expanded: true,
          ),
          const SizedBox(height: 12),
          const GradientButton(
            label: 'Generate Analysis',
            icon: Icons.auto_graph_rounded,
            expanded: true,
          ),
        ],
      ),
    );
  }
}

class CurrentFocusSessionCard extends ConsumerWidget {
  const CurrentFocusSessionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);
    final task = stats.nextBestTask;
    return DashboardCard(
      title: 'Current Focus Session',
      icon: Icons.timer_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recommended Focus',
            style: TextStyle(color: DashboardColors.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          ShaderMask(
            shaderCallback:
                (rect) => const LinearGradient(
                  colors: [DashboardColors.primary, DashboardColors.secondary],
                ).createShader(rect),
            child: Text(
              task?.estimatedMinutes == null
                  ? '-- min'
                  : '${task!.estimatedMinutes} min',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 46,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Task:',
            style: TextStyle(color: DashboardColors.onSurfaceVariant),
          ),
          Text(
            task?.title ?? 'No active task available',
            style: const TextStyle(
              color: DashboardColors.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          _StatusBadge(
            label: task?.status.toUpperCase() ?? 'NO TASK',
            color: DashboardColors.primary,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: MetricTile(
                  icon: Icons.priority_high_rounded,
                  label: 'High Priority',
                  value: '${stats.highPriorityTasks}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MetricTile(
                  icon: Icons.speed_rounded,
                  label: 'Focus Score',
                  value: '${stats.focusScore}%',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const GradientButton(
            label: 'Pause Session',
            icon: Icons.pause_rounded,
            expanded: true,
          ),
          const SizedBox(height: 12),
          const GradientButton(
            label: 'End Session',
            icon: Icons.stop_rounded,
            expanded: true,
          ),
        ],
      ),
    );
  }
}

class QuarterGoalsCard extends ConsumerWidget {
  const QuarterGoalsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);
    final total = stats.totalTasks == 0 ? 1 : stats.totalTasks;
    return DashboardCard(
      title: 'Task Goals',
      icon: Icons.flag_rounded,
      child: Column(
        children: [
          ProgressWidget(
            label: 'Task Completion',
            value: stats.completedTasks / total,
          ),
          ProgressWidget(
            label: 'Due Today',
            value: stats.dueTodayTasks / total,
            color: DashboardColors.secondary,
          ),
          ProgressWidget(
            label: 'High Priority',
            value: stats.highPriorityTasks / total,
            color: DashboardColors.tertiary,
          ),
          ProgressWidget(
            label: 'Overdue',
            value: stats.overdueTasks / total,
            color: DashboardColors.error,
          ),
        ],
      ),
    );
  }
}

class ActivityHeatmapCard extends StatelessWidget {
  const ActivityHeatmapCard({super.key});

  static const _values = [
    1,
    3,
    2,
    4,
    3,
    1,
    2,
    4,
    2,
    1,
    3,
    4,
    1,
    2,
    3,
    2,
    4,
    4,
    1,
    3,
    2,
    1,
    4,
    3,
    2,
    4,
    1,
    3,
  ];

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      title: 'Activity Heatmap',
      icon: Icons.grid_view_rounded,
      color: DashboardColors.tertiary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Column(
                children: [
                  _HeatmapDay('Mon'),
                  _HeatmapDay('Tue'),
                  _HeatmapDay('Wed'),
                  _HeatmapDay('Thu'),
                  _HeatmapDay('Fri'),
                  _HeatmapDay('Sat'),
                  _HeatmapDay('Sun'),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final value in _values) _HeatmapCell(value: value),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                'Low',
                style: TextStyle(
                  color: DashboardColors.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              for (var i = 1; i <= 4; i++) ...[
                _HeatmapCell(value: i, small: true),
                const SizedBox(width: 5),
              ],
              const Text(
                'High Activity',
                style: TextStyle(
                  color: DashboardColors.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(DashboardRadii.full),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _HeatmapDay extends StatelessWidget {
  const _HeatmapDay(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 22,
      child: Text(
        label,
        style: const TextStyle(
          color: DashboardColors.onSurfaceVariant,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _HeatmapCell extends StatelessWidget {
  const _HeatmapCell({required this.value, this.small = false});

  final int value;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value / 4),
      duration: Duration(milliseconds: 350 + value * 80),
      builder: (context, animated, _) {
        return Container(
          width: small ? 12 : 18,
          height: small ? 12 : 18,
          decoration: BoxDecoration(
            color: DashboardColors.primary.withValues(
              alpha: .10 + animated * .75,
            ),
            borderRadius: BorderRadius.circular(5),
            boxShadow:
                value > 2
                    ? [
                      BoxShadow(
                        color: DashboardColors.primary.withValues(alpha: .22),
                        blurRadius: 12,
                      ),
                    ]
                    : null,
          ),
        );
      },
    );
  }
}

class ProjectHealthOverviewCard extends ConsumerWidget {
  const ProjectHealthOverviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);
    return DashboardCard(
      title: 'Project Health',
      icon: Icons.health_and_safety_rounded,
      child: Column(
        children: [
          ProjectHealthCard(
            name: 'Task Completion',
            progress: stats.completionPercent / 100,
            status: '${stats.completionPercent}%',
            color: DashboardColors.primary,
          ),
          ProjectHealthCard(
            name: 'Overdue Tasks',
            progress:
                stats.totalTasks == 0
                    ? 0
                    : stats.overdueTasks / stats.totalTasks,
            status: '${stats.overdueTasks}',
            color:
                stats.overdueTasks > 0
                    ? DashboardColors.error
                    : DashboardColors.tertiary,
          ),
          ProjectHealthCard(
            name: 'High Priority',
            progress:
                stats.totalTasks == 0
                    ? 0
                    : stats.highPriorityTasks / stats.totalTasks,
            status: '${stats.highPriorityTasks}',
            color: DashboardColors.secondary,
          ),
        ],
      ),
    );
  }
}

class AchievementsCard extends ConsumerWidget {
  const AchievementsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);
    final badges = <String>[
      if (stats.streakDays >= 7) '${stats.streakDays}-Day Focus Streak',
      if (stats.completedTasks >= 10) '${stats.completedTasks} Tasks Completed',
      if (stats.focusHours > 0) '${stats.focusHours} Focus Hours',
      if (stats.level > 1) 'Level ${stats.level}',
    ];
    return DashboardCard(
      title: 'Achievements',
      icon: Icons.emoji_events_rounded,
      color: DashboardColors.secondary,
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children:
            badges.isEmpty
                ? const [AchievementBadge(label: 'No achievements yet')]
                : badges
                    .map((label) => AchievementBadge(label: label))
                    .toList(),
      ),
    );
  }
}

class DailyChallengeCard extends ConsumerWidget {
  const DailyChallengeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);
    final challenge =
        stats.overdueTasks > 0
            ? 'Clear ${stats.overdueTasks} overdue task${stats.overdueTasks == 1 ? '' : 's'}'
            : stats.dueTodayTasks > 0
            ? 'Complete ${stats.dueTodayTasks} task${stats.dueTodayTasks == 1 ? '' : 's'} due today'
            : 'Create or complete one task today';
    return DashboardCard(
      title: "Today's Challenge",
      icon: Icons.military_tech_rounded,
      color: DashboardColors.tertiary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            challenge,
            style: const TextStyle(
              color: DashboardColors.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Current XP: ${stats.currentXp}',
            style: const TextStyle(
              color: DashboardColors.primary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 18),
          GradientButton(
            label: 'Start Challenge',
            icon: Icons.play_arrow_rounded,
            expanded: true,
          ),
        ],
      ),
    );
  }
}

class KnowledgeHubCard extends StatelessWidget {
  const KnowledgeHubCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const DashboardCard(
      title: 'Knowledge Hub',
      icon: Icons.menu_book_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _KnowledgeRow('Flutter Architecture'),
          _KnowledgeRow('System Design'),
          _KnowledgeRow('AI Agents Research'),
          SizedBox(height: 18),
          GradientButton(
            label: 'Open Notes',
            icon: Icons.folder_open_rounded,
            expanded: true,
          ),
          SizedBox(height: 12),
          GradientButton(
            label: 'Add Knowledge',
            icon: Icons.add_rounded,
            expanded: true,
          ),
        ],
      ),
    );
  }
}

class _KnowledgeRow extends StatelessWidget {
  const _KnowledgeRow(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(
            Icons.article_rounded,
            color: DashboardColors.primary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              color: DashboardColors.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class XPLevelCard extends ConsumerWidget {
  const XPLevelCard({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final totalXp = profile?.totalXp ?? 0;
    final levelState = leveling.xpProgressFromTotalXp(totalXp);
    final level = levelState.level;
    final progress = levelState.progress;
    final xpInto = levelState.xpIntoLevel;
    final xpForNext = levelState.xpForNextLevel;
    final title = leveling.xpRankForLevel(level).title;

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: DashboardColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: DashboardColors.primary.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.emoji_events_rounded,
              color: DashboardColors.primary,
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              'Lvl $level',
              style: const TextStyle(
                color: DashboardColors.onSurface,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return GlassCard(
      radius: DashboardRadii.full,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      glowColor: DashboardColors.primary,
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Icon(
            Icons.emoji_events_rounded,
            color: DashboardColors.primary,
            size: 20,
          ),
          Text(
            'Level $level',
            style: const TextStyle(
              color: DashboardColors.onSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(width: 120, child: _MiniProgress(value: progress)),
          Text(
            '$xpInto / $xpForNext XP',
            style: const TextStyle(
              color: DashboardColors.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: DashboardColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniProgress extends StatelessWidget {
  const _MiniProgress({required this.value, this.color});

  final double value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final start = color ?? DashboardColors.primaryContainer;
    return ClipRRect(
      borderRadius: BorderRadius.circular(DashboardRadii.full),
      child: Stack(
        children: [
          Container(height: 8, color: Colors.white.withValues(alpha: .07)),
          FractionallySizedBox(
            widthFactor: value,
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [start, DashboardColors.secondaryContainer],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FocusAudioCard extends StatelessWidget {
  const FocusAudioCard({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      title: 'Focus Audio',
      icon: Icons.music_note_rounded,
      color: DashboardColors.secondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Playlist:',
            style: TextStyle(color: DashboardColors.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          const Text(
            'Deep Work Mix',
            style: TextStyle(
              color: DashboardColors.onSurface,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              _AudioButton(Icons.skip_previous_rounded),
              SizedBox(width: 12),
              _AudioButton(Icons.pause_rounded, large: true),
              SizedBox(width: 12),
              _AudioButton(Icons.skip_next_rounded),
            ],
          ),
          const SizedBox(height: 18),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: DashboardColors.primary,
              inactiveTrackColor: Colors.white.withValues(alpha: .08),
              thumbColor: DashboardColors.primary,
            ),
            child: const Slider(value: .72, onChanged: null),
          ),
          const Text(
            '02:18 / 06:42',
            style: TextStyle(
              color: DashboardColors.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _AudioButton extends StatelessWidget {
  const _AudioButton(this.icon, {this.large = false});

  final IconData icon;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: large ? 56 : 44,
      height: large ? 56 : 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient:
            large
                ? const LinearGradient(
                  colors: [
                    DashboardColors.primaryContainer,
                    DashboardColors.secondaryContainer,
                  ],
                )
                : null,
        color: large ? null : Colors.white.withValues(alpha: .06),
      ),
      child: Icon(
        icon,
        color: large ? Colors.white : DashboardColors.onSurface,
      ),
    );
  }
}

class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({
    this.onNewTask,
    this.onAskAI,
    this.onSchedule,
    this.onAnalytics,
    super.key,
  });

  final VoidCallback? onNewTask;
  final VoidCallback? onAskAI;
  final VoidCallback? onSchedule;
  final VoidCallback? onAnalytics;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 700;
    final columns = isCompact ? 2 : 4;
    return DashboardCard(
      title: 'Quick Actions',
      icon: Icons.bolt_rounded,
      padding: const EdgeInsets.all(20),
      child: GridView.count(
        crossAxisCount: columns,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: isCompact ? 2.25 : 2.7,
        children: [
          QuickActionCard(
            icon: Icons.add_rounded,
            label: 'New Task',
            onTap: onNewTask,
          ),
          QuickActionCard(
            icon: Icons.psychology_rounded,
            label: 'Ask AI',
            color: DashboardColors.secondary,
            onTap: onAskAI,
          ),
          QuickActionCard(
            icon: Icons.calendar_month_rounded,
            label: 'Schedule',
            color: DashboardColors.tertiary,
            onTap: onSchedule,
          ),
          QuickActionCard(
            icon: Icons.query_stats_rounded,
            label: 'Analytics',
            onTap: onAnalytics,
          ),
        ],
      ),
    );
  }
}

class WeeklySummaryCard extends ConsumerWidget {
  const WeeklySummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);
    final weekTotal = stats.weeklyCompletedCounts.fold<int>(0, (a, b) => a + b);
    return DashboardCard(
      title: 'This Week Summary',
      icon: Icons.summarize_rounded,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: MetricTile(
                  icon: Icons.task_alt_rounded,
                  label: 'Tasks Completed',
                  value: '$weekTotal',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MetricTile(
                  icon: Icons.timer_rounded,
                  label: 'Due Today',
                  value: '${stats.dueTodayTasks}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: MetricTile(
                  icon: Icons.work_history_rounded,
                  label: 'Focus Hours',
                  value: '${stats.focusHours}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MetricTile(
                  icon: Icons.trending_up_rounded,
                  label: 'Completion',
                  value: '${stats.completionPercent}%',
                ),
              ),
            ],
          ),
          SizedBox(height: 18),
          GradientButton(
            label: 'View Full Report',
            icon: Icons.arrow_forward_rounded,
            expanded: true,
          ),
        ],
      ),
    );
  }
}

class TeamActivityCard extends ConsumerWidget {
  const TeamActivityCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);
    final recent = stats.recentTasks;
    return DashboardCard(
      title: 'Team Activity',
      icon: Icons.groups_rounded,
      color: DashboardColors.tertiary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Active tasks: ${stats.activeTasks}',
            style: const TextStyle(
              color: DashboardColors.primary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          if (recent.isEmpty)
            const _TeamRow('No recent task updates')
          else
            for (final task in recent)
              _TeamRow(
                '${task.status == 'done' ? 'Completed' : 'Updated'} ${task.title}',
              ),
          SizedBox(height: 18),
          GradientButton(
            label: 'Open Workspace',
            icon: Icons.open_in_new_rounded,
            expanded: true,
          ),
        ],
      ),
    );
  }
}

class _TeamRow extends StatelessWidget {
  const _TeamRow(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: DashboardColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: DashboardColors.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
