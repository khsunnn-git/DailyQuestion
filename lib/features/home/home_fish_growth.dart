enum HomeFishGrowthLevel {
  level1,
  level2,
  level3,
  level4,
  level5,
  level6;

  int get number => index + 1;
}

HomeFishGrowthLevel homeFishGrowthLevelForRecordCount(int recordCount) {
  final int normalizedCount = recordCount < 0 ? 0 : recordCount;
  if (normalizedCount >= 45) {
    return HomeFishGrowthLevel.level6;
  }
  if (normalizedCount >= 31) {
    return HomeFishGrowthLevel.level5;
  }
  if (normalizedCount >= 17) {
    return HomeFishGrowthLevel.level4;
  }
  if (normalizedCount >= 10) {
    return HomeFishGrowthLevel.level3;
  }
  if (normalizedCount >= 3) {
    return HomeFishGrowthLevel.level2;
  }
  return HomeFishGrowthLevel.level1;
}

extension HomeFishGrowthLevelDetails on HomeFishGrowthLevel {
  int get requiredRecordCount => switch (this) {
    HomeFishGrowthLevel.level1 => 0,
    HomeFishGrowthLevel.level2 => 3,
    HomeFishGrowthLevel.level3 => 10,
    HomeFishGrowthLevel.level4 => 17,
    HomeFishGrowthLevel.level5 => 31,
    HomeFishGrowthLevel.level6 => 45,
  };

  bool get canCelebrate => this != HomeFishGrowthLevel.level1;

  String get celebrationHeadline => switch (this) {
    HomeFishGrowthLevel.level1 => "물고기와 첫 만남이에요!",
    HomeFishGrowthLevel.level2 => "작은 물고기로 자라났어요!",
    HomeFishGrowthLevel.level3 => "제법 자라났어요!",
    HomeFishGrowthLevel.level4 => "더 크게 자라났어요!",
    HomeFishGrowthLevel.level5 => "무럭무럭 자랐어요!",
    HomeFishGrowthLevel.level6 => "물고기가 어른이 되었어요!",
  };
}
