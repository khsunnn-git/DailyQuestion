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


  group("legacy character growth (구버전 강제 순서 이어받기)", () {
    int legacyGrowth(int total) {
      return legacyHomeCharacterSelectionForTotalRecordCount(
        total,
      ).growthRecordCountFor(total);
    }

    test("keeps fish growth on the total record count", () {
      expect(legacyGrowth(59), 59);
    });

    test("starts tree growth from level 1 at the 60th total record", () {
      expect(
        legacyHomeCharacterSelectionForTotalRecordCount(60).characterType,
        HomeCharacterType.tree,
      );
      expect(legacyGrowth(60), 0);
      expect(
        homeFishGrowthLevelForRecordCount(legacyGrowth(63)),
        HomeFishGrowthLevel.level2,
      );
      expect(
        homeFishGrowthLevelForRecordCount(legacyGrowth(70)),
        HomeFishGrowthLevel.level3,
      );
    });

    test("starts stone growth from level 1 at the 120th total record", () {
      expect(
        legacyHomeCharacterSelectionForTotalRecordCount(120).characterType,
        HomeCharacterType.stone,
      );
      expect(legacyGrowth(120), 0);
      expect(
        homeFishGrowthLevelForRecordCount(legacyGrowth(123)),
        HomeFishGrowthLevel.level2,
      );
    });

    test("keeps the dog from the 180th record", () {
      expect(
        legacyHomeCharacterSelectionForTotalRecordCount(180).characterType,
        HomeCharacterType.dog,
      );
      expect(legacyGrowth(240), 60);
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

  test("resolves stone assets from the nested character directory", () {
    expect(
      HomeCharacterAssets.assetFor(
        HomeCharacterType.stone,
        HomeFishGrowthLevel.level1,
      ),
      "assets/images/home/characters/stone/level_1.webp",
    );
    expect(
      HomeCharacterAssets.assetFor(
        HomeCharacterType.stone,
        HomeFishGrowthLevel.level6,
      ),
      "assets/images/home/characters/stone/level_6.webp",
    );
    expect(
      HomeCharacterAssets.stoneRecord,
      "assets/images/home/characters/stone/record_stone.webp",
    );
  });

  test("uses the updated celebration headlines", () {
    expect(HomeFishGrowthLevel.level2.celebrationHeadline, "작은 물고기로 자라났어요!");
    expect(HomeFishGrowthLevel.level3.celebrationHeadline, "제법 자라났어요!");
    expect(HomeFishGrowthLevel.level4.celebrationHeadline, "더 크게 자라났어요!");
    expect(HomeFishGrowthLevel.level5.celebrationHeadline, "무럭무럭 자랐어요!");
    expect(HomeFishGrowthLevel.level6.celebrationHeadline, "물고기가 어른이 되었어요!");
  });

  group("HomeCharacterTypeX", () {
    test("maps every character to a brand theme", () {
      expect(HomeCharacterType.fish.brandTheme, AppBrandTheme.blue);
      expect(HomeCharacterType.parrotbill.brandTheme, AppBrandTheme.blue);
      expect(HomeCharacterType.tree.brandTheme, AppBrandTheme.green);
      expect(HomeCharacterType.dino.brandTheme, AppBrandTheme.green);
      expect(HomeCharacterType.stone.brandTheme, AppBrandTheme.brown);
      expect(HomeCharacterType.cat.brandTheme, AppBrandTheme.brown);
      expect(HomeCharacterType.dog.brandTheme, AppBrandTheme.purple);
      expect(HomeCharacterType.axolotl.brandTheme, AppBrandTheme.purple);
    });

    test("lists characters in the Figma selection order", () {
      expect(HomeCharacterType.values, <HomeCharacterType>[
        HomeCharacterType.fish,
        HomeCharacterType.tree,
        HomeCharacterType.stone,
        HomeCharacterType.dino,
        HomeCharacterType.dog,
        HomeCharacterType.cat,
        HomeCharacterType.axolotl,
        HomeCharacterType.parrotbill,
      ]);
    });

    test("attaches the right 와/과 particle", () {
      expect(HomeCharacterType.fish.displayNameWithAnd, "물고기와");
      expect(HomeCharacterType.tree.displayNameWithAnd, "새싹과");
      expect(HomeCharacterType.dino.displayNameWithAnd, "공룡과");
      expect(HomeCharacterType.axolotl.displayNameWithAnd, "우파루파와");
    });
  });

  group("new character assets", () {
    test("resolves level assets from each character directory", () {
      for (final HomeCharacterType type in <HomeCharacterType>[
        HomeCharacterType.dino,
        HomeCharacterType.cat,
        HomeCharacterType.axolotl,
        HomeCharacterType.parrotbill,
      ]) {
        expect(
          HomeCharacterAssets.assetFor(type, HomeFishGrowthLevel.level3),
          "assets/images/home/characters/${type.name}/level_3.webp",
        );
        expect(
          HomeCharacterAssets.recordAssetFor(type),
          "assets/images/home/characters/${type.name}/record_${type.name}.webp",
        );
        expect(
          HomeCharacterAssets.inviteBannerAssetFor(type),
          "assets/images/home/characters/${type.name}/home_banner_invite_${type.name}.webp",
        );
      }
    });

    test("has no blink frame on level 1", () {
      expect(
        HomeCharacterAssets.blinkAssetFor(
          HomeCharacterType.cat,
          HomeFishGrowthLevel.level1,
        ),
        isNull,
      );
      expect(
        HomeCharacterAssets.blinkAssetFor(
          HomeCharacterType.cat,
          HomeFishGrowthLevel.level2,
        ),
        "assets/images/home/characters/cat/level_2_blink.webp",
      );
    });

    test("uses each character's empty bucket image", () {
      for (final HomeCharacterType type in HomeCharacterType.values) {
        expect(
          HomeCharacterAssets.emptyBucketAssetFor(type),
          "assets/images/bucket/bucketlist_empty_state_note_${type.name}.webp",
        );
      }
    });
  });

  group("resolveHomeInviteBannerAsset", () {
    test("uses the fish invite banner for the fish", () {
      expect(
        resolveHomeInviteBannerAsset(HomeCharacterType.fish),
        "assets/images/home/invite/home_banner_invite_fish_blue.webp",
      );
    });

    test("uses the tree invite banner for the tree", () {
      expect(
        resolveHomeInviteBannerAsset(HomeCharacterType.tree),
        "assets/images/home/invite/home_banner_invite_tree.webp",
      );
    });

    test("uses the stone invite banner for the stone", () {
      expect(
        resolveHomeInviteBannerAsset(HomeCharacterType.stone),
        "assets/images/home/characters/stone/home_banner_invite_stone.webp",
      );
    });
  });
}
