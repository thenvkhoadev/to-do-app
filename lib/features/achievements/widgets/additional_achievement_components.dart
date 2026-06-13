import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/constants/dashboard_constants.dart';
import 'package:to_do_app/features/achievements/providers/achievements_provider.dart';
import 'package:to_do_app/features/achievements/domain/achievement.dart';
import 'package:to_do_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';
import 'package:to_do_app/widgets/dashboard/dashboard_stats_provider.dart';

/// Component 1: Weekly Challenges / Quest Center
class WeeklyChallengesCard extends ConsumerWidget {
  const WeeklyChallengesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final dashboardStats = ref.watch(dashboardStatsProvider);

    if (profile == null) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(DashboardColors.primary),
          ),
        ),
      );
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));

    // Get weekly completed tasks to calculate focus hours
    final weekCompletedTasksList = dashboardStats.tasks.where((t) =>
      t.status == 'done' &&
      t.completedAt != null &&
      !t.completedAt!.isBefore(weekStart)
    ).toList();

    final weekFocusMinutes = weekCompletedTasksList.fold<int>(0, (sum, t) => sum + (t.estimatedMinutes ?? 25));
    final weekFocusHours = (weekFocusMinutes / 60).round();

    // Real weekly completed tasks count
    final weekCompletedTasks = dashboardStats.weeklyCompletedCounts.fold<int>(0, (a, b) => a + b);

    // Calculate dynamic targets so they're tailored to the user's progress:
    final int focusTarget = weekFocusHours < 2 ? 2 : weekFocusHours < 5 ? 5 : weekFocusHours < 10 ? 10 : weekFocusHours < 20 ? 20 : 40;
    final int taskTarget = weekCompletedTasks < 5 ? 5 : weekCompletedTasks < 10 ? 10 : weekCompletedTasks < 30 ? 30 : weekCompletedTasks < 50 ? 50 : 100;
    final int streakTarget = profile.streakCount < 3 ? 3 : profile.streakCount < 7 ? 7 : profile.streakCount < 14 ? 14 : profile.streakCount < 30 ? 30 : profile.streakCount < 100 ? 100 : 365;

    // Time left until next Monday (Sunday 23:59:59 reset)
    final daysToMonday = 8 - now.weekday;
    final nextMonday = DateTime(now.year, now.month, now.day + daysToMonday);
    final difference = nextMonday.difference(now);
    final daysLeft = difference.inDays;
    final hoursLeft = difference.inHours % 24;
    final timeLeftStr = '${daysLeft}d ${hoursLeft}h left';

    // Define three challenges using real profile / dashboard data
    final challenges = [
      _ChallengeItem(
        title: 'Focus Marathon',
        description: 'Log $focusTarget hours of deep work sessions',
        current: weekFocusHours,
        target: focusTarget,
        unit: 'hrs',
        xpReward: focusTarget * 20,
        color: DashboardColors.primary,
      ),
      _ChallengeItem(
        title: 'Task Sprint',
        description: 'Complete $taskTarget tasks this week',
        current: weekCompletedTasks,
        target: taskTarget,
        unit: 'tasks',
        xpReward: taskTarget * 15,
        color: DashboardColors.secondary,
      ),
      _ChallengeItem(
        title: 'Perfect Week',
        description: 'Maintain a $streakTarget-day task completion streak',
        current: profile.streakCount,
        target: streakTarget,
        unit: 'days',
        xpReward: streakTarget * 80,
        color: DashboardColors.warning,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(DashboardSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Weekly Quests',
                style: TextStyle(
                  color: DashboardColors.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: DashboardColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: DashboardColors.error.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined, color: DashboardColors.error, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      timeLeftStr,
                      style: const TextStyle(
                        color: DashboardColors.error,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            children: challenges.map((challenge) {
              final progress = (challenge.current / challenge.target).clamp(0.0, 1.0);
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                challenge.title,
                                style: const TextStyle(
                                  color: DashboardColors.onSurface,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                challenge.description,
                                style: const TextStyle(
                                  color: DashboardColors.onSurfaceVariant,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '+${challenge.xpReward} XP',
                          style: TextStyle(
                            color: challenge.color,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: Stack(
                              children: [
                                Container(
                                  height: 6,
                                  color: Colors.white.withValues(alpha: 0.05),
                                ),
                                FractionallySizedBox(
                                  widthFactor: progress,
                                  child: Container(
                                    height: 6,
                                    color: challenge.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${challenge.current}/${challenge.target} ${challenge.unit}',
                          style: const TextStyle(
                            color: DashboardColors.onSurfaceVariant,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ChallengeItem {
  const _ChallengeItem({
    required this.title,
    required this.description,
    required this.current,
    required this.target,
    required this.unit,
    required this.xpReward,
    required this.color,
  });

  final String title;
  final String description;
  final int current;
  final int target;
  final String unit;
  final int xpReward;
  final Color color;
}

/// Component 2: Badge Rarity Distribution Chart
class RarityDistributionCard extends ConsumerWidget {
  const RarityDistributionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievements = ref.watch(achievementsProvider);
    final unlocked = achievements.where((a) => a.isUnlocked).toList();

    // Helper to count totals and unlocked by rarity group
    int getTotalCount(List<AchievementRarity> rarities) =>
        achievements.where((a) => rarities.contains(a.rarity)).length;

    int getUnlockedCount(List<AchievementRarity> rarities) =>
        unlocked.where((a) => rarities.contains(a.rarity)).length;

    final distributions = [
      _DistributionItem(
        label: 'Bronze & Silver',
        unlocked: getUnlockedCount([AchievementRarity.bronze, AchievementRarity.silver]),
        total: getTotalCount([AchievementRarity.bronze, AchievementRarity.silver]),
        color: const Color(0xFFC0C0C0), // silverish
      ),
      _DistributionItem(
        label: 'Gold & Diamond',
        unlocked: getUnlockedCount([AchievementRarity.gold, AchievementRarity.diamond]),
        total: getTotalCount([AchievementRarity.gold, AchievementRarity.diamond]),
        color: const Color(0xFFFFD700), // gold
      ),
      _DistributionItem(
        label: 'Elite & Master',
        unlocked: getUnlockedCount([AchievementRarity.elite, AchievementRarity.master]),
        total: getTotalCount([AchievementRarity.elite, AchievementRarity.master]),
        color: const Color(0xFF9C27B0), // purple
      ),
      _DistributionItem(
        label: 'Challenger & Grandmaster',
        unlocked: getUnlockedCount([AchievementRarity.challenger, AchievementRarity.grandmaster, AchievementRarity.supreme]),
        total: getTotalCount([AchievementRarity.challenger, AchievementRarity.grandmaster, AchievementRarity.supreme]),
        color: const Color(0xFFFF5722), // deep orange
      ),
      _DistributionItem(
        label: 'Legend & Mythic',
        unlocked: getUnlockedCount([AchievementRarity.legend, AchievementRarity.immortal, AchievementRarity.mythic]),
        total: getTotalCount([AchievementRarity.legend, AchievementRarity.immortal, AchievementRarity.mythic]),
        color: const Color(0xFFE91E63), // hot pink
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(DashboardSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Badge Distribution',
            style: TextStyle(
              color: DashboardColors.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: distributions.map((dist) {
              final progress = dist.total == 0 ? 0.0 : (dist.unlocked / dist.total);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 130,
                      child: Text(
                        dist.label,
                        style: const TextStyle(
                          color: DashboardColors.onSurfaceVariant,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: Stack(
                          children: [
                            Container(
                              height: 6,
                              color: Colors.white.withValues(alpha: 0.05),
                            ),
                            FractionallySizedBox(
                              widthFactor: progress.clamp(0.0, 1.0),
                              child: Container(
                                height: 6,
                                color: dist.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 36,
                      child: Text(
                        '${dist.unlocked}/${dist.total}',
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          color: dist.color,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _DistributionItem {
  const _DistributionItem({
    required this.label,
    required this.unlocked,
    required this.total,
    required this.color,
  });

  final String label;
  final int unlocked;
  final int total;
  final Color color;
}

/// Component 3: Milestone Roadmap Card (Closest to unlocking)
class MilestoneRoadmapCard extends ConsumerWidget {
  const MilestoneRoadmapCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locked = ref.watch(lockedAchievementsProvider);
    final nextMilestones = locked.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(DashboardSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Milestone Roadmap',
            style: TextStyle(
              color: DashboardColors.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          if (nextMilestones.isEmpty)
            const Center(
              child: Text(
                'All achievements unlocked! 🏆',
                style: TextStyle(color: DashboardColors.success, fontSize: 13),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: nextMilestones.length,
              itemBuilder: (context, index) {
                final achievement = nextMilestones[index];
                final progress = achievement.progress; // double 0.0 to 1.0
                final isLast = index == nextMilestones.length - 1;

                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Timeline indicator
                      Column(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: achievement.rarity.color.withValues(alpha: 0.15),
                              border: Border.all(
                                color: achievement.rarity.color,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: achievement.rarity.color.withValues(alpha: 0.25),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: achievement.rarity.color,
                                ),
                              ),
                            ),
                          ),
                          if (!isLast)
                            Expanded(
                              child: Container(
                                width: 2,
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      // Content Details
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      achievement.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: DashboardColors.onSurface,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '+${achievement.xpReward} XP',
                                    style: TextStyle(
                                      color: achievement.rarity.color,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                achievement.description,
                                style: const TextStyle(
                                  color: DashboardColors.onSurfaceVariant,
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(999),
                                      child: Stack(
                                        children: [
                                          Container(
                                            height: 5,
                                            color: Colors.white.withValues(alpha: 0.05),
                                          ),
                                          FractionallySizedBox(
                                            widthFactor: progress.clamp(0.0, 1.0),
                                            child: Container(
                                              height: 5,
                                              color: achievement.rarity.color,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${achievement.currentValue}/${achievement.targetValue}',
                                    style: const TextStyle(
                                      color: DashboardColors.onSurfaceVariant,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

/// Component 4: Daily XP Boosters Card (Daily quick objectives)
class DailyBoostersCard extends ConsumerWidget {
  const DailyBoostersCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardStats = ref.watch(dashboardStatsProvider);
    
    // 1. Morning Warrior / Daily completed tasks count
    final completedToday = dashboardStats.completedTodayTasks;
    const taskTarget = 3;

    // 2. Urgent Execution (completed urgent/high priority tasks today)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final completedUrgentToday = dashboardStats.tasks.where((t) =>
      t.status == 'done' &&
      (t.priority == 'high' || t.priority == 'urgent') &&
      t.completedAt != null &&
      !t.completedAt!.isBefore(today)
    ).length;
    const urgentTarget = 1;

    // 3. Deep Focus session booster
    final hasFocusToday = (completedToday > 0) ? 1 : 0;
    const focusTarget = 1;

    final boosters = [
      _BoosterItem(
        title: 'Daily Warrior',
        description: 'Complete 3 tasks today',
        current: completedToday,
        target: taskTarget,
        unit: 'tasks',
        xpReward: 100,
        color: const Color(0xFF00E5FF), // cyan
      ),
      _BoosterItem(
        title: 'Priority Execution',
        description: 'Resolve 1 high/urgent task today',
        current: completedUrgentToday,
        target: urgentTarget,
        unit: 'tasks',
        xpReward: 150,
        color: const Color(0xFFFF3D00), // deep orange
      ),
      _BoosterItem(
        title: 'Focus Surge',
        description: 'Log any focus hours session today',
        current: hasFocusToday,
        target: focusTarget,
        unit: 'session',
        xpReward: 120,
        color: const Color(0xFFAEEA00), // lime green
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(DashboardSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Daily Boosters',
                style: TextStyle(
                  color: DashboardColors.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFF8F00),
                      Color(0xFFFF5722),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'XP BOOST',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            children: boosters.map((booster) {
              final progress = (booster.current / booster.target).clamp(0.0, 1.0);
              final isCompleted = progress >= 1.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.01),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isCompleted
                          ? booster.color.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.03),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Status Circle Check
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted
                              ? booster.color.withValues(alpha: 0.15)
                              : Colors.white.withValues(alpha: 0.03),
                          border: Border.all(
                            color: isCompleted ? booster.color : Colors.white24,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            isCompleted ? Icons.check : Icons.lock_open_rounded,
                            color: isCompleted ? booster.color : Colors.white38,
                            size: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booster.title,
                              style: TextStyle(
                                color: isCompleted ? booster.color : DashboardColors.onSurface,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              booster.description,
                              style: const TextStyle(
                                color: DashboardColors.onSurfaceVariant,
                                fontSize: 9.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Mini progress
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: Stack(
                                children: [
                                  Container(
                                    height: 4,
                                    color: Colors.white.withValues(alpha: 0.05),
                                  ),
                                  FractionallySizedBox(
                                    widthFactor: progress,
                                    child: Container(
                                      height: 4,
                                      color: booster.color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // XP tag
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '+${booster.xpReward}',
                            style: TextStyle(
                              color: isCompleted ? booster.color : Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Text(
                            'XP',
                            style: TextStyle(
                              color: DashboardColors.onSurfaceVariant,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _BoosterItem {
  const _BoosterItem({
    required this.title,
    required this.description,
    required this.current,
    required this.target,
    required this.unit,
    required this.xpReward,
    required this.color,
  });

  final String title;
  final String description;
  final int current;
  final int target;
  final String unit;
  final int xpReward;
  final Color color;
}

/// Component 5: Achievement Category Mastery Card
class CategoryMasteryCard extends ConsumerWidget {
  const CategoryMasteryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievements = ref.watch(achievementsProvider);
    final categories = ['Tasks', 'Streak', 'Focus', 'XP', 'Projects', 'AI', 'Social', 'Special'];

    final categoryStats = categories.map((cat) {
      final list = achievements.where((a) => a.category == cat).toList();
      final total = list.length;
      final unlocked = list.where((a) => a.isUnlocked).toList();
      final unlockedCount = unlocked.length;
      final percent = total == 0 ? 0.0 : unlockedCount / total;

      // Find highest rarity unlocked in this category
      AchievementRarity? highestRarity;
      for (final a in unlocked) {
        if (highestRarity == null || a.rarity.index > highestRarity.index) {
          highestRarity = a.rarity;
        }
      }

      // Color mapping and icons
      final (icon, color) = switch (cat) {
        'Tasks' => (Icons.task_alt_rounded, const Color(0xFF00E5FF)),
        'Streak' => (Icons.local_fire_department_rounded, const Color(0xFFFF8F00)),
        'Focus' => (Icons.psychology_rounded, const Color(0xFFAEEA00)),
        'XP' => (Icons.stars_rounded, const Color(0xFFFFD700)),
        'Projects' => (Icons.folder_copy_rounded, const Color(0xFF00FFC6)),
        'AI' => (Icons.memory_rounded, const Color(0xFFE91E63)),
        'Social' => (Icons.groups_rounded, const Color(0xFF9C27B0)),
        _ => (Icons.auto_awesome_rounded, const Color(0xFFFF1744)),
      };

      return _CategoryMasteryItem(
        name: cat,
        percent: percent,
        unlockedCount: unlockedCount,
        totalCount: total,
        highestRarity: highestRarity,
        icon: icon,
        color: color,
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(DashboardSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Category Mastery',
            style: TextStyle(
              color: DashboardColors.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categoryStats.length,
            itemBuilder: (context, index) {
              final stat = categoryStats[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    // Icon
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: stat.color.withValues(alpha: 0.1),
                        border: Border.all(color: stat.color.withValues(alpha: 0.2)),
                      ),
                      child: Icon(stat.icon, color: stat.color, size: 14),
                    ),
                    const SizedBox(width: 12),
                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                stat.name,
                                style: const TextStyle(
                                  color: DashboardColors.onSurface,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${(stat.percent * 100).toStringAsFixed(0)}%',
                                style: TextStyle(
                                  color: stat.color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: Stack(
                              children: [
                                Container(
                                  height: 4,
                                  color: Colors.white.withValues(alpha: 0.05),
                                ),
                                FractionallySizedBox(
                                  widthFactor: stat.percent,
                                  child: Container(
                                    height: 4,
                                    color: stat.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Highest Rarity Badge
                    SizedBox(
                      width: 70,
                      child: stat.highestRarity == null
                          ? const Text(
                              'Locked',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: DashboardColors.onSurfaceVariant,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: stat.highestRarity!.color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: stat.highestRarity!.color.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                stat.highestRarity!.label,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: stat.highestRarity!.color,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CategoryMasteryItem {
  const _CategoryMasteryItem({
    required this.name,
    required this.percent,
    required this.unlockedCount,
    required this.totalCount,
    required this.highestRarity,
    required this.icon,
    required this.color,
  });

  final String name;
  final double percent;
  final int unlockedCount;
  final int totalCount;
  final AchievementRarity? highestRarity;
  final IconData icon;
  final Color color;
}

