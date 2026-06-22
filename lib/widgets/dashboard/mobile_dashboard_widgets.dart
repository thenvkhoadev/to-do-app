import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:to_do_app/constants/dashboard_constants.dart';
import 'package:to_do_app/screens/tasks_projects/tasks_projects_content.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';
import 'package:to_do_app/widgets/dashboard/dashboard_enhancement_widgets.dart';
import 'package:to_do_app/widgets/dashboard/dashboard_shared.dart';
import 'package:to_do_app/widgets/dashboard/dashboard_stats_provider.dart';
import 'package:to_do_app/features/social/presentation/screens/feed_screen.dart';
import 'package:to_do_app/features/social/presentation/screens/friends_screen.dart';
import 'package:to_do_app/features/social/presentation/screens/messages_screen.dart';
import 'package:to_do_app/screens/settings/settings_screen.dart';
import 'package:to_do_app/screens/profile/user_profile_screen.dart';

class MobileDashboardLayout extends StatelessWidget {
  const MobileDashboardLayout({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Stack(
      children: [
        Positioned.fill(
          child: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 88)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  DashboardSpacing.md,
                  0,
                  DashboardSpacing.md,
                  132,
                ),
                sliver: SliverToBoxAdapter(
                  child: switch (initialIndex) {
                    12 => FeedScreen(
                        onFindFriends: () => context.go('/friends'),
                      ),
                    13 => const FriendsScreen(),
                    14 => const MessagesScreen(),
                    5 => const SettingsScreen(embeddedInDashboard: true),
                    7 => const UserProfileScreen(),
                    _ => const MobileDashboardContent(),
                  },
                ),
              ),
            ],
          ),
        ),
        const Positioned(top: 0, left: 0, right: 0, child: MobileTopBar()),
        Positioned(
          right: 28,
          bottom: 92 + bottomInset,
          child: const FloatingActionTaskButton(),
        ),
        Positioned(
          right: 24,
          bottom: 166 + bottomInset,
          child: const AIAssistantWidget(),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: MobileBottomNavBar(bottomInset: bottomInset),
        ),
      ],
    );
  }
}

class MobileDashboardContent extends StatelessWidget {
  const MobileDashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MobileHeroSection(),
        SizedBox(height: DashboardSpacing.md),
        XPLevelCard(),
        SizedBox(height: DashboardSpacing.md),
        QuickActionsGrid(),
        SizedBox(height: DashboardSpacing.md),
        FocusProgressCard(),
        SizedBox(height: DashboardSpacing.md),
        CurrentFocusSessionCard(),
        SizedBox(height: DashboardSpacing.md),
        FocusTimerCard(),
        SizedBox(height: DashboardSpacing.md),
        AIInsightsPanel(),
        SizedBox(height: DashboardSpacing.md),
        WeeklySummaryCard(),
        SizedBox(height: DashboardSpacing.md),
        AnalyticsCard(),
        SizedBox(height: DashboardSpacing.md),
        ActivityHeatmapCard(),
        SizedBox(height: DashboardSpacing.md),
        QuarterGoalsCard(),
        SizedBox(height: DashboardSpacing.md),
        DailyChallengeCard(),
        SizedBox(height: DashboardSpacing.md),
        TeamActivityCard(),
        SizedBox(height: DashboardSpacing.md),
        ProjectHealthOverviewCard(),
        SizedBox(height: DashboardSpacing.md),
        AchievementsCard(),
        SizedBox(height: DashboardSpacing.md),
        KnowledgeHubCard(),
        SizedBox(height: DashboardSpacing.md),
        FocusAudioCard(),
        SizedBox(height: DashboardSpacing.md),
        _DashboardMobileProjectsSection(),
        SizedBox(height: DashboardSpacing.md),
        _SystemStatusBar(),
      ],
    );
  }
}

