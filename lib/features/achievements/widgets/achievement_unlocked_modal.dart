import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/dashboard_theme.dart';
import 'package:to_do_app/features/achievements/domain/achievement.dart';
import 'package:to_do_app/features/achievements/widgets/badge_widget.dart';
import 'package:to_do_app/features/profile/presentation/providers/profile_provider.dart';

/// State provider to hold the queue of achievements pending celebration overlay.
class AchievementNotificationNotifier extends Notifier<List<Achievement>> {
  @override
  List<Achievement> build() => [];

  void queue(Achievement achievement) {
    if (state.any((a) => a.id == achievement.id)) return;
    state = [...state, achievement];
  }

  void dismissCurrent() {
    if (state.isNotEmpty) {
      state = state.sublist(1);
    }
  }
}

final achievementNotificationProvider =
    NotifierProvider<AchievementNotificationNotifier, List<Achievement>>(
  AchievementNotificationNotifier.new,
);

class AchievementUnlockedModal extends ConsumerStatefulWidget {
  const AchievementUnlockedModal({
    super.key,
    required this.achievement,
    required this.onContinue,
  });

  final Achievement achievement;
  final VoidCallback onContinue;

  @override
  ConsumerState<AchievementUnlockedModal> createState() =>
      _AchievementUnlockedModalState();
}

