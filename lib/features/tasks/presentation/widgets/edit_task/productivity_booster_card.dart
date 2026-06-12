import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class TaskProductivityBoosterCard extends StatefulWidget {
  const TaskProductivityBoosterCard({super.key});

  @override
  State<TaskProductivityBoosterCard> createState() => _TaskProductivityBoosterCardState();
}

class _TaskProductivityBoosterCardState extends State<TaskProductivityBoosterCard>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _boostController;

  double _boostMultiplier = 1.0;
  int _quoteIndex = 0;
  Timer? _quoteTimer;
  bool _isHovered = false;

  final List<String> _productivityQuotes = [
    "Deep Work: Limit context switching to maximize cognitive performance.",
    "Focus Matrix: 90-minute work blocks matched with 15-minute breaks.",
    "Cognitive Load: Declutter your workspace to reduce visual distraction.",
    "Dopamine Loop: Complete micro-tasks to maintain project momentum.",
    "Atomic Win: Scale down tasks to overcome starting friction.",
  ];

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _boostController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _boostController.addListener(() {
      setState(() {
        // Boost multiplier decays from 4.0 back to 1.0 based on curve
        final t = _boostController.value;
        _boostMultiplier = 1.0 + (3.0 * (1.0 - Curves.easeOutCubic.transform(t)));
      });
    });

    _quoteTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (mounted) {
        setState(() {
          _quoteIndex = (_quoteIndex + 1) % _productivityQuotes.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _boostController.dispose();
    _quoteTimer?.cancel();
    super.dispose();
  }

  void _triggerBoost() {
    if (!_boostController.isAnimating) {
      _boostController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scaleAnim = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: _isHovered 
              ? const Color.fromRGBO(255, 255, 255, 0.04)
              : const Color.fromRGBO(255, 255, 255, 0.03),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _isHovered 
                ? DashboardColors.primary.withValues(alpha: 0.15)
                : const Color.fromRGBO(255, 255, 255, 0.08),
          ),
          boxShadow: [
            if (_isHovered)
              BoxShadow(
                color: DashboardColors.primary.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'AI FOCUS SPECTRUM',
                  style: TextStyle(
                    color: DashboardColors.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'FLOW ACTIVE',
                        style: TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // The Quantum/Core focus painter
            Center(
              child: SizedBox(
                width: 140,
                height: 140,
                child: AnimatedBuilder(
                  animation: Listenable.merge([_rotationController, _pulseController, _boostController]),
                  builder: (context, child) {
                    final rotationVal = _rotationController.value * 2 * math.pi;
                    final pulseVal = scaleAnim.value;
                    return CustomPaint(
                      painter: _QuantumFocusPainter(
                        rotation: rotationVal,
                        pulse: pulseVal,
                        boost: _boostMultiplier,
                        boostAnimationVal: _boostController.value,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _boostMultiplier > 1.2 
                                  ? '${(98 * _boostMultiplier).toInt().clamp(98, 199)}%' 
                                  : '98%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const Text(
                              'FLOW RATE',
                              style: TextStyle(
                                color: DashboardColors.onSurfaceVariant,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Quotes/Insight section
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.1),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: Container(
                key: ValueKey<int>(_quoteIndex),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.04),
                  ),
                ),
                child: Text(
                  _productivityQuotes[_quoteIndex],
                  style: const TextStyle(
                    color: DashboardColors.onSurfaceVariant,
                    fontSize: 11.5,
                    height: 1.4,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 18),
            // Boost interactive button
            ElevatedButton(
              onPressed: _triggerBoost,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: DashboardColors.primary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: _boostMultiplier > 1.2
                        ? DashboardColors.primary.withValues(alpha: 0.4)
                        : Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Row(
                  key: ValueKey<bool>(_boostMultiplier > 1.2),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _boostMultiplier > 1.2
                      ? [
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              valueColor: AlwaysStoppedAnimation<Color>(DashboardColors.primary),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'BOOSTING COGNITION...',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ]
                      : [
                          const Icon(Icons.bolt_rounded, size: 14),
                          const SizedBox(width: 4),
                          const Text(
                            'BOOST MATRIX',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantumFocusPainter extends CustomPainter {
  _QuantumFocusPainter({
    required this.rotation,
    required this.pulse,
    required this.boost,
    required this.boostAnimationVal,
  });

  final double rotation;
  final double pulse;
  final double boost;
  final double boostAnimationVal;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // 1. Draw glowing shockwave ripple if boost is active
    if (boostAnimationVal > 0 && boostAnimationVal < 1.0) {
      final rippleRadius = (size.width / 2) * (0.3 + 0.7 * boostAnimationVal);
      final ripplePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 * (1.0 - boostAnimationVal)
        ..color = const Color(0xFFC0C1FF).withValues(alpha: 0.4 * (1.0 - boostAnimationVal));
      canvas.drawCircle(center, rippleRadius, ripplePaint);
    }

    // 2. Draw outer dashed orbit (slow rotation clockwise)
    final outerRadius = (size.width / 2) * 0.95;
    paint.color = DashboardColors.primary.withValues(alpha: 0.08);
    paint.strokeWidth = 1.0;
    _drawDashedCircle(canvas, center, outerRadius, paint, 36, rotation * boost);

    // 3. Draw middle dashed orbit (counter-clockwise)
    final midRadius = (size.width / 2) * 0.75;
    paint.color = const Color(0xFFADC6FF).withValues(alpha: 0.15);
    paint.strokeWidth = 1.2;
    _drawDashedCircle(canvas, center, midRadius, paint, 24, -rotation * 1.5 * boost);

    // 4. Draw inner dashed orbit (clockwise)
    final innerRadius = (size.width / 2) * 0.55;
    paint.color = const Color(0xFFDDB7FF).withValues(alpha: 0.22);
    paint.strokeWidth = 1.5;
    _drawDashedCircle(canvas, center, innerRadius, paint, 16, rotation * 2.2 * boost);

    // 5. Draw crosshairs
    final crossPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(center.dx - outerRadius, center.dy), Offset(center.dx - innerRadius, center.dy), crossPaint);
    canvas.drawLine(Offset(center.dx + innerRadius, center.dy), Offset(center.dx + outerRadius, center.dy), crossPaint);
    canvas.drawLine(Offset(center.dx, center.dy - outerRadius), Offset(center.dx, center.dy - innerRadius), crossPaint);
    canvas.drawLine(Offset(center.dx, center.dy + innerRadius), Offset(center.dx, center.dy + outerRadius), crossPaint);

    // 6. Draw orbiting particles
    final particlePaint = Paint()
      ..style = PaintingStyle.fill;

    // Particle 1 on outer ring
    final p1Angle = rotation * 0.8 * boost;
    final p1 = Offset(
      center.dx + outerRadius * math.cos(p1Angle),
      center.dy + outerRadius * math.sin(p1Angle),
    );
    particlePaint.color = DashboardColors.primary.withValues(alpha: 0.6);
    canvas.drawCircle(p1, 3.0, particlePaint);

    // Particle 2 on mid ring
    final p2Angle = -rotation * 1.3 * boost + math.pi;
    final p2 = Offset(
      center.dx + midRadius * math.cos(p2Angle),
      center.dy + midRadius * math.sin(p2Angle),
    );
    particlePaint.color = const Color(0xFFADC6FF);
    canvas.drawCircle(p2, 2.5, particlePaint);

    // Particle 3 on inner ring
    final p3Angle = rotation * 2.0 * boost - (math.pi / 2);
    final p3 = Offset(
      center.dx + innerRadius * math.cos(p3Angle),
      center.dy + innerRadius * math.sin(p3Angle),
    );
    particlePaint.color = const Color(0xFFDDB7FF);
    canvas.drawCircle(p3, 3.5, particlePaint);

    // 7. Pulsing core glowing background
    final coreGlowPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF8083FF).withValues(alpha: 0.25 * boost),
          const Color(0xFF6F00BE).withValues(alpha: 0.05 * boost),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: innerRadius * 0.8 * pulse));
    canvas.drawCircle(center, innerRadius * 0.8 * pulse, coreGlowPaint);

    // 8. Core solid ring
    paint.color = const Color(0xFFC0C1FF).withValues(alpha: 0.3 * boost);
    paint.strokeWidth = 2.0;
    canvas.drawCircle(center, innerRadius * 0.45 * pulse, paint);
  }

  void _drawDashedCircle(Canvas canvas, Offset center, double radius, Paint paint, int dashCount, double startAngle) {
    final dashAngle = 2 * math.pi / dashCount;
    for (int i = 0; i < dashCount; i += 2) {
      final start = startAngle + i * dashAngle;
      final sweep = dashAngle;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _QuantumFocusPainter oldDelegate) {
    return oldDelegate.rotation != rotation ||
        oldDelegate.pulse != pulse ||
        oldDelegate.boost != boost ||
        oldDelegate.boostAnimationVal != boostAnimationVal;
  }
}
