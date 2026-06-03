import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'edit_profile_shared.dart';

class ProfileCompletionCard extends StatefulWidget {
  const ProfileCompletionCard({
    required this.avatarUrlController,
    required this.usernameController,
    required this.fullNameController,
    required this.bioController,
    super.key,
  });

  final TextEditingController avatarUrlController;
  final TextEditingController usernameController;
  final TextEditingController fullNameController;
  final TextEditingController bioController;

  @override
  State<ProfileCompletionCard> createState() => _ProfileCompletionCardState();
}

class _ProfileCompletionCardState extends State<ProfileCompletionCard> with SingleTickerProviderStateMixin {
  double _oldPercent = 0.0;
  double _newPercent = 0.0;
  bool _showCelebration = false;

  Timer? _celebrationTimer;
  List<_ConfettiParticle> _particles = [];
  Ticker? _ticker;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _newPercent = _calculatePercent();
    _oldPercent = _newPercent;

    widget.avatarUrlController.addListener(_onControllersChanged);
    widget.usernameController.addListener(_onControllersChanged);
    widget.fullNameController.addListener(_onControllersChanged);
    widget.bioController.addListener(_onControllersChanged);
  }

  @override
  void dispose() {
    widget.avatarUrlController.removeListener(_onControllersChanged);
    widget.usernameController.removeListener(_onControllersChanged);
    widget.fullNameController.removeListener(_onControllersChanged);
    widget.bioController.removeListener(_onControllersChanged);
    _celebrationTimer?.cancel();
    _ticker?.dispose();
    super.dispose();
  }

  double _calculatePercent() {
    final hasAvatar = widget.avatarUrlController.text.trim().isNotEmpty;
    final hasBio = widget.bioController.text.trim().isNotEmpty;
    final hasFullName = widget.fullNameController.text.trim().isNotEmpty;
    final hasUsername = widget.usernameController.text.trim().isNotEmpty;

    final items = [hasAvatar, hasBio, hasFullName, hasUsername];
    final completedCount = items.where((val) => val).length;
    return items.isEmpty ? 0.0 : (completedCount / items.length);
  }

  void _onControllersChanged() {
    final computed = _calculatePercent();
    if (computed != _newPercent) {
      setState(() {
        _oldPercent = _newPercent;
        _newPercent = computed;

        if (_newPercent == 1.0 && _oldPercent < 1.0) {
          _triggerCelebration();
        }
      });
    }
  }

  void _triggerCelebration() {
    _celebrationTimer?.cancel();
    _ticker?.stop();

    setState(() {
      _showCelebration = true;
      _particles = List.generate(60, (index) => _ConfettiParticle.random(_random));
    });

    _ticker = createTicker((elapsed) {
      setState(() {
        for (final p in _particles) {
          p.update();
        }
      });
    });
    _ticker!.start();

    _celebrationTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showCelebration = false;
        });
        _ticker?.stop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasAvatar = widget.avatarUrlController.text.trim().isNotEmpty;
    final hasBio = widget.bioController.text.trim().isNotEmpty;
    final hasFullName = widget.fullNameController.text.trim().isNotEmpty;
    final hasUsername = widget.usernameController.text.trim().isNotEmpty;

    final items = [
      _CompletionItem('Avatar & Identity', hasAvatar),
      _CompletionItem('Professional Bio', hasBio),
      _CompletionItem('Legal Full Name', hasFullName),
      _CompletionItem('Public Username', hasUsername),
    ];

    return EditProfileGlassCard(
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Profile Completion',
                style: TextStyle(
                  color: EditProfileColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: SizedBox(
                  width: 140,
                  height: 140,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: _oldPercent, end: _newPercent),
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.easeInOutCubic,
                        builder: (context, val, _) {
                          return SizedBox.expand(
                            child: CircularProgressIndicator(
                              value: val,
                              strokeWidth: 8,
                              strokeCap: StrokeCap.round,
                              backgroundColor: Colors.white.withValues(alpha: 0.05),
                              valueColor: const AlwaysStoppedAnimation(EditProfileColors.primary),
                            ),
                          );
                        },
                      ),
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: _oldPercent, end: _newPercent),
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.easeInOutCubic,
                        builder: (context, val, _) {
                          return Text(
                            '${(val * 100).round()}%',
                            style: const TextStyle(
                              color: EditProfileColors.textPrimary,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Column(
                children: items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Icon(
                          item.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: item.isCompleted ? EditProfileColors.success : EditProfileColors.textOutline.withValues(alpha: 0.6),
                          size: 18,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          item.label,
                          style: TextStyle(
                            color: item.isCompleted ? EditProfileColors.success : EditProfileColors.textSecondary,
                            fontSize: 14,
                            fontWeight: item.isCompleted ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          if (_showCelebration)
            Positioned.fill(
              child: AnimatedOpacity(
                opacity: _showCelebration ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _ConfettiPainter(_particles),
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.elasticOut,
                              builder: (context, scale, child) {
                                return Transform.scale(scale: scale, child: child);
                              },
                              child: const Text(
                                '🎉',
                                style: TextStyle(fontSize: 48),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Profile Completed',
                              style: TextStyle(
                                color: EditProfileColors.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Your profile is now fully optimized.',
                              style: TextStyle(
                                color: EditProfileColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CompletionItem {
  _CompletionItem(this.label, this.isCompleted);
  final String label;
  final bool isCompleted;
}

class _ConfettiParticle {
  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
  });

  double x;
  double y;
  double vx;
  double vy;
  Color color;
  double size;
  double rotation;
  double rotationSpeed;

  static const List<Color> confettiColors = [
    Color(0xFF7C5CFF),
    Color(0xFF48CAE4),
    Colors.white,
  ];

  factory _ConfettiParticle.random(math.Random rand) {
    return _ConfettiParticle(
      x: rand.nextDouble() * 200 - 100,
      y: -10.0,
      vx: rand.nextDouble() * 4 - 2,
      vy: rand.nextDouble() * 4 + 2,
      color: confettiColors[rand.nextInt(confettiColors.length)],
      size: rand.nextDouble() * 6 + 6,
      rotation: rand.nextDouble() * 2 * math.pi,
      rotationSpeed: rand.nextDouble() * 0.1 - 0.05,
    );
  }

  void update() {
    x += vx;
    y += vy;
    vy += 0.08;
    rotation += rotationSpeed;
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.particles);
  final List<_ConfettiParticle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, 0);

    for (final p in particles) {
      paint.color = p.color;
      canvas.save();
      canvas.translate(center.dx + p.x, p.y);
      canvas.rotate(p.rotation);
      final rect = Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size / 2);
      canvas.drawRect(rect, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}
