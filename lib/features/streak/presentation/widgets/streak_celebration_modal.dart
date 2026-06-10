import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:to_do_app/features/streak/presentation/providers/streak_providers.dart';
import 'package:to_do_app/features/streak/presentation/providers/streak_services.dart';

class StreakAchievementModal extends ConsumerStatefulWidget {
  const StreakAchievementModal({
    super.key,
    required this.celebration,
  });

  final StreakCelebration celebration;

  @override
  ConsumerState<StreakAchievementModal> createState() =>
      _StreakAchievementModalState();
}

class _StreakAchievementModalState extends ConsumerState<StreakAchievementModal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;
  bool _exiting = false;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: Curves.elasticOut,
      ),
    );

    _opacity = CurvedAnimation(
      parent: _entryCtrl,
      curve: Curves.easeOutCubic,
    );

    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    if (_exiting) return;
    _exiting = true;
    _entryCtrl.duration = const Duration(milliseconds: 260);
    await _entryCtrl.reverse();
    if (mounted) {
      ref.read(pendingStreakProvider.notifier).dismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _dismiss,
        child: Stack(
          children: [
            // 1. Backdrop Blur Overlay
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _opacity,
                builder: (context, child) {
                  return Opacity(
                    opacity: _opacity.value,
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.6),
                      ),
                    ),
                  );
                },
              ),
            ),
            // 2. Main Dialog card with entry animations
            Center(
              child: AnimatedBuilder(
                animation: _entryCtrl,
                builder: (context, child) {
                  return ScaleTransition(
                    scale: _scale,
                    child: FadeTransition(
                      opacity: _opacity,
                      child: child,
                    ),
                  );
                },
                child: GestureDetector(
                  onTap: () {}, // Prevent taps on dialog from dismissing
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = MediaQuery.sizeOf(context).width;
                      final isMobile = width < 720;

                      return Container(
                        width: isMobile ? width * 0.95 : 900.0,
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF030817),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 45,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          children: [
                            // Atmospheric Background effects
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: Stack(
                                  children: [
                                    // Orange Glow (Top-Left)
                                    Positioned(
                                      top: -100,
                                      left: -100,
                                      child: Container(
                                        width: 400,
                                        height: 400,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: RadialGradient(
                                            colors: [
                                              const Color(0xFFF59E0B).withValues(alpha: 0.2),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Purple Glow (Bottom-Right)
                                    Positioned(
                                      bottom: -100,
                                      right: -100,
                                      child: Container(
                                        width: 400,
                                        height: 400,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: RadialGradient(
                                            colors: [
                                              const Color(0xFFA855F7).withValues(alpha: 0.15),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Floating Particles
                                    const Positioned.fill(
                                      child: FloatingParticlesWidget(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Responsive Layout Content
                            isMobile
                                ? StreakModalMobile(
                                    celebration: widget.celebration,
                                    onContinue: _dismiss,
                                  )
                                : StreakModalDesktop(
                                    celebration: widget.celebration,
                                    onContinue: _dismiss,
                                  ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StreakModalDesktop extends StatelessWidget {
  final StreakCelebration celebration;
  final VoidCallback onContinue;

  const StreakModalDesktop({
    super.key,
    required this.celebration,
    required this.onContinue,
  });

  static const _messages = [
    'Consistency beats intensity.',
    'Your momentum is growing.',
    'Small wins compound into greatness.',
    'Every day counts.',
    'You stayed productive today.',
  ];

  @override
  Widget build(BuildContext context) {
    final message = _messages[celebration.currentCount % _messages.length];

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Column (70% equivalent: 580px of 900px)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(48.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🔥 STREAK INCREASED',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFF59E0B),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 4.0,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const FireBadgeWidget(),
                          const SizedBox(width: 32),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                StreakCounterWidget(
                                  previousCount: celebration.previousCount,
                                  currentCount: celebration.currentCount,
                                  fontSize: 60.0,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  message,
                                  style: GoogleFonts.inter(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 16,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StreakTrackerWidget(currentStreak: celebration.currentCount),
                      const SizedBox(height: 24),
                      MomentumPillWidget(streakCount: celebration.currentCount),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Divider
          Container(
            width: 1.5,
            color: Colors.white.withValues(alpha: 0.08),
          ),
          // Right Column (320px)
          Container(
            width: 320,
            constraints: const BoxConstraints(minHeight: 420),
            color: const Color(0xFF1b1c1d).withValues(alpha: 0.40),
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
            child: MilestonePanelWidget(
              currentStreak: celebration.currentCount,
              onContinue: onContinue,
            ),
          ),
        ],
      ),
    );
  }
}

class StreakModalMobile extends StatelessWidget {
  final StreakCelebration celebration;
  final VoidCallback onContinue;

  const StreakModalMobile({
    super.key,
    required this.celebration,
    required this.onContinue,
  });

  static const _messages = [
    'Consistency beats intensity.',
    'Your momentum is growing.',
    'Small wins compound into greatness.',
    'Every day counts.',
    'You stayed productive today.',
  ];

  @override
  Widget build(BuildContext context) {
    final message = _messages[celebration.currentCount % _messages.length];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.center,
            child: Text(
              '🔥 STREAK INCREASED',
              style: GoogleFonts.inter(
                color: const Color(0xFFF59E0B),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 4.0,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Hero Section
          Column(
            children: [
              const FireBadgeWidget(),
              const SizedBox(height: 16),
              StreakCounterWidget(
                previousCount: celebration.previousCount,
                currentCount: celebration.currentCount,
                fontSize: 44.0,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 16),
              MomentumPillWidget(streakCount: celebration.currentCount),
            ],
          ),
          const SizedBox(height: 28),
          // Streak Tracker Section
          StreakTrackerWidget(currentStreak: celebration.currentCount),
          const SizedBox(height: 28),
          // Milestone Panel Section
          MilestonePanelWidget(
            currentStreak: celebration.currentCount,
            onContinue: onContinue,
          ),
        ],
      ),
    );
  }
}

class FireBadgeWidget extends StatefulWidget {
  const FireBadgeWidget({super.key});

  @override
  State<FireBadgeWidget> createState() => _FireBadgeWidgetState();
}

class _FireBadgeWidgetState extends State<FireBadgeWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glow behind the badge
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                  blurRadius: 60,
                  spreadRadius: 10,
                ),
              ],
            ),
          ),
          // Lottie loader with custom vector fallback
          Lottie.network(
            'https://assets3.lottiefiles.com/packages/lf20_fp74scle.json',
            width: 140,
            height: 140,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    painter: VectorFlamePainter(_controller.value),
                    size: const Size(140, 140),
                  );
                },
              );
            },
            frameBuilder: (context, child, composition) {
              if (composition == null) {
                return AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: VectorFlamePainter(_controller.value),
                      size: const Size(140, 140),
                    );
                  },
                );
              }
              return child;
            },
          ),
        ],
      ),
    );
  }
}

