import "home_fish_growth.dart";

enum HomeCharacterType { fish }

class HomeCharacterAssets {
  const HomeCharacterAssets._();

  static const String levelUpConfettiLeft =
      "assets/images/home/level_up/congrat_left.webp";
  static const String levelUpConfettiRight =
      "assets/images/home/level_up/congrat_right.webp";

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
        "assets/images/home/characters/fish/level_1.webp",
      HomeFishGrowthLevel.level2 =>
        "assets/images/home/characters/fish/level_2.webp",
      HomeFishGrowthLevel.level3 =>
        "assets/images/home/characters/fish/level_3.webp",
      HomeFishGrowthLevel.level4 =>
        "assets/images/home/characters/fish/level_4.webp",
      HomeFishGrowthLevel.level5 =>
        "assets/images/home/characters/fish/level_5.webp",
      HomeFishGrowthLevel.level6 =>
        "assets/images/home/characters/fish/level_6.webp",
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
