import "package:flutter/material.dart";

import "../../design_system/theme/app_theme.dart";
import "../../design_system/tokens/app_colors.dart";
import "home_fish_growth.dart";

/// 홈에서 키울 수 있는 캐릭터(테마) 목록.
///
/// 선언 순서가 캐릭터 선택 화면의 노출 순서다. (Figma 기준)
enum HomeCharacterType {
  fish,
  tree,
  stone,
  dino,
  dog,
  cat,
  axolotl,
  parrotbill,
}

extension HomeCharacterTypeX on HomeCharacterType {
  /// 사용자에게 보여주는 캐릭터 이름.
  String get displayName => switch (this) {
    HomeCharacterType.fish => "물고기",
    HomeCharacterType.tree => "새싹",
    HomeCharacterType.stone => "돌맹이",
    HomeCharacterType.dino => "공룡",
    HomeCharacterType.dog => "백구",
    HomeCharacterType.cat => "고양이",
    HomeCharacterType.axolotl => "우파루파",
    HomeCharacterType.parrotbill => "뱁새",
  };

  /// "물고기와", "새싹과"처럼 받침에 맞는 조사(와/과)를 붙인 이름.
  String get displayNameWithAnd {
    final String name = displayName;
    final int code = name.codeUnitAt(name.length - 1);
    final bool hasFinalConsonant =
        code >= 0xAC00 && code <= 0xD7A3 && (code - 0xAC00) % 28 != 0;
    return "$name${hasFinalConsonant ? "과" : "와"}";
  }

  /// 이미지 로드 실패 시 대신 보여줄 이모지.
  String get fallbackEmoji => switch (this) {
    HomeCharacterType.fish => "🐟",
    HomeCharacterType.tree => "🌱",
    HomeCharacterType.stone => "🪨",
    HomeCharacterType.dino => "🦖",
    HomeCharacterType.dog => "🐶",
    HomeCharacterType.cat => "🐱",
    HomeCharacterType.axolotl => "🦎",
    HomeCharacterType.parrotbill => "🐦",
  };

  /// 캐릭터가 사용할 앱 색상 테마.
  AppBrandTheme get brandTheme => switch (this) {
    HomeCharacterType.fish || HomeCharacterType.parrotbill => AppBrandTheme.blue,
    HomeCharacterType.tree || HomeCharacterType.dino => AppBrandTheme.green,
    HomeCharacterType.stone || HomeCharacterType.cat => AppBrandTheme.brown,
    HomeCharacterType.dog || HomeCharacterType.axolotl => AppBrandTheme.purple,
  };

  BrandScale get brandScale => switch (brandTheme) {
    AppBrandTheme.blue => AppBrandThemes.blue,
    AppBrandTheme.green => AppBrandThemes.green,
    AppBrandTheme.brown => AppBrandThemes.brown,
    AppBrandTheme.purple => AppBrandThemes.purple,
  };

  /// 1024 캔버스 전체를 쓰는 일러스트라서 레벨과 상관없이 같은 크기로 그리는 캐릭터.
  /// (물고기·새싹은 레벨에 따라 그리는 크기를 키운다)
  bool get usesFixedCanvasArt => switch (this) {
    HomeCharacterType.fish || HomeCharacterType.tree => false,
    _ => true,
  };

  /// 레벨별 눈 깜빡임 프레임(level_N_blink)이 있는 캐릭터.
  bool get hasBlinkFrames => switch (this) {
    HomeCharacterType.dino ||
    HomeCharacterType.cat ||
    HomeCharacterType.axolotl ||
    HomeCharacterType.parrotbill => true,
    _ => false,
  };

  String get assetDirectory => "assets/images/home/characters/$name";

