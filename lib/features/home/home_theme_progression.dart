import "../../design_system/theme/app_theme.dart";
import "home_character_assets.dart";

/// 캐릭터 하나를 키우는 한 사이클의 기록 수. (60회 = 약 60일)
const int homeCharacterCycleRecordCount = 60;

/// 사이클이 끝나기 몇 기록 전부터 "곧 새 캐릭터를 고를 수 있어요" 안내를 띄울지.
const int homeNextCharacterComingSoonLeadRecordCount = 7;

/// 예전(강제 순서) 기준 테마 해금 기록 수. 기존 이용자 마이그레이션에만 쓴다.
const int homeGreenThemeUnlockRecordCount = 60;
const int homeBrownThemeUnlockRecordCount = 120;
const int homePurpleThemeUnlockRecordCount = 180;

/// 이용자가 지금 키우고 있는 캐릭터와 그 사이클이 시작된 누적 기록 수.
class HomeCharacterSelection {
  const HomeCharacterSelection({
    required this.characterType,
    required this.cycleStartRecordCount,
  });

  final HomeCharacterType characterType;

  /// 이 캐릭터를 키우기 시작한 시점의 누적 기록 수.
  final int cycleStartRecordCount;

  /// 이 캐릭터 사이클에서 쌓은 기록 수.
  int growthRecordCountFor(int totalRecordCount) {
    final int growth = totalRecordCount - cycleStartRecordCount;
    return growth < 0 ? 0 : growth;
  }

  /// 같은 캐릭터를 다시 골라도 구분되도록 사이클 시작점까지 포함한 키.
  String get cycleKey => "${characterType.name}@$cycleStartRecordCount";

  @override
  bool operator ==(Object other) {
    return other is HomeCharacterSelection &&
        other.characterType == characterType &&
        other.cycleStartRecordCount == cycleStartRecordCount;
  }

  @override
  int get hashCode => Object.hash(characterType, cycleStartRecordCount);

  @override
  String toString() => "HomeCharacterSelection($cycleKey)";
}

/// 캐릭터를 직접 고르기 전(구버전) 이용자는 예전 강제 순서
/// (물고기 → 새싹 → 돌맹이 → 백구)를 그대로 이어받는다.
HomeCharacterSelection legacyHomeCharacterSelectionForTotalRecordCount(
  int totalRecordCount,
) {
  if (totalRecordCount >= homePurpleThemeUnlockRecordCount) {
    return const HomeCharacterSelection(
      characterType: HomeCharacterType.dog,
      cycleStartRecordCount: homePurpleThemeUnlockRecordCount,
    );
  }
  if (totalRecordCount >= homeBrownThemeUnlockRecordCount) {
    return const HomeCharacterSelection(
      characterType: HomeCharacterType.stone,
      cycleStartRecordCount: homeBrownThemeUnlockRecordCount,
    );
  }
  if (totalRecordCount >= homeGreenThemeUnlockRecordCount) {
    return const HomeCharacterSelection(
      characterType: HomeCharacterType.tree,
      cycleStartRecordCount: homeGreenThemeUnlockRecordCount,
    );
  }
  return const HomeCharacterSelection(
    characterType: HomeCharacterType.fish,
    cycleStartRecordCount: 0,
  );
}

/// 저장된 선택이 있으면 그것을, 없으면 구버전 순서로 계산한 캐릭터를 쓴다.
HomeCharacterSelection resolveHomeCharacterSelection({
  required HomeCharacterSelection? stored,
  required int totalRecordCount,
}) {
  return stored ??
      legacyHomeCharacterSelectionForTotalRecordCount(totalRecordCount);
}

/// 새 캐릭터를 골랐을 때 사이클 시작점.
///
/// 60회 단위 경계를 유지해서, 선택을 조금 늦게 해도 넘친 기록이
/// 새 캐릭터 성장에 그대로 반영되도록 한다. 여러 사이클이 밀려 있어도
/// (예: 300회 기록한 구버전 이용자) 한 번 고르면 바로 다시 선택 화면이 뜨지 않는다.
int nextHomeCharacterCycleStartRecordCount({
  required HomeCharacterSelection current,
  required int totalRecordCount,
}) {
  final int elapsed = totalRecordCount - current.cycleStartRecordCount;
  if (elapsed <= 0) {
    return current.cycleStartRecordCount;
  }
  final int completedCycles = elapsed ~/ homeCharacterCycleRecordCount;
  return current.cycleStartRecordCount +
      completedCycles * homeCharacterCycleRecordCount;
}

/// 현재 캐릭터를 끝까지 키워서 다음 캐릭터를 골라야 하는지.
bool shouldPresentHomeNextCharacterSelection({
  required HomeCharacterSelection selection,
  required int totalRecordCount,
}) {
  return selection.growthRecordCountFor(totalRecordCount) >=
      homeCharacterCycleRecordCount;
}

/// 사이클 종료가 가까워서 "곧 새 캐릭터를 고를 수 있어요" 안내를 띄울지.
bool shouldShowHomeNextCharacterComingSoonNotice({
  required HomeCharacterSelection selection,
  required int totalRecordCount,
}) {
  final int growth = selection.growthRecordCountFor(totalRecordCount);
  return growth >=
          homeCharacterCycleRecordCount -
              homeNextCharacterComingSoonLeadRecordCount &&
      growth < homeCharacterCycleRecordCount;
}

/// 다음 캐릭터를 고를 수 있을 때까지 남은 기록 수.
int homeRecordsUntilNextCharacterSelection({
  required HomeCharacterSelection selection,
  required int totalRecordCount,
}) {
  final int remaining =
      homeCharacterCycleRecordCount -
      selection.growthRecordCountFor(totalRecordCount);
  return remaining < 0 ? 0 : remaining;
}

HomeCharacterType? parseHomeCharacterType(String raw) {
  switch (raw.trim().toLowerCase()) {
    case "fish":
    case "blue":
    case "물고기":
      return HomeCharacterType.fish;
    case "tree":
    case "green":
    case "새싹":
      return HomeCharacterType.tree;
    case "stone":
    case "rock":
    case "brown":
    case "돌맹이":
      return HomeCharacterType.stone;
    case "dog":
    case "purple":
    case "백구":
      return HomeCharacterType.dog;
    case "dino":
    case "공룡":
      return HomeCharacterType.dino;
    case "cat":
    case "고양이":
      return HomeCharacterType.cat;
    case "axolotl":
    case "우파루파":
      return HomeCharacterType.axolotl;
    case "parrotbill":
    case "bird":
    case "뱁새":
      return HomeCharacterType.parrotbill;
  }
  return null;
}

AppBrandTheme resolveHomeBrandTheme({
  required HomeCharacterType characterType,
}) {
  return characterType.brandTheme;
}

String resolveHomeInviteBannerAsset(HomeCharacterType characterType) {
  return HomeCharacterAssets.inviteBannerAssetFor(characterType);
}
