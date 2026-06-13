import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';
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
  
  late final Animation<double> _scaleAnim;
  late final Animation<double> _opacityAnim;

  bool _exiting = false;
  final List<_ParticleModel> _particles = [];
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

  void _generateParticles() {
    _particles.clear();
    final random = math.Random();
    final icons = ['✨', '⭐', '🔥', '✨', '⚡'];
    final count = 24;

    for (int i = 0; i < count; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final distance = 100.0 + random.nextDouble() * 140.0;
      final delay = random.nextDouble() * 0.5; // Up to 500ms delay

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
    super.dispose();
  }

  Future<void> _handleDismiss() async {
    if (_exiting) return;
    setState(() => _exiting = true);

    _entryCtrl.duration = const Duration(milliseconds: 300);
    await _entryCtrl.reverse();
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

            // 2. Animated Particle Layer
            Positioned.fill(
              child: IgnorePointer(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final center = Offset(constraints.maxWidth / 2, constraints.maxHeight * 0.45);
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
            ),

            // 3. Modal Card
            Center(
              child: ScaleTransition(
                scale: _scaleAnim,
                child: FadeTransition(
                  opacity: _opacityAnim,
                  child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GestureDetector(
                        onTap: () {}, // Absorb taps on the card itself so it doesn't trigger dismissal
                        child: Container(
                          width: 600,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                              width: 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.55),
                                blurRadius: 40,
                                offset: const Offset(0, 16),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
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
                                // Left/Top Panel: Badge
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Soft Glow behind Badge
                                    Container(
                                      width: 180,
                                      height: 180,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: widget.achievement.rarity.color.withValues(alpha: 0.12),
                                            blurRadius: 40,
                                            spreadRadius: 10,
                                          ),
                                        ],
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
                                        );
                                      },
                                    ),
                                  ],
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