  /// 캐릭터 선택 화면 썸네일 원 배경색. (Figma 기준)
  Color get selectionBackgroundColor => switch (this) {
    HomeCharacterType.fish => const Color(0xFFD9E6EA),
    HomeCharacterType.tree => const Color(0xFFEFFEBB),
    HomeCharacterType.stone => const Color(0xFFFCE3C7),
    HomeCharacterType.dino => const Color(0xFFE8F6BD),
    HomeCharacterType.dog => const Color(0xFFD3C2E3),
    HomeCharacterType.cat => const Color(0xFFF8E9D2),
    HomeCharacterType.axolotl => const Color(0xFFC5A9E6),
    HomeCharacterType.parrotbill => const Color(0xFFB5D6E6),
  };
}

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
  static const String stoneRecord =
      "assets/images/home/characters/stone/record_stone.webp";
  static const String dogRecord =
      "assets/images/home/characters/dog/record_dog.webp";

  /// "오늘의 기록" 빈 카드에 쓰는 기록하는 포즈 이미지. 물고기·새싹은 없음.
  static String? recordAssetFor(HomeCharacterType type) {
    return switch (type) {
      HomeCharacterType.fish || HomeCharacterType.tree => null,
      _ => "${type.assetDirectory}/record_${type.name}.webp",
    };
  }

  /// 홈 친구초대 배너 이미지.
  static String inviteBannerAssetFor(HomeCharacterType type) {
    return switch (type) {
      HomeCharacterType.fish =>
        "assets/images/home/invite/home_banner_invite_fish_blue.webp",
      HomeCharacterType.tree =>
        "assets/images/home/invite/home_banner_invite_tree.webp",
      _ => "${type.assetDirectory}/home_banner_invite_${type.name}.webp",
    };
  }

  /// 버킷리스트가 비어 있을 때 보여주는 이미지.
  static String emptyBucketAssetFor(HomeCharacterType type) {
    return "assets/images/bucket/bucketlist_empty_state_note_${type.name}.webp";
  }

  /// 눈 깜빡임 프레임. 1레벨은 깜빡임 프레임이 없어서 null.
  static String? blinkAssetFor(
    HomeCharacterType type,
    HomeFishGrowthLevel level,
  ) {
    if (!type.hasBlinkFrames || level == HomeFishGrowthLevel.level1) {
      return null;
    }
    return "${type.assetDirectory}/level_${level.number}_blink.webp";
  }

  /// 캐릭터 선택 화면에서 쓰는 대표 이미지. (2레벨 이미지를 캐릭터에 맞춰 잘라낸 썸네일)
  static String selectionAssetFor(HomeCharacterType type) {
    return "${type.assetDirectory}/select.webp";
  }

  static String assetFor(
    HomeCharacterType type,
    HomeFishGrowthLevel growthLevel,
  ) {
    return switch (type) {
      HomeCharacterType.fish => _fishAssetForLevel(growthLevel),
      HomeCharacterType.tree => _treeAssetForLevel(growthLevel),
      HomeCharacterType.stone => _stoneAssetForLevel(growthLevel),
      HomeCharacterType.dog => _dogAssetForLevel(growthLevel),
      HomeCharacterType.dino ||
      HomeCharacterType.cat ||
      HomeCharacterType.axolotl ||
      HomeCharacterType.parrotbill =>
        "${type.assetDirectory}/level_${growthLevel.number}.webp",
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

  static String _stoneAssetForLevel(HomeFishGrowthLevel growthLevel) {
    return switch (growthLevel) {
      HomeFishGrowthLevel.level1 =>
        "assets/images/home/characters/stone/level_1.webp",
      HomeFishGrowthLevel.level2 =>
        "assets/images/home/characters/stone/level_2.webp",
      HomeFishGrowthLevel.level3 =>
        "assets/images/home/characters/stone/level_3.webp",
      HomeFishGrowthLevel.level4 =>
        "assets/images/home/characters/stone/level_4.webp",
      HomeFishGrowthLevel.level5 =>
        "assets/images/home/characters/stone/level_5.webp",
      HomeFishGrowthLevel.level6 =>
        "assets/images/home/characters/stone/level_6.webp",
    };
  }

  static String _dogAssetForLevel(HomeFishGrowthLevel growthLevel) {
    return "assets/images/home/characters/dog/level_${growthLevel.number}.webp";
  }

  static String levelUpOverlayAssetFor(
    HomeCharacterType type,
    HomeFishGrowthLevel growthLevel,
  ) {
    return switch (type) {
      HomeCharacterType.fish => _fishLevelUpOverlayAssetForLevel(growthLevel),
      HomeCharacterType.tree => _treeAssetForLevel(growthLevel),
      HomeCharacterType.stone => _stoneAssetForLevel(growthLevel),
      HomeCharacterType.dog ||
      HomeCharacterType.dino ||
      HomeCharacterType.cat ||
      HomeCharacterType.axolotl ||
      HomeCharacterType.parrotbill => assetFor(type, growthLevel),
    };
  }

  static String _fishLevelUpOverlayAssetForLevel(
    HomeFishGrowthLevel growthLevel,
  ) {
    return _fishAssetForLevel(growthLevel);
  }
}
