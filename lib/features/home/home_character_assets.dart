import "home_fish_growth.dart";

enum HomeCharacterType { fish, tree }

class HomeCharacterAssets {
  const HomeCharacterAssets._();

  static const String levelUpConfettiLeft =
      "assets/images/home/level_up/congrat_left.webp";
  static const String levelUpConfettiRight =
      "assets/images/home/level_up/congrat_right.webp";
  static const String treeLevel1Base =
      "assets/images/home/characters/tree/level_1_base.webp";
  static const String treeLevel1Leaf =
      "assets/images/home/characters/tree/leve_l1_leaf.webp";
  static const String treeLevel2Base =
      "assets/images/home/characters/tree/level_2_base.webp";
  static const String treeLevel2Leaf =
      "assets/images/home/characters/tree/level_2_leaf.webp";
  static const String treeLevel3Base =
      "assets/images/home/characters/tree/level_3_base.webp";
  static const String treeLevel3Leaf =
      "assets/images/home/characters/tree/level_3_leaf.webp";
  static const String treeLevel4Base =
      "assets/images/home/characters/tree/level_4_base.webp";
  static const String treeLevel4Leaf =
      "assets/images/home/characters/tree/level_4_leaf.webp";
  static const String treeLevel5Base =
      "assets/images/home/characters/tree/level_5_base.webp";
  static const String treeLevel5Leaf =
      "assets/images/home/characters/tree/level_5_leaf.webp";
  static const String treeLevel6Base =
      "assets/images/home/characters/tree/level_6_base.webp";
  static const String treeLevel6Leaf =
      "assets/images/home/characters/tree/level_6_leaf.webp";

  static String assetFor(
    HomeCharacterType type,
    HomeFishGrowthLevel growthLevel,
  ) {
    return switch (type) {
      HomeCharacterType.fish => _fishAssetForLevel(growthLevel),
      HomeCharacterType.tree => _treeAssetForLevel(growthLevel),
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

  static String _treeAssetForLevel(HomeFishGrowthLevel growthLevel) {
    return switch (growthLevel) {
      HomeFishGrowthLevel.level1 =>
        "assets/images/home/characters/tree/level_1.webp",
      HomeFishGrowthLevel.level2 =>
        "assets/images/home/characters/tree/level_2.webp",
      HomeFishGrowthLevel.level3 =>
        "assets/images/home/characters/tree/level_3.webp",
      HomeFishGrowthLevel.level4 =>
        "assets/images/home/characters/tree/level_4.webp",
      HomeFishGrowthLevel.level5 =>
        "assets/images/home/characters/tree/level_5.webp",
      HomeFishGrowthLevel.level6 =>
        "assets/images/home/characters/tree/level_6.webp",
    };
  }

  static String levelUpOverlayAssetFor(
    HomeCharacterType type,
    HomeFishGrowthLevel growthLevel,
  ) {
    return switch (type) {
      HomeCharacterType.fish => _fishLevelUpOverlayAssetForLevel(growthLevel),
      HomeCharacterType.tree => _treeAssetForLevel(growthLevel),
    };
  }

  static String _fishLevelUpOverlayAssetForLevel(
    HomeFishGrowthLevel growthLevel,
  ) {
    return _fishAssetForLevel(growthLevel);
  }
}
