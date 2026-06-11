import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:to_do_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:to_do_app/features/xp/domain/xp_leveling.dart' as leveling;
import 'package:to_do_app/features/xp/presentation/providers/xp_providers.dart';
import 'package:to_do_app/features/xp/data/models/xp_log_model.dart';

// ── Models & Classes for Particles ─────────────────────────────────────────

class ExplosionParticle {
  final double angle;
  final double speed;
  final Color color;
  final double size;

  ExplosionParticle({
    required this.angle,
    required this.speed,
    required this.color,
    required this.size,
  });
}

class FloatingParticle {
  final double baseX;
  final double baseY;
  final double speed;
  final double wobbleFreq;
  final double size;
  final Color color;
  final double opacity;

  FloatingParticle({
    required this.baseX,
    required this.baseY,
    required this.speed,
    required this.wobbleFreq,
    required this.size,
    required this.color,
    required this.opacity,
  });
}

// ── Level Up Modal ────────────────────────────────────────────────────────

class LevelUpModal extends ConsumerStatefulWidget {
  const LevelUpModal({super.key, required this.newLevel});
  final int newLevel;

  @override
  ConsumerState<LevelUpModal> createState() => _LevelUpModalState();
}

class _LevelUpModalState extends ConsumerState<LevelUpModal>
    with TickerProviderStateMixin {
  late AnimationController _entryCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _floatCtrl;

  // Staggered Animations
  late Animation<double> _backdropAnim;
  late Animation<double> _glowScaleAnim;
  late Animation<double> _glowOpacityAnim;
  late Animation<double> _cardSlideAnim;
  late Animation<double> _cardScaleAnim;
  late Animation<double> _particlesAnim;
  late Animation<double> _punchAnim;

  final List<ExplosionParticle> _explosionParticles = [];
  final List<FloatingParticle> _floatingParticles = [];

  bool _exiting = false;
  bool _soundPlayed = false;

  @override
  void initState() {
    super.initState();

    // Controllers
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

    // Curves & Staggered Animations
    _backdropAnim = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );

    _glowScaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOutBack),
      ),
    );
    _glowOpacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.2, 0.5, curve: Curves.easeOut),
      ),
    );

    _cardSlideAnim = Tween<double>(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
      ),
    );
    _cardScaleAnim = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _particlesAnim = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.5, 0.9, curve: Curves.easeOut),
    );

    _punchAnim = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
    );

    // Particles Initialization
    final random = math.Random();
    final colors = [
      const Color(0xFFC084FC), // Purple
      const Color(0xFF6366F1), // Blue
      const Color(0xFFFFD700), // Gold
    ];

    for (int i = 0; i < 25; i++) {
      _explosionParticles.add(
        ExplosionParticle(
          angle: random.nextDouble() * 2 * math.pi,
          speed: 80.0 + random.nextDouble() * 100.0,
          color: colors[random.nextInt(colors.length)],
          size: 3.0 + random.nextDouble() * 3.0,
        ),
      );
    }

    for (int i = 0; i < 20; i++) {
      _floatingParticles.add(
        FloatingParticle(
          baseX: random.nextDouble(),
          baseY: random.nextDouble(),
          speed: 0.05 + random.nextDouble() * 0.05,
          wobbleFreq: 0.5 + random.nextDouble() * 1.5,
          size: 2.0 + random.nextDouble() * 3.0,
          color: colors[random.nextInt(colors.length)],
          opacity: 0.1 + random.nextDouble() * 0.2,
        ),
      );
    }

    // Sound hook listener
    _entryCtrl.addListener(() {
      if (_entryCtrl.value >= 0.7 && !_soundPlayed) {
        _soundPlayed = true;
        playLevelUpSound();
      }
    });

    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _pulseCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  void playLevelUpSound() {
    // Hook for future sound logic: playLevelUpSound();
  }

  Future<void> _dismiss() async {
    if (_exiting) return;
    setState(() => _exiting = true);
    _entryCtrl.duration = const Duration(milliseconds: 300);
    await _entryCtrl.reverse();
    if (mounted) {
      ref.read(levelUpProvider.notifier).dismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 720;
    final cardWidth = isMobile ? width * 0.9 : 520.0;

    // Load logs to extract the reward summary
    final logsAsync = ref.watch(xpLogsProvider);
    final logs = logsAsync.valueOrNull ?? [];
    final latestLog = logs.firstOrNull;

    // Load profile to calculate the old level
    final profile = ref.watch(userProfileProvider).valueOrNull;

    int oldLevel = widget.newLevel - 1;
    if (profile != null && latestLog != null) {
      final previousTotalXp = (profile.totalXp - latestLog.xpGained).clamp(0, 1 << 30);
      oldLevel = leveling.xpLevelFromTotalXp(previousTotalXp);
      // Ensure we don't display oldLevel >= newLevel
      if (oldLevel >= widget.newLevel) {
        oldLevel = widget.newLevel - 1;
      }
    }

    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        onTap: _dismiss,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _backdropAnim,
          builder: (context, child) {
            final blurVal = _backdropAnim.value * 16.0;
            final opacityVal = _backdropAnim.value * 0.75;
            return Stack(
              children: [
                // 1. Backdrop Blur & Dim
                if (blurVal > 0)
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: blurVal, sigmaY: blurVal),
                      child: Container(
                        color: Colors.black.withValues(alpha: opacityVal),
                      ),
                    ),
                  ),

                // 2. Slow drifting floating background particles
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _floatCtrl,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: FloatingParticlesPainter(
                          particles: _floatingParticles,
                          progress: _floatCtrl.value,
                        ),
                      );
                    },
                  ),
                ),

                // 3. Ambient Glow Pulse behind the card
                Center(
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_glowScaleAnim, _glowOpacityAnim, _pulseCtrl]),
                    builder: (context, child) {
                      final pulseScale = 1.0 + 0.08 * math.sin(_pulseCtrl.value * 2 * math.pi);
                      final pulseOpacity = 0.5 + 0.15 * math.cos(_pulseCtrl.value * 2 * math.pi);
                      
                      final scale = _glowScaleAnim.value * pulseScale;
                      final opacity = _glowOpacityAnim.value * pulseOpacity;

                      return Transform.scale(
                        scale: scale,
                        child: Opacity(
                          opacity: opacity.clamp(0.0, 1.0),
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      width: cardWidth * 0.8,
                      height: cardWidth * 0.8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF8B5CF6).withValues(alpha: 0.4), // Purple
                            const Color(0xFF6366F1).withValues(alpha: 0.4), // Blue
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // 4. Glassmorphic Card (Slides & Scales)
                Center(
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_cardSlideAnim, _cardScaleAnim]),
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _cardSlideAnim.value),
                        child: Transform.scale(
                          scale: _cardScaleAnim.value,
                          child: child,
                        ),
                      );
                    },
                    child: SizedBox(
                      width: cardWidth,
                      child: ShineSweepWidget(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF0B1020).withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 40,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 40,
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            clipBehavior: Clip.none,
                            children: [
                              // Main content
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Header: Glowing Rank Medallion
                                  _RankMedallion(
                                    level: widget.newLevel,
                                    scaleAnim: _glowScaleAnim,
                                  ),
                                  const SizedBox(height: 28),

                                  // Centered Title: THĂNG CẤP THÀNH CÔNG
                                  const _GradientTitle(),
                                  const SizedBox(height: 12),

                                  // Large Rank & Division title: e.g. LEGEND I
                                  _RankDivisionHeader(
                                    level: widget.newLevel,
                                    punchAnim: _punchAnim,
                                  ),
                                  const SizedBox(height: 24),

                                  // Level Progress Summary: Level 6 -> Level 7
                                  _LevelSummary(
                                    oldLevel: oldLevel,
                                    newLevel: widget.newLevel,
                                  ),
                                  const SizedBox(height: 28),

                                  // XP Reward Summary
                                  _XpRewardSummary(latestLog: latestLog),
                                ],
                              ),

                              // XP explosion particles overlay (centered in card)
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: AnimatedBuilder(
                                    animation: _particlesAnim,
                                    builder: (context, _) {
                                      return CustomPaint(
                                        painter: ParticleExplosionPainter(
                                          particles: _explosionParticles,
                                          progress: _particlesAnim.value,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Floating Background Background Particles Painter ────────────────────────

class FloatingParticlesPainter extends CustomPainter {
  final List<FloatingParticle> particles;
  final double progress;

  FloatingParticlesPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final p in particles) {
      double y = (p.baseY - progress * p.speed) % 1.0;
      double x = (p.baseX + 0.05 * math.sin(progress * 2 * math.pi * p.wobbleFreq)) % 1.0;

      final offset = Offset(x * size.width, y * size.height);
      paint.color = p.color.withValues(alpha: p.opacity);
      canvas.drawCircle(offset, p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant FloatingParticlesPainter oldDelegate) {
    return true;
  }
}

// ── Particle Explosion Painter ─────────────────────────────────────────────

class ParticleExplosionPainter extends CustomPainter {
  final List<ExplosionParticle> particles;
  final double progress;

  ParticleExplosionPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1.0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      final distance = p.speed * Curves.easeOutCubic.transform(progress);
      final dx = distance * math.cos(p.angle);
      final dy = distance * math.sin(p.angle);
      final offset = center + Offset(dx, dy);

      final opacity = (1.0 - progress).clamp(0.0, 1.0);
      paint.color = p.color.withValues(alpha: opacity);

      canvas.drawCircle(offset, p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ParticleExplosionPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// ── Shine Sweep Widget ──────────────────────────────────────────────────────

class ShineSweepWidget extends StatefulWidget {
  const ShineSweepWidget({super.key, required this.child});
  final Widget child;

  @override
  State<ShineSweepWidget> createState() => _ShineSweepWidgetState();
}

class _ShineSweepWidgetState extends State<ShineSweepWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _shineCtrl;

  @override
  void initState() {
    super.initState();
    _shineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Repeat sweep every 3 seconds
    Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        _shineCtrl.forward(from: 0.0);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _shineCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shineCtrl,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final double slideValue = lerpDouble(-1.5, 1.5, _shineCtrl.value)!;
            return LinearGradient(
              begin: Alignment(slideValue - 0.3, -1),
              end: Alignment(slideValue + 0.3, 1),
              colors: [
                Colors.transparent,
                Colors.white.withValues(alpha: 0.0),
                Colors.white.withValues(alpha: 0.25),
                Colors.white.withValues(alpha: 0.0),
                Colors.transparent,
              ],
              stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
      child: widget.child,
    );
  }
}

// ── Component Widgets ──────────────────────────────────────────────────────

class _RankMedallion extends StatefulWidget {
  final int level;
  final Animation<double> scaleAnim;
  const _RankMedallion({required this.level, required this.scaleAnim});

  @override
  State<_RankMedallion> createState() => _RankMedallionState();
}

class _RankMedallionState extends State<_RankMedallion> with SingleTickerProviderStateMixin {
  late final AnimationController _rotationCtrl;

  @override
  void initState() {
    super.initState();
    _rotationCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationCtrl.dispose();
    super.dispose();
  }

  IconData _getRankIcon(String name) {
    final lowercase = name.toLowerCase();
    if (lowercase.contains('eternal') || lowercase.contains('mythic') || lowercase.contains('legend')) {
      return Icons.emoji_events_rounded;
    } else if (lowercase.contains('master') || lowercase.contains('grandmaster')) {
      return Icons.bolt_rounded;
    } else if (lowercase.contains('elite')) {
      return Icons.diamond_rounded;
    } else if (lowercase.contains('challenger')) {
      return Icons.workspace_premium_rounded;
    } else if (lowercase.contains('explorer')) {
      return Icons.explore_rounded;
    } else if (lowercase.contains('apprentice')) {
      return Icons.military_tech_rounded;
    } else {
      return Icons.shield_rounded;
    }
  }

  Color _getRankColor(String name) {
    final lowercase = name.toLowerCase();
    if (lowercase.contains('rookie') || lowercase.contains('bronze')) {
      return const Color(0xFFCD7F32); // Bronze
    } else if (lowercase.contains('apprentice') || lowercase.contains('explorer') || lowercase.contains('silver')) {
      return const Color(0xFF94A3B8); // Silver
    } else if (lowercase.contains('challenger') || lowercase.contains('gold')) {
      return const Color(0xFFFFD700); // Gold
    } else if (lowercase.contains('elite') || lowercase.contains('platinum')) {
      return const Color(0xFF38BDF8); // Platinum
    } else if (lowercase.contains('master') || lowercase.contains('grandmaster')) {
      return const Color(0xFF10B981); // Emerald
    } else {
      return const Color(0xFFD946EF); // Cosmic purple/magenta for Legend+
    }
  }

  @override
  Widget build(BuildContext context) {
    final rank = leveling.xpRankForLevel(widget.level);
    final rankColor = _getRankColor(rank.name);
    final rankIcon = _getRankIcon(rank.name);

    return ScaleTransition(
      scale: widget.scaleAnim,
      child: Container(
        width: 140,
        height: 140,
        alignment: Alignment.center,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer glowing aura
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: rankColor.withValues(alpha: 0.35),
                    blurRadius: 40,
                    spreadRadius: 6,
                  ),
                ],
              ),
            ),
            
            // Rotating outer ring dashes
            RotationTransition(
              turns: _rotationCtrl,
              child: CustomPaint(
                size: const Size(130, 130),
                painter: _MedallionRingPainter(color: rankColor),
              ),
            ),

            // Inner solid metal border
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF111827).withValues(alpha: 0.9),
                border: Border.all(
                  color: rankColor,
                  width: 3.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Icon(
                rankIcon,
                color: rankColor,
                size: 48,
              ),
            ),

            // Floating Level indicator pill at the bottom
            Positioned(
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      rankColor,
                      rankColor.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF0F1322),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: rankColor.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'LVL ${widget.level}',
                  style: GoogleFonts.jetBrainsMono(
                    color: const Color(0xFF0F1322),
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
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

class _MedallionRingPainter extends CustomPainter {
  final Color color;
  const _MedallionRingPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    for (int i = 0; i < 4; i++) {
      final startAngle = i * (math.pi / 2) + 0.15;
      final sweepAngle = (math.pi / 2) - 0.3;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GradientTitle extends StatelessWidget {
  const _GradientTitle();

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Color(0xFFFDE047), Color(0xFFFACC15), Color(0xFFCA8A04)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds),
      child: Text(
        'THĂNG CẤP THÀNH CÔNG',
        textAlign: TextAlign.center,
        style: GoogleFonts.interTight(
          fontSize: 13,
          fontWeight: FontWeight.w900,
          letterSpacing: 2.5,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _RankDivisionHeader extends StatelessWidget {
  final int level;
  final Animation<double> punchAnim;
  const _RankDivisionHeader({required this.level, required this.punchAnim});

  Color _getRankColor(String name) {
    final lowercase = name.toLowerCase();
    if (lowercase.contains('rookie') || lowercase.contains('bronze')) {
      return const Color(0xFFCD7F32); // Bronze
    } else if (lowercase.contains('apprentice') || lowercase.contains('explorer') || lowercase.contains('silver')) {
      return const Color(0xFF94A3B8); // Silver
    } else if (lowercase.contains('challenger') || lowercase.contains('gold')) {
      return const Color(0xFFFFD700); // Gold
    } else if (lowercase.contains('elite') || lowercase.contains('platinum')) {
      return const Color(0xFF38BDF8); // Platinum
    } else if (lowercase.contains('master') || lowercase.contains('grandmaster')) {
      return const Color(0xFF10B981); // Emerald
    } else {
      return const Color(0xFFD946EF); // Cosmic purple/magenta for Legend+
    }
  }

  @override
  Widget build(BuildContext context) {
    final rank = leveling.xpRankForLevel(level);
    final rankName = rank.name.toUpperCase();
    final rankDivision = rank.division;
    final rankColor = _getRankColor(rank.name);

    return AnimatedBuilder(
      animation: punchAnim,
      builder: (context, child) {
        final double punchVal = punchAnim.value;
        final double scale = 1.0 + 0.08 * math.sin(punchVal * math.pi);

        return Transform.scale(
          scale: scale,
          child: Text(
            '$rankName $rankDivision',
            textAlign: TextAlign.center,
            style: GoogleFonts.interTight(
              fontSize: 40,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.5,
              shadows: [
                Shadow(
                  color: rankColor.withValues(alpha: 0.6),
                  blurRadius: 25,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LevelSummary extends StatelessWidget {
  const _LevelSummary({required this.oldLevel, required this.newLevel});
  final int oldLevel;
  final int newLevel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Level $oldLevel',
          style: GoogleFonts.inter(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 16),
        const _SlidingArrow(),
        const SizedBox(width: 16),
        Text(
          'Level $newLevel',
          style: GoogleFonts.inter(
            color: const Color(0xFF67E8F9),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _SlidingArrow extends StatefulWidget {
  const _SlidingArrow();

  @override
  State<_SlidingArrow> createState() => _SlidingArrowState();
}

class _SlidingArrowState extends State<_SlidingArrow>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
    _slide = Tween<double>(begin: -4.0, end: 4.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slide,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_slide.value, 0),
          child: const Icon(
            Icons.arrow_forward_rounded,
            color: Color(0xFF8B5CF6),
            size: 20,
          ),
        );
      },
    );
  }
}

class _XpRewardSummary extends StatelessWidget {
  const _XpRewardSummary({required this.latestLog});
  final XpLogModel? latestLog;

  @override
  Widget build(BuildContext context) {
    if (latestLog == null) {
      return const SizedBox.shrink();
    }

    final hasLucky = latestLog!.hasLuckyBonus;
    const tierValues = [100, 50, 20, 10];
    int baseXp = 10;
    for (final t in tierValues) {
      if (latestLog!.xpGained >= t) {
        baseXp = t;
        break;
      }
    }
    final bonusXp = hasLucky ? (latestLog!.xpGained - baseXp).clamp(0, 15) : 0;
    final baseGained = latestLog!.xpGained - bonusXp;

    final rawReason = latestLog!.reason;
    final baseReason = rawReason.replaceAll(RegExp(r'\(?Lucky.*', caseSensitive: false), '').trim();
    final displayReason = baseReason.isNotEmpty ? baseReason : 'Task Completed';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF070B19),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.04),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'XP REWARDS',
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          // Base reward row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                displayReason,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                '+$baseGained XP',
                style: GoogleFonts.jetBrainsMono(
                  color: const Color(0xFF67E8F9),
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          if (bonusXp > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Lucky Bonus',
                  style: GoogleFonts.inter(
                    color: const Color(0xFFFFD700),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '+$bonusXp XP',
                  style: GoogleFonts.jetBrainsMono(
                    color: const Color(0xFFFFD700),
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