class MobileTopBar extends StatelessWidget {
  const MobileTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
          child: Container(
            height: 66,
            padding: const EdgeInsets.symmetric(
              horizontal: DashboardSpacing.md,
            ),
            decoration: BoxDecoration(
              color: DashboardColors.surface.withValues(alpha: .42),
              border: Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: .08)),
              ),
            ),
            child: Row(
              children: [
                const ProfileAvatar(radius: 20),
                const SizedBox(width: 12),
                ShaderMask(
                  shaderCallback:
                      (rect) => const LinearGradient(
                        colors: [
                          DashboardColors.primary,
                          DashboardColors.secondary,
                        ],
                      ).createShader(rect),
                  child: const Text(
                    'NEXUS AI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.6,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => context.go('/settings'),
                  icon: const Icon(
                    Icons.settings_rounded,
                    color: DashboardColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MobileHeroSection extends ConsumerWidget {
  const MobileHeroSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTight = MediaQuery.sizeOf(context).width < 380;
    final greeting = dashboardGreeting(DateTime.now());
    final username = dashboardUsername(ref);
    final stats = ref.watch(dashboardStatsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          label: 'System Ready',
          color: DashboardColors.primary,
        ),
        const SizedBox(height: 12),
        Text.rich(
          TextSpan(
            text: '$greeting, ',
            children: [
              TextSpan(
                text: username,
                style: const TextStyle(color: DashboardColors.primary),
              ),
            ],
          ),
          style: TextStyle(
            color: DashboardColors.onSurface,
            fontSize: isTight ? 38 : 46,
            height: 1.02,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.1,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          stats.headerSummary,
          style: const TextStyle(
            color: DashboardColors.onSurfaceVariant,
            fontSize: 17,
            height: 1.5,
          ),
        ),
        const SizedBox(height: DashboardSpacing.md),
        const AIRecommendationMobileCard(),
      ],
    );
  }
}

class AIRecommendationMobileCard extends ConsumerWidget {
  const AIRecommendationMobileCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final task = ref.watch(dashboardStatsProvider).nextBestTask;
    return GlassCard(
      glowColor: DashboardColors.primary,
      padding: const EdgeInsets.all(20),
      radius: DashboardRadii.lg,
      child: Stack(
        children: [
          Positioned.fill(child: IgnorePointer(child: _ShimmerBand())),
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: DashboardColors.primaryContainer.withValues(
                    alpha: .20,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: DashboardColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI RECOMMENDATION',
                      style: TextStyle(
                        color: DashboardColors.outline,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      task == null ? 'No active task recommendation' : 'Next best task: ${task.title}',
                      style: const TextStyle(
                        color: DashboardColors.onSurface,
                        fontSize: 20,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: DashboardColors.primaryContainer,
                  borderRadius: BorderRadius.circular(DashboardRadii.full),
                ),
                child: const Text(
                  'Start',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShimmerBand extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: -1, end: 1),
      duration: const Duration(seconds: 2),
      curve: Curves.linear,
      builder:
          (context, value, _) => Transform.translate(
            offset: Offset(value * 280, 0),
            child: Container(
              width: 90,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.white.withValues(alpha: .05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
    );
  }
}

class FocusProgressCard extends ConsumerWidget {
  const FocusProgressCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);
    return GlassCard(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          CircularScore(value: stats.focusProgress, label: 'FOCUSED', size: 190),
          const SizedBox(height: 22),
          Text(
            stats.focusSummary,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: DashboardColors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class FocusTimerCard extends StatelessWidget {
  const FocusTimerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              IconBadge(
                icon: Icons.timer_rounded,
                color: DashboardColors.primary,
              ),
              Spacer(),
              SectionTitle(label: 'Deep Work'),
            ],
          ),
          SizedBox(height: 24),
          Text(
            'Focus Timer',
            style: TextStyle(
              color: DashboardColors.onSurface,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Configure your next session for maximum intensity.',
            style: TextStyle(
              color: DashboardColors.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          SizedBox(height: 28),
          PulsingGradientButton(),
        ],
      ),
    );
  }
}

class PulsingGradientButton extends StatelessWidget {
  const PulsingGradientButton({super.key});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: .96, end: 1),
      duration: const Duration(seconds: 2),
      curve: Curves.easeInOut,
      builder:
          (context, scale, child) =>
              Transform.scale(scale: scale, child: child),
      child: const GradientButton(label: 'Start Focus Session', expanded: true),
    );
  }
}

class AnalyticsCard extends ConsumerWidget {
  const AnalyticsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Text(
                'Analytics',
                style: TextStyle(
                  color: DashboardColors.onSurface,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Spacer(),
              Icon(Icons.trending_up_rounded, color: DashboardColors.outline),
            ],
          ),
          const SizedBox(height: 18),
          AnalyticsBars(
            counts: stats.weeklyCompletedCounts,
            labels: const ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
          ),
        ],
      ),
    );
  }
}

class _DashboardMobileProjectsSection extends StatelessWidget {
  const _DashboardMobileProjectsSection();

  @override
  Widget build(BuildContext context) {
    return const CustomScrollView(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      slivers: [TasksProjectsMobileSliverBody(compact: true)],
    );
  }
}

class IconBadge extends StatelessWidget {
  const IconBadge({required this.icon, required this.color, super.key});
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Icon(icon, color: color),
  );
}

