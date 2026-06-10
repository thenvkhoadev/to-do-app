class StreakAchievement {
  const StreakAchievement({
    required this.title,
    required this.description,
    required this.xpReward,
  });

  final String title;
  final String description;
  final int xpReward;
}

class StreakService {
  const StreakService();

  static const List<int> milestones = [7, 14, 30, 60, 100, 365];

  int getNextMilestone(int currentStreak) {
    for (final m in milestones) {
      if (m > currentStreak) {
        return m;
      }
    }
    // Fallback: round up to the next 50-day milestone
    return ((currentStreak / 50).floor() + 1) * 50;
  }
}

class AchievementService {
  const AchievementService();

  StreakAchievement getAchievementForMilestone(int milestone, int currentStreak) {
    final remaining = milestone - currentStreak;
    final String title;
    final int xpReward;

    switch (milestone) {
      case 7:
        title = 'Weekly Warrior';
        xpReward = 50;
        break;
      case 14:
        title = 'Fortnight Force';
        xpReward = 100;
        break;
      case 30:
        title = 'Monthly Master';
        xpReward = 200;
        break;
      case 60:
        title = 'Consistency King';
        xpReward = 400;
        break;
      case 100:
        title = 'Centurion Elite';
        xpReward = 1000;
        break;
      default:
        title = 'Streak Master';
        xpReward = milestone * 10;
    }

    final plural = remaining == 1 ? 'day' : 'days';
    final description = 'Complete $remaining more $plural';

    return StreakAchievement(
      title: title,
      description: description,
      xpReward: xpReward,
    );
  }
}
