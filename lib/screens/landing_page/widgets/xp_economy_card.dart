import 'package:flutter/material.dart';
import 'design_system.dart';

class XpEconomyCard extends StatelessWidget {
  final bool isMobile;

  const XpEconomyCard({super.key, this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return GlassCard(
        padding: const EdgeInsets.all(24.0),
        borderRadius: 28.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LEVEL 42',
                      style: getLandingGeistStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w600,
                        color: LandingColors.textSecondary,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      'Visionary Architect',
                      style: getLandingGeistStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.w700,
                        color: LandingColors.textPrimary,
                        letterSpacing: -0.48,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: LandingColors.success.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: Text(
                    '+450 XP',
                    style: getLandingGeistMonoStyle(
                      fontSize: 13.0,
                      fontWeight: FontWeight.w500,
                      color: LandingColors.success,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            
            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(9999.0),
              child: Container(
                height: 8.0,
                width: double.infinity,
                color: LandingColors.surfaceVariant,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: 0.75,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: LandingColors.primary,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xCC131449),
                            blurRadius: 10.0,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8.0),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '12,400 XP',
                  style: getLandingGeistMonoStyle(
                    fontSize: 13.0,
                    fontWeight: FontWeight.w500,
                    color: LandingColors.textSecondary,
                  ),
                ),
                Text(
                  '15,000 XP',
                  style: getLandingGeistMonoStyle(
                    fontSize: 13.0,
                    fontWeight: FontWeight.w500,
                    color: LandingColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      return GlassCard(
        padding: const EdgeInsets.all(24.0),
        bgColor: LandingColors.surface, // Matches CSS gradient-to-br from-surface-container to-surface-dim
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.leaderboard,
              color: LandingColors.tertiary,
              size: 40.0,
            ),
            const SizedBox(height: 16.0),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'XP Economy',
                      style: getLandingGeistStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.w600,
                        color: LandingColors.textPrimary,
                        letterSpacing: -0.48,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      'Every task completed earns you XP. Unlock new themes, custom badges, and executive dashboard features as you level up.',
                      style: getLandingGeistStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w400,
                        color: LandingColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}
