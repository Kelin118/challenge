class LevelData {
  const LevelData({
    required this.level,
    required this.currentLevelMinXp,
    required this.nextLevelXp,
    required this.levelProgress,
    required this.nextLevelDelta,
  });

  final int level;
  final int currentLevelMinXp;
  final int nextLevelXp;
  final double levelProgress;
  final int nextLevelDelta;
}

LevelData calculateLevel(int xp) {
  final level = (xp / 120).sqrtFloor() + 1;
  final currentLevelMinXp = (level - 1) * (level - 1) * 120;
  final nextLevelXp = level * level * 120;
  final levelProgress = nextLevelXp == currentLevelMinXp
      ? 1.0
      : (xp - currentLevelMinXp) / (nextLevelXp - currentLevelMinXp);

  return LevelData(
    level: level,
    currentLevelMinXp: currentLevelMinXp,
    nextLevelXp: nextLevelXp,
    levelProgress: levelProgress.clamp(0.0, 1.0),
    nextLevelDelta: (nextLevelXp - xp).clamp(0, nextLevelXp),
  );
}

extension on num {
  int sqrtFloor() {
    var x = 0;
    while ((x + 1) * (x + 1) <= this) {
      x++;
    }
    return x;
  }
}
