import 'package:flutter/material.dart';
import 'edit_profile_shared.dart';

class AchievementsCard extends StatelessWidget {
  const AchievementsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final achievements = [
      _Badge(
        title: 'STREAK 7',
        icon: Icons.workspace_premium,
        color: EditProfileColors.primary,
        isUnlocked: true,
      ),
      _Badge(
        title: '100 TASKS',
        icon: Icons.task_alt,
        color: EditProfileColors.secondary,
        isUnlocked: true,
      ),
      _Badge(
        title: '100 HRS',
        icon: Icons.timer,
        color: Colors.cyanAccent,
        isUnlocked: true,
      ),
      _Badge(
        title: 'ZEN MASTER',
        icon: Icons.self_improvement,
        color: EditProfileColors.primary,
        isUnlocked: false,
      ),
      _Badge(
        title: 'OVERDRIVE',
        icon: Icons.bolt,
        color: EditProfileColors.secondary,
        isUnlocked: false,
      ),
      _Badge(
        title: 'UNSTOPPABLE',
        icon: Icons.shield,
        color: Colors.cyanAccent,
        isUnlocked: false,
      ),
    ];

    return EditProfileGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Achievements',
                style: TextStyle(
                  color: EditProfileColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'View All',
                style: TextStyle(
                  color: EditProfileColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 400;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isWide ? 3 : 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.0,
                ),
                itemCount: achievements.length,
                itemBuilder: (context, index) {
                  final badge = achievements[index];
                  return _buildBadgeCard(badge);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeCard(_Badge badge) {
    final bgColor = badge.isUnlocked
        ? badge.color.withValues(alpha: 0.05)
        : Colors.white.withValues(alpha: 0.01);
    final borderColor = badge.isUnlocked
        ? badge.color.withValues(alpha: 0.2)
        : EditProfileColors.borderSides;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Opacity(
        opacity: badge.isUnlocked ? 1.0 : 0.3,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              badge.icon,
              color: badge.color,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              badge.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: EditProfileColors.textPrimary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge {
  _Badge({
    required this.title,
    required this.icon,
    required this.color,
    required this.isUnlocked,
  });

  final String title;
  final IconData icon;
  final Color color;
  final bool isUnlocked;
}
