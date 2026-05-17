import "../../design_system/theme/app_theme.dart";
import "../../design_system/tokens/app_colors.dart";
import "home_character_assets.dart";

const String _fishInviteBannerAsset =
    "assets/images/home/invite/home_banner_invite_fish_blue.webp";
const String _treeInviteBannerAsset =
    "assets/images/home/invite/home_banner_invite_tree.webp";
const int homeGreenThemeComingSoonLeadRecordCount = 7;
const int homeGreenThemeUnlockRecordCount = 60;
const int homeGreenThemeComingSoonStartRecordCount =
    homeGreenThemeUnlockRecordCount - homeGreenThemeComingSoonLeadRecordCount;

bool hasUnlockedHomeGreenTheme(int totalRecordCount) {
  return totalRecordCount >= homeGreenThemeUnlockRecordCount;
}

int homeGrowthRecordCountForCharacter({
  required HomeCharacterType characterType,
  required int totalRecordCount,
}) {
  final int cycleStartRecordCount = switch (characterType) {
    HomeCharacterType.fish => 0,
    HomeCharacterType.tree => homeGreenThemeUnlockRecordCount,
  };
  final int growthRecordCount = totalRecordCount - cycleStartRecordCount;
  return growthRecordCount < 0 ? 0 : growthRecordCount;
}

bool shouldShowHomeGreenThemeComingSoonNotice(
  int totalRecordCount, {
  HomeCharacterType currentCharacterType = HomeCharacterType.fish,
}) {
  return currentCharacterType != HomeCharacterType.tree &&
      totalRecordCount >= homeGreenThemeComingSoonStartRecordCount &&
      totalRecordCount < homeGreenThemeUnlockRecordCount;
}

bool shouldPresentHomeGreenThemeUnlock({
  required int totalRecordCount,
  required HomeCharacterType currentCharacterType,
  required bool hasPresented,
}) {
  return !hasPresented &&
      currentCharacterType != HomeCharacterType.tree &&
      hasUnlockedHomeGreenTheme(totalRecordCount);
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
  }
  final AppBrandTheme baseTheme = AppCharacterThemeMapper.fromCharacterName(
    characterName,
  );
  if (characterName.trim() != "물고기") {
    return baseTheme;
  }
  return hasUnlockedHomeGreenTheme(totalRecordCount)
      ? AppBrandTheme.green
      : baseTheme;
}

String resolveHomeInviteBannerAsset(BrandScale brand) {
  return brand.c500 == AppBrandThemes.green.c500
      ? _treeInviteBannerAsset
      : _fishInviteBannerAsset;
}

HomeCharacterType resolveHomeCharacterType(BrandScale brand) {
  return brand.c500 == AppBrandThemes.green.c500
      ? HomeCharacterType.tree
      : HomeCharacterType.fish;
}
