import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:to_do_app/constants/dashboard_constants.dart';
import 'package:to_do_app/features/achievements/domain/achievement.dart';
import 'package:to_do_app/features/achievements/widgets/badge_widget.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class AchievementDetailModal extends StatelessWidget {
  const AchievementDetailModal({required this.achievement, super.key});

  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    final color = achievement.rarity.color;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
      child: Center(
        child: Container(
          width: 380,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: DashboardColors.surfaceLowest.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: color.withValues(alpha: 0.25), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: 32,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top close button
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, color: DashboardColors.onSurfaceVariant),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Large Badge
                  Hero(
                    tag: 'achievement-badge-${achievement.id}',
                    child: BadgeWidget(
                      rarity: achievement.rarity,
                      icon: achievement.icon,
                      svgName: achievement.svgName,
                      size: 96,
                      isLocked: !achievement.isUnlocked,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Name
                  Text(
                    achievement.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: DashboardColors.onSurface,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Rarity Info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${achievement.rarity.label} Rarity',
                        style: TextStyle(
                          color: color,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Requirement Description
                  Text(
                    achievement.description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: DashboardColors.onSurfaceVariant,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: Colors.white12, height: 1),
                  const SizedBox(height: 20),
                  // Progress details
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Progression',
                        style: TextStyle(
                          color: DashboardColors.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        achievement.isUnlocked
                            ? '100% Unlocked'
                            : '${(achievement.progress * 100).round()}% Completed',
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(DashboardRadii.full),
                    child: Stack(
                      children: [
                        Container(
                          height: 8,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                        FractionallySizedBox(
                          widthFactor: achievement.progress,
                          child: Container(
                            height: 8,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      achievement.isUnlocked
                          ? 'Criteria met (${achievement.targetValue}/${achievement.targetValue})'
                          : 'Progress: ${achievement.currentValue} / ${achievement.targetValue}',
                      style: const TextStyle(
                        color: DashboardColors.onSurfaceVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Rewards and Unlock date
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'REWARD',
                              style: TextStyle(
                                color: DashboardColors.onSurfaceVariant,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '+${achievement.xpReward} XP',
                              style: const TextStyle(
                                color: DashboardColors.secondary,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              achievement.isUnlocked ? 'UNLOCKED AT' : 'STATUS',
                              style: const TextStyle(
                                color: DashboardColors.onSurfaceVariant,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              achievement.isUnlocked && achievement.unlockedAt != null
                                  ? DateFormat('MMM d, yyyy').format(achievement.unlockedAt!)
                                  : 'In Progress',
                              style: TextStyle(
                                color: achievement.isUnlocked ? DashboardColors.success : DashboardColors.warning,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Share Button
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Achievement shared with your workspace!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: const Text('Share Achievement'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
