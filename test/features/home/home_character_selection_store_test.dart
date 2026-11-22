import "package:dailyquestion/features/home/home_character_assets.dart";
import "package:dailyquestion/features/home/home_character_selection_store.dart";
import "package:dailyquestion/features/home/home_theme_progression.dart";
import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    HomeCharacterSelectionStore.instance.debugReset();
  });

  test("고른 적이 없으면 구버전 순서를 따른다", () async {
    final HomeCharacterSelectionStore store =
        HomeCharacterSelectionStore.instance;
    await store.initialize();
    expect(store.hasExplicitSelection, isFalse);
    expect(store.resolve(0).characterType, HomeCharacterType.fish);
    expect(store.resolve(130).characterType, HomeCharacterType.stone);
  });

  test("회원가입에서 고른 캐릭터를 저장하고 다시 불러온다", () async {
    final HomeCharacterSelectionStore store =
        HomeCharacterSelectionStore.instance;
    await store.initialize();
    await store.select(HomeCharacterType.parrotbill, totalRecordCount: 0);
    expect(store.resolve(0).characterType, HomeCharacterType.parrotbill);
    expect(store.resolve(0).cycleStartRecordCount, 0);

    store.debugReset();
    await store.initialize();
    expect(store.hasExplicitSelection, isTrue);
    expect(store.resolve(12).characterType, HomeCharacterType.parrotbill);
    expect(store.resolve(12).growthRecordCountFor(12), 12);
  });

  test("다음 캐릭터는 60개 경계에서 새 사이클을 시작한다", () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      "home_character_type": "cat",
      "home_character_cycle_start": 0,
    });
    final HomeCharacterSelectionStore store =
        HomeCharacterSelectionStore.instance;
    await store.initialize();
    expect(
      shouldPresentHomeNextCharacterSelection(
        selection: store.resolve(62),
        totalRecordCount: 62,
      ),
      isTrue,
    );
    final HomeCharacterSelection next = await store.select(
      HomeCharacterType.dino,
      totalRecordCount: 62,
    );
    expect(next.cycleStartRecordCount, 60);
    expect(next.growthRecordCountFor(62), 2);
    expect(
      shouldPresentHomeNextCharacterSelection(
        selection: store.resolve(62),
        totalRecordCount: 62,
      ),
      isFalse,
    );
  });

  test("알 수 없는 값이 저장돼 있으면 무시한다", () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      "home_character_type": "unicorn",
      "home_character_cycle_start": 0,
    });
    final HomeCharacterSelectionStore store =
        HomeCharacterSelectionStore.instance;
    await store.initialize();
    expect(store.hasExplicitSelection, isFalse);
  });

  test("디버그 테마 지정은 저장값보다 우선한다", () async {
    final HomeCharacterSelectionStore store =
        HomeCharacterSelectionStore.instance;
    await store.initialize();
    store.setDebugOverride(parseHomeCharacterType("axolotl"));
    expect(store.resolve(5).characterType, HomeCharacterType.axolotl);
    store.setDebugOverride(null);
    expect(store.resolve(5).characterType, HomeCharacterType.fish);
  });

  test("구버전 이용자는 처음 홈에 들어올 때 지금 캐릭터를 저장한다", () async {
    final HomeCharacterSelectionStore store =
        HomeCharacterSelectionStore.instance;
    await store.initialize();
    await store.persistLegacySelectionIfNeeded(90);
    expect(store.hasExplicitSelection, isTrue);
    expect(store.resolve(120).characterType, HomeCharacterType.tree);
    expect(
      shouldPresentHomeNextCharacterSelection(
        selection: store.resolve(120),
        totalRecordCount: 120,
      ),
      isTrue,
    );

    store.debugReset();
    await store.initialize();
    expect(store.resolve(120).characterType, HomeCharacterType.tree);
  });

  test("이미 고른 캐릭터가 있으면 덮어쓰지 않는다", () async {
    final HomeCharacterSelectionStore store =
        HomeCharacterSelectionStore.instance;
    await store.initialize();
    await store.select(HomeCharacterType.cat, totalRecordCount: 0);
    await store.persistLegacySelectionIfNeeded(130);
    expect(store.resolve(130).characterType, HomeCharacterType.cat);
  });
}
