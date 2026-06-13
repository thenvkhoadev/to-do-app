import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'design_system.dart';

class AiIntelligenceCard extends StatefulWidget {
  const AiIntelligenceCard({super.key});

  @override
  State<AiIntelligenceCard> createState() => _AiIntelligenceCardState();
}

class _AiIntelligenceCardState extends State<AiIntelligenceCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HoverBuilder(
      builder: (context, isHovered) {
        return GlassCard(
          padding: EdgeInsets.zero,
          child: Stack(
            children: [
              // Shader background on the right side
              Positioned.fill(
                child: FractionallySizedBox(
                  alignment: Alignment.centerRight,
                  widthFactor: 0.6,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(24.0),
                      bottomRight: Radius.circular(24.0),
                    ),
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: _CardShaderPainter(
                            time: _controller.value,
                            opacityMultiplier: isHovered ? 0.4 : 0.2,
                          ),
                          child: const SizedBox.expand(),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // Card details
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.psychology,
                          color: LandingColors.primary,
                          size: 36.0,
                        ),
                        const SizedBox(height: 12.0),
                        Text(
                          'AI Intelligence',
                          style: getLandingGeistStyle(
                            fontSize: 32.0,
                            fontWeight: FontWeight.w600,
                            color: LandingColors.textPrimary,
                            letterSpacing: -0.64,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 6.0),
                        Text(
                          'Our neural network analyzes your working patterns to suggest the perfect schedule, blocking distractions before they happen.',
                          style: getLandingGeistStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.w400,
                            color: LandingColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        _buildTag('Neural Net'),
                        const SizedBox(width: 8.0),
                        _buildTag('Real-time Analysis'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: LandingColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(9999.0),
      ),
      child: Text(
        text,
        style: getLandingGeistMonoStyle(
          fontSize: 11.0,
          fontWeight: FontWeight.w500,
          color: LandingColors.primary,
        ),
      ),
    );
  }
}

class _CardShaderPainter extends CustomPainter {
  final double time;
  final double opacityMultiplier;

  _CardShaderPainter({required this.time, required this.opacityMultiplier});

  @override
  void paint(Canvas canvas, Size size) {
    final double t = time * 2.0 * math.pi;

    // Pulse Glow 1 (Vibrant Purple nebula)
    final glow1Center = Offset(
      math.sin(t * 0.5) * size.width * 0.20 + size.width * 0.5,
      math.cos(t * 0.3) * size.height * 0.20 + size.height * 0.5,
    );
    final glow1Paint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF8A5CF6).withValues(alpha: 0.60 * opacityMultiplier),
          const Color(0xFF8A5CF6).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: glow1Center, radius: size.width * 0.8));
    canvas.drawCircle(glow1Center, size.width * 0.8, glow1Paint);

    // Pulse Glow 2 (Vibrant Cyan nebula)
    final glow2Center = Offset(
      math.cos(t * 0.4) * size.width * 0.25 + size.width * 0.6,
      math.sin(t * 0.6) * size.height * 0.15 + size.height * 0.6,
    );
    final glow2Paint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF06B6D4).withValues(alpha: 0.50 * opacityMultiplier),
          const Color(0xFF06B6D4).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: glow2Center, radius: size.width * 0.7));
    canvas.drawCircle(glow2Center, size.width * 0.7, glow2Paint);
  }

  @override
  bool shouldRepaint(covariant _CardShaderPainter oldDelegate) {
    return oldDelegate.time != time || oldDelegate.opacityMultiplier != opacityMultiplier;
  }
}
