import 'package:flutter/material.dart';
import 'design_system.dart';

class SocialProofSection extends StatelessWidget {
  const SocialProofSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        children: [
          _buildStatCard(
            '50K+',
            'Power Users Active',
            borderColor: LandingColors.primary,
          ),
          const SizedBox(width: 16.0),
          _buildStatCard(
            '4.9/5',
            'Average Rating',
            borderColor: LandingColors.success,
          ),
          const SizedBox(width: 16.0),
          _buildStatCard(
            '1M+',
            'Tasks Optimized',
            borderColor: LandingColors.tertiary,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, {required Color borderColor}) {
    return SizedBox(
      width: 256.0,
      child: GlassCard(
        borderRadius: 16.0,
        padding: EdgeInsets.zero,
        child: Stack(
          children: [
            // Left border highlight
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 4.0,
                color: borderColor,
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(28.0, 24.0, 24.0, 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: getLandingGeistStyle(
                      fontSize: 32.0,
                      fontWeight: FontWeight.w700,
                      color: LandingColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    label.toUpperCase(),
                    style: getLandingGeistStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w600,
                      color: LandingColors.textSecondary,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
