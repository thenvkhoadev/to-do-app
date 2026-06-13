import 'package:flutter/material.dart';
import 'design_system.dart';

class StreakCard extends StatelessWidget {
  final bool isMobile;

  const StreakCard({super.key, this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return GlassCard(
        padding: const EdgeInsets.all(24.0),
        borderRadius: 28.0,
        bgColor: LandingColors.surface, // Matches gradient from-surface-container to-surface
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'CURRENT STREAK',
                  style: getLandingGeistStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w600,
                    color: LandingColors.textSecondary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4.0),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '12',
                      style: getLandingGeistStyle(
                        fontSize: 32.0,
                        fontWeight: FontWeight.w900,
                        color: LandingColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Text(
                      'Days',
                      style: getLandingGeistStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w400,
                        color: LandingColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Stack(
              alignment: Alignment.center,
              children: [
                // Glowing background circle
                Container(
                  width: 56.0,
                  height: 56.0,
                  decoration: BoxDecoration(
                    color: LandingColors.tertiary.withValues(alpha: 0.20),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: LandingColors.tertiary.withValues(alpha: 0.30),
                        blurRadius: 16.0,
                        spreadRadius: 4.0,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.local_fire_department,
                  color: LandingColors.tertiary,
                  size: 48.0,
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      return GlassCard(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80.0,
                      height: 80.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: LandingColors.errorRed.withValues(alpha: 0.20),
                          width: 4.0,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.local_fire_department,
                          color: LandingColors.errorRed,
                          size: 40.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    Text(
                      '14 Day Streak',
                      style: getLandingGeistStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.w600,
                        color: LandingColors.textPrimary,
                        letterSpacing: -0.48,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      'Maintain your momentum. Get smart nudges when you\'re about to lose your flow.',
                      style: getLandingGeistStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w400,
                        color: LandingColors.textSecondary,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
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
