import "../../design_system/theme/app_theme.dart";
import "../../design_system/tokens/app_colors.dart";
import "home_character_assets.dart";

const String _fishInviteBannerAsset =
    "assets/images/home/invite/home_banner_invite_fish_blue.webp";
const String _treeInviteBannerAsset =
    "assets/images/home/invite/home_banner_invite_tree.webp";
const String _stoneInviteBannerAsset =
    "assets/images/home/characters/stone/home_banner_invite_stone.webp";
const int homeGreenThemeComingSoonLeadRecordCount = 7;
const int homeGreenThemeUnlockRecordCount = 60;
const int homeBrownThemeUnlockRecordCount = 120;
const int homeGreenThemeComingSoonStartRecordCount =
    homeGreenThemeUnlockRecordCount - homeGreenThemeComingSoonLeadRecordCount;
const int homeBrownThemeComingSoonStartRecordCount =
    homeBrownThemeUnlockRecordCount - homeGreenThemeComingSoonLeadRecordCount;

bool hasUnlockedHomeGreenTheme(int totalRecordCount) {
  return totalRecordCount >= homeGreenThemeUnlockRecordCount;
}

bool hasUnlockedHomeBrownTheme(int totalRecordCount) {
  return totalRecordCount >= homeBrownThemeUnlockRecordCount;
}

int homeGrowthRecordCountForCharacter({
  required HomeCharacterType characterType,
  required int totalRecordCount,
}) {
  final int cycleStartRecordCount = switch (characterType) {
    HomeCharacterType.fish => 0,
    HomeCharacterType.tree => homeGreenThemeUnlockRecordCount,
    HomeCharacterType.stone => homeBrownThemeUnlockRecordCount,
  };
  final int growthRecordCount = totalRecordCount - cycleStartRecordCount;
  return growthRecordCount < 0 ? 0 : growthRecordCount;
}

String homeCharacterAssetForTotalRecordCount({
  required HomeCharacterType characterType,
  required int totalRecordCount,
}) {
  final int growthRecordCount = homeGrowthRecordCountForCharacter(
    characterType: characterType,
    totalRecordCount: totalRecordCount,
  );
  return HomeCharacterAssets.assetForRecordCount(
    characterType,
    growthRecordCount,
  );
}

bool shouldShowHomeGreenThemeComingSoonNotice(
  int totalRecordCount, {
  HomeCharacterType currentCharacterType = HomeCharacterType.fish,
}) {
  return currentCharacterType != HomeCharacterType.tree &&
      totalRecordCount >= homeGreenThemeComingSoonStartRecordCount &&
      totalRecordCount < homeGreenThemeUnlockRecordCount;
}

bool shouldShowHomeBrownThemeComingSoonNotice(
  int totalRecordCount, {
  HomeCharacterType currentCharacterType = HomeCharacterType.tree,
}) {
  return currentCharacterType == HomeCharacterType.tree &&
      totalRecordCount >= homeBrownThemeComingSoonStartRecordCount &&
      totalRecordCount < homeBrownThemeUnlockRecordCount;
}

bool shouldPresentHomeGreenThemeUnlock({
  required int totalRecordCount,
  required HomeCharacterType currentCharacterType,
  required bool hasPresented,
}) {
  return !hasPresented &&
      !hasUnlockedHomeBrownTheme(totalRecordCount) &&
      hasUnlockedHomeGreenTheme(totalRecordCount);
}

bool shouldPresentHomeBrownThemeUnlock({
  required int totalRecordCount,
  required bool hasPresented,
}) {
  return !hasPresented && hasUnlockedHomeBrownTheme(totalRecordCount);
}

AppBrandTheme resolveHomeBrandTheme({
  required String characterName,
  required int totalRecordCount,
  String debugThemeOverride = "",
}) {
  switch (debugThemeOverride.trim().toLowerCase()) {
    case "green":
    case "tree":
      return AppBrandTheme.green;
    case "blue":
    case "fish":
      return AppBrandTheme.blue;
    case "brown":
    case "stone":
    case "rock":
      return AppBrandTheme.brown;
  }
  final AppBrandTheme baseTheme = AppCharacterThemeMapper.fromCharacterName(
    characterName,
  );
  if (characterName.trim() != "물고기") {
    return baseTheme;
  }
  if (hasUnlockedHomeBrownTheme(totalRecordCount)) {
    return AppBrandTheme.brown;
  }
  if (hasUnlockedHomeGreenTheme(totalRecordCount)) {
    return AppBrandTheme.green;
  }
  return baseTheme;
}

String resolveHomeInviteBannerAsset(BrandScale brand) {
  if (brand.c500 == AppBrandThemes.green.c500) {
    return _treeInviteBannerAsset;
  }
  if (brand.c500 == AppBrandThemes.brown.c500) {
    return _stoneInviteBannerAsset;
  }
  return _fishInviteBannerAsset;
}

HomeCharacterType resolveHomeCharacterType(BrandScale brand) {
  if (brand.c500 == AppBrandThemes.green.c500) {
    return HomeCharacterType.tree;
  }
  if (brand.c500 == AppBrandThemes.brown.c500) {
    return HomeCharacterType.stone;
  }
  return HomeCharacterType.fish;
}
