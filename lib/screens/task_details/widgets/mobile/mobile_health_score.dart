import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class MobileHealthScore extends StatelessWidget {
  const MobileHealthScore({this.score = 92, this.probability = 87, super.key});
  final int score;
  final int probability;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _HealthCard(score: score)),
        const SizedBox(width: 16),
        Expanded(child: _AiBentoCard(probability: probability)),
      ],
    );
  }
}

class _HealthCard extends StatelessWidget {
  const _HealthCard({required this.score});
  final int score;

  @override
  Widget build(BuildContext context) => _GlassCard(
        child: Column(
          children: [
            SizedBox(
              width: 96,
              height: 96,
              child: CustomPaint(
                painter: _RingPainter(progress: score / 100),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$score',
                        style: const TextStyle(
                          color: DashboardColors.primary,
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          height: 1,
                        ),
                      ),
                      const Text(
                        '/100',
                        style: TextStyle(
                          color: DashboardColors.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.check_circle_rounded,
                    color: DashboardColors.success, size: 14),
                SizedBox(width: 4),
                Text(
                  'On Track',
                  style: TextStyle(
                    color: DashboardColors.success,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    const strokeWidth = 5.0;

    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = Colors.white.withValues(alpha: .10);
    canvas.drawCircle(center, radius, bgPaint);

    final fgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = DashboardColors.primary;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

class _AiBentoCard extends StatelessWidget {
  const _AiBentoCard({required this.probability});
  final int probability;

  @override
  Widget build(BuildContext context) => _GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.auto_awesome_rounded,
                    color: DashboardColors.primary, size: 18),
                SizedBox(width: 6),
                Text(
                  'AI Insights',
                  style: TextStyle(
                    color: DashboardColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Build analytics cards first to unblock backend integration.',
              style: TextStyle(
                color: DashboardColors.onSurfaceVariant,
                fontSize: 11,
                height: 1.4,
              ),
            ),
            const Spacer(),
            const Divider(color: Color(0x0DFFFFFF), height: 16),
            Text(
              '$probability%',
              style: const TextStyle(
                color: DashboardColors.primary,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Text(
              'Probability',
              style: TextStyle(
                color: DashboardColors.onSurfaceVariant,
                fontSize: 11,
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