class FloatingActionTaskButton extends StatelessWidget {
  const FloatingActionTaskButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [DashboardColors.primary, DashboardColors.secondary],
        ),
        boxShadow: [
          BoxShadow(
            color: DashboardColors.primary.withValues(alpha: .35),
            blurRadius: 30,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {},
          child: const Icon(
            Icons.add_rounded,
            color: DashboardColors.onPrimary,
            size: 34,
          ),
        ),
      ),
    );
  }
}

class MobileBottomNavBar extends StatelessWidget {
  const MobileBottomNavBar({required this.bottomInset, super.key});

  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    String location = '/home';
    try {
      location = GoRouterState.of(context).matchedLocation;
    } catch (_) {}

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: EdgeInsets.fromLTRB(12, 10, 12, 10 + bottomInset),
          decoration: BoxDecoration(
            color: DashboardColors.surface.withValues(alpha: .48),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: .10)),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _BottomNavItem(
                icon: Icons.home_rounded,
                label: 'Dashboard',
                active: location == '/home' || location == '/',
                onTap: () => context.go('/home'),
              ),
              _BottomNavItem(
                icon: Icons.assignment_rounded,
                label: 'Tasks',
                active: location == '/tasks',
                onTap: () => context.go('/tasks'),
              ),
              _BottomNavItem(
                icon: Icons.dynamic_feed_rounded,
                label: 'Feed',
                active: location == '/feed',
                onTap: () => context.go('/feed'),
              ),
              _BottomNavItem(
                icon: Icons.forum_rounded,
                label: 'Messages',
                active: location == '/messages',
                onTap: () => context.go('/messages'),
              ),
              _BottomNavItem(
                icon: Icons.person_rounded,
                label: 'Profile',
                active: location == '/profile',
                onTap:
                    ProfileNavigationScope.maybeOf(context)?.onProfileSelected ??
                    () => context.go('/profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.label,
    this.active = false,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? DashboardColors.primaryContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(DashboardRadii.full),
      child: InkWell(
        borderRadius: BorderRadius.circular(DashboardRadii.full),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: active ? 14 : 8,
            vertical: 7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: active ? Colors.white : DashboardColors.onSurfaceVariant,
                size: 22,
              ),
              Text(
                label,
                style: TextStyle(
                  color:
                      active ? Colors.white : DashboardColors.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SystemStatusBar extends StatelessWidget {
  const _SystemStatusBar();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.circle, color: Color(0xFF4ADE80), size: 9),
        SizedBox(width: 6),
        Flexible(
          child: Text(
            'SYSTEM: OPTIMAL',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: DashboardColors.outline,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: .8,
            ),
          ),
        ),
        SizedBox(width: 12),
        Flexible(
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              'LAST SYNC: 2 MINS AGO',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: DashboardColors.outline,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: .8,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
