import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/constants/dashboard_constants.dart';
import 'package:to_do_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:to_do_app/features/xp/domain/xp_leveling.dart' as leveling;
import 'package:to_do_app/theme/dashboard_theme.dart';

class LevelProgressCard extends ConsumerStatefulWidget {
  const LevelProgressCard({super.key});

  @override
  ConsumerState<LevelProgressCard> createState() => _LevelProgressCardState();
}

class _LevelProgressCardState extends ConsumerState<LevelProgressCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider).valueOrNull;

    if (profile == null) {
      return const SizedBox(
        height: 150,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final totalXp = profile.totalXp;
    final levelState = leveling.xpProgressFromTotalXp(totalXp);
    final level = levelState.level;
    final progress = levelState.progress;
    final xpInto = levelState.xpIntoLevel;
    final xpForNext = levelState.xpForNextLevel;

    final rank = leveling.xpRankForLevel(level);
    final nextRank = leveling.xpRankForLevel(level + 1);

    final xpRemaining = xpForNext - xpInto;

    return Container(
      padding: const EdgeInsets.all(DashboardSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07), width: 1.5),
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.04),
            Colors.white.withValues(alpha: 0.01),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: DashboardColors.primary.withValues(alpha: 0.04),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    // Premium Level Badge
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          width: 52,
                          height: 52,
                          alignment: Alignment.center,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Pulsing outer aura (Diamond 1)
                              Transform.rotate(
                                angle: math.pi / 4,
                                child: Container(
                                  width: 38 + (4 * _pulseController.value),
                                  height: 38 + (4 * _pulseController.value),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: DashboardColors.primary.withValues(alpha: 0.3),
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              // Solid outer diamond border (Diamond 2)
                              Transform.rotate(
                                angle: math.pi / 4,
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        DashboardColors.primary,
                                        DashboardColors.secondary,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                    boxShadow: [
                                      BoxShadow(
                                        color: DashboardColors.primary.withValues(alpha: 0.45),
                                        blurRadius: 10,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Inner dark core container (Diamond 3) to make it hollow
                              Transform.rotate(
                                angle: math.pi / 4,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF0F1524),
                                        Color(0xFF1E2638),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.1),
                                      width: 1,
                                    ),
                                  ),
                                ),
                              ),
                              // Text content without rotation (white with neon glow)
                              Text(
                                '$level',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  shadows: [
                                    Shadow(
                                      color: DashboardColors.primary,
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Shader text rank
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [DashboardColors.primary, Colors.white],
                            ).createShader(bounds),
                            child: Text(
                              rank.title,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'Active Progress Rank',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: DashboardColors.onSurfaceVariant,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$xpRemaining XP left',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: DashboardColors.secondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Next: ${nextRank.title}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: DashboardColors.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 22),
          // Thicker progress bar with glowing dots
          ClipRRect(
            borderRadius: BorderRadius.circular(DashboardRadii.full),
            child: Stack(
              children: [
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(DashboardRadii.full),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    height: 12,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          DashboardColors.primary,
                          DashboardColors.secondary,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress: $xpInto XP',
                style: const TextStyle(
                  color: DashboardColors.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Target: $xpForNext XP',
                style: const TextStyle(
                  color: DashboardColors.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
