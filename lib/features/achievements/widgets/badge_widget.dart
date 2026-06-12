import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:to_do_app/features/achievements/domain/achievement.dart';

class BadgeWidget extends StatefulWidget {
  const BadgeWidget({
    required this.rarity,
    required this.icon,
    this.svgName,
    this.size = 60,
    this.isLocked = false,
    super.key,
  });

  final AchievementRarity rarity;
  final IconData icon;
  final String? svgName;
  final double size;
  final bool isLocked;

  @override
  State<BadgeWidget> createState() => _BadgeWidgetState();
}

class _BadgeWidgetState extends State<BadgeWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getBadgePath(AchievementRarity rarity, String? svgName) {
    final slug = switch (rarity) {
      AchievementRarity.bronze => 'bronze',
      AchievementRarity.silver => 'silver',
      AchievementRarity.gold => 'gold',
      AchievementRarity.diamond => 'diamond',
      AchievementRarity.elite => 'elite',
      AchievementRarity.master => 'master',
      AchievementRarity.challenger => 'challenger',
      AchievementRarity.grandmaster => 'grandmaster',
      AchievementRarity.supreme => 'supreme_challenger', // maps to supreme directory or supreme_challenger in frames
      AchievementRarity.legend => 'legend',
      AchievementRarity.immortal => 'immortal',
      AchievementRarity.mythic => 'mythic',
    };
    
    // Fallback if no svgName is specified
    final iconName = svgName ?? 'special_milestone';
    
    return 'assets/badges/$slug/$iconName.svg';
  }

  String _getIconPath(String svgName) {
    final baseName = switch (svgName) {
      'tasks_completed' => 'shield_check',
      'tasks_created' => 'clipboard',
      'subtasks_completed' => 'checklist',
      'total_xp' => 'crystal',
      'level' => 'rocket',
      'rank_reached' => 'crown',
      'streak_count' => 'fire',
      'longest_streak' => 'flame_crown',
      'projects_created' => 'folder',
      'focus_sessions' => 'brain',
      'focus_minutes' => 'hourglass',
      'comments_created' => 'chat',
      'assigned_tasks' => 'users',
      'ai_tasks_created' => 'ai_chip',
      'completion_rate' => 'target',
      'perfect_tasks' => 'gem',
      'night_task' => 'moon',
      'early_task' => 'sunrise',
      'fast_completion' => 'lightning',
      'categories_created' => 'grid',
      'tags_created' => 'tag',
      'archived_tasks' => 'archive',
      'restored_tasks' => 'restore',
      'high_priority_tasks' => 'flag',
      'urgent_tasks' => 'siren',
      'due_date_completed' => 'calendar',
      'overdue_avoided' => 'shield_clock',
      'attachments_added' => 'paperclip',
      'special_milestone' => 'trophy',
      _ => svgName,
    };
    return 'assets/svg/achievements/icons/$baseName.svg';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLocked) {
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.04),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1.5),
        ),
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (widget.svgName != null)
                Opacity(
                  opacity: 0.15,
                  child: SvgPicture.asset(
                    _getIconPath(widget.svgName!),
                    width: widget.size * 0.45,
                    height: widget.size * 0.45,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              Icon(
                Icons.lock_outline_rounded,
                color: Colors.white.withValues(alpha: 0.3),
                size: widget.size * 0.38,
              ),
            ],
          ),
        ),
      );
    }

    final color = widget.rarity.color;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // 1. Aura & Custom Paint Effects behind the badge
            CustomPaint(
              size: Size(widget.size * 1.5, widget.size * 1.5),
              painter: _BadgeEffectPainter(
                rarity: widget.rarity,
                color: color,
                progress: _controller.value,
              ),
            ),

            // 2. Pre-rendered combined SVG Badge (Frame + Rank Border + Glowing Inner Plate + Icon)
            SvgPicture.asset(
              _getBadgePath(widget.rarity, widget.svgName),
              width: widget.size,
              height: widget.size,
            ),

            // 3. Floating Sparkle or Overlay Effect (Silver Shimmer)
            if (widget.rarity == AchievementRarity.silver)
              _ShimmerOverlay(size: widget.size, progress: _controller.value),
            if (widget.rarity == AchievementRarity.legend)
              Positioned(
                top: -widget.size * 0.08,
                child: Icon(
                  Icons.workspace_premium_rounded,
                  color: const Color(0xFFFFD700),
                  size: widget.size * 0.28,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ShimmerOverlay extends StatelessWidget {
  const _ShimmerOverlay({required this.size, required this.progress});

  final double size;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Colors.white.withValues(alpha: 0.15 * (math.sin(progress * math.pi * 2) + 1)),
              Colors.transparent,
            ],
            radius: 0.5,
          ),
        ),
      ),
    );
  }
}

class _BadgeEffectPainter extends CustomPainter {
  _BadgeEffectPainter({
    required this.rarity,
    required this.color,
    required this.progress,
  });

