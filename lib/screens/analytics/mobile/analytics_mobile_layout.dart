import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:to_do_app/constants/dashboard_constants.dart';
import 'package:to_do_app/screens/analytics/mobile/mobile_ai_insight.dart';
import 'package:to_do_app/screens/analytics/mobile/mobile_bottom_navigation.dart';
import 'package:to_do_app/screens/analytics/mobile/mobile_category_card.dart';
import 'package:to_do_app/screens/analytics/mobile/mobile_chart_card.dart';
import 'package:to_do_app/screens/analytics/mobile/mobile_focus_score.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';
import 'package:to_do_app/widgets/dashboard/dashboard_shared.dart';

class AnalyticsMobileLayout extends StatelessWidget {
  const AnalyticsMobileLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Stack(
      children: [
        Positioned.fill(
          child: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 92)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  DashboardSpacing.md,
                  0,
                  DashboardSpacing.md,
                  136,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: const [
                      MobileFocusScore(),
                      SizedBox(height: DashboardSpacing.lg),
                      MobileChartCard(),
                      SizedBox(height: DashboardSpacing.md),
                      MobileAiInsight(),
                      SizedBox(height: DashboardSpacing.md),
                      MobileCategoryCard(),
                      SizedBox(height: DashboardSpacing.md),
                      _MobileSessionStats(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _AnalyticsMobileTopBar(),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: AnalyticsMobileBottomNavigation(bottomInset: bottomInset),
        ),
      ],
    );
  }
}

class _AnalyticsMobileTopBar extends StatelessWidget {
  const _AnalyticsMobileTopBar();

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
              color: DashboardColors.surface.withValues(alpha: .48),
              border: Border(
                bottom: BorderSide(
                  color: DashboardColors.primaryContainer.withValues(
                    alpha: .18,
                  ),
                ),
              ),
            ),
            child: const Row(
              children: [
                ProfileAvatar(radius: 19),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Analytics',
                    style: TextStyle(
                      color: DashboardColors.primary,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.5,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Icon(
                  Icons.auto_awesome_rounded,
                  color: DashboardColors.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileSessionStats extends StatelessWidget {
  const _MobileSessionStats();

  @override
  Widget build(BuildContext context) {
    return const GlassCard(
      child: Row(
        children: [
          Expanded(child: _StatBlock(label: 'Sessions', value: '12')),
          _Divider(),
          Expanded(child: _StatBlock(label: 'Focus', value: '34.5h')),
          _Divider(),
          Expanded(child: _StatBlock(label: 'Score', value: '92%')),
        ],
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: DashboardColors.primary,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(
            color: DashboardColors.onSurfaceVariant,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 38,
    child: VerticalDivider(color: Colors.white.withValues(alpha: .08)),
  );
}
