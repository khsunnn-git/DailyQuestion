import "package:dailyquestion/design_system/tokens/app_colors.dart";
import "package:dailyquestion/design_system/theme/app_theme.dart";
import "package:dailyquestion/features/home/home_character_assets.dart";
import "package:dailyquestion/features/home/home_fish_growth.dart";
import "package:dailyquestion/features/home/home_theme_progression.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  group("homeFishGrowthLevelForRecordCount", () {
    test("maps cumulative record thresholds to the expected levels", () {
      expect(homeFishGrowthLevelForRecordCount(0), HomeFishGrowthLevel.level1);
      expect(homeFishGrowthLevelForRecordCount(2), HomeFishGrowthLevel.level1);
      expect(homeFishGrowthLevelForRecordCount(3), HomeFishGrowthLevel.level2);
      expect(homeFishGrowthLevelForRecordCount(9), HomeFishGrowthLevel.level2);
      expect(homeFishGrowthLevelForRecordCount(10), HomeFishGrowthLevel.level3);
      expect(homeFishGrowthLevelForRecordCount(16), HomeFishGrowthLevel.level3);
      expect(homeFishGrowthLevelForRecordCount(17), HomeFishGrowthLevel.level4);
      expect(homeFishGrowthLevelForRecordCount(30), HomeFishGrowthLevel.level4);
      expect(homeFishGrowthLevelForRecordCount(31), HomeFishGrowthLevel.level5);
      expect(homeFishGrowthLevelForRecordCount(44), HomeFishGrowthLevel.level5);
      expect(homeFishGrowthLevelForRecordCount(45), HomeFishGrowthLevel.level6);
    });

    test("never goes below level 1", () {
      expect(
        homeFishGrowthLevelForRecordCount(-10),
        HomeFishGrowthLevel.level1,
      );
    });
  });

  group("homeGrowthRecordCountForCharacter", () {
    test("keeps fish growth on the total record count", () {
      expect(
        homeGrowthRecordCountForCharacter(
          characterType: HomeCharacterType.fish,
          totalRecordCount: 60,
        ),
        60,
      );
    });

    test("starts tree growth from level 1 at the 60th total record", () {
      expect(
        homeGrowthRecordCountForCharacter(
          characterType: HomeCharacterType.tree,
          totalRecordCount: 59,
        ),
        0,
      );
      expect(
        homeGrowthRecordCountForCharacter(
          characterType: HomeCharacterType.tree,
          totalRecordCount: 60,
        ),
        0,
      );
      expect(
        homeFishGrowthLevelForRecordCount(
          homeGrowthRecordCountForCharacter(
            characterType: HomeCharacterType.tree,
            totalRecordCount: 60,
          ),
        ),
        HomeFishGrowthLevel.level1,
      );
    });

    test("uses the fish growth cadence inside the tree cycle", () {
      expect(
        homeFishGrowthLevelForRecordCount(
          homeGrowthRecordCountForCharacter(
            characterType: HomeCharacterType.tree,
            totalRecordCount: 63,
          ),
        ),
        HomeFishGrowthLevel.level2,
      );
      expect(
        homeFishGrowthLevelForRecordCount(
          homeGrowthRecordCountForCharacter(
            characterType: HomeCharacterType.tree,
            totalRecordCount: 70,
          ),
        ),
        HomeFishGrowthLevel.level3,
      );
    });
  });

  test("resolves fish assets from the nested character directory", () {
    expect(
      HomeCharacterAssets.assetFor(
        HomeCharacterType.fish,
        HomeFishGrowthLevel.level1,
      ),
      "assets/images/home/characters/fish/level_1.webp",
    );
    expect(
      HomeCharacterAssets.assetFor(
        HomeCharacterType.fish,
        HomeFishGrowthLevel.level6,
      ),
      "assets/images/home/characters/fish/level_6.webp",
    );
  });

  test("resolves fish assets directly from the cumulative record count", () {
    expect(
      HomeCharacterAssets.assetForRecordCount(HomeCharacterType.fish, 0),
      "assets/images/home/characters/fish/level_1.webp",
    );
    expect(
      HomeCharacterAssets.assetForRecordCount(HomeCharacterType.fish, 17),
      "assets/images/home/characters/fish/level_4.webp",
    );
  });

  test("resolves tree assets from the nested character directory", () {
    expect(
      HomeCharacterAssets.assetFor(
        HomeCharacterType.tree,
        HomeFishGrowthLevel.level1,
      ),
      "assets/images/home/characters/tree/level_1.webp",
    );
    expect(
      HomeCharacterAssets.assetFor(
        HomeCharacterType.tree,
        HomeFishGrowthLevel.level6,
      ),
      "assets/images/home/characters/tree/level_6.webp",
    );
  });

  test("uses the updated celebration headlines", () {
    expect(HomeFishGrowthLevel.level2.celebrationHeadline, "작은 물고기로 자라났어요!");
    expect(HomeFishGrowthLevel.level3.celebrationHeadline, "제법 자라났어요!");
    expect(HomeFishGrowthLevel.level4.celebrationHeadline, "더 크게 자라났어요!");
    expect(HomeFishGrowthLevel.level5.celebrationHeadline, "무럭무럭 자랐어요!");
    expect(HomeFishGrowthLevel.level6.celebrationHeadline, "물고기가 어른이 되었어요!");
  });

  group("resolveHomeBrandTheme", () {
    test("keeps the fish theme blue through full fish growth", () {
      expect(
        resolveHomeBrandTheme(characterName: "물고기", totalRecordCount: 45),
        AppBrandTheme.blue,
      );
      expect(
        resolveHomeBrandTheme(characterName: "물고기", totalRecordCount: 59),
        AppBrandTheme.blue,
      );
    });

    test(
      "moves the fish theme to green after the next theme unlock threshold",
      () {
        expect(
          resolveHomeBrandTheme(characterName: "물고기", totalRecordCount: 60),
          AppBrandTheme.green,
        );
      },
    );

    test("keeps non-fish characters on their mapped theme", () {
      expect(
        resolveHomeBrandTheme(characterName: "강아지", totalRecordCount: 60),
        AppBrandTheme.purple,
      );
    });

    test("allows forcing the green preview theme in debug mode", () {
      expect(
        resolveHomeBrandTheme(
          characterName: "물고기",
          totalRecordCount: 0,
          debugThemeOverride: "tree",
        ),
        AppBrandTheme.green,
      );
    });
  });

  group("hasUnlockedHomeGreenTheme", () {
    test("returns false before 60 total records", () {
      expect(hasUnlockedHomeGreenTheme(59), isFalse);
    });

    test("returns true from 60 total records", () {
      expect(hasUnlockedHomeGreenTheme(60), isTrue);
    });
  });

  group("shouldShowHomeGreenThemeComingSoonNotice", () {
    test("returns false before the 7-day lead window", () {
      expect(
        shouldShowHomeGreenThemeComingSoonNotice(
          homeGreenThemeComingSoonStartRecordCount - 1,
        ),
        isFalse,
      );
    });

    test("returns true during the 53rd to 59th record window", () {
      expect(
        shouldShowHomeGreenThemeComingSoonNotice(
          homeGreenThemeComingSoonStartRecordCount,
        ),
        isTrue,
      );
      expect(shouldShowHomeGreenThemeComingSoonNotice(59), isTrue);
    });

    test("returns false once the green theme is unlocked", () {
      expect(
        shouldShowHomeGreenThemeComingSoonNotice(
          homeGreenThemeUnlockRecordCount,
        ),
        isFalse,
      );
    });

    test("returns false when the green theme is already active", () {
      expect(
        shouldShowHomeGreenThemeComingSoonNotice(
          homeGreenThemeComingSoonStartRecordCount,
          currentCharacterType: HomeCharacterType.tree,
        ),
        isFalse,
      );
    });
  });

  group("shouldPresentHomeGreenThemeUnlock", () {
    test("returns true at unlock only before the green theme is active", () {
      expect(
        shouldPresentHomeGreenThemeUnlock(
          totalRecordCount: homeGreenThemeUnlockRecordCount,
          currentCharacterType: HomeCharacterType.fish,
          hasPresented: false,
        ),
        isTrue,
      );
    });

    test("returns false when the green theme is already active", () {
      expect(
        shouldPresentHomeGreenThemeUnlock(
          totalRecordCount: homeGreenThemeUnlockRecordCount,
          currentCharacterType: HomeCharacterType.tree,
          hasPresented: false,
        ),
        isFalse,
      );
    });

    test("returns false after the unlock has already been presented", () {
      expect(
        shouldPresentHomeGreenThemeUnlock(
          totalRecordCount: homeGreenThemeUnlockRecordCount,
          currentCharacterType: HomeCharacterType.fish,
          hasPresented: true,
        ),
        isFalse,
      );
    });
  });

  group("resolveHomeInviteBannerAsset", () {
    test("uses the fish invite banner for the blue theme", () {
      expect(
        resolveHomeInviteBannerAsset(AppBrandThemes.blue),
        "assets/images/home/invite/home_banner_invite_fish_blue.webp",
      );
    });

    test("uses the tree invite banner for the green theme", () {
      expect(
        resolveHomeInviteBannerAsset(AppBrandThemes.green),
        "assets/images/home/invite/home_banner_invite_tree.webp",
      );
    });
  });

  group("resolveHomeCharacterType", () {
    test("uses the fish character for the blue theme", () {
      expect(
        resolveHomeCharacterType(AppBrandThemes.blue),
        HomeCharacterType.fish,
      );
    });

    test("uses the tree character for the green theme", () {
      expect(
        resolveHomeCharacterType(AppBrandThemes.green),
        HomeCharacterType.tree,
      );
    });
  });
}
