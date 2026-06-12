import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/features/achievements/providers/achievements_provider.dart';
import 'package:to_do_app/features/achievements/domain/achievement.dart';
import 'package:to_do_app/features/achievements/widgets/badge_widget.dart';
import 'package:to_do_app/features/achievements/widgets/achievement_detail_modal.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class LockedAchievementsSection extends ConsumerWidget {
  const LockedAchievementsSection({super.key});

  void _showDetails(BuildContext context, Achievement achievement) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (context) => AchievementDetailModal(achievement: achievement),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locked = ref.watch(lockedAchievementsProvider);

    if (locked.isEmpty) {
      return const SizedBox.shrink();
    }

    // Only take top 3 closest to unlock
    final nextMilestones = locked.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Next Milestones',
          style: TextStyle(
            color: DashboardColors.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: nextMilestones.map((achievement) {
            final color = achievement.rarity.color;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () => _showDetails(context, achievement),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: Row(
                    children: [
                      // Blurred locked badge
                      BadgeWidget(
                        rarity: achievement.rarity,
                        icon: achievement.icon,
                        svgName: achievement.svgName,
                        size: 40,
                        isLocked: true,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              achievement.name,
                              style: const TextStyle(
                                color: DashboardColors.onSurface,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              achievement.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: DashboardColors.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Progress bar
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(999),
                                    child: Stack(
                                      children: [
                                        Container(height: 4, color: Colors.white.withValues(alpha: 0.05)),
                                        FractionallySizedBox(
                                          widthFactor: achievement.progress,
                                          child: Container(height: 4, color: color),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  '${(achievement.progress * 100).round()}%',
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