  final AchievementRarity rarity;
  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width / 3;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    switch (rarity) {
      case AchievementRarity.bronze:
        // Simple ring
        paint.color = color.withValues(alpha: 0.2);
        canvas.drawCircle(center, baseRadius + 4, paint);
        break;

      case AchievementRarity.silver:
        // Shiny rotating dash
        paint.color = color.withValues(alpha: 0.3);
        final dashCount = 8;
        final sweepAngle = (2 * math.pi) / (dashCount * 2);
        for (var i = 0; i < dashCount; i++) {
          final startAngle = (i * 2 * sweepAngle) + (progress * 2 * math.pi);
          canvas.drawArc(
            Rect.fromCircle(center: center, radius: baseRadius + 6),
            startAngle,
            sweepAngle,
            false,
            paint,
          );
        }
        break;

      case AchievementRarity.gold:
        // Soft pulsing ring glow
        final pulseRadius = baseRadius + 6 + 4 * math.sin(progress * math.pi * 2);
        paint.color = color.withValues(alpha: 0.35);
        paint.strokeWidth = 3;
        canvas.drawCircle(center, pulseRadius, paint);
        break;

      case AchievementRarity.diamond:
        // Crystalline double ring
        paint.color = color.withValues(alpha: 0.4);
        paint.strokeWidth = 1.5;
        canvas.drawCircle(center, baseRadius + 5, paint);
        paint.color = const Color(0xFF00E5FF).withValues(alpha: 0.2);
        canvas.drawCircle(center, baseRadius + 9, paint);
        break;

      case AchievementRarity.elite:
        // Orbiting energy dots
        final dots = 3;
        paint.style = PaintingStyle.fill;
        for (var i = 0; i < dots; i++) {
          final angle = (progress * 2 * math.pi) + (i * 2 * math.pi / dots);
          final dotOffset = Offset(
            center.dx + (baseRadius + 8) * math.cos(angle),
            center.dy + (baseRadius + 8) * math.sin(angle),
          );
          paint.color = color;
          canvas.drawCircle(dotOffset, 3, paint);
        }
        break;

      case AchievementRarity.master:
        // Purple pulsing rings
        paint.strokeWidth = 2;
        paint.color = color.withValues(alpha: 0.25);
        canvas.drawCircle(center, baseRadius + 6, paint);
        paint.color = color.withValues(alpha: 0.15);
        canvas.drawCircle(center, baseRadius + 12 + 2 * math.cos(progress * math.pi * 2), paint);
        break;

      case AchievementRarity.challenger:
        // Fiery flame sparkles
        final rng = math.Random(10);
        paint.style = PaintingStyle.fill;
        for (var i = 0; i < 6; i++) {
          final p = (progress + (i / 6.0)) % 1.0;
          final angle = rng.nextDouble() * 2 * math.pi + (progress * 0.5);
          final radius = baseRadius + 6 + (p * 14);
          final offset = Offset(
            center.dx + radius * math.cos(angle),
            center.dy - radius * math.sin(angle),
          );
          paint.color = const Color(0xFFFF9800).withValues(alpha: (1.0 - p) * 0.8);
          canvas.drawCircle(offset, 2.5 * (1.0 - p), paint);
        }
        break;

      case AchievementRarity.grandmaster:
        // Wing structures on the sides
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = 3;
        paint.color = color.withValues(alpha: 0.4);

        final wingPathLeft = Path()
          ..moveTo(center.dx - baseRadius - 2, center.dy)
          ..quadraticBezierTo(
            center.dx - baseRadius - 16,
            center.dy - 12,
            center.dx - baseRadius - 20,
            center.dy - 8,
          )
          ..quadraticBezierTo(
            center.dx - baseRadius - 12,
            center.dy + 8,
            center.dx - baseRadius - 2,
            center.dy + 12,
          );
        canvas.drawPath(wingPathLeft, paint);

        final wingPathRight = Path()
          ..moveTo(center.dx + baseRadius + 2, center.dy)
          ..quadraticBezierTo(
            center.dx + baseRadius + 16,
            center.dy - 12,
            center.dx + baseRadius + 20,
            center.dy - 8,
          )
          ..quadraticBezierTo(
            center.dx + baseRadius + 12,
            center.dy + 8,
            center.dx + baseRadius + 2,
            center.dy + 12,
          );
        canvas.drawPath(wingPathRight, paint);
        break;

      case AchievementRarity.supreme:
        // Double aura circles
        paint.strokeWidth = 1.5;
        paint.color = color.withValues(alpha: 0.3);
        canvas.drawCircle(center, baseRadius + 6, paint);
        paint.color = const Color(0xFFFF5252).withValues(alpha: 0.2);
        canvas.drawCircle(center, baseRadius + 12, paint);
        break;

      case AchievementRarity.legend:
        // Circular halo
        paint.strokeWidth = 1;
        paint.color = const Color(0xFFFFD700).withValues(alpha: 0.3);
        canvas.drawCircle(center, baseRadius + 10, paint);
        break;

      case AchievementRarity.immortal:
        // Pulsing orbital rings
        paint.strokeWidth = 2;
        paint.color = color.withValues(alpha: 0.35);
        canvas.drawCircle(center, baseRadius + 6, paint);
        final orbitalRadius = baseRadius + 10 + 4 * math.sin(progress * math.pi * 2);
        paint.color = color.withValues(alpha: 0.18);
        canvas.drawCircle(center, orbitalRadius, paint);
        break;

      case AchievementRarity.mythic:
        // Galaxy particles floating around
        final rng = math.Random(42);
        paint.style = PaintingStyle.fill;
        for (var i = 0; i < 10; i++) {
          final p = (progress + (i / 10.0)) % 1.0;
          final angle = rng.nextDouble() * 2 * math.pi + (progress * 0.2);
          final radius = baseRadius + 5 + (p * 18);
          final offset = Offset(
            center.dx + radius * math.cos(angle),
            center.dy + radius * math.sin(angle),
          );
          paint.color = (i % 2 == 0 ? const Color(0xFFE91E63) : const Color(0xFF9C27B0))
              .withValues(alpha: (1.0 - p) * 0.7);
          canvas.drawCircle(offset, 2 * (1.0 - p), paint);
        }
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _BadgeEffectPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.rarity != rarity ||
        oldDelegate.color != color;
  }
}
