import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:to_do_app/constants/dashboard_constants.dart';
import 'package:to_do_app/screens/tasks_projects/tasks_projects_content.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';
import 'package:to_do_app/widgets/dashboard/dashboard_shared.dart';

class MobileDashboardLayout extends StatelessWidget {
  const MobileDashboardLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Stack(
      children: [
        const Positioned.fill(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: SizedBox(height: 88)),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  DashboardSpacing.md,
                  0,
                  DashboardSpacing.md,
                  132,
                ),
                sliver: SliverToBoxAdapter(child: MobileDashboardContent()),
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
        FocusProgressCard(),
        SizedBox(height: DashboardSpacing.md),
        FocusTimerCard(),
        SizedBox(height: DashboardSpacing.md),
        AnalyticsCard(),
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
                    'TaskFlow AI',
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

class MobileHeroSection extends StatelessWidget {
  const MobileHeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isTight = MediaQuery.sizeOf(context).width < 380;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          label: 'System Ready',
          color: DashboardColors.primary,
        ),
        const SizedBox(height: 12),
        Text.rich(
          const TextSpan(
            text: 'Good morning, ',
            children: [
              TextSpan(
                text: 'Alex',
                style: TextStyle(color: DashboardColors.primary),
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
        const Text(
          'Your productivity cycle is peaking. It is the perfect time for deep work.',
          style: TextStyle(
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

class AIRecommendationMobileCard extends StatelessWidget {
  const AIRecommendationMobileCard({super.key});

  @override
  Widget build(BuildContext context) {
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
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI RECOMMENDATION',
                      style: TextStyle(
                        color: DashboardColors.outline,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Next best task: Review Q3 Plan',
                      style: TextStyle(
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

class FocusProgressCard extends StatelessWidget {
  const FocusProgressCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const GlassCard(
      padding: EdgeInsets.all(28),
      child: Column(
        children: [
          CircularScore(value: .85, label: 'FOCUSED', size: 190),
          SizedBox(height: 22),
          Text(
            'You are 15% ahead of your weekly average. Keep the momentum.',
            textAlign: TextAlign.center,
            style: TextStyle(
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

class AnalyticsCard extends StatelessWidget {
  const AnalyticsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
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
          SizedBox(height: 18),
          AnalyticsBars(
            values: [.6, .45, .8, .55, .9, .75, .2],
            labels: ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
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
                label: 'Home',
                active: true,
                onTap: () => context.go('/home'),
              ),
              _BottomNavItem(
                icon: Icons.calendar_month_rounded,
                label: 'Calendar',
                onTap: () => context.go('/calendar'),
              ),
              _BottomNavItem(
                icon: Icons.assignment_rounded,
                label: 'Tasks',
                onTap: () => context.go('/tasks'),
              ),
              _BottomNavItem(
                icon: Icons.bar_chart_rounded,
                label: 'Stats',
                onTap: () => context.go('/analytics'),
              ),
              _BottomNavItem(
                icon: Icons.person_rounded,
                label: 'Profile',
                onTap:
                    ProfileNavigationScope.maybeOf(context) ??
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
