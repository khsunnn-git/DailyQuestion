import "home_fish_growth.dart";

enum HomeCharacterType { fish }

class HomeCharacterAssets {
  const HomeCharacterAssets._();

  static const String levelUpConfettiLeft =
      "assets/images/home/level_up/congrat_left.png";
  static const String levelUpConfettiRight =
      "assets/images/home/level_up/congrat_right.png";

  static String assetFor(
    HomeCharacterType type,
    HomeFishGrowthLevel growthLevel,
  ) {
    return switch (type) {
      HomeCharacterType.fish => _fishAssetForLevel(growthLevel),
    };
  }

  static String assetForRecordCount(HomeCharacterType type, int recordCount) {
    return assetFor(type, homeFishGrowthLevelForRecordCount(recordCount));
  }

  static String _fishAssetForLevel(HomeFishGrowthLevel growthLevel) {
    return switch (growthLevel) {
      HomeFishGrowthLevel.level1 =>
        "assets/images/home/characters/fish/level_1.png",
      HomeFishGrowthLevel.level2 =>
        "assets/images/home/characters/fish/level_2.png",
      HomeFishGrowthLevel.level3 =>
        "assets/images/home/characters/fish/level_3.png",
      HomeFishGrowthLevel.level4 =>
        "assets/images/home/characters/fish/level_4.png",
      HomeFishGrowthLevel.level5 =>
        "assets/images/home/characters/fish/level_5.png",
      HomeFishGrowthLevel.level6 =>
        "assets/images/home/characters/fish/level_6.png",
    };
  }

  static String levelUpOverlayAssetFor(
    HomeCharacterType type,
    HomeFishGrowthLevel growthLevel,
  ) {
    return switch (type) {
      HomeCharacterType.fish => _fishLevelUpOverlayAssetForLevel(growthLevel),
    };
  }

  static String _fishLevelUpOverlayAssetForLevel(
    HomeFishGrowthLevel growthLevel,
  ) {
    return _fishAssetForLevel(growthLevel);
  }
}
