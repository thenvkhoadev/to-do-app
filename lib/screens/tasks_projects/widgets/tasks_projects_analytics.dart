import 'dart:math';

import 'package:flutter/material.dart';
import 'package:to_do_app/screens/tasks_projects/tasks_projects_models.dart';
import 'package:to_do_app/screens/tasks_projects/widgets/tasks_projects_glass.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class TasksProjectsAnalyticsStrip extends StatelessWidget {
  const TasksProjectsAnalyticsStrip({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return const Column(
        children: [
          TasksProjectsCircularAnalytics(compact: true),
          SizedBox(height: 14),
          TasksProjectsHeatmap(compact: true),
        ],
      );
    }

    return Row(
      children: const [
        Expanded(child: TasksProjectsCircularAnalytics()),
        SizedBox(width: 14),
        Expanded(flex: 2, child: TasksProjectsHeatmap()),
      ],
    );
  }
}

class TasksProjectsCircularAnalytics extends StatelessWidget {
  const TasksProjectsCircularAnalytics({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _Metric('Focus', .86, DashboardColors.primary),
      _Metric('Done', .74, DashboardColors.secondary),
      _Metric('AI', .92, DashboardColors.tertiary),
    ];

    return TasksProjectsGlass(
      padding: EdgeInsets.all(compact ? 16 : 18),
      glowColor: DashboardColors.secondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelTitle(
            icon: Icons.donut_large_rounded,
            title: 'Progress Analytics',
          ),
          SizedBox(height: compact ? 14 : 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final ringSize = min(
                compact ? 78.0 : 92.0,
                constraints.maxWidth / metrics.length,
              );

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children:
                    metrics
                        .map(
                          (metric) =>
                              _ProgressRing(metric: metric, size: ringSize),
                        )
                        .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class TasksProjectsHeatmap extends StatelessWidget {
  const TasksProjectsHeatmap({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return TasksProjectsGlass(
      padding: EdgeInsets.all(compact ? 16 : 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelTitle(
            icon: Icons.grid_view_rounded,
            title: 'Productivity Heatmap',
          ),
          SizedBox(height: compact ? 14 : 18),
          Semantics(
            label:
                'Productivity heatmap. Strongest output appears mid-week and Friday.',
            child: Wrap(
              spacing: 7,
              runSpacing: 7,
              children:
                  tasksProjectHeatmapValues.map((value) {
                    final color =
                        Color.lerp(
                          DashboardColors.surfaceHighest,
                          DashboardColors.primary,
                          value,
                        )!;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: compact ? 13 : 15,
                      height: compact ? 13 : 15,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: .35 + value * .55),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow:
                            value > .75
                                ? [
                                  BoxShadow(
                                    color: DashboardColors.primary.withValues(
                                      alpha: .22,
                                    ),
                                    blurRadius: 8,
                                  ),
                                ]
                                : null,
                      ),
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class TasksProjectsActivityTimeline extends StatelessWidget {
  const TasksProjectsActivityTimeline({super.key});

  @override
  Widget build(BuildContext context) {
    return TasksProjectsGlass(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelTitle(
            icon: Icons.timeline_rounded,
            title: 'AI Activity Feed',
          ),
          const SizedBox(height: 18),
          ...tasksProjectActivities.map(
            (activity) => _TimelineRow(activity: activity),
          ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.activity});

  final TasksProjectActivity activity;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: activity.accent.withValues(alpha: .16),
              border: Border.all(color: activity.accent.withValues(alpha: .35)),
            ),
            child: Icon(activity.icon, color: activity.accent, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: const TextStyle(
                    color: DashboardColors.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activity.detail,
                  style: const TextStyle(
                    color: DashboardColors.onSurfaceVariant,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activity.time,
                  style: TextStyle(
                    color: activity.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelTitle extends StatelessWidget {
  const _PanelTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: DashboardColors.primary, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: DashboardColors.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _Metric {
  const _Metric(this.label, this.value, this.color);

  final String label;
  final double value;
  final Color color;
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.metric, required this.size});

  final _Metric metric;
  final double size;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: metric.value),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder:
          (context, value, _) => Column(
            children: [
              SizedBox(
                width: size,
                height: size,
                child: CustomPaint(
                  painter: _RingPainter(value: value, color: metric.color),
                  child: Center(
                    child: Text(
                      '${(value * 100).round()}%',
                      style: TextStyle(
                        color: metric.color,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                metric.label,
                style: const TextStyle(
                  color: DashboardColors.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 5;
    final base =
        Paint()
          ..color = Colors.white.withValues(alpha: .08)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round;
    final active =
        Paint()
          ..shader = SweepGradient(
            colors: [color.withValues(alpha: .15), color],
          ).createShader(Rect.fromCircle(center: center, radius: radius))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, base);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      value * 2 * pi,
      false,
      active,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.color != color;
}
