import 'dart:math';
import 'package:flutter/material.dart';
import 'edit_profile_shared.dart';

class WorkDistributionCard extends StatelessWidget {
  const WorkDistributionCard({
    required this.deepWorkPercent,
    required this.adminPercent,
    required this.learningPercent,
    super.key,
  });

  final int deepWorkPercent;
  final int adminPercent;
  final int learningPercent;

  @override
  Widget build(BuildContext context) {
    final segments = [
      _DonutSegment(
        label: 'Deep Work',
        percent: deepWorkPercent,
        color: EditProfileColors.primary,
      ),
      _DonutSegment(
        label: 'Learning',
        percent: learningPercent,
        color: EditProfileColors.secondary,
      ),
      _DonutSegment(
        label: 'Admin',
        percent: adminPercent,
        color: Colors.cyanAccent, // fallback color matching HTML tertiary
      ),
    ];

    return EditProfileGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Work Distribution',
                style: TextStyle(
                  color: EditProfileColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: EditProfileColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'HEALTHY',
                  style: TextStyle(
                    color: EditProfileColors.success,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Custom Donut Chart Area
          Center(
            child: SizedBox(
              width: 160,
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(160, 160),
                    painter: _DonutChartPainter(segments: segments),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'FLOW',
                        style: TextStyle(
                          color: EditProfileColors.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$deepWorkPercent%',
                        style: const TextStyle(
                          color: EditProfileColors.textPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Legends
          Column(
            children: segments.map((seg) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: seg.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          seg.label,
                          style: const TextStyle(
                            color: EditProfileColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${seg.percent}%',
                      style: const TextStyle(
                        color: EditProfileColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _DonutSegment {
  _DonutSegment({
    required this.label,
    required this.percent,
    required this.color,
  });

  final String label;
  final int percent;
  final Color color;
}

class _DonutChartPainter extends CustomPainter {
  _DonutChartPainter({required this.segments});

  final List<_DonutSegment> segments;

  @override
  void paint(Canvas canvas, Size size) {
    final total = segments.fold<int>(0, (sum, seg) => sum + seg.percent);
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 16) / 2; // leave room for stroke width

    final rect = Rect.fromCircle(center: center, radius: radius);

    double startAngle = -pi / 2; // Start at the top

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    for (final seg in segments) {
      if (seg.percent == 0) continue;
      final sweepAngle = (seg.percent / total) * 2 * pi;

      paint.color = seg.color;
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
