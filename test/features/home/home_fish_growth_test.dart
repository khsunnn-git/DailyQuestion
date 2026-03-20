import "package:dailyquestion/features/home/home_character_assets.dart";
import "package:dailyquestion/features/home/home_fish_growth.dart";
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

  test("uses the updated celebration headlines", () {
    expect(HomeFishGrowthLevel.level2.celebrationHeadline, "작은 물고기로 자라났어요!");
    expect(HomeFishGrowthLevel.level3.celebrationHeadline, "제법 자라났어요!");
    expect(HomeFishGrowthLevel.level4.celebrationHeadline, "더 크게 자라났어요!");
    expect(HomeFishGrowthLevel.level5.celebrationHeadline, "무럭무럭 자랐어요!");
    expect(HomeFishGrowthLevel.level6.celebrationHeadline, "물고기가 어른이 되었어요!");
  });
}
