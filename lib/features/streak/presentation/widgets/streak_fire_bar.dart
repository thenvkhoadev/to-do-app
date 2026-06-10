import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:to_do_app/features/streak/presentation/providers/streak_providers.dart';

class StreakFireBar extends ConsumerWidget {
  const StreakFireBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final streakDays = ref.watch(userStreakDaysProvider).valueOrNull ?? [];
    if (profile == null) return const SizedBox.shrink();

    final count = displayStreakCount(
      profile.streakCount,
      profile.lastActivityDate,
    );
    final activeKeys = streakDays
        .map((day) => _dayKey(day.activeDate))
        .toSet();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = List.generate(
      7,
      (index) => today.subtract(Duration(days: 6 - index)),
    );

    return Material(
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 360),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            decoration: BoxDecoration(
              color: const Color(0xEE0B0F1E),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF8A00).withValues(alpha: 0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 40,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFFFF8A00), Color(0xFFFF4500)],
                      ).createShader(bounds),
                      child: const Icon(
                        Icons.local_fire_department_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$count Day Streak',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Best: ${profile.longestStreak} Days • Keep the fire burning!',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (final day in days)
                      _FireCell(
                        active: activeKeys.contains(_dayKey(day)),
                        today: _sameDay(day, today),
                        date: day,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FireCell extends StatefulWidget {
  const _FireCell({
    required this.active,
    required this.today,
    required this.date,
  });

  final bool active;
  final bool today;
  final DateTime date;

  @override
  State<_FireCell> createState() => _FireCellState();
}

class _FireCellState extends State<_FireCell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
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
    final letter = _weekdayLetter(widget.date);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final pulse = 0.7 + math.sin(_controller.value * math.pi) * 0.3;
        
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: widget.active
                    ? const LinearGradient(
                        colors: [Color(0xFFFF8A00), Color(0xFFFF4500)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: widget.active ? null : Colors.white.withValues(alpha: 0.05),
                border: widget.today
                    ? Border.all(
                        color: const Color(0xFFC0C1FF).withValues(alpha: pulse),
                        width: 2,
                      )
                    : Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                        width: 1,
                      ),
                boxShadow: widget.active
                    ? [
                        BoxShadow(
                          color: const Color(0xFFFF4500).withValues(alpha: 0.35 * pulse),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ]
                    : (widget.today
                        ? [
                            BoxShadow(
                              color: const Color(0xFFC0C1FF).withValues(alpha: 0.15 * pulse),
                              blurRadius: 8,
                            ),
                          ]
                        : null),
              ),
              child: widget.active
                  ? Transform.scale(
                      scale: 0.94 + pulse * 0.08,
                      child: const Icon(
                        Icons.local_fire_department_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    )
                  : Text(
                      letter,
                      style: TextStyle(
                        color: widget.today
                            ? const Color(0xFFC0C1FF)
                            : Colors.white.withValues(alpha: 0.35),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
            const SizedBox(height: 6),
            Text(
              letter,
              style: TextStyle(
                color: widget.today
                    ? const Color(0xFFC0C1FF)
                    : Colors.white.withValues(alpha: widget.active ? 0.78 : 0.42),
                fontSize: 10,
                fontWeight: widget.today ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ],
        );
      },
    );
  }
}

String _dayKey(DateTime date) {
  final local = date.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
}

bool _sameDay(DateTime a, DateTime b) {
  final la = a.toLocal();
  final lb = b.toLocal();
  return la.year == lb.year && la.month == lb.month && la.day == lb.day;
}