class VectorFlamePainter extends CustomPainter {
  final double animationValue;

  VectorFlamePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Draw three overlapping layers of flame shapes
    // Layer 1: Outer Flame (Darker Red-Orange gradient)
    final outerPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          const Color(0xFFD97706).withValues(alpha: 0.8),
          const Color(0xFFEF4444).withValues(alpha: 0.2),
        ],
      ).createShader(Rect.fromLTWH(0, 0, width, height));

    final outerPath = Path();
    final wobble1 = 4.0 * math.sin(animationValue * 2 * math.pi);
    outerPath.moveTo(width * 0.5, height * 0.1);
    outerPath.cubicTo(
      width * 0.8 + wobble1, height * 0.4,
      width * 0.85, height * 0.7,
      width * 0.75, height * 0.85,
    );
    outerPath.cubicTo(
      width * 0.65, height * 0.95,
      width * 0.35, height * 0.95,
      width * 0.25, height * 0.85,
    );
    outerPath.cubicTo(
      width * 0.15, height * 0.7,
      width * 0.2 - wobble1, height * 0.4,
      width * 0.5, height * 0.1,
    );
    outerPath.close();
    canvas.drawPath(outerPath, outerPaint);

    // Layer 2: Middle Flame (Vibrant Orange-Amber)
    final middlePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          const Color(0xFFF59E0B),
          const Color(0xFFD97706).withValues(alpha: 0.4),
        ],
      ).createShader(Rect.fromLTWH(0, 0, width, height));

    final middlePath = Path();
    final wobble2 = 3.0 * math.sin(animationValue * 2 * math.pi + 1.0);
    middlePath.moveTo(width * 0.5, height * 0.25);
    middlePath.cubicTo(
      width * 0.72 + wobble2, height * 0.48,
      width * 0.76, height * 0.7,
      width * 0.68, height * 0.8,
    );
    middlePath.cubicTo(
      width * 0.6, height * 0.9,
      width * 0.4, height * 0.9,
      width * 0.32, height * 0.8,
    );
    middlePath.cubicTo(
      width * 0.24, height * 0.7,
      width * 0.28 - wobble2, height * 0.48,
      width * 0.5, height * 0.25,
    );
    middlePath.close();
    canvas.drawPath(middlePath, middlePaint);

    // Layer 3: Inner Flame (Yellow-White Core)
    final innerPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          Colors.white,
          const Color(0xFFF59E0B).withValues(alpha: 0.6),
        ],
      ).createShader(Rect.fromLTWH(0, 0, width, height));

    final innerPath = Path();
    final wobble3 = 2.0 * math.sin(animationValue * 2 * math.pi + 2.0);
    innerPath.moveTo(width * 0.5, height * 0.42);
    innerPath.cubicTo(
      width * 0.63 + wobble3, height * 0.58,
      width * 0.65, height * 0.72,
      width * 0.6, height * 0.78,
    );
    innerPath.cubicTo(
      width * 0.55, height * 0.84,
      width * 0.45, height * 0.84,
      width * 0.4, height * 0.78,
    );
    innerPath.cubicTo(
      width * 0.35, height * 0.72,
      width * 0.37 - wobble3, height * 0.58,
      width * 0.5, height * 0.42,
    );
    innerPath.close();
    canvas.drawPath(innerPath, innerPaint);
  }

  @override
  bool shouldRepaint(covariant VectorFlamePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

class StreakCounterWidget extends StatefulWidget {
  final int previousCount;
  final int currentCount;
  final double fontSize;

  const StreakCounterWidget({
    super.key,
    required this.previousCount,
    required this.currentCount,
    required this.fontSize,
  });

  @override
  State<StreakCounterWidget> createState() => _StreakCounterWidgetState();
}

class _StreakCounterWidgetState extends State<StreakCounterWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<int> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = IntTween(
      begin: widget.previousCount,
      end: widget.currentCount,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    // Stagger count animation with 800ms start delay
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final text = 'DAY ${_animation.value} STREAK';
        return ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(bounds),
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: widget.fontSize,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.1,
            ),
          ),
        );
      },
    );
  }
}

