import 'package:flutter/material.dart';
import 'design_system.dart';
import 'achievement_card.dart';

class RewardsSection extends StatelessWidget {
  final double width;

  const RewardsSection({super.key, required this.width});

  @override
  Widget build(BuildContext context) {
    final isDesktop = width >= 1200;
    final isTablet = width >= 768 && width < 1200;

    return Container(
      width: double.infinity,
      color: LandingColors.surfaceContainerLow, // Matches bg-surface-container-low
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1440.0),
          child: Column(
            children: [
              // Header & Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TaskFlow Rewards',
                          style: getLandingGeistStyle(
                            fontSize: 32.0,
                            fontWeight: FontWeight.w600,
                            color: LandingColors.textPrimary,
                            letterSpacing: -0.64,
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 576.0),
                          child: Text(
                            'Don\'t just work—evolve. Our gamified system transforms mundane checklists into an addictive quest for professional mastery.',
                            style: getLandingGeistStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.w400,
                              color: LandingColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isDesktop || isTablet)
                    GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                      borderRadius: 9999.0,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star,
                            color: LandingColors.tertiary,
                            size: 16.0,
                          ),
                          const SizedBox(width: 8.0),
                          Text(
                            'Legendary Status',
                            style: getLandingGeistMonoStyle(
                              fontSize: 13.0,
                              fontWeight: FontWeight.w500,
                              color: LandingColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 48.0),

              // Achievement Cards Layout
              if (isDesktop)
                const SizedBox(
                  height: 280.0,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: _WorkKingCard()),
                      SizedBox(width: 24.0),
                      Expanded(child: _SynergistCard()),
                      SizedBox(width: 24.0),
                      Expanded(child: _CrusherCard()),
                      SizedBox(width: 24.0),
                      Expanded(child: _FocusCard()),
                    ],
                  ),
                )
              else if (isTablet)
                const Column(
                  children: [
                    SizedBox(
                      height: 280.0,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: _WorkKingCard()),
                          SizedBox(width: 24.0),
                          Expanded(child: _SynergistCard()),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.0),
                    SizedBox(
                      height: 280.0,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: _CrusherCard()),
                          SizedBox(width: 24.0),
                          Expanded(child: _FocusCard()),
                        ],
                      ),
                    ),
                  ],
                )
              else
                // Mobile List
                const Column(
                  children: [
                    SizedBox(height: 240.0, child: _WorkKingCard()),
                    SizedBox(height: 16.0),
                    SizedBox(height: 240.0, child: _SynergistCard()),
                    SizedBox(height: 16.0),
                    SizedBox(height: 240.0, child: _CrusherCard()),
                    SizedBox(height: 16.0),
                    SizedBox(height: 240.0, child: _FocusCard()),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkKingCard extends StatelessWidget {
  const _WorkKingCard();

  @override
  Widget build(BuildContext context) {
    return const AchievementCard(
      icon: Icons.military_tech,
      iconColor: LandingColors.primary,
      title: 'Deep Work King',
      description: 'Completed 50 hours of uninterrupted work sessions.',
      rarity: 'Rare Achievement',
      rarityColor: LandingColors.primary,
      xp: '+500 XP',
    );
  }
}

class _SynergistCard extends StatelessWidget {
  const _SynergistCard();

  @override
  Widget build(BuildContext context) {
    return const AchievementCard(
      icon: Icons.auto_awesome,
      iconColor: LandingColors.tertiary,
      title: 'AI Synergist',
      description: 'Implemented 10 AI-suggested schedule optimizations.',
      rarity: 'Uncommon',
      rarityColor: LandingColors.tertiary,
      xp: '+250 XP',
    );
  }
}

class _CrusherCard extends StatelessWidget {
  const _CrusherCard();

  @override
  Widget build(BuildContext context) {
    return const AchievementCard(
      icon: Icons.verified,
      iconColor: LandingColors.success,
      title: 'Task Crusher',
      description: 'Completed all tasks within the set estimate for 7 days.',
      rarity: 'Common',
      rarityColor: LandingColors.success,
      xp: '+100 XP',
    );
  }
}

class _FocusCard extends StatelessWidget {
  const _FocusCard();

  @override
  Widget build(BuildContext context) {
    return const AchievementCard(
      icon: Icons.diamond,
      iconColor: LandingColors.secondary,
      title: 'Infinite Focus',
      description: 'Reach Level 50 and unlock the high-density dashboard.',
      rarity: 'Legendary',
      rarityColor: LandingColors.secondary,
      xp: '+1000 XP',
    );
  }
}
