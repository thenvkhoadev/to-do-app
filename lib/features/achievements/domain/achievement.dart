import 'package:flutter/material.dart';

enum AchievementRarity {
  bronze,
  silver,
  gold,
  diamond,
  elite,
  master,
  challenger,
  grandmaster,
  supreme,
  legend,
  immortal,
  mythic,
}

extension AchievementRarityExtension on AchievementRarity {
  String get label => switch (this) {
        AchievementRarity.bronze => 'Bronze',
        AchievementRarity.silver => 'Silver',
        AchievementRarity.gold => 'Gold',
        AchievementRarity.diamond => 'Diamond',
        AchievementRarity.elite => 'Elite',
        AchievementRarity.master => 'Master',
        AchievementRarity.challenger => 'Challenger',
        AchievementRarity.grandmaster => 'Grandmaster',
        AchievementRarity.supreme => 'Supreme',
        AchievementRarity.legend => 'Legend',
        AchievementRarity.immortal => 'Immortal',
        AchievementRarity.mythic => 'Mythic',
      };

  Color get color => switch (this) {
        AchievementRarity.bronze => const Color(0xFFB87333),
        AchievementRarity.silver => const Color(0xFFC0C0C0),
        AchievementRarity.gold => const Color(0xFFFFD700),
        AchievementRarity.diamond => const Color(0xFF59D5FF),
        AchievementRarity.elite => const Color(0xFF00FFC6),
        AchievementRarity.master => const Color(0xFF9C27B0),
        AchievementRarity.challenger => const Color(0xFFFF5722),
        AchievementRarity.grandmaster => const Color(0xFFF44336),
        AchievementRarity.supreme => const Color(0xFFFF1744),
        AchievementRarity.legend => const Color(0xFFFF9800),
        AchievementRarity.immortal => const Color(0xFF00E5FF),
        AchievementRarity.mythic => const Color(0xFFE91E63),
      };

  String get effectDescription => switch (this) {
        AchievementRarity.bronze => 'Basic border',
        AchievementRarity.silver => 'Soft shine metallic',
        AchievementRarity.gold => 'Gold glow aura',
        AchievementRarity.diamond => 'Crystal cyan aura',
        AchievementRarity.elite => 'Turquoise energy aura',
        AchievementRarity.master => 'Purple glow aura',
        AchievementRarity.challenger => 'Fiery flame effect',
        AchievementRarity.grandmaster => 'Crimson wing aura',
        AchievementRarity.supreme => 'Double scarlet aura',
        AchievementRarity.legend => 'Crown halo overlay',
        AchievementRarity.immortal => 'Orbital energy ring',
        AchievementRarity.mythic => 'Galaxy cosmic particles',
      };
}

class Achievement {
  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    required this.rarity,
    required this.xpReward,
    required this.currentValue,
    required this.targetValue,
    required this.isUnlocked,
    this.svgName,
    this.unlockedAt,
  });

  final String id;
  final String name;
  final String description;
  final IconData icon;
  final String category; // e.g. Tasks, Focus, Streak, XP, Projects, AI, Social, Special
  final AchievementRarity rarity;
  final int xpReward;
  final int currentValue;
  final int targetValue;
  final bool isUnlocked;
  final String? svgName;
  final DateTime? unlockedAt;

  double get progress => targetValue == 0 ? 0.0 : (currentValue / targetValue).clamp(0.0, 1.0);
}