class StreakTrackerWidget extends ConsumerWidget {
  final int currentStreak;

  const StreakTrackerWidget({
    super.key,
    required this.currentStreak,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakDays = ref.watch(userStreakDaysProvider).valueOrNull ?? [];
    final activeKeys = streakDays.map((day) => _dayKey(day.activeDate)).toSet();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = List.generate(
      7,
      (index) => today.subtract(Duration(days: 6 - index)),
    );

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: List.generate(7, (i) {
        final day = days[i];
        final isCompleted = activeKeys.contains(_dayKey(day));
        final delayMs = 600 + i * 100;
        return StreakTrackerCircle(
          date: day,
          isCompleted: isCompleted,
          delayMs: delayMs,
        );
      }),
    );
  }
}

class StreakTrackerCircle extends StatefulWidget {
  final DateTime date;
  final bool isCompleted;
  final int delayMs;

  const StreakTrackerCircle({
    super.key,
    required this.date,
    required this.isCompleted,
    required this.delayMs,
  });

  @override
  State<StreakTrackerCircle> createState() => _StreakTrackerCircleState();
}

class _StreakTrackerCircleState extends State<StreakTrackerCircle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scale = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _weekdayLetter(DateTime date) {
    const letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return letters[date.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final label = _weekdayLetter(widget.date);

    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.isCompleted
              ? const Color(0xFFF59E0B).withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.03),
          border: Border.all(
            color: widget.isCompleted
                ? const Color(0xFFF59E0B)
                : Colors.white.withValues(alpha: 0.08),
            width: 2,
          ),
          boxShadow: widget.isCompleted
              ? [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                    blurRadius: 15,
                  )
                ]
              : null,
        ),
        child: Center(
          child: widget.isCompleted
              ? const Icon(
                  Icons.local_fire_department_rounded,
                  color: Color(0xFFF59E0B),
                  size: 24,
                )
              : Text(
                  label,
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
        ),
      ),
    );
  }
}

String _dayKey(DateTime date) {
  final local = date.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
}

