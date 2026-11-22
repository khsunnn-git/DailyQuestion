import "package:dailyquestion/features/home/home_character_assets.dart";
import "package:dailyquestion/features/home/home_fish_growth.dart";
import "package:dailyquestion/features/home/home_theme_progression.dart";
import "package:flutter_test/flutter_test.dart";

/// 홈 화면 `_evaluatePendingCelebration`과 같은 순서로 다음 캐릭터 선택/예고를 고른다.
/// 이용자는 선택 화면이 뜨면 [picks] 순서대로 캐릭터를 고른다.
class _Journey {
  _Journey({required this.picks, this.stored});

  final List<HomeCharacterType> picks;
  HomeCharacterSelection? stored;
  final Set<String> soonShown = <String>{};
  final List<String> events = <String>[];

  HomeCharacterSelection current(int count) {
    return resolveHomeCharacterSelection(
      stored: stored,
      totalRecordCount: count,
    );
  }

  void visitHome(int count) {
    final HomeCharacterSelection selection = current(count);
    if (shouldPresentHomeNextCharacterSelection(
      selection: selection,
      totalRecordCount: count,
    )) {
      final HomeCharacterType pick = picks.removeAt(0);
      stored = HomeCharacterSelection(
        characterType: pick,
        cycleStartRecordCount: nextHomeCharacterCycleStartRecordCount(
          current: selection,
          totalRecordCount: count,
        ),
      );
      events.add("$count:선택 ${pick.displayName}");
      return;
    }
    if (shouldShowHomeNextCharacterComingSoonNotice(
          selection: selection,
          totalRecordCount: count,
        ) &&
        soonShown.add(selection.cycleKey)) {
      events.add("$count:예고");
    }
  }
}

void main() {
  test("회원가입 때 고른 캐릭터로 시작해 60개마다 직접 다음 캐릭터를 고른다", () {
    final _Journey journey = _Journey(
      stored: const HomeCharacterSelection(
        characterType: HomeCharacterType.cat,
        cycleStartRecordCount: 0,
      ),
      picks: <HomeCharacterType>[
        HomeCharacterType.axolotl,
        HomeCharacterType.cat,
        HomeCharacterType.parrotbill,
      ],
    );
    for (int count = 0; count <= 190; count++) {
      journey.visitHome(count);
    }
    expect(journey.events, <String>[
      "53:예고",
      "60:선택 우파루파",
      "113:예고",
      "120:선택 고양이",
      "173:예고",
      "180:선택 뱁새",
    ]);
    expect(journey.current(190).characterType, HomeCharacterType.parrotbill);
    expect(journey.current(190).growthRecordCountFor(190), 10);
  });

  test("같은 캐릭터를 다시 고르면 1레벨부터 다시 키운다", () {
    final _Journey journey = _Journey(
      stored: const HomeCharacterSelection(
        characterType: HomeCharacterType.dino,
        cycleStartRecordCount: 0,
      ),
      picks: <HomeCharacterType>[HomeCharacterType.dino],
    );
    for (int count = 0; count <= 60; count++) {
      journey.visitHome(count);
    }
    final HomeCharacterSelection selection = journey.current(60);
    expect(selection.characterType, HomeCharacterType.dino);
    expect(selection.cycleStartRecordCount, 60);
    expect(
      homeFishGrowthLevelForRecordCount(selection.growthRecordCountFor(60)),
      HomeFishGrowthLevel.level1,
    );
    expect(selection.cycleKey, isNot("dino@0"));
  });

  test("저장하지 않으면 120회에 예전처럼 자동으로 넘어가 버린다 (회귀 방지)", () {
    final _Journey journey = _Journey(picks: <HomeCharacterType>[]);
    expect(journey.current(119).characterType, HomeCharacterType.tree);
    expect(journey.current(120).characterType, HomeCharacterType.stone);
  });

  test("구버전 이용자는 지금 캐릭터를 끝까지 키운 뒤 선택 화면을 만난다", () {
    // 90개 기록: 구버전 기준 새싹(60부터) 30개째.
    // 업데이트 후 처음 홈에 들어올 때 지금 캐릭터를 저장한다.
    // (HomeCharacterSelectionStore.persistLegacySelectionIfNeeded)
    final _Journey journey = _Journey(
      stored: legacyHomeCharacterSelectionForTotalRecordCount(90),
      picks: <HomeCharacterType>[HomeCharacterType.cat],
    );
    expect(journey.current(90).characterType, HomeCharacterType.tree);
    for (int count = 90; count <= 125; count++) {
      journey.visitHome(count);
    }
    expect(journey.events, <String>["113:예고", "120:선택 고양이"]);
  });

  test("여러 사이클이 밀린 구버전 이용자도 한 번만 고르면 된다", () {
    // 300개 기록: 구버전 기준 백구(180부터) 120개째 → 바로 선택
    final _Journey journey = _Journey(
      stored: legacyHomeCharacterSelectionForTotalRecordCount(300),
      picks: <HomeCharacterType>[HomeCharacterType.axolotl],
    );
    journey.visitHome(300);
    journey.visitHome(300);
    journey.visitHome(301);
    expect(journey.events, <String>["300:선택 우파루파"]);
    expect(journey.current(301).growthRecordCountFor(301), 1);
  });
}
