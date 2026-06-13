import 'package:flutter/material.dart';
import 'design_system.dart';

class AchievementCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final String rarity;
  final Color rarityColor;
  final String xp;

  const AchievementCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.rarity,
    required this.rarityColor,
    required this.xp,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 24.0,
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          // Top border highlight
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 2.0,
              color: iconColor.withValues(alpha: 0.30),
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Icon(
                  icon,
                  color: iconColor,
                  size: 48.0,
                ),
                const SizedBox(height: 16.0),
                
                // Title
                Text(
                  title,
                  style: getLandingGeistStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.w600,
                    color: LandingColors.textPrimary,
                    letterSpacing: -0.48,
                  ),
                ),
                const SizedBox(height: 4.0),
                
                // Description
                Expanded(
                  child: Text(
                    description,
                    style: getLandingGeistStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w400,
                      color: LandingColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 24.0),
                
                // Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      rarity.toUpperCase(),
                      style: getLandingGeistMonoStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w600,
                        color: rarityColor,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      xp,
                      style: getLandingGeistMonoStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w600,
                        color: LandingColors.secondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
