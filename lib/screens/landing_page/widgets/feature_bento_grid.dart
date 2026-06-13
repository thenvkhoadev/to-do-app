import 'package:flutter/material.dart';
import 'design_system.dart';
import 'ai_intelligence_card.dart';
import 'xp_economy_card.dart';
import 'streak_card.dart';
import 'analytics_card.dart';

class FeatureBentoGrid extends StatelessWidget {
  final double width;

  const FeatureBentoGrid({super.key, required this.width});

  @override
  Widget build(BuildContext context) {
    final isDesktop = width >= 1200;
    final isTablet = width >= 768 && width < 1200;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1440.0),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
        child: Column(
          children: [
            // Header
            Text(
              'Master Your Output',
              style: getLandingGeistStyle(
                fontSize: 32.0,
                fontWeight: FontWeight.w600,
                color: LandingColors.textPrimary,
                letterSpacing: -0.64,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16.0),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640.0),
              child: Text(
                'Designed for those who view productivity as an art form. Every feature is tuned for peak performance.',
                style: getLandingGeistStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w400,
                  color: LandingColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 48.0),

            // Grid Layout
            if (isDesktop)
              Column(
                children: [
                  const SizedBox(
                    height: 250.0,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(flex: 8, child: AiIntelligenceCard()),
                        SizedBox(width: 24.0),
                        Expanded(flex: 4, child: XpEconomyCard(isMobile: false)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  const SizedBox(
                    height: 250.0,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(flex: 4, child: StreakCard(isMobile: false)),
                        SizedBox(width: 24.0),
                        Expanded(flex: 8, child: AnalyticsCard()),
                      ],
                    ),
                  ),
                ],
              )
            else if (isTablet)
              Column(
                children: [
                  const SizedBox(
                    height: 250.0,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(flex: 8, child: AiIntelligenceCard()),
                        SizedBox(width: 24.0),
                        Expanded(flex: 4, child: XpEconomyCard(isMobile: false)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  const SizedBox(
                    height: 250.0,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(flex: 4, child: StreakCard(isMobile: false)),
                        SizedBox(width: 24.0),
                        Expanded(flex: 8, child: AnalyticsCard()),
                      ],
                    ),
                  ),
                ],
              )
            else
              // Mobile View (if rendered as list fallback)
              const Column(
                children: [
                  SizedBox(height: 250.0, child: AiIntelligenceCard()),
                  SizedBox(height: 24.0),
                  SizedBox(height: 250.0, child: XpEconomyCard(isMobile: false)),
                  SizedBox(height: 24.0),
                  SizedBox(height: 250.0, child: StreakCard(isMobile: false)),
                  SizedBox(height: 24.0),
                  SizedBox(height: 250.0, child: AnalyticsCard()),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
