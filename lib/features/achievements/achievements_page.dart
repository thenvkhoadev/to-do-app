import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/constants/dashboard_constants.dart';
import 'package:to_do_app/features/achievements/providers/achievements_provider.dart';
import 'package:to_do_app/features/achievements/widgets/achievement_card.dart';
import 'package:to_do_app/features/achievements/widgets/achievement_filter.dart';
import 'package:to_do_app/features/achievements/widgets/achievement_header.dart';
import 'package:to_do_app/features/achievements/widgets/achievement_statistics.dart';
import 'package:to_do_app/features/achievements/widgets/achievement_summary.dart';
import 'package:to_do_app/features/achievements/widgets/achievement_tabs.dart';
import 'package:to_do_app/features/achievements/widgets/leaderboard_preview_card.dart';
import 'package:to_do_app/features/achievements/widgets/level_progress_card.dart';
import 'package:to_do_app/features/achievements/widgets/locked_achievements_section.dart';
import 'package:to_do_app/features/achievements/widgets/recently_unlocked_section.dart';
import 'package:to_do_app/features/achievements/widgets/additional_achievement_components.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';
import 'package:to_do_app/widgets/dashboard/dashboard_shared.dart';
import 'package:to_do_app/widgets/dashboard/desktop_dashboard_widgets.dart';

class AchievementsPage extends StatelessWidget {
  const AchievementsPage({this.embeddedInDashboard = false, super.key});

  final bool embeddedInDashboard;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: DashboardTheme.dark(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= DashboardBreakpoints.desktop;
          final isTablet = constraints.maxWidth >= DashboardBreakpoints.mobile &&
              constraints.maxWidth < DashboardBreakpoints.desktop;

          final content = isDesktop
              ? const _AchievementsDesktopLayout()
              : _AchievementsMobileLayout(isTablet: isTablet);

          if (embeddedInDashboard) return content;
          return DashboardScaffold(child: content);
        },
      ),
    );
  }
}

