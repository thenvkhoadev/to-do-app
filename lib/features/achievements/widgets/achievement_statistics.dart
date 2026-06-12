import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/constants/dashboard_constants.dart';
import 'package:to_do_app/features/achievements/providers/achievements_provider.dart';
import 'package:to_do_app/features/achievements/domain/achievement.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class AchievementStatistics extends ConsumerWidget {
  const AchievementStatistics({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(achievementsStatsProvider);
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < DashboardBreakpoints.mobile;

    return GridView.count(
      crossAxisCount: isMobile ? 2 : 4,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: isMobile ? 1.35 : 1.45,
      children: [
        _StatCard(
          title: 'Total Badges',
          value: stats.totalCount.toString(),
          icon: Icons.emoji_events_rounded,
          accentColor: DashboardColors.primary,
        ),
        _StatCard(
          title: 'Unlocked',
          value: '${stats.unlockPercentage}%',
          icon: Icons.lock_open_rounded,
          accentColor: DashboardColors.secondary,
        ),
        _StatCard(
          title: 'Rare Badges',
          value: stats.rareUnlockedCount.toString(),
          icon: Icons.workspace_premium_rounded,
          accentColor: DashboardColors.tertiary,
        ),
        _StatCard(
          title: 'Highest Rank',
          value: stats.highestRarityUnlocked != null
              ? stats.highestRarityUnlocked!.label
              : 'None',
          icon: Icons.military_tech_rounded,
          accentColor: stats.highestRarityUnlocked != null
              ? stats.highestRarityUnlocked!.color
              : DashboardColors.outline,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accentColor,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: DashboardColors.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                icon,
                color: accentColor.withValues(alpha: 0.75),
                size: 20,
              ),
            ],
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: accentColor,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}
