class XpLevelProgress {
  const XpLevelProgress({
    required this.level,
    required this.levelStartXp,
    required this.nextLevelXp,
    required this.xpIntoLevel,
    required this.xpForNextLevel,
    required this.progress,
  });

  final int level;
  final int levelStartXp;
  final int nextLevelXp;
  final int xpIntoLevel;
  final int xpForNextLevel;
  final double progress;
}

class XpRank {
  const XpRank({
    required this.name,
    required this.division,
    required this.title,
  });

  final String name;
  final String division;
  final String title;
}

class _RankBand {
  const _RankBand(this.name, this.minLevel, this.maxLevel);

  final String name;
  final int minLevel;
  final int? maxLevel;
}

const _rankBands = [
  _RankBand('Rookie', 1, 4),
  _RankBand('Apprentice', 5, 9),
  _RankBand('Explorer', 10, 19),
  _RankBand('Challenger', 20, 34),
  _RankBand('Elite', 35, 54),
  _RankBand('Master', 55, 79),
  _RankBand('Grandmaster', 80, 119),
  _RankBand('Legend', 120, 199),
  _RankBand('Mythic', 200, 349),
  _RankBand('Eternal', 350, null),
];

const _divisions = ['V', 'IV', 'III', 'II', 'I'];

int xpRequiredForLevel(int level) {
  if (level <= 1) return 0;
  var total = 0;
  for (var nextLevel = 2; nextLevel <= level; nextLevel++) {
    total += xpRequiredToAdvanceToLevel(nextLevel);
  }
  return total;
}

int xpRequiredToAdvanceToLevel(int nextLevel) {
  if (nextLevel <= 2) return 50;
  return 50 + ((nextLevel - 2) * 25) + ((nextLevel - 2) * (nextLevel - 2) * 5);
}

int xpLevelFromTotalXp(int totalXp) {
  final safeTotal = totalXp < 0 ? 0 : totalXp;
  var level = 1;
  while (safeTotal >= xpRequiredForLevel(level + 1)) {
    level++;
  }
  return level;
}

XpLevelProgress xpProgressFromTotalXp(int totalXp) {
  final safeTotal = totalXp < 0 ? 0 : totalXp;
  final level = xpLevelFromTotalXp(safeTotal);
  final levelStart = xpRequiredForLevel(level);
  final nextLevel = xpRequiredForLevel(level + 1);
  final xpInto = (safeTotal - levelStart).clamp(0, 1 << 30);
  final xpNeeded = (nextLevel - levelStart).clamp(1, 1 << 30);
  return XpLevelProgress(
    level: level,
    levelStartXp: levelStart,
    nextLevelXp: nextLevel,
    xpIntoLevel: xpInto,
    xpForNextLevel: xpNeeded,
    progress: (xpInto / xpNeeded).clamp(0.0, 1.0),
  );
}

XpRank xpRankForLevel(int level) {
  final safeLevel = level < 1 ? 1 : level;
  final band = _rankBands.lastWhere(
    (band) =>
        safeLevel >= band.minLevel &&
        (band.maxLevel == null || safeLevel <= band.maxLevel!),
  );
  final maxLevel = band.maxLevel;
  if (maxLevel == null) {
    return XpRank(name: band.name, division: 'I', title: '${band.name} I');
  }

  final bandSize = maxLevel - band.minLevel + 1;
  final position = safeLevel - band.minLevel;
  final divisionIndex = ((position * _divisions.length) ~/ bandSize).clamp(
    0,
    _divisions.length - 1,
  );
  final division = _divisions[divisionIndex];
  return XpRank(
    name: band.name,
    division: division,
    title: '${band.name} $division',
  );
}