class _AchievementsDesktopLayout extends StatelessWidget {
  const _AchievementsDesktopLayout();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const DesktopTopbar(),
        Expanded(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(DashboardSpacing.lg),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: DashboardSpacing.desktopMaxWidth,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Panel (Main Content)
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const AchievementHeader(),
                                const SizedBox(height: DashboardSpacing.md),
                                const AchievementStatistics(),
                                const SizedBox(height: DashboardSpacing.md),
                                // Row 1: Weekly Quests & Daily Boosters
                                const Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: WeeklyChallengesCard()),
                                    SizedBox(width: DashboardSpacing.md),
                                    Expanded(child: DailyBoostersCard()),
                                  ],
                                ),
                                const SizedBox(height: DashboardSpacing.md),
                                const AchievementTabs(),
                                const SizedBox(height: DashboardSpacing.md),
                                const AchievementFilter(),
                                const SizedBox(height: DashboardSpacing.md),
                                const _AchievementsGrid(crossAxisCount: 4),
                                const SizedBox(height: DashboardSpacing.md),
                                const _AchievementsPagination(),
                                const SizedBox(height: DashboardSpacing.md),
                                // Row 2: Milestone Roadmap & Rarity Distribution
                                const Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: MilestoneRoadmapCard()),
                                    SizedBox(width: DashboardSpacing.md),
                                    Expanded(child: RarityDistributionCard()),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: DashboardSpacing.md),
                          // Right Panel (Summary, Level, Streak & Leaderboard)
                          const SizedBox(
                            width: 320,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AchievementSummary(),
                                SizedBox(height: DashboardSpacing.md),
                                LevelProgressCard(),
                                SizedBox(height: DashboardSpacing.md),
                                RecentlyUnlockedSection(),
                                SizedBox(height: DashboardSpacing.md),
                                LockedAchievementsSection(),
                                SizedBox(height: DashboardSpacing.md),
                                LeaderboardPreviewCard(),
                                SizedBox(height: DashboardSpacing.md),
                                CategoryMasteryCard(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AchievementsMobileLayout extends StatelessWidget {
  const _AchievementsMobileLayout({required this.isTablet});
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(DashboardSpacing.sm),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AchievementHeader(),
                  const SizedBox(height: DashboardSpacing.sm),
                  const AchievementSummary(),
                  const SizedBox(height: DashboardSpacing.sm),
                  const LevelProgressCard(),
                  const SizedBox(height: DashboardSpacing.sm),
                  const AchievementStatistics(),
                  const SizedBox(height: DashboardSpacing.sm),
                  const RecentlyUnlockedSection(),
                  const SizedBox(height: DashboardSpacing.sm),
                  const LockedAchievementsSection(),
                  const SizedBox(height: DashboardSpacing.sm),
                  const AchievementTabs(),
                  const SizedBox(height: DashboardSpacing.sm),
                  const AchievementFilter(),
                  const SizedBox(height: DashboardSpacing.sm),
                  _AchievementsGrid(crossAxisCount: isTablet ? 3 : 2),
                  const SizedBox(height: DashboardSpacing.sm),
                  const _AchievementsPagination(),
                  const SizedBox(height: DashboardSpacing.sm),
                  const LeaderboardPreviewCard(),
                  const SizedBox(height: DashboardSpacing.sm),
                  const CategoryMasteryCard(),
                  const SizedBox(height: DashboardSpacing.sm),
                  const WeeklyChallengesCard(),
                  const SizedBox(height: DashboardSpacing.sm),
                  const DailyBoostersCard(),
                  const SizedBox(height: DashboardSpacing.sm),
                  const MilestoneRoadmapCard(),
                  const SizedBox(height: DashboardSpacing.sm),
                  const RarityDistributionCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementsGrid extends ConsumerWidget {
  const _AchievementsGrid({required this.crossAxisCount});
  final int crossAxisCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievements = ref.watch(paginatedAchievementsProvider);

    if (achievements.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: const Text(
          'No achievements found matching your search.',
          style: TextStyle(
            color: DashboardColors.onSurfaceVariant,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        return AchievementCard(achievement: achievements[index]);
      },
    );
  }
}

class _AchievementsPagination extends ConsumerWidget {
  const _AchievementsPagination();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(achievementsPageProvider);
    final totalPages = ref.watch(achievementsTotalPagesProvider);
    final filteredCount = ref.watch(filteredAchievementsProvider).length;
    final itemsPerPage = ref.watch(achievementsItemsPerPageProvider);

    if (totalPages <= 1) return const SizedBox.shrink();

    final startItem = (page - 1) * itemsPerPage + 1;
    final endItem = (page * itemsPerPage).clamp(0, filteredCount);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.01),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Items Range Text
          Text(
            'Showing $startItem-$endItem of $filteredCount badges',
            style: const TextStyle(
              color: DashboardColors.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          
          // Controls
          Row(
            children: [
              // Previous Button
              _PageNavButton(
                icon: Icons.chevron_left_rounded,
                isEnabled: page > 1,
                onTap: () => ref.read(achievementsPageProvider.notifier).state = page - 1,
              ),
              const SizedBox(width: 12),
              
              // Page Numbers
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Text(
                  'Page $page / $totalPages',
                  style: const TextStyle(
                    color: DashboardColors.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Next Button
              _PageNavButton(
                icon: Icons.chevron_right_rounded,
                isEnabled: page < totalPages,
                onTap: () => ref.read(achievementsPageProvider.notifier).state = page + 1,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PageNavButton extends StatelessWidget {
  const _PageNavButton({
    required this.icon,
    required this.isEnabled,
    required this.onTap,
  });

  final IconData icon;
  final bool isEnabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isEnabled 
                ? Colors.white.withValues(alpha: 0.04) 
                : Colors.white.withValues(alpha: 0.01),
            border: Border.all(
              color: isEnabled 
                  ? Colors.white.withValues(alpha: 0.08) 
                  : Colors.white.withValues(alpha: 0.02),
            ),
          ),
          child: Icon(
            icon,
            color: isEnabled 
                ? DashboardColors.onSurface 
                : DashboardColors.onSurfaceVariant.withValues(alpha: 0.3),
            size: 20,
          ),
        ),
      ),
    );
  }
}
