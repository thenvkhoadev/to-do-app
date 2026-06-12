import 'package:flutter/material.dart';
import 'package:to_do_app/constants/dashboard_constants.dart';
import 'package:to_do_app/features/achievements/domain/achievement.dart';
import 'package:to_do_app/features/achievements/widgets/achievement_detail_modal.dart';
import 'package:to_do_app/features/achievements/widgets/badge_widget.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class AchievementCard extends StatefulWidget {
  const AchievementCard({required this.achievement, super.key});

  final Achievement achievement;

  @override
  State<AchievementCard> createState() => _AchievementCardState();
}

class _AchievementCardState extends State<AchievementCard> {
  bool _isHovered = false;

  void _showDetails(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (context) => AchievementDetailModal(achievement: widget.achievement),
    );
  }

  @override
  Widget build(BuildContext context) {
    final achievement = widget.achievement;
    final color = achievement.rarity.color;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _showDetails(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          transform: Matrix4.diagonal3Values(
            _isHovered ? 1.04 : 1.0,
            _isHovered ? 1.04 : 1.0,
            1.0,
          ),
          transformAlignment: Alignment.center,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: _isHovered ? 0.05 : 0.02),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isHovered
                  ? color.withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.06),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? color.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.2),
                blurRadius: _isHovered ? 16 : 8,
                spreadRadius: _isHovered ? 2 : 0,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Badge
              Hero(
                tag: 'achievement-badge-${achievement.id}',
                child: BadgeWidget(
                  rarity: achievement.rarity,
                  icon: achievement.icon,
                  svgName: achievement.svgName,
                  size: 56,
                  isLocked: !achievement.isUnlocked,
                ),
              ),
              const SizedBox(height: 12),
              // Name
              Text(
                achievement.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: DashboardColors.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              // Rarity Label
              Text(
                achievement.rarity.label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              // Progress indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      achievement.isUnlocked
                          ? 'Unlocked'
                          : '${achievement.currentValue}/${achievement.targetValue} ${achievement.category == 'Streak' ? 'days' : achievement.category == 'Focus' ? 'hrs' : 'tasks'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: DashboardColors.onSurfaceVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '+${achievement.xpReward} XP',
                    style: const TextStyle(
                      color: DashboardColors.secondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(DashboardRadii.full),
                child: Stack(
                  children: [
                    Container(
                      height: 4,
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                    FractionallySizedBox(
                      widthFactor: achievement.progress,
                      child: Container(
                        height: 4,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