class _AchievementUnlockedModalState extends ConsumerState<AchievementUnlockedModal>
    with TickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final AnimationController _floatCtrl;
  late final AnimationController _shimmerCtrl;
  late final AnimationController _premiumParticleCtrl;
  late final AnimationController _orbitCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _sweepCtrl;
  
  late final Animation<double> _scaleAnim;
  late final Animation<double> _opacityAnim;
  late final Animation<double> _badgeScale;
  late final Animation<double> _badgeRotation;
  late final Animation<double> _ringProgress;
  late final Animation<double> _borderGlow;

  bool _exiting = false;
  final List<_ParticleModel> _particles = [];
  final List<_PremiumParticle> _premiumParticles = [];
  Timer? _particleTimer;

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _premiumParticleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _orbitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _sweepCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _scaleAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.0, 0.8, curve: Curves.elasticOut),
      ),
    );

    _opacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _badgeScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.25).chain(CurveTween(curve: Curves.easeOut)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.25, end: 1.0).chain(CurveTween(curve: Curves.bounceOut)),
        weight: 40,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.2, 0.9),
      ),
    );

    _badgeRotation = Tween<double>(begin: -30.0 * math.pi / 180.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.2, 0.9, curve: Curves.easeOutBack),
      ),
    );

    _ringProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    _borderGlow = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 70,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.4, 1.0),
      ),
    );

    _initPremiumParticles();

    _entryCtrl.forward();
    _generateParticles();

    // Re-trigger sparkle burst occasionally for atmosphere (every 4 seconds like HTML)
    _particleTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted && !_exiting) {
        setState(() {
          _generateParticles();
        });
      }
    });
  }

  void _initPremiumParticles() {
    final random = math.Random(101);
    final count = 100;
    
    final colors = <Color>[];
    switch (widget.achievement.rarity) {
      case AchievementRarity.bronze:
        colors.addAll([const Color(0xFFCD7F32), const Color(0xFFB87333)]);
        break;
      case AchievementRarity.silver:
        colors.addAll([const Color(0xFFC0C1FF), const Color(0xFFE0E0E0), Colors.white]);
        break;
      case AchievementRarity.gold:
        colors.addAll([const Color(0xFFFFD700), const Color(0xFFFFB300), const Color(0xFFFFF9C4)]);
        break;
      case AchievementRarity.diamond:
        colors.addAll([const Color(0xFF59D5FF), const Color(0xFF00E5FF), Colors.white]);
        break;
      case AchievementRarity.elite:
        colors.addAll([const Color(0xFF00FFC6), const Color(0xFF00BFA5), const Color(0xFFE0F2F1)]);
        break;
      case AchievementRarity.master:
        colors.addAll([const Color(0xFF9C27B0), const Color(0xFFBA68C8), const Color(0xFFE1BEE7)]);
        break;
      case AchievementRarity.challenger:
      case AchievementRarity.grandmaster:
      case AchievementRarity.supreme:
        colors.addAll([const Color(0xFFFF3D00), const Color(0xFFFF9100), const Color(0xFFFFEA00)]);
        break;
      case AchievementRarity.legend:
        colors.addAll([const Color(0xFFFF9800), const Color(0xFFFFD700), const Color(0xFFFFF9C4)]);
        break;
      case AchievementRarity.mythic:
        colors.addAll([const Color(0xFFE91E63), const Color(0xFF9C27B0), const Color(0xFF00E5FF), const Color(0xFF29B6F6)]);
        break;
      default:
        colors.add(const Color(0xFFFFD700));
    }

    for (int i = 0; i < count; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final speed = 300.0 + random.nextDouble() * 350.0; // Spray far beyond the 300px card boundary
      final delay = random.nextDouble();
      final duration = 0.3 + random.nextDouble() * 0.4;
      final layer = i % 3;

      double size = 4.0;
      if (layer == 0) size = 2.0 + random.nextDouble() * 2.0;
      else if (layer == 1) size = 4.0 + random.nextDouble() * 2.0;
      else size = 6.0 + random.nextDouble() * 3.0;

      _premiumParticles.add(
        _PremiumParticle(
          angle: angle,
          speed: speed,
          maxSize: size,
          color: colors[random.nextInt(colors.length)],
          delay: delay,
          duration: duration,
          shapeType: random.nextInt(3),
          curveAmp: random.nextDouble() * 12.0,
          curveFreq: 1.0 + random.nextDouble() * 2.0,
          rotSpeed: (random.nextDouble() - 0.5) * 4 * math.pi,
        ),
      );
    }
  }

  void _generateParticles() {
    _particles.clear();
    final random = math.Random();
    final icons = ['✨', '⭐', '🔥', '✨', '⚡'];
    final count = 24;

    for (int i = 0; i < count; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final distance = 280.0 + random.nextDouble() * 260.0; // Emojis float outside the card borders
      final delay = random.nextDouble() * 0.5;

      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1500),
      );

      final model = _ParticleModel(
        emoji: icons[random.nextInt(icons.length)],
        angle: angle,
        distance: distance,
        controller: controller,
      );

      _particles.add(model);

      Future.delayed(Duration(milliseconds: (delay * 1000).round()), () {
        if (mounted) {
          controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _particleTimer?.cancel();
    for (final p in _particles) {
      p.controller.dispose();
    }
    _entryCtrl.dispose();
    _floatCtrl.dispose();
    _shimmerCtrl.dispose();
    _premiumParticleCtrl.dispose();
    _orbitCtrl.dispose();
    _pulseCtrl.dispose();
    _sweepCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleDismiss() async {
    if (_exiting) return;
    setState(() => _exiting = true);
    widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final levelProgress = profile != null && profile.nextLevelXp > 0
        ? (profile.currentXp / profile.nextLevelXp).clamp(0.0, 1.0)
        : 0.70;

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handleDismiss,
        child: Stack(
          children: [
            // 1. Backdrop Blur Overlay
            Positioned.fill(
              child: FadeTransition(
                opacity: _opacityAnim,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),

            // Concentric rings, premium particles, and simple floaters clipped to only appear around the modal card
            Positioned.fill(
              child: IgnorePointer(
                child: ClipPath(
                  clipper: _ModalExcludeClipper(),
                  child: Stack(
                    children: [
                      // Concentric shockwave expanding rings
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _RingPainter(
                            progress: _ringProgress,
                            color: widget.achievement.rarity.color,
                          ),
                        ),
                      ),

                      // Premium particle canvas layer
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _PremiumParticlePainter(
                            particles: _premiumParticles,
                            progress: _premiumParticleCtrl,
                          ),
                        ),
                      ),

                      // Animated Particle Layer (Simple emoji floaters)
                      Positioned.fill(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final center = Offset(constraints.maxWidth / 2, constraints.maxHeight * 0.5);
                            return Stack(
                              children: _particles.map((p) {
                                return AnimatedBuilder(
                                  animation: p.controller,
                                  builder: (context, child) {
                                    final progress = p.controller.value;
                                    if (progress == 0.0) return const SizedBox.shrink();

                                    final currentDistance = p.distance * progress;
                                    final dx = math.cos(p.angle) * currentDistance;
                                    final dy = math.sin(p.angle) * currentDistance;
                                    final opacity = (1.0 - progress).clamp(0.0, 1.0);
                                    final scale = progress.clamp(0.2, 1.0);

                                    return Positioned(
                                      left: center.dx + dx - 12,
                                      top: center.dy + dy - 12,
                                      child: Opacity(
                                        opacity: opacity,
                                        child: Transform.scale(
                                          scale: scale,
                                          child: Text(
                                            p.emoji,
                                            style: const TextStyle(fontSize: 24),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 3. Modal Card (Drawn on top of the background layers)
            Center(
              child: ScaleTransition(
                scale: _scaleAnim,
                child: FadeTransition(
                  opacity: _opacityAnim,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GestureDetector(
                      onTap: () {}, // Absorb taps on the card itself so it doesn't trigger dismissal
                      child: AnimatedBuilder(
                        animation: _borderGlow,
                        builder: (context, child) {
                          final glowVal = _borderGlow.value;
                          final rarityColor = widget.achievement.rarity.color;

                          return Container(
                            width: 600,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(32),
                              border: Border.all(
                                color: Color.lerp(
                                  Colors.white.withValues(alpha: 0.12),
                                  rarityColor.withValues(alpha: 0.8),
                                  glowVal,
                                )!,
                                width: 1.0 + 1.5 * glowVal,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.55),
                                  blurRadius: 40,
                                  offset: const Offset(0, 16),
                                ),
                                if (glowVal > 0.01)
                                  BoxShadow(
                                    color: rarityColor.withValues(alpha: 0.3 * glowVal),
                                    blurRadius: 20 + 20 * glowVal,
                                    spreadRadius: 2 * glowVal,
                                  ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: child,
                          );
                        },
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withValues(alpha: 0.05),
                                  Colors.white.withValues(alpha: 0.01),
                                ],
                              ),
                            ),
                            padding: const EdgeInsets.all(32),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final isSmall = constraints.maxWidth < 450;
                                final content = [
                                  // Left/Top Panel: Badge with all enhanced wrappers
                                  AnimatedBuilder(
                                    animation: Listenable.merge([_badgeScale, _badgeRotation]),
                                    builder: (context, child) {
                                      return Transform.scale(
                                        scale: _badgeScale.value,
                                        child: Transform.rotate(
                                          angle: _badgeRotation.value,
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // Soft Glow behind Badge (Pulsing dynamically)
                                        AnimatedBuilder(
                                          animation: _pulseCtrl,
                                          builder: (context, child) {
                                            final pulse = _pulseCtrl.value;
                                            final radius = 30.0 + 20.0 * pulse;
                                            final spread = 5.0 + 8.0 * pulse;
                                            final opacity = 0.08 + 0.12 * pulse;

                                            return Container(
                                              width: 180,
                                              height: 180,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: widget.achievement.rarity.color.withValues(alpha: opacity),
                                                    blurRadius: radius,
                                                    spreadRadius: spread,
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),

                                        // 3D Perspective Orbit Sparkles
                                        CustomPaint(
                                          size: const Size(180, 180),
                                          painter: _OrbitPainter(
                                            progress: _orbitCtrl,
                                            color: widget.achievement.rarity.color,
                                          ),
                                        ),

                                        // Floating and Shimmering Badge Widget
                                        AnimatedBuilder(
                                          animation: _floatCtrl,
                                          builder: (context, child) {
                                            final bobbing = math.sin(_floatCtrl.value * 2 * math.pi) * 6.0;
                                            final tilt = math.sin(_floatCtrl.value * 2 * math.pi) * 0.02;

                                            return Transform.translate(
                                              offset: Offset(0, bobbing),
                                              child: Transform.rotate(
                                                angle: tilt,
                                                child: AnimatedBuilder(
                                                  animation: _sweepCtrl,
                                                  builder: (context, child) {
                                                    final progress = _sweepCtrl.value;
                                                    final offset = -1.5 + 3.0 * progress;

                                                    return ShaderMask(
                                                      blendMode: BlendMode.srcATop,
                                                      shaderCallback: (bounds) {
                                                        return LinearGradient(
                                                          begin: Alignment(offset - 0.4, -0.4),
                                                          end: Alignment(offset + 0.4, 0.4),
                                                          colors: const [
                                                            Colors.transparent,
                                                            Colors.white10,
                                                            Colors.white70,
                                                            Colors.white10,
                                                            Colors.transparent,
                                                          ],
                                                          stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                                                        ).createShader(bounds);
                                                      },
                                                      child: child,
                                                    );
                                                  },
                                                  child: AnimatedBuilder(
                                                    animation: _shimmerCtrl,
                                                    builder: (context, child) {
                                                      final bright = 1.0 + 0.15 * _shimmerCtrl.value;
                                                      return ColorFiltered(
                                                        colorFilter: ColorFilter.matrix([
                                                          bright, 0, 0, 0, 0,
                                                          0, bright, 0, 0, 0,
                                                          0, 0, bright, 0, 0,
                                                          0, 0, 0, 1, 0,
                                                        ]),
                                                        child: BadgeWidget(
                                                          rarity: widget.achievement.rarity,
                                                          icon: widget.achievement.icon,
                                                          svgName: widget.achievement.svgName,
                                                          size: 160,
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSmall) const SizedBox(height: 24) else const SizedBox(width: 32),
                                  // Right/Bottom Panel: Text content
                                  Expanded(
                                    flex: isSmall ? 0 : 1,
                                    child: Column(
                                      crossAxisAlignment: isSmall
                                          ? CrossAxisAlignment.center
                                          : CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'ACHIEVEMENT UNLOCKED',
                                          style: TextStyle(
                                            color: DashboardColors.onSurfaceVariant.withValues(alpha: 0.7),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 2.5,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        // Gradient Title
                                        ShaderMask(
                                          shaderCallback: (bounds) => const LinearGradient(
                                            colors: [
                                              Color(0xFFFFD54F),
                                              Color(0xFFFF8A65),
                                            ],
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                          ).createShader(bounds),
                                          child: Text(
                                            widget.achievement.name,
                                            textAlign: isSmall ? TextAlign.center : TextAlign.left,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 28,
                                              fontWeight: FontWeight.w900,
                                              height: 1.1,
                                              letterSpacing: -0.5,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          widget.achievement.description,
                                          textAlign: isSmall ? TextAlign.center : TextAlign.left,
                                          style: TextStyle(
                                            color: DashboardColors.onSurface.withValues(alpha: 0.8),
                                            fontSize: 14,
                                            height: 1.4,
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        // XP Badge & Level Progress Row
                                        Row(
                                          children: [
                                            // XP Pill
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 0.04),
                                                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.bolt_rounded,
                                                    color: Color(0xFFFFB300),
                                                    size: 16,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '+${widget.achievement.xpReward} XP',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            // Level Progress Bar
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          'Level Up Progress',
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: TextStyle(
                                                            color: DashboardColors.onSurfaceVariant.withValues(alpha: 0.6),
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.w800,
                                                            letterSpacing: 0.5,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        '${(levelProgress * 100).toStringAsFixed(0)}%',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  ClipRRect(
                                                    borderRadius: BorderRadius.circular(999),
                                                    child: Container(
                                                      height: 6,
                                                      color: Colors.white.withValues(alpha: 0.05),
                                                      child: FractionallySizedBox(
                                                        widthFactor: levelProgress,
                                                        alignment: Alignment.centerLeft,
                                                        child: Container(
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFFC0C1FF),
                                                            borderRadius: BorderRadius.circular(999),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 28),
                                        // Continue Button
                                        _PremiumButton(
                                          onPressed: _handleDismiss,
                                          label: 'Continue',
                                        ),
                                      ],
                                    ),
                                  ),
                                ];

                                return isSmall
                                    ? Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: content,
                                      )
                                    : Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: content,
                                      );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
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

class _PremiumButton extends StatefulWidget {
  const _PremiumButton({required this.onPressed, required this.label});

  final VoidCallback onPressed;
  final String label;

  @override
  State<_PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<_PremiumButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF635BFF),
                Color(0xFFC0C1FF),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF635BFF).withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _ParticleModel {
  _ParticleModel({
    required this.emoji,
    required this.angle,
    required this.distance,
    required this.controller,
  });

  final String emoji;
  final double angle;
  final double distance;
  final AnimationController controller;
}

class _PremiumParticle {
  _PremiumParticle({
    required this.angle,
    required this.speed,
    required this.maxSize,
    required this.color,
    required this.delay,
    required this.duration,
    required this.shapeType,
    required this.curveAmp,
    required this.curveFreq,
    required this.rotSpeed,
  });

  final double angle;
  final double speed;
  final double maxSize;
  final Color color;
  final double delay;
  final double duration;
  final int shapeType;
  final double curveAmp;
  final double curveFreq;
  final double rotSpeed;
}

class _PremiumParticlePainter extends CustomPainter {
  _PremiumParticlePainter({
    required this.particles,
    required this.progress,
  }) : super(repaint: progress);

  final List<_PremiumParticle> particles;
  final Animation<double> progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.5);
    final t = progress.value;

    for (final p in particles) {
      double particleTime = (t - p.delay) % 1.0;
      if (particleTime < 0.0) particleTime += 1.0;

      if (particleTime > p.duration) continue;

      final life = particleTime / p.duration;
      final currentDist = p.speed * life;
      final wave = p.curveAmp * math.sin(life * p.curveFreq * 2 * math.pi);

      double x = math.cos(p.angle) * currentDist - math.sin(p.angle) * wave;
      double y = math.sin(p.angle) * currentDist + math.cos(p.angle) * wave;

      // Gravity effect pulling down
      y += 40.0 * life * life;

      final currentOpacity = (1.0 - life).clamp(0.0, 1.0);
      double opacity = currentOpacity;
      if (life < 0.2) {
        opacity = (life / 0.2) * currentOpacity;
      }

      double currentScale = 1.0;
      if (life < 0.2) {
        currentScale = life / 0.2;
      } else {
        currentScale = 1.0 - (life - 0.2) / 0.8;
      }
      final particleSize = p.maxSize * currentScale;

      if (particleSize <= 0.1 || opacity <= 0.01) continue;

      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(center.dx + x, center.dy + y);
      canvas.rotate(p.rotSpeed * life);

      if (p.shapeType == 0) {
        final glowPaint = Paint()
          ..color = p.color.withValues(alpha: opacity * 0.4)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, particleSize * 0.5);
        canvas.drawCircle(Offset.zero, particleSize * 1.5, glowPaint);
        canvas.drawCircle(Offset.zero, particleSize, paint);
      } else if (p.shapeType == 1) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: '✨',
            style: TextStyle(
              fontSize: particleSize * 2.8,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(
          canvas,
          Offset(-textPainter.width / 2, -textPainter.height / 2),
        );
      } else {
        final textPainter = TextPainter(
          text: TextSpan(
            text: '🏆',
            style: TextStyle(
              fontSize: particleSize * 2.8,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(
          canvas,
          Offset(-textPainter.width / 2, -textPainter.height / 2),
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _PremiumParticlePainter oldDelegate) => true;
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.5);
    final t = progress.value;
    if (t <= 0.0 || t >= 1.0) return;

    for (int i = 0; i < 2; i++) {
      final ringT = (t - (i * 0.15)).clamp(0.0, 1.0);
      if (ringT <= 0.0 || ringT >= 1.0) continue;

      final radius = 240.0 + 360.0 * ringT; // Expands from 240 to 600
      final opacity = (1.0 - ringT) * 0.4;

      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0 * (1.0 - ringT);

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => true;
}

class _OrbitPainter extends CustomPainter {
  _OrbitPainter({
    required this.progress,
    required this.color,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final t = progress.value;

    for (int i = 0; i < 3; i++) {
      final angle = t * 2 * math.pi + (i * 2 * math.pi / 3);
      final rx = 85.0;
      final ry = 35.0;

      final x = rx * math.cos(angle);
      final y = ry * math.sin(angle);

      final tiltedX = x * math.cos(0.2) - y * math.sin(0.2);
      final tiltedY = x * math.sin(0.2) + y * math.cos(0.2);

      final isFront = y > 0;
      final sizeFactor = isFront ? 1.2 : 0.6;
      final sparkleSize = 8.0 * sizeFactor;
      final opacity = isFront ? 1.0 : 0.4;

      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(center.dx + tiltedX, center.dy + tiltedY);
      canvas.rotate(angle * 2);

      final path = Path()
        ..moveTo(0, -sparkleSize)
        ..quadraticBezierTo(0, 0, sparkleSize, 0)
        ..quadraticBezierTo(0, 0, 0, sparkleSize)
        ..quadraticBezierTo(0, 0, -sparkleSize, 0)
        ..quadraticBezierTo(0, 0, 0, -sparkleSize)
        ..close();

      canvas.drawPath(path, paint);
      canvas.drawCircle(Offset.zero, sparkleSize * 0.2, Paint()..color = Colors.white.withValues(alpha: opacity));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter oldDelegate) => true;
}

class _ModalExcludeClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final cardWidth = math.min(600.0, size.width - 32.0);
    final isSmall = size.width < 450;
    final cardHeight = isSmall ? 520.0 : 310.0;

    final cardRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.5),
        width: cardWidth,
        height: cardHeight,
      ),
      const Radius.circular(32),
    );

    path.addRRect(cardRect);
    path.fillType = PathFillType.evenOdd;
    return path;
  }

  @override
  bool shouldReclip(covariant _ModalExcludeClipper oldClipper) => true;
}
