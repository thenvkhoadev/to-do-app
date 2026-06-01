import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:to_do_app/constants/dashboard_constants.dart';
import 'package:to_do_app/screens/analytics/models/analytics_models.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';
import 'package:to_do_app/widgets/dashboard/dashboard_shared.dart' as dashboard;

class AnalyticsHeader extends StatelessWidget {
  const AnalyticsHeader({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                compact ? 'Analytics' : 'Analytics & Performance',
                style: TextStyle(
                  color: DashboardColors.onSurface,
                  fontSize: compact ? 24 : 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                compact
                    ? 'Live focus intelligence for today.'
                    : 'Your productivity cycle is peaking. AI found a stronger deep-work window this week.',
                style: TextStyle(
                  color: DashboardColors.onSurfaceVariant,
                  fontSize: compact ? 13 : 15,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        const _LiveInsightPill(),
      ],
    );
  }
}

class _LiveInsightPill extends StatelessWidget {
  const _LiveInsightPill();

  @override
  Widget build(BuildContext context) {
    return dashboard.GlassCard(
      radius: DashboardRadii.full,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      glowColor: DashboardColors.primary,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: .45, end: 1),
            duration: const Duration(seconds: 2),
            builder:
                (context, value, child) =>
                    Opacity(opacity: value, child: child),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: DashboardColors.primary,
                boxShadow: [
                  BoxShadow(
                    color: DashboardColors.primary.withValues(alpha: .7),
                    blurRadius: 12,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'LIVE AI INSIGHT',
            style: TextStyle(
              color: DashboardColors.primary,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({required this.metric, super.key});

  final AnalyticsMetric metric;

  @override
  Widget build(BuildContext context) {
    return dashboard.AnimatedHoverCard(
      glowColor: metric.color,
      child: Stack(
        children: [
          Positioned(
            right: -28,
            top: -34,
            child: Icon(
              metric.icon,
              color: metric.color.withValues(alpha: .08),
              size: 112,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: metric.color.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(metric.icon, color: metric.color, size: 20),
                  ),
                  const Spacer(),
                  Text(
                    metric.delta,
                    style: TextStyle(
                      color: metric.color,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                metric.label,
                style: const TextStyle(
                  color: DashboardColors.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                metric.value,
                style: const TextStyle(
                  color: DashboardColors.onSurface,
                  fontSize: 31,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ChartCard extends StatelessWidget {
  const ChartCard({
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
    this.height,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return dashboard.AnimatedHoverCard(
      glowColor: DashboardColors.primary,
      child: SizedBox(
        height: height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: DashboardColors.onSurface,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 5),
                        Text(
                          subtitle!,
                          style: const TextStyle(
                            color: DashboardColors.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 22),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class InsightCard extends StatelessWidget {
  const InsightCard({required this.insight, super.key});

  final AnalyticsInsight insight;

  @override
  Widget build(BuildContext context) {
    return dashboard.GlassCard(
      radius: 20,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: insight.color.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(insight.icon, color: insight.color, size: 21),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: const TextStyle(
                    color: DashboardColors.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  insight.description,
                  style: const TextStyle(
                    color: DashboardColors.onSurfaceVariant,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          if (insight.actionLabel != null) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: insight.color.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(DashboardRadii.full),
              ),
              child: Text(
                insight.actionLabel!,
                style: TextStyle(
                  color: insight.color,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ProgressBarCard extends StatelessWidget {
  const ProgressBarCard({required this.category, super.key});

  final AnalyticsCategory category;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                category.label,
                style: const TextStyle(
                  color: DashboardColors.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              '${(category.value * 100).round()}%',
              style: TextStyle(
                color: category.color,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(DashboardRadii.full),
          child: Container(
            height: 9,
            color: Colors.white.withValues(alpha: .055),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: category.value),
              duration: DashboardDurations.slow,
              curve: Curves.easeOutCubic,
              builder:
                  (context, value, _) => Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: value,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              category.color,
                              category.color.withValues(alpha: .55),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(
                            DashboardRadii.full,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: category.color.withValues(alpha: .25),
                              blurRadius: 14,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          category.detail,
          style: const TextStyle(
            color: DashboardColors.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class FocusGauge extends StatelessWidget {
  const FocusGauge({
    required this.value,
    this.size = 230,
    this.label = 'Optimized',
    super.key,
  });

  final double value;
  final double size;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Focus score ${(value * 100).round()} percent, $label',
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value),
        duration: const Duration(milliseconds: 950),
        curve: Curves.easeOutCubic,
        builder:
            (context, animated, _) => SizedBox(
              width: size,
              height: size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: Size.square(size),
                    painter: FocusGaugePainter(value: animated),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(animated * 100).round()}%',
                        style: TextStyle(
                          color: DashboardColors.onSurface,
                          fontSize: size * .22,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        label.toUpperCase(),
                        style: const TextStyle(
                          color: DashboardColors.primary,
                          fontSize: 11,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
      ),
    );
  }
}

class FocusGaugePainter extends CustomPainter {
  const FocusGaugePainter({required this.value});

  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width * .39;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final track =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * .075
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withValues(alpha: .055);
    final progress =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * .075
          ..strokeCap = StrokeCap.round
          ..shader = const SweepGradient(
            colors: [
              DashboardColors.primaryContainer,
              DashboardColors.primary,
              DashboardColors.secondary,
              DashboardColors.primaryContainer,
            ],
          ).createShader(rect)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    final secondary =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * .018
          ..strokeCap = StrokeCap.round
          ..color = DashboardColors.secondary.withValues(alpha: .7);

    canvas.drawCircle(center, radius, track);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * value, false, progress);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * .78),
      math.pi * .9,
      math.pi * 1.15,
      false,
      secondary,
    );
  }

  @override
  bool shouldRepaint(FocusGaugePainter oldDelegate) =>
      oldDelegate.value != value;
}

class LineChart extends StatelessWidget {
  const LineChart({required this.points, this.summary, super.key});

  final List<AnalyticsPoint> points;
  final String? summary;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: summary ?? 'Analytics line chart with ${points.length} points.',
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder:
            (context, progress, _) => CustomPaint(
              painter: LineChartPainter(points: points, progress: progress),
              child: const SizedBox.expand(),
            ),
      ),
    );
  }
}

class LineChartPainter extends CustomPainter {
  const LineChartPainter({required this.points, required this.progress});

  final List<AnalyticsPoint> points;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final chartRect = Rect.fromLTWH(4, 8, size.width - 8, size.height - 32);
    final gridPaint =
        Paint()
          ..color = Colors.white.withValues(alpha: .055)
          ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = chartRect.top + chartRect.height * i / 3;
      canvas.drawLine(
        Offset(chartRect.left, y),
        Offset(chartRect.right, y),
        gridPaint,
      );
    }

    final offsets = <Offset>[];
    for (var i = 0; i < points.length; i++) {
      offsets.add(
        Offset(
          chartRect.left + chartRect.width * i / (points.length - 1),
          chartRect.bottom - chartRect.height * points[i].value,
        ),
      );
    }

    final path = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (var i = 0; i < offsets.length - 1; i++) {
      final current = offsets[i];
      final next = offsets[i + 1];
      final control = Offset((current.dx + next.dx) / 2, current.dy);
      final control2 = Offset((current.dx + next.dx) / 2, next.dy);
      path.cubicTo(
        control.dx,
        control.dy,
        control2.dx,
        control2.dy,
        next.dx,
        next.dy,
      );
    }

    final metric = path.computeMetrics().first;
    final animatedPath = metric.extractPath(0, metric.length * progress);
    final fillPath =
        Path.from(animatedPath)
          ..lineTo(
            chartRect.left + chartRect.width * progress,
            chartRect.bottom,
          )
          ..lineTo(chartRect.left, chartRect.bottom)
          ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            DashboardColors.primary.withValues(alpha: .22),
            DashboardColors.primary.withValues(alpha: 0),
          ],
        ).createShader(chartRect),
    );
    canvas.drawPath(
      animatedPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..shader = const LinearGradient(
          colors: [DashboardColors.primary, DashboardColors.secondary],
        ).createShader(chartRect),
    );

    final visible = (points.length * progress).floor().clamp(0, points.length);
    for (var i = 0; i < visible; i++) {
      final point = offsets[i];
      canvas.drawCircle(
        point,
        4,
        Paint()
          ..color =
              i == 4 || i == 6
                  ? DashboardColors.primary
                  : DashboardColors.surfaceHigh,
      );
      canvas.drawCircle(
        point,
        7,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = DashboardColors.primary.withValues(alpha: .4),
      );
    }

    final labelPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    for (
      var i = 0;
      i < points.length;
      i += math.max(1, (points.length / 5).floor())
    ) {
      labelPainter.text = TextSpan(
        text: points[i].label,
        style: const TextStyle(
          color: DashboardColors.onSurfaceVariant,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      );
      labelPainter.layout();
      labelPainter.paint(
        canvas,
        Offset(offsets[i].dx - labelPainter.width / 2, size.height - 18),
      );
    }
  }

  @override
  bool shouldRepaint(LineChartPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.points != points;
}
