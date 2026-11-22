import "package:flutter/foundation.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../question/today_question_store.dart";
import "home_character_assets.dart";
import "home_theme_progression.dart";

/// 이용자가 고른 홈 캐릭터(테마)를 기기에 저장하고 앱 전체에 알려준다.
///
/// 값이 null이면 아직 직접 고른 적이 없는 구버전 이용자라는 뜻이고,
/// 이때는 [legacyHomeCharacterSelectionForTotalRecordCount] 순서를 따른다.
class HomeCharacterSelectionStore
    extends ValueNotifier<HomeCharacterSelection?> {
  HomeCharacterSelectionStore._() : super(null);

  static final HomeCharacterSelectionStore instance =
      HomeCharacterSelectionStore._();

  static const String _characterTypePrefsKey = "home_character_type";
  static const String _cycleStartPrefsKey = "home_character_cycle_start";

  Future<void>? _initializing;
  bool _isInitialized = false;

  /// 디버그 프리뷰(DEBUG_PREVIEW_THEME)용 강제 캐릭터.
  HomeCharacterType? _debugOverride;

  bool get isInitialized => _isInitialized;

  /// 이용자가 직접 캐릭터를 고른 적이 있는지.
  bool get hasExplicitSelection => value != null;

  Future<void> initialize() {
    return _initializing ??= _load();
  }

  Future<void> _load() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? rawType = prefs.getString(_characterTypePrefsKey);
      final int? cycleStart = prefs.getInt(_cycleStartPrefsKey);
      final HomeCharacterType? type = rawType == null
          ? null
          : HomeCharacterType.values.asNameMap()[rawType];
      if (type != null && cycleStart != null) {
        value = HomeCharacterSelection(
          characterType: type,
          cycleStartRecordCount: cycleStart < 0 ? 0 : cycleStart,
        );
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint("[HomeCharacterSelectionStore] load failed: $error");
      }
    } finally {
      _isInitialized = true;
    }
  }

  void setDebugOverride(HomeCharacterType? type) {
    if (_debugOverride == type) {
      return;
    }
    _debugOverride = type;
    notifyListeners();
  }

  /// 디버그 프리뷰(DEBUG_PREVIEW_CHARACTER)용: 이 캐릭터를 0번째 기록부터 직접
  /// 고른 것처럼 메모리에만 설정한다. 저장하지 않으므로 앱을 다시 켜면 다시 적용된다.
  /// [setDebugOverride]와 달리 선택 화면에서 다른 캐릭터를 고르면 그대로 바뀐다.
  void debugSeedSelection(HomeCharacterType type) {
    value = HomeCharacterSelection(
      characterType: type,
      cycleStartRecordCount: 0,
    );
  }

  /// 디버그 프리뷰(DEBUG_PREVIEW_CHARACTER=legacy)용: 직접 고른 적 없는
  /// 구버전 이용자처럼 보이게 메모리에서만 선택을 비운다.
  void debugUseLegacySelection() {
    _isDebugLegacyPreview = true;
    value = null;
  }

  bool _isDebugLegacyPreview = false;

  /// 업데이트 전부터 쓰던 이용자(직접 고른 적 없음)는 처음 홈에 들어올 때
  /// 지금 키우던 캐릭터(구버전 순서)를 한 번 저장한다.
  ///
  /// 저장하지 않고 매번 기록 수로 계산하면, 60·120·180회가 되는 순간
  /// 예전처럼 다음 캐릭터로 자동으로 넘어가 버려서 선택 화면을 만날 수 없다.
  Future<void> persistLegacySelectionIfNeeded(int totalRecordCount) async {
    if (value != null || _debugOverride != null) {
      return;
    }
    final HomeCharacterSelection legacy =
        legacyHomeCharacterSelectionForTotalRecordCount(totalRecordCount);
    value = legacy;
    if (_isDebugLegacyPreview) {
      return;
    }
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_characterTypePrefsKey, legacy.characterType.name);
      await prefs.setInt(_cycleStartPrefsKey, legacy.cycleStartRecordCount);
    } catch (error) {
      if (kDebugMode) {
        debugPrint("[HomeCharacterSelectionStore] legacy save failed: $error");
      }
    }
  }

  /// 누적 기록 수 기준으로 지금 키우는 캐릭터 사이클.
  HomeCharacterSelection resolve(int totalRecordCount) {
    final HomeCharacterType? debugOverride = _debugOverride;
    if (debugOverride != null) {
      return HomeCharacterSelection(
        characterType: debugOverride,
        cycleStartRecordCount: _debugCycleStartFor(debugOverride),
      );
    }
    return resolveHomeCharacterSelection(
      stored: value,
      totalRecordCount: totalRecordCount,
    );
  }

  /// 지금 누적 기록 수 기준 현재 사이클.
  HomeCharacterSelection get current =>
      resolve(TodayQuestionStore.instance.value.length);

  /// 캐릭터를 고른다. 회원가입 첫 선택과, 한 사이클을 마친 뒤 다음 캐릭터
  /// 선택 모두 이 함수를 쓴다. 같은 캐릭터를 다시 골라도 1레벨부터 다시 시작한다.
  Future<HomeCharacterSelection> select(
    HomeCharacterType type, {
    required int totalRecordCount,
  }) async {
    final HomeCharacterSelection previous = resolveHomeCharacterSelection(
      stored: value,
      totalRecordCount: totalRecordCount,
    );
    final HomeCharacterSelection next = HomeCharacterSelection(
      characterType: type,
      cycleStartRecordCount: nextHomeCharacterCycleStartRecordCount(
        current: previous,
        totalRecordCount: totalRecordCount,
      ),
    );
    value = next;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_characterTypePrefsKey, type.name);
      await prefs.setInt(_cycleStartPrefsKey, next.cycleStartRecordCount);
    } catch (error) {
      if (kDebugMode) {
        debugPrint("[HomeCharacterSelectionStore] save failed: $error");
      }
    }
    return next;
  }

  /// 데이터 초기화 등으로 처음 상태로 돌릴 때.
  Future<void> clear() async {
    value = null;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_characterTypePrefsKey);
    await prefs.remove(_cycleStartPrefsKey);
    // 홈 레벨업 축하 기록도 사이클 기준이라 함께 지운다. (home_screen.dart)
    await prefs.remove("home_celebrated_cycle_key");
    await prefs.remove("home_celebrated_cycle_level");
  }

  @visibleForTesting
  void debugReset() {
    _initializing = null;
    _isInitialized = false;
    _debugOverride = null;
    _isDebugLegacyPreview = false;
    value = null;
  }

  int _debugCycleStartFor(HomeCharacterType type) {
    return switch (type) {
      HomeCharacterType.tree => homeGreenThemeUnlockRecordCount,
      HomeCharacterType.stone => homeBrownThemeUnlockRecordCount,
      HomeCharacterType.dog => homePurpleThemeUnlockRecordCount,
      _ => 0,
    };
  }
}

/// 지금 홈에서 키우고 있는 캐릭터.
HomeCharacterType currentHomeCharacterType() {
  return HomeCharacterSelectionStore.instance.current.characterType;
}

/// 지금 캐릭터 사이클에서 쌓은 기록 수.
int currentHomeGrowthRecordCount(int totalRecordCount) {
  return HomeCharacterSelectionStore.instance
      .resolve(totalRecordCount)
      .growthRecordCountFor(totalRecordCount);
}

/// 지금 캐릭터 사이클 기준, 해당 캐릭터의 성장 단계 이미지.
String homeCharacterAssetForTotalRecordCount({
  required HomeCharacterType characterType,
  required int totalRecordCount,
}) {
  return HomeCharacterAssets.assetForRecordCount(
    characterType,
    currentHomeGrowthRecordCount(totalRecordCount),
  );
}