class MomentumPillWidget extends StatelessWidget {
  final int streakCount;
  const MomentumPillWidget({super.key, required this.streakCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.bolt_rounded,
            color: Color(0xFFF59E0B),
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            streakCount > 1 ? 'Momentum Maintained' : '+ Streak Protected',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class MilestonePanelWidget extends StatelessWidget {
  final int currentStreak;
  final VoidCallback onContinue;

  const MilestonePanelWidget({
    super.key,
    required this.currentStreak,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    const streakService = StreakService();
    const achievementService = AchievementService();

    final nextMilestone = streakService.getNextMilestone(currentStreak);
    final achievement = achievementService.getAchievementForMilestone(nextMilestone, currentStreak);
    final progress = (currentStreak / nextMilestone).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'NEXT MILESTONE: $nextMilestone DAYS',
          style: GoogleFonts.inter(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '+${achievement.xpReward} XP Bonus',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '$currentStreak/$nextMilestone',
              style: GoogleFonts.inter(
                color: const Color(0xFFF59E0B),
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AnimatedProgressBarWidget(progress: progress),
        const SizedBox(height: 24),
        AchievementCardWidget(
          title: achievement.title,
          subtitle: achievement.description,
        ),
        const SizedBox(height: 24),
        _ContinueButton(onPressed: onContinue),
      ],
    );
  }
}

class AchievementCardWidget extends StatelessWidget {
  final String title;
  final String subtitle;

  const AchievementCardWidget({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.military_tech_rounded,
              color: Color(0xFFF59E0B),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
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

class AnimatedProgressBarWidget extends StatefulWidget {
  final double progress;

  const AnimatedProgressBarWidget({
    super.key,
    required this.progress,
  });

  @override
  State<AnimatedProgressBarWidget> createState() => _AnimatedProgressBarWidgetState();
}

class _AnimatedProgressBarWidgetState extends State<AnimatedProgressBarWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: widget.progress,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic));

    // Stagger progress animation with 1200ms delay
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 12,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1f2021),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return FractionallySizedBox(
                    widthFactor: _animation.value,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
                            blurRadius: 15,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ContinueButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _ContinueButton({required this.onPressed});

  @override
  State<_ContinueButton> createState() => _ContinueButtonState();
}

class _ContinueButtonState extends State<_ContinueButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
    _scale = _controller;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.reverse(),
      onTapUp: (_) {
        _controller.forward();
        widget.onPressed();
      },
      onTapCancel: () => _controller.forward(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            'CONTINUE',
            style: GoogleFonts.inter(
              color: const Color(0xFF030817),
              fontWeight: FontWeight.w800,
              fontSize: 16,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}

class FloatingParticlesWidget extends StatefulWidget {
  const FloatingParticlesWidget({super.key});

  @override
  State<FloatingParticlesWidget> createState() => _FloatingParticlesWidgetState();
}

class _FloatingParticlesWidgetState extends State<FloatingParticlesWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<ParticleData> _particles;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    _particles = List.generate(18, (index) {
      return ParticleData(
        left: _random.nextDouble(),
        scale: 0.5 + _random.nextDouble() * 1.0,
        opacitySeed: 0.3 + _random.nextDouble() * 0.7,
        speed: 1.0 + _random.nextDouble() * 1.5,
        startDelay: _random.nextDouble(),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: FloatingParticlesPainter(
            particles: _particles,
            progress: _controller.value,
          ),
          child: Container(),
        );
      },
    );
  }
}

class ParticleData {
  double left;
  double scale;
  double opacitySeed;
  double speed;
  double startDelay;

  ParticleData({
    required this.left,
    required this.scale,
    required this.opacitySeed,
    required this.speed,
    required this.startDelay,
  });
}

class FloatingParticlesPainter extends CustomPainter {
  final List<ParticleData> particles;
  final double progress;

  FloatingParticlesPainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.fill;

    for (final p in particles) {
      double localProgress = (progress * p.speed + p.startDelay) % 1.0;
      double y = size.height * (1.1 - localProgress * 1.2);
      double x = size.width * (p.left + 0.05 * math.sin(localProgress * 4 * math.pi));

      double opacity = p.opacitySeed;
      if (localProgress < 0.2) {
        opacity *= (localProgress / 0.2);
      } else if (localProgress > 0.8) {
        opacity *= ((1.0 - localProgress) / 0.2);
      }

      paint.color = const Color(0xFFF59E0B).withValues(alpha: opacity.clamp(0.0, 1.0));
      canvas.drawCircle(Offset(x, y), 2.0 * p.scale, paint);
    }
  }

  @override
  bool shouldRepaint(covariant FloatingParticlesPainter oldDelegate) {
    return true;
  }
}
