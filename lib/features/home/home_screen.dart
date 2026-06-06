import "dart:async";
import "dart:ui" as ui;

import "package:flutter/gestures.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../../core/app_route_observer.dart";
import "../../core/kst_date_time.dart";
import "../../design_system/design_system.dart";
import "../navigation/main_tab_shell.dart";
import "annual_record_screen.dart";
import "green_theme_coming_soon_popup.dart";
import "my_record_detail_screen.dart";
import "home_character_assets.dart";
import "home_fish_growth.dart";
import "next_theme_unlock_screen.dart";
import "home_theme_progression.dart";
import "my_records_screen.dart";
import "public_record_detail_screen.dart";
import "public_today_records_repository.dart";
import "../question/today_question_answer_screen.dart";
import "../question/today_question_prompt_store.dart";
import "../question/today_question_store.dart";
import "daily_checkin_store.dart";
import "today_records_screen.dart";

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.showNavigationBar = true});

  final bool showNavigationBar;

  static const String _decoSeaweedAsset =
      "assets/images/home/home_deco_seaweed_blue.webp";
  static const String _decoCrabAsset =
      "assets/images/home/home_deco_crab_blue.webp";
  static const String _decoBubbleAsset =
      "assets/images/home/home_deco_bubble_blue.webp";
  static const String _iosInviteStoreUrl =
      "https://apps.apple.com/kr/app/dailyquestion/id6760876920";
  static const String _androidInviteStoreUrl =
      "https://play.google.com/store/apps/details?id=com.pland.dailyquestion";
  static const String _topWaterBackgroundAsset =
      "assets/images/home/home_bg_water.webp";

  static void openTodayQuestionAnswer(
    BuildContext context, {
    String? questionText,
    int? questionSlot,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TodayQuestionAnswerScreen(
          questionText: questionText,
          questionSlot: questionSlot,
        ),
      ),
    );
  }

  static Future<void> openTodayRecords(
    BuildContext context, {
    String? questionDateKey,
    String? questionText,
    List<PublicTodayRecord> initialRecords = const <PublicTodayRecord>[],
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TodayRecordsScreen(
          questionDateKey: questionDateKey,
          questionText: questionText,
          initialRecords: initialRecords,
        ),
      ),
    );
  }

  static Future<PublicRecordDetailResult?> openPublicRecordDetail(
    BuildContext context, {
    required PublicTodayRecord record,
    required String questionDateKey,
    required String questionText,
  }) {
    return showGeneralDialog<PublicRecordDetailResult>(
      context: context,
      barrierDismissible: false,
      barrierLabel: "타인의 기록 닫기",
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder:
          (
            BuildContext dialogContext,
            Animation<double> primaryAnimation,
            Animation<double> secondaryAnimation,
          ) => PublicRecordDetailOverlay(
            record: record,
            questionDateKey: questionDateKey,
            questionText: questionText,
          ),
      transitionBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
              child: child,
            );
          },
    );
  }

  static void goHome(BuildContext context) {
    Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    return Scaffold(
      backgroundColor: brand.bg,
      body: Padding(
        padding: EdgeInsets.zero,
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: AppNavigationBar.totalHeight(context) + AppSpacing.s8,
                ),
                child: Column(
                  children: <Widget>[
                    const _TopQuestionPanel(),
                    const SizedBox(height: AppSpacing.s24),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _RecordStreakSection(),
                          const SizedBox(height: AppSpacing.s24),
                          _TodayRecordSection(),
                          const SizedBox(height: AppSpacing.s24),
                          const _TodayMeSection(),
                          const SizedBox(height: AppSpacing.s24),
                          _InviteFriendsBanner(),
                          const SizedBox(height: AppSpacing.s40),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (showNavigationBar)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: AppNavigationBar(
                  currentIndex: 0,
                  onTap: (int index) {
                    if (index == 0) {
                      goHome(context);
                      return;
                    }
                    MainTabShell.replace(context, index: index);
                  },
                  items: const <AppNavigationBarItemData>[
                    AppNavigationBarItemData(
                      label: "오늘의 질문",
                      icon: Icons.home_outlined,
                    ),
                    AppNavigationBarItemData(
                      label: "버킷리스트",
                      icon: Icons.format_list_bulleted,
                    ),
                    AppNavigationBarItemData(
                      label: "나의기록",
                      icon: Icons.assignment_outlined,
                    ),
                    AppNavigationBarItemData(
                      label: "더보기",
                      icon: Icons.more_horiz,
                    ),
                  ],
                ),
              ),
            const Positioned.fill(child: _HomeLevelUpOverlayHost()),
          ],
        ),
      ),
    );
  }
}

class _TopQuestionPanel extends StatefulWidget {
  const _TopQuestionPanel();

  @override
  State<_TopQuestionPanel> createState() => _TopQuestionPanelState();
}

class _TopQuestionPanelState extends State<_TopQuestionPanel>
    with WidgetsBindingObserver {
  Timer? _dateRefreshTimer;
  String _lastKstDateKey = kstDateKeyNow();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(TodayQuestionPromptStore.instance.initialize());
    _scheduleDateRefreshTimer();
  }

  void _scheduleDateRefreshTimer() {
    _dateRefreshTimer?.cancel();
    _dateRefreshTimer = Timer(durationUntilNextKstDateChange(), () {
      unawaited(_refreshByKstDateChange());
      if (!mounted) {
        return;
      }
      _scheduleDateRefreshTimer();
    });
  }

  Future<void> _refreshByKstDateChange() async {
    final String currentDateKey = kstDateKeyNow();
    if (currentDateKey != _lastKstDateKey) {
      _lastKstDateKey = currentDateKey;
      await TodayQuestionPromptStore.instance.reloadIfNeeded();
      if (!mounted) {
        return;
      }
      setState(() {});
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshByKstDateChange());
      _scheduleDateRefreshTimer();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dateRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    const BorderRadius panelRadius = BorderRadius.only(
      bottomLeft: Radius.circular(40),
      bottomRight: Radius.circular(40),
    );
    return ValueListenableBuilder<List<TodayQuestionRecord>>(
      valueListenable: TodayQuestionStore.instance,
      builder:
          (
            BuildContext context,
            List<TodayQuestionRecord> records,
            Widget? child,
          ) {
            final bool isTreeTheme =
                resolveHomeCharacterType(brand) == HomeCharacterType.tree;
            final bool hasRecord =
                records.isNotEmpty &&
                TodayQuestionStore.instance.hasRecordForTodayKst;
            final int totalRecordCount = records.length;
            return Container(
              decoration: BoxDecoration(
                color: isTreeTheme ? brand.c200 : brand.c100,
                borderRadius: panelRadius,
                boxShadow: AppElevation.level2,
              ),
              child: ClipRRect(
                borderRadius: panelRadius,
                child: Stack(
                  children: <Widget>[
                    if (hasRecord && !isTreeTheme)
                      Positioned(
                        left: 0,
                        top: 0,
                        right: 0,
                        height: 247,
                        child: IgnorePointer(
                          child: Opacity(
                            opacity: 0.5,
                            child: Image.asset(
                              HomeScreen._topWaterBackgroundAsset,
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                            ),
                          ),
                        ),
                      ),
                    if (hasRecord)
                      Positioned(
                        left: -35,
                        top: 125,
                        width: 460,
                        height: 460,
                        child: IgnorePointer(
                          child: Center(
                            child: ImageFiltered(
                              imageFilter: ui.ImageFilter.blur(
                                sigmaX: 50,
                                sigmaY: 50,
                              ),
                              child: Container(
                                width: 260,
                                height: 260,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppNeutralColors.white.withValues(
                                    alpha: 0.72,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                      child: Column(
                        children: <Widget>[
                          const SizedBox(height: 49),
                          SizedBox(
                            height: 65,
                            child: Row(
                              children: <Widget>[
                                const SizedBox(width: 24, height: 24),
                                Expanded(
                                  child: Text(
                                    "Daily Question",
                                    textAlign: TextAlign.center,
                                    style: AppTypography.headingXSmall.copyWith(
                                      color: AppNeutralColors.grey900,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 24, height: 24),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.s24),
                          if (hasRecord) ...<Widget>[
                            const _QuestionWrittenPreviewCard(),
                            SizedBox(
                              height: isTreeTheme
                                  ? AppSpacing.s0
                                  : AppSpacing.s8,
                            ),
                            Transform.translate(
                              offset: Offset(0, isTreeTheme ? -44 : 0),
                              child: _TopCharacterDecorations(
                                bubbleColor: brand.c500,
                                recordCount: totalRecordCount,
                              ),
                            ),
                          ] else ...<Widget>[
                            _QuestionBeforeRecordCard(
                              recordCount: totalRecordCount,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
    );
  }
}

class _HomeLevelUpOverlayHost extends StatefulWidget {
  const _HomeLevelUpOverlayHost();

  @override
  State<_HomeLevelUpOverlayHost> createState() =>
      _HomeLevelUpOverlayHostState();
}

class _HomeLevelUpOverlayHostState extends State<_HomeLevelUpOverlayHost>
    with RouteAware, WidgetsBindingObserver {
  static const String _legacyFishCelebratedLevelPrefsKey =
      "home_last_celebrated_fish_level";
  static const String _lastCelebratedFishLevelPrefsKey =
      "home_last_celebrated_level_fish";
  static const String _lastCelebratedTreeLevelPrefsKey =
      "home_last_celebrated_level_tree";
  static const String _greenThemeComingSoonDismissedDatePrefsKey =
      "home_green_theme_coming_soon_dismissed_date";
  static const String _greenThemeUnlockPresentedPrefsKey =
      "home_green_theme_unlock_presented";
  static const Duration _visibleDuration = Duration(seconds: 5);
  static const Duration _fadeDuration = Duration(milliseconds: 220);

  SharedPreferences? _prefs;
  final Map<HomeCharacterType, int> _lastCelebratedLevels =
      <HomeCharacterType, int>{};
  String? _dismissedGreenThemeComingSoonDateKey;
  String? _acknowledgedGreenThemeComingSoonDateKey;
  bool _hasPresentedGreenThemeUnlock = false;
  HomeFishGrowthLevel? _visibleLevel;
  HomeCharacterType? _visibleCharacterType;
  PageRoute<dynamic>? _pageRoute;
  bool _isOverlayVisible = false;
  bool _isRouteVisible = false;
  bool _isPresentingGreenThemeComingSoon = false;
  bool _isPresentingNextThemeUnlock = false;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    TodayQuestionStore.instance.addListener(_handleRecordsChanged);
    unawaited(_prepare());
  }

  Future<void> _prepare() async {
    await TodayQuestionStore.instance.initialize();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int totalRecordCount = TodayQuestionStore.instance.value.length;
    final HomeCharacterType currentCharacterType = _currentCharacterType();
    final int growthRecordCount = homeGrowthRecordCountForCharacter(
      characterType: currentCharacterType,
      totalRecordCount: totalRecordCount,
    );
    final HomeFishGrowthLevel currentLevel = homeFishGrowthLevelForRecordCount(
      growthRecordCount,
    );
    final int storedFishLevelNumber =
        prefs.getInt(_lastCelebratedFishLevelPrefsKey) ??
        prefs.getInt(_legacyFishCelebratedLevelPrefsKey) ??
        (currentCharacterType == HomeCharacterType.fish
            ? currentLevel.number
            : HomeFishGrowthLevel.level1.number);
    final int storedTreeLevelNumber = _normalizedStoredLevelNumber(
      storedLevelNumber: prefs.getInt(_lastCelebratedTreeLevelPrefsKey),
      fallbackLevelNumber: currentCharacterType == HomeCharacterType.tree
          ? currentLevel.number
          : HomeFishGrowthLevel.level1.number,
      currentLevelNumber: currentLevel.number,
      shouldClampToCurrent: currentCharacterType == HomeCharacterType.tree,
    );
    final int previousStoredTreeLevelNumber =
        prefs.getInt(_lastCelebratedTreeLevelPrefsKey) ??
        (currentCharacterType == HomeCharacterType.tree
            ? currentLevel.number
            : HomeFishGrowthLevel.level1.number);
    final String? storedGreenThemeComingSoonDismissedDateKey = prefs.getString(
      _greenThemeComingSoonDismissedDatePrefsKey,
    );
    final bool storedGreenThemeUnlockPresented =
        prefs.getBool(_greenThemeUnlockPresentedPrefsKey) ?? false;
    if (!prefs.containsKey(_lastCelebratedFishLevelPrefsKey)) {
      await prefs.setInt(
        _lastCelebratedFishLevelPrefsKey,
        storedFishLevelNumber,
      );
    }
    if (!prefs.containsKey(_lastCelebratedTreeLevelPrefsKey)) {
      await prefs.setInt(
        _lastCelebratedTreeLevelPrefsKey,
        storedTreeLevelNumber,
      );
    } else if (storedTreeLevelNumber != previousStoredTreeLevelNumber) {
      await prefs.setInt(
        _lastCelebratedTreeLevelPrefsKey,
        storedTreeLevelNumber,
      );
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _prefs = prefs;
      _lastCelebratedLevels[HomeCharacterType.fish] = storedFishLevelNumber;
      _lastCelebratedLevels[HomeCharacterType.tree] = storedTreeLevelNumber;
      _dismissedGreenThemeComingSoonDateKey =
          storedGreenThemeComingSoonDismissedDateKey;
      _hasPresentedGreenThemeUnlock = storedGreenThemeUnlockPresented;
    });
    _evaluatePendingCelebration();
  }

  void _handleRecordsChanged() {
    _evaluatePendingCelebration();
  }

  int _normalizedStoredLevelNumber({
    required int? storedLevelNumber,
    required int fallbackLevelNumber,
    required int currentLevelNumber,
    required bool shouldClampToCurrent,
  }) {
    final int levelNumber = storedLevelNumber ?? fallbackLevelNumber;
    if (shouldClampToCurrent && levelNumber > currentLevelNumber) {
      return currentLevelNumber;
    }
    return levelNumber;
  }

  void _evaluatePendingCelebration() {
    final SharedPreferences? prefs = _prefs;
    if (prefs == null) {
      return;
    }
    if (!_isRouteVisible) {
      return;
    }
    final int totalRecordCount = TodayQuestionStore.instance.value.length;
    final HomeCharacterType currentCharacterType = _currentCharacterType();
    final int growthRecordCount = homeGrowthRecordCountForCharacter(
      characterType: currentCharacterType,
      totalRecordCount: totalRecordCount,
    );
    final int? lastCelebratedLevelNumber =
        _lastCelebratedLevels[currentCharacterType];
    if (lastCelebratedLevelNumber == null) {
      return;
    }
    if (!_hasPresentedGreenThemeUnlock &&
        hasUnlockedHomeGreenTheme(totalRecordCount)) {
      _hasPresentedGreenThemeUnlock = true;
      unawaited(prefs.setBool(_greenThemeUnlockPresentedPrefsKey, true));
      if (shouldPresentHomeGreenThemeUnlock(
        totalRecordCount: totalRecordCount,
        currentCharacterType: currentCharacterType,
        hasPresented: false,
      )) {
        unawaited(_presentNextThemeUnlockScreen());
      }
      return;
    }
    final String todayDateKey = kstDateKeyNow();
    if (shouldShowHomeGreenThemeComingSoonNotice(
          totalRecordCount,
          currentCharacterType: currentCharacterType,
        ) &&
        _dismissedGreenThemeComingSoonDateKey != todayDateKey &&
        _acknowledgedGreenThemeComingSoonDateKey != todayDateKey) {
      unawaited(_presentGreenThemeComingSoonNotice(todayDateKey));
      return;
    }
    final HomeFishGrowthLevel currentLevel = homeFishGrowthLevelForRecordCount(
      growthRecordCount,
    );
    if (!currentLevel.canCelebrate ||
        currentLevel.number <= lastCelebratedLevelNumber) {
      return;
    }
    _lastCelebratedLevels[currentCharacterType] = currentLevel.number;
    unawaited(
      prefs.setInt(
        _prefsKeyForCharacterType(currentCharacterType),
        currentLevel.number,
      ),
    );
    _showOverlay(currentCharacterType, currentLevel);
  }

  HomeCharacterType _currentCharacterType() {
    return resolveHomeCharacterType(context.appBrandScale);
  }

  String _prefsKeyForCharacterType(HomeCharacterType type) {
    return switch (type) {
      HomeCharacterType.fish => _lastCelebratedFishLevelPrefsKey,
      HomeCharacterType.tree => _lastCelebratedTreeLevelPrefsKey,
    };
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ModalRoute<dynamic>? route = ModalRoute.of(context);
    if (route is! PageRoute<dynamic>) {
      return;
    }
    if (_pageRoute == route) {
      _isRouteVisible = route.isCurrent;
      return;
    }
    if (_pageRoute != null) {
      appRouteObserver.unsubscribe(this);
    }
    _pageRoute = route;
    _isRouteVisible = route.isCurrent;
    appRouteObserver.subscribe(this, route);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _evaluatePendingCelebration();
    });
  }

  @override
  void didPush() {
    _isRouteVisible = true;
    _evaluatePendingCelebration();
  }

  @override
  void didPopNext() {
    _isRouteVisible = true;
    _evaluatePendingCelebration();
  }

  @override
  void didPushNext() {
    _isRouteVisible = false;
  }

  @override
  void didPop() {
    _isRouteVisible = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _evaluatePendingCelebration();
    }
  }

  void _showOverlay(
    HomeCharacterType characterType,
    HomeFishGrowthLevel level,
  ) {
    _hideTimer?.cancel();
    if (!mounted) {
      return;
    }
    setState(() {
      _visibleLevel = level;
      _visibleCharacterType = characterType;
      _isOverlayVisible = true;
    });
    _hideTimer = Timer(_visibleDuration, () {
      if (!mounted) {
        return;
      }
      setState(() {
        _isOverlayVisible = false;
      });
      Timer(_fadeDuration, () {
        if (!mounted || _isOverlayVisible) {
          return;
        }
        setState(() {
          _visibleLevel = null;
          _visibleCharacterType = null;
        });
      });
    });
  }

  Future<void> _presentNextThemeUnlockScreen() async {
    if (_isPresentingGreenThemeComingSoon ||
        _isPresentingNextThemeUnlock ||
        !mounted) {
      return;
    }
    _isPresentingNextThemeUnlock = true;
    _hideTimer?.cancel();
    if (_visibleLevel != null || _isOverlayVisible) {
      setState(() {
        _visibleLevel = null;
        _visibleCharacterType = null;
        _isOverlayVisible = false;
      });
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const NextThemeUnlockScreen()),
    );
    _isPresentingNextThemeUnlock = false;
  }

  Future<void> _presentGreenThemeComingSoonNotice(String todayDateKey) async {
    if (_isPresentingGreenThemeComingSoon ||
        _isPresentingNextThemeUnlock ||
        !mounted) {
      return;
    }
    _isPresentingGreenThemeComingSoon = true;
    final bool? dismissForToday = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: AppPopupTokens.dimmed,
      builder: (BuildContext dialogContext) {
        return Center(
          child: GreenThemeComingSoonPopup(
            onCloseForToday: () => Navigator.of(dialogContext).pop(true),
            onConfirm: () => Navigator.of(dialogContext).pop(false),
          ),
        );
      },
    );
    _isPresentingGreenThemeComingSoon = false;
    if (dismissForToday == null || !mounted) {
      return;
    }
    _acknowledgedGreenThemeComingSoonDateKey = todayDateKey;
    if (dismissForToday) {
      _dismissedGreenThemeComingSoonDateKey = todayDateKey;
      final SharedPreferences? prefs = _prefs;
      if (prefs != null) {
        unawaited(
          prefs.setString(
            _greenThemeComingSoonDismissedDatePrefsKey,
            todayDateKey,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    TodayQuestionStore.instance.removeListener(_handleRecordsChanged);
    if (_pageRoute != null) {
      appRouteObserver.unsubscribe(this);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final HomeFishGrowthLevel? visibleLevel = _visibleLevel;
    final HomeCharacterType? visibleCharacterType = _visibleCharacterType;
    if (visibleLevel == null || visibleCharacterType == null) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      ignoring: !_isOverlayVisible,
      child: AnimatedOpacity(
        opacity: _isOverlayVisible ? 1 : 0,
        duration: _fadeDuration,
        curve: Curves.easeOutCubic,
        child: _HomeLevelUpOverlay(
          characterType: visibleCharacterType,
          level: visibleLevel,
        ),
      ),
    );
  }
}

class _HomeLevelUpOverlay extends StatelessWidget {
  const _HomeLevelUpOverlay({required this.characterType, required this.level});

  final HomeCharacterType characterType;
  final HomeFishGrowthLevel level;

  static const Color _scrimColor = Color(0xB8000000);
  static final Color _fishAccentColor = AppBrandThemes.blue.c300;
  static final Color _treeAccentColor = AppBrandThemes.green.c300;

  String get _headline {
    if (characterType == HomeCharacterType.fish) {
      return level.celebrationHeadline;
    }
    return switch (level) {
      HomeFishGrowthLevel.level1 => "새싹과 첫 만남이에요!",
      HomeFishGrowthLevel.level2 => "작은 잎사귀가 자라났어요!",
      HomeFishGrowthLevel.level3 => "제법 자라났어요!",
      HomeFishGrowthLevel.level4 => "더 크게 자라났어요!",
      HomeFishGrowthLevel.level5 => "무럭무럭 자랐어요!",
      HomeFishGrowthLevel.level6 => "풍성한 나무가 되었어요!",
    };
  }

  Color get _accentColor {
    return switch (characterType) {
      HomeCharacterType.fish => _fishAccentColor,
      HomeCharacterType.tree => _treeAccentColor,
    };
  }

  _HomeLevelUpOverlayDecorLayout get _decorLayout {
    if (characterType == HomeCharacterType.fish) {
      return const _HomeLevelUpOverlayDecorLayout(
        width: 285,
        leftTop: 34,
        rightTop: 32,
      );
    }
    return switch (level) {
      HomeFishGrowthLevel.level1 => const _HomeLevelUpOverlayDecorLayout(
        width: 285,
        leftTop: 34,
        rightTop: 32,
      ),
      HomeFishGrowthLevel.level2 => const _HomeLevelUpOverlayDecorLayout(
        width: 285,
        leftTop: 34,
        rightTop: 32,
      ),
      HomeFishGrowthLevel.level3 => const _HomeLevelUpOverlayDecorLayout(
        width: 285,
        leftTop: 34,
        rightTop: 32,
      ),
      HomeFishGrowthLevel.level4 => const _HomeLevelUpOverlayDecorLayout(
        width: 298,
        leftTop: 34,
        rightTop: 32,
      ),
      HomeFishGrowthLevel.level5 => const _HomeLevelUpOverlayDecorLayout(
        width: 327,
        leftTop: 20,
        rightTop: 18,
      ),
      HomeFishGrowthLevel.level6 => const _HomeLevelUpOverlayDecorLayout(
        width: 327,
        leftTop: 20,
        rightTop: 18,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final String assetPath = HomeCharacterAssets.levelUpOverlayAssetFor(
      characterType,
      level,
    );
    return ColoredBox(
      color: _scrimColor,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  "축하해요!",
                  textAlign: TextAlign.center,
                  style: AppTypography.heading2XSmall.copyWith(
                    color: _accentColor,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _headline,
                  textAlign: TextAlign.center,
                  style: AppTypography.headingLarge.copyWith(
                    color: AppNeutralColors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Level ${level.number}",
                  style: AppTypography.heading2XSmall.copyWith(
                    color: _accentColor,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: _decorLayout.width,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      Positioned(
                        left: 0,
                        top: _decorLayout.leftTop,
                        child: Image.asset(
                          HomeCharacterAssets.levelUpConfettiLeft,
                          width: 88,
                          height: 131,
                          fit: BoxFit.contain,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: _decorLayout.rightTop,
                        child: Image.asset(
                          HomeCharacterAssets.levelUpConfettiRight,
                          width: 97,
                          height: 133,
                          fit: BoxFit.contain,
                        ),
                      ),
                      SizedBox(
                        width: 190,
                        height: 190,
                        child: Image.asset(
                          assetPath,
                          fit: BoxFit.contain,
                          errorBuilder: (_, error, stackTrace) {
                            return Center(
                              child: AppEmojiText(
                                characterType == HomeCharacterType.tree
                                    ? (level == HomeFishGrowthLevel.level6
                                          ? "🌳"
                                          : "🌱")
                                    : "🐟",
                                style: const TextStyle(fontSize: 80),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  "누적기록 횟수 ${level.requiredRecordCount}회 달성!",
                  textAlign: TextAlign.center,
                  style: AppTypography.heading2XSmall.copyWith(
                    color: AppNeutralColors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeLevelUpOverlayDecorLayout {
  const _HomeLevelUpOverlayDecorLayout({
    required this.width,
    required this.leftTop,
    required this.rightTop,
  });

  final double width;
  final double leftTop;
  final double rightTop;
}

enum _SpeechTailDirection { right, down }

class _HomeHeroFishImage extends StatelessWidget {
  const _HomeHeroFishImage({
    required this.characterType,
    required this.growthLevel,
    required this.assetPath,
    required this.size,
    required this.fallbackFontSize,
    this.treeLeafAngle = 0,
    this.treeLeafScale = 1,
  });

  final HomeCharacterType characterType;
  final HomeFishGrowthLevel growthLevel;
  final String assetPath;
  final double size;
  final double fallbackFontSize;
  final double treeLeafAngle;
  final double treeLeafScale;

  @override
  Widget build(BuildContext context) {
    final _SplitTreeAssetConfig? splitTreeConfig = switch (growthLevel) {
      HomeFishGrowthLevel.level1 when characterType == HomeCharacterType.tree =>
        _SplitTreeAssetConfig(
          baseAssetPath: HomeCharacterAssets.treeLevel1Base,
          leafAssetPath: HomeCharacterAssets.treeLevel1Leaf,
          leafYOffsetFactor: 0.02,
          leafRotationAlignment: const Alignment(0.0, 0.36),
          leafScaleAlignment: const Alignment(0.0, 0.36),
          leafScaleCompensationFactor: 0,
        ),
      HomeFishGrowthLevel.level2 when characterType == HomeCharacterType.tree =>
        _SplitTreeAssetConfig(
          baseAssetPath: HomeCharacterAssets.treeLevel2Base,
          leafAssetPath: HomeCharacterAssets.treeLevel2Leaf,
          leafYOffsetFactor: 0.008,
          leafRotationAlignment: const Alignment(0.0, 0.42),
          leafScaleAlignment: const Alignment(0.0, 0.42),
          leafScaleCompensationFactor: 0,
        ),
      HomeFishGrowthLevel.level3 when characterType == HomeCharacterType.tree =>
        _SplitTreeAssetConfig(
          baseAssetPath: HomeCharacterAssets.treeLevel3Base,
          leafAssetPath: HomeCharacterAssets.treeLevel3Leaf,
          leafYOffsetFactor: 0.008,
          leafRotationAlignment: const Alignment(0.0, 0.5),
          leafScaleAlignment: const Alignment(0.0, 0.5),
          leafScaleCompensationFactor: 0,
        ),
      HomeFishGrowthLevel.level4 when characterType == HomeCharacterType.tree =>
        _SplitTreeAssetConfig(
          baseAssetPath: HomeCharacterAssets.treeLevel4Base,
          leafAssetPath: HomeCharacterAssets.treeLevel4Leaf,
          leafYOffsetFactor: 0,
          leafRotationAlignment: const Alignment(0.0, 0.5),
          leafScaleAlignment: const Alignment(0.0, 0.86),
          leafScaleCompensationFactor: 0.7,
        ),
      HomeFishGrowthLevel.level5 when characterType == HomeCharacterType.tree =>
        _SplitTreeAssetConfig(
          baseAssetPath: HomeCharacterAssets.treeLevel5Base,
          leafAssetPath: HomeCharacterAssets.treeLevel5Leaf,
          leafYOffsetFactor: 0,
          leafRotationAlignment: const Alignment(0.0, 0.5),
          leafScaleAlignment: const Alignment(0.0, 0.86),
          leafScaleCompensationFactor: 0.7,
        ),
      HomeFishGrowthLevel.level6 when characterType == HomeCharacterType.tree =>
        _SplitTreeAssetConfig(
          baseAssetPath: HomeCharacterAssets.treeLevel6Base,
          leafAssetPath: HomeCharacterAssets.treeLevel6Leaf,
          leafYOffsetFactor: 0,
          leafRotationAlignment: const Alignment(0.0, 0.5),
          leafScaleAlignment: const Alignment(0.0, 0.86),
          leafScaleCompensationFactor: 0.7,
        ),
      _ => null,
    };
    if (splitTreeConfig != null) {
      final double leafYOffset = size * splitTreeConfig.leafYOffsetFactor;
      final double leafPulseCompensation =
          (treeLeafScale - 1) *
          size *
          splitTreeConfig.leafScaleCompensationFactor;
      return SizedBox(
        key: ValueKey<String>(
          "tree-split-${growthLevel.name}-${splitTreeConfig.leafAssetPath}",
        ),
        width: size,
        height: size,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Image.asset(
              splitTreeConfig.baseAssetPath,
              fit: BoxFit.contain,
              errorBuilder: (_, error, stackTrace) {
                return const SizedBox.shrink();
              },
            ),
            Transform.translate(
              offset: Offset(0, leafYOffset + leafPulseCompensation),
              child: Transform.scale(
                alignment: splitTreeConfig.leafScaleAlignment,
                scale: treeLeafScale,
                child: Transform.rotate(
                  alignment: splitTreeConfig.leafRotationAlignment,
                  angle: treeLeafAngle,
                  child: Image.asset(
                    splitTreeConfig.leafAssetPath,
                    fit: BoxFit.contain,
                    errorBuilder: (_, error, stackTrace) {
                      return Center(
                        child: AppEmojiText(
                          "🌱",
                          style: TextStyle(fontSize: fallbackFontSize),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: SizedBox(
        key: ValueKey<String>(assetPath),
        width: size,
        height: size,
        child: Image.asset(
          assetPath,
          fit: BoxFit.contain,
          errorBuilder: (_, error, stackTrace) {
            return Center(
              child: AppEmojiText(
                characterType == HomeCharacterType.tree ? "🌱" : "🐟",
                style: TextStyle(fontSize: fallbackFontSize),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SplitTreeAssetConfig {
  const _SplitTreeAssetConfig({
    required this.baseAssetPath,
    required this.leafAssetPath,
    required this.leafYOffsetFactor,
    required this.leafRotationAlignment,
    required this.leafScaleAlignment,
    required this.leafScaleCompensationFactor,
  });

  final String baseAssetPath;
  final String leafAssetPath;
  final double leafYOffsetFactor;
  final Alignment leafRotationAlignment;
  final Alignment leafScaleAlignment;
  final double leafScaleCompensationFactor;
}

double _homeFishVisualSizeForRecordCount(int recordCount, double baseSize) {
  final HomeFishGrowthLevel level = homeFishGrowthLevelForRecordCount(
    recordCount,
  );
  if (level == HomeFishGrowthLevel.level6) {
    return baseSize * 0.9;
  }
  return baseSize;
}

double _homeTreeSwayMaxAngleForLevel(HomeFishGrowthLevel level) {
  return switch (level) {
    HomeFishGrowthLevel.level1 => 0.095,
    HomeFishGrowthLevel.level2 => 0.082,
    HomeFishGrowthLevel.level3 => 0.05,
    HomeFishGrowthLevel.level4 => 0.04,
    HomeFishGrowthLevel.level5 => 0.034,
    HomeFishGrowthLevel.level6 => 0.018,
  };
}

bool _homeTreeUsesLeafPulse(HomeFishGrowthLevel level) {
  return switch (level) {
    HomeFishGrowthLevel.level4 || HomeFishGrowthLevel.level5 => true,
    _ => false,
  };
}

double _homeTreeLeafScaleForLevel(HomeFishGrowthLevel level, double swayValue) {
  final double normalizedPhase = (swayValue + 1) / 2;
  final double easedPhase = Curves.easeInOutCubic.transform(normalizedPhase);
  final double maxScale = switch (level) {
    HomeFishGrowthLevel.level4 => 1.012,
    HomeFishGrowthLevel.level5 => 1.01,
    HomeFishGrowthLevel.level6 => 1.008,
    _ => 1,
  };
  return 1 + ((maxScale - 1) * easedPhase);
}

class _QuestionBeforeRecordCard extends StatefulWidget {
  const _QuestionBeforeRecordCard({required this.recordCount});

  final int recordCount;

  @override
  State<_QuestionBeforeRecordCard> createState() =>
      _QuestionBeforeRecordCardState();
}

class _QuestionBeforeRecordCardState extends State<_QuestionBeforeRecordCard>
    with TickerProviderStateMixin {
  static const List<String> _messages = <String>[
    "오늘은 아직 답변하지 않았어요",
    "무엇이든 가볍게 적어보세요",
  ];
  int _messageIndex = 0;
  Timer? _messageTimer;
  late final AnimationController _fishController;
  late final AnimationController _bubbleController;
  late final Animation<double> _fishDy;
  late final Animation<double> _bubbleDy;
  late final Animation<double> _treeSway;

  @override
  void initState() {
    super.initState();
    TodayQuestionPromptStore.instance.initialize();
    _fishController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat(reverse: true);
    _bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2300),
    )..repeat(reverse: true);
    _fishDy = Tween<double>(begin: 2, end: -6).animate(
      CurvedAnimation(parent: _fishController, curve: Curves.easeInOut),
    );
    _bubbleDy = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(parent: _bubbleController, curve: Curves.easeInOutSine),
    );
    _treeSway = Tween<double>(begin: -1, end: 1).animate(
      CurvedAnimation(parent: _fishController, curve: Curves.easeInOutSine),
    );
    _messageTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      setState(() {
        _messageIndex = (_messageIndex + 1) % _messages.length;
      });
    });
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _fishController.dispose();
    _bubbleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    final HomeCharacterType characterType = resolveHomeCharacterType(brand);
    final int growthRecordCount = homeGrowthRecordCountForCharacter(
      characterType: characterType,
      totalRecordCount: widget.recordCount,
    );
    final HomeFishGrowthLevel growthLevel = homeFishGrowthLevelForRecordCount(
      growthRecordCount,
    );
    final bool isTreeCharacter = characterType == HomeCharacterType.tree;
    final bool useTreeLeafPulse =
        isTreeCharacter && _homeTreeUsesLeafPulse(growthLevel);
    final String characterAssetPath = HomeCharacterAssets.assetForRecordCount(
      characterType,
      growthRecordCount,
    );
    final double fishVisualSize = _homeFishVisualSizeForRecordCount(
      growthRecordCount,
      212,
    );
    return ValueListenableBuilder<TodayQuestionPromptState>(
      valueListenable: TodayQuestionPromptStore.instance,
      builder:
          (
            BuildContext context,
            TodayQuestionPromptState questionState,
            Widget? _,
          ) {
            final bool canUseQuestion = questionState.hasLoaded;
            final String questionText = canUseQuestion
                ? questionState.currentQuestionText
                : "";
            return Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s40,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 116),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: canUseQuestion
                          ? Text(
                              questionText,
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.headingLarge.copyWith(
                                color: AppNeutralColors.grey900,
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -20),
                  child: _QuestionWrittenSpeechBubble(
                    text: _messages[_messageIndex],
                    color: AppNeutralColors.white,
                    tailDirection: _SpeechTailDirection.down,
                  ),
                ),
                const SizedBox(height: AppSpacing.s24),
                SizedBox(
                  width: 150,
                  height: 150,
                  child: AnimatedBuilder(
                    animation: Listenable.merge(<Listenable>[
                      _fishController,
                      _bubbleController,
                    ]),
                    builder: (BuildContext context, Widget? child) {
                      final Widget characterImage = SizedBox(
                        width: 150,
                        height: 150,
                        child: OverflowBox(
                          maxWidth: fishVisualSize,
                          maxHeight: fishVisualSize,
                          child: _HomeHeroFishImage(
                            characterType: characterType,
                            growthLevel: growthLevel,
                            assetPath: characterAssetPath,
                            size: fishVisualSize,
                            fallbackFontSize: 72,
                            treeLeafAngle: isTreeCharacter && !useTreeLeafPulse
                                ? _treeSway.value *
                                      _homeTreeSwayMaxAngleForLevel(growthLevel)
                                : 0,
                            treeLeafScale: useTreeLeafPulse
                                ? _homeTreeLeafScaleForLevel(
                                    growthLevel,
                                    _treeSway.value,
                                  )
                                : 1,
                          ),
                        ),
                      );
                      if (isTreeCharacter) {
                        return characterImage;
                      }
                      return Stack(
                        clipBehavior: Clip.none,
                        children: <Widget>[
                          Positioned(
                            left: -2,
                            top: -4,
                            child: Transform.translate(
                              offset: Offset(0, _bubbleDy.value),
                              child: Opacity(
                                opacity: 0.92,
                                child: Image.asset(
                                  HomeScreen._decoBubbleAsset,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.contain,
                                  errorBuilder:
                                      (
                                        BuildContext context,
                                        Object error,
                                        StackTrace? stackTrace,
                                      ) => Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: const Color(0x9937B8FF),
                                          shape: BoxShape.circle,
                                          boxShadow: const <BoxShadow>[
                                            BoxShadow(
                                              color: Color(0x33017AF7),
                                              blurRadius: 8,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                      ),
                                ),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: Transform.translate(
                              offset: Offset(0, _fishDy.value),
                              child: characterImage,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.s24),
                const SizedBox(height: AppSpacing.s12),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: FilledButton(
                    onPressed: canUseQuestion
                        ? () => HomeScreen.openTodayQuestionAnswer(
                            context,
                            questionText: questionText,
                            questionSlot: 0,
                          )
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: brand.c500,
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      "기록하기",
                      style: AppTypography.buttonLarge.copyWith(
                        color: AppNeutralColors.white,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
    );
  }
}

class _QuestionWrittenPreviewCard extends StatefulWidget {
  const _QuestionWrittenPreviewCard();

  @override
  State<_QuestionWrittenPreviewCard> createState() =>
      _QuestionWrittenPreviewCardState();
}

class _QuestionWrittenPreviewCardState
    extends State<_QuestionWrittenPreviewCard> {
  static const double _cardHeight = 458;
  bool _showMoreMenu = false;
  bool _showAnswerScrollHint = false;
  int? _selectedMoreMenuIndex;
  String? _lastAnswerText;
  bool _pendingAnswerScrollSync = false;
  bool _pendingAnswerScrollReset = false;
  final ScrollController _answerScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _answerScrollController.addListener(_syncAnswerScrollHint);
  }

  @override
  void dispose() {
    _answerScrollController.removeListener(_syncAnswerScrollHint);
    _answerScrollController.dispose();
    super.dispose();
  }

  void _dismissMoreMenu() {
    if (!_showMoreMenu) {
      return;
    }
    setState(() {
      _showMoreMenu = false;
      _selectedMoreMenuIndex = null;
    });
  }

  void _toggleMoreMenu() {
    setState(() {
      _showMoreMenu = !_showMoreMenu;
      if (_showMoreMenu) {
        _selectedMoreMenuIndex = null;
      }
    });
  }

  void _scheduleAnswerScrollSync({bool resetToTop = false}) {
    _pendingAnswerScrollReset = _pendingAnswerScrollReset || resetToTop;
    if (_pendingAnswerScrollSync) {
      return;
    }
    _pendingAnswerScrollSync = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pendingAnswerScrollSync = false;
      final bool shouldReset = _pendingAnswerScrollReset;
      _pendingAnswerScrollReset = false;

      if (!mounted || !_answerScrollController.hasClients) {
        if (_showAnswerScrollHint) {
          setState(() {
            _showAnswerScrollHint = false;
          });
        }
        return;
      }

      final ScrollPosition position = _answerScrollController.position;
      if (shouldReset) {
        _answerScrollController.jumpTo(position.minScrollExtent);
      } else if (_answerScrollController.offset > position.maxScrollExtent) {
        _answerScrollController.jumpTo(position.maxScrollExtent);
      }
      _syncAnswerScrollHint();
    });
  }

  void _syncAnswerScrollHint() {
    if (!_answerScrollController.hasClients) {
      if (_showAnswerScrollHint && mounted) {
        setState(() {
          _showAnswerScrollHint = false;
        });
      }
      return;
    }

    final ScrollPosition position = _answerScrollController.position;
    final bool shouldShow =
        position.maxScrollExtent > 1 &&
        position.pixels < position.maxScrollExtent - 1;
    if (_showAnswerScrollHint == shouldShow || !mounted) {
      return;
    }
    setState(() {
      _showAnswerScrollHint = shouldShow;
    });
  }

  Future<void> _handleMoreMenuTap({
    required int index,
    required Future<void> Function() action,
  }) async {
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedMoreMenuIndex = index;
    });
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) {
      return;
    }
    await action();
  }

  Future<void> _openEditScreen(TodayQuestionRecord latest) async {
    _dismissMoreMenu();
    await Navigator.of(context).push<TodayQuestionRecord>(
      MaterialPageRoute<TodayQuestionRecord>(
        builder: (_) => TodayQuestionAnswerScreen(editingRecord: latest),
      ),
    );
  }

  Future<void> _deleteRecordWithPopup(TodayQuestionRecord latest) async {
    _dismissMoreMenu();
    final BrandScale brand = context.appBrandScale;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: AppPopupTokens.dimmed,
      builder: (BuildContext dialogContext) {
        return Center(
          child: AppPopup(
            width: AppPopupTokens.maxWidth,
            title: "질문과 내용 모두\n삭제하시겠습니까?",
            body: "삭제해도 질문에 대한 답변은\n언제든 다시 작성 할 수 있어요",
            actions: <Widget>[
              SizedBox(
                width: 100,
                height: 56,
                child: FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppNeutralColors.grey100,
                    foregroundColor: AppNeutralColors.grey600,
                    surfaceTintColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    overlayColor: Colors.transparent,
                    splashFactory: NoSplash.splashFactory,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.s8),
                    ),
                    textStyle: AppTypography.buttonLarge,
                    padding: EdgeInsets.zero,
                  ),
                  child: Text(
                    "취소",
                    style: AppTypography.buttonLarge.copyWith(
                      color: AppNeutralColors.grey600,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 170,
                height: 56,
                child: FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: brand.c500,
                    foregroundColor: AppNeutralColors.white,
                    surfaceTintColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    overlayColor: Colors.transparent,
                    splashFactory: NoSplash.splashFactory,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.s8),
                    ),
                    textStyle: AppTypography.buttonLarge,
                    padding: EdgeInsets.zero,
                  ),
                  child: Text(
                    "삭제하기",
                    style: AppTypography.buttonLarge.copyWith(
                      color: AppNeutralColors.white,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
    if (!mounted || confirmed != true) {
      return;
    }
    final bool removed = await TodayQuestionStore.instance.deleteRecord(
      createdAt: latest.createdAt,
    );
    if (!mounted || !removed) {
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
      (Route<dynamic> route) => false,
    );
  }

  void _showHistoryDisabledToast() {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Center(child: AppToastMessage(text: "앗, 이 질문은 아직 쌓이지 않았어요")),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
          backgroundColor: Colors.transparent,
          elevation: 0,
          padding: EdgeInsets.zero,
          margin: EdgeInsets.fromLTRB(50, 0, 50, 98),
        ),
      );
  }

  List<AnnualRecordEntry> _buildAnnualEntries({
    required DateTime baseDate,
    required TodayQuestionRecord? latest,
  }) {
    final Map<int, AnnualRecordEntry> byYear = <int, AnnualRecordEntry>{};

    if (latest != null) {
      final String currentDateLabel =
          "${baseDate.year.toString().padLeft(4, "0")}."
          "${baseDate.month.toString().padLeft(2, "0")}."
          "${baseDate.day.toString().padLeft(2, "0")} 기록";
      byYear[baseDate.year] = AnnualRecordEntry(
        year: baseDate.year,
        answer: latest.answer,
        dateLabel: currentDateLabel,
      );
    }

    final List<TodayQuestionRecord> sameDay = TodayQuestionStore.instance.value
        .where(
          (TodayQuestionRecord record) =>
              record.createdAt.month == baseDate.month &&
              record.createdAt.day == baseDate.day &&
              record.createdAt.year <= baseDate.year,
        )
        .toList(growable: false);
    final List<TodayQuestionRecord> mergedSameDay = <TodayQuestionRecord>[
      ...sameDay,
      ...MyRecordsScreen.debugAnnualMockRecords(baseDate: baseDate),
    ];
    for (final TodayQuestionRecord record in mergedSameDay) {
      byYear.putIfAbsent(record.createdAt.year, () {
        final String dateLabel =
            "${record.createdAt.year.toString().padLeft(4, "0")}."
            "${record.createdAt.month.toString().padLeft(2, "0")}."
            "${record.createdAt.day.toString().padLeft(2, "0")} 기록";
        return AnnualRecordEntry(
          year: record.createdAt.year,
          answer: record.answer,
          dateLabel: dateLabel,
        );
      });
    }

    final List<int> years = byYear.keys.toList()
      ..sort((int a, int b) => b.compareTo(a));
    return years.map((int year) => byYear[year]!).toList(growable: false);
  }

  Future<void> _openQuestionHistory({
    required List<AnnualRecordEntry> entries,
    required String questionText,
  }) async {
    if (!mounted || entries.isEmpty) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AnnualRecordScreen(
          question: questionText,
          entries: entries,
          continuousYears: entries.length,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    final TodayQuestionRecord? latest =
        TodayQuestionStore.instance.latestRecordForTodayKst;
    final DateTime now = nowInKst();
    final DateTime displayDate = _displayDateForRecord(latest) ?? now;
    final List<String> weekdays = <String>[
      "월요일",
      "화요일",
      "수요일",
      "목요일",
      "금요일",
      "토요일",
      "일요일",
    ];
    final String currentDate =
        "${displayDate.day}일 ${weekdays[displayDate.weekday - 1]}";
    final DateTime baseDate = DateTime(
      displayDate.year,
      displayDate.month,
      displayDate.day,
      12,
    );
    final List<AnnualRecordEntry> annualEntries = _buildAnnualEntries(
      baseDate: baseDate,
      latest: latest,
    );
    final bool hasPastYearRecord = annualEntries.any(
      (AnnualRecordEntry entry) => entry.year < baseDate.year,
    );
    final String answerText =
        latest?.answer ??
        "올해는 꼭 제주도 한라산에 올라가 백록담을 직접 보고 싶어. "
            "예전부터 사진으로만 보던 그 푸른 호수를 실제로 내 눈으로 담아보고 싶다는 마음이 있었거든요...";
    final bool shouldResetAnswerScroll = _lastAnswerText != answerText;
    _lastAnswerText = answerText;
    _scheduleAnswerScrollSync(resetToTop: shouldResetAnswerScroll);
    final String questionText =
        (latest?.questionText?.trim().isNotEmpty ?? false)
        ? latest!.questionText!.trim()
        : TodayQuestionPromptStore.instance.value.currentQuestionText;
    final List<String> bucketTags = latest == null
        ? const <String>[]
        : latest.bucketTags.isNotEmpty
        ? latest.bucketTags
        : (latest.bucketTag == null || latest.bucketTag!.trim().isEmpty)
        ? const <String>[]
        : <String>[latest.bucketTag!.trim()];
    final List<String> visibleBucketTags = latest == null
        ? const <String>[]
        : bucketTags;

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: latest == null || _showMoreMenu
                ? null
                : () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => MyRecordDetailScreen(record: latest),
                      ),
                    );
                  },
            borderRadius: AppRadius.br24,
            child: SizedBox(
              width: double.infinity,
              height: _cardHeight,
              child: ClipRRect(
                borderRadius: AppRadius.br24,
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 26, sigmaY: 26),
                  child: DecoratedBox(
                    decoration: _buildCardDecoration(brand),
                    child: Stack(
                      children: <Widget>[
                        Positioned(
                          left: 0,
                          top: 0,
                          right: 0,
                          height: 112,
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: _buildCardHighlightDecoration(brand),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 32,
                          ),
                          child: Column(
                            children: <Widget>[
                              SizedBox(
                                width: 286,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.s4,
                                  ),
                                  child: Row(
                                    children: <Widget>[
                                      IconButton(
                                        onPressed: () {
                                          if (!hasPastYearRecord) {
                                            _showHistoryDisabledToast();
                                            return;
                                          }
                                          _openQuestionHistory(
                                            entries: annualEntries,
                                            questionText: questionText,
                                          );
                                        },
                                        padding: EdgeInsets.zero,
                                        constraints:
                                            const BoxConstraints.tightFor(
                                              width: 24,
                                              height: 24,
                                            ),
                                        visualDensity: VisualDensity.compact,
                                        icon: Icon(
                                          Icons.history,
                                          size: AppSpacing.s24,
                                          color: hasPastYearRecord
                                              ? brand.c500
                                              : AppNeutralColors.grey300,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          currentDate,
                                          textAlign: TextAlign.center,
                                          style: AppTypography
                                              .bodyMediumSemiBold
                                              .copyWith(color: brand.c500),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: IconButton(
                                          onPressed: latest == null
                                              ? null
                                              : _toggleMoreMenu,
                                          padding: EdgeInsets.zero,
                                          constraints:
                                              const BoxConstraints.tightFor(
                                                width: 24,
                                                height: 24,
                                              ),
                                          icon: const Icon(
                                            Icons.more_horiz,
                                            size: AppSpacing.s24,
                                            color: AppNeutralColors.grey300,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.s16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.s16,
                                ),
                                decoration: const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: AppNeutralColors.grey50,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  questionText,
                                  textAlign: TextAlign.center,
                                  style: AppTypography.headingMediumExtraBold
                                      .copyWith(
                                        color: AppNeutralColors.grey900,
                                      ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.s16),
                              Expanded(
                                child: Stack(
                                  children: <Widget>[
                                    Positioned.fill(
                                      child: SingleChildScrollView(
                                        controller: _answerScrollController,
                                        physics: const BouncingScrollPhysics(),
                                        child: Align(
                                          alignment: Alignment.topLeft,
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              right: AppSpacing.s4,
                                              bottom: AppSpacing.s28,
                                            ),
                                            child: Text(
                                              answerText,
                                              textAlign: TextAlign.left,
                                              style: AppTypography
                                                  .bodyLargeRegular
                                                  .copyWith(
                                                    color: AppNeutralColors
                                                        .grey800,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (_showAnswerScrollHint)
                                      Positioned(
                                        left: 0,
                                        right: 0,
                                        bottom: 0,
                                        height: 48,
                                        child: IgnorePointer(
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: _answerScrollFadeColors(
                                                  brand,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (visibleBucketTags.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.s16,
                                  ),
                                  child: SizedBox(
                                    width: double.infinity,
                                    height: 38,
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: visibleBucketTags
                                            .map(
                                              (String tag) => Padding(
                                                padding: const EdgeInsets.only(
                                                  right: AppSpacing.s6,
                                                ),
                                                child: Container(
                                                  height: 38,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal:
                                                            AppSpacing.s16,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: brand.c100,
                                                    borderRadius:
                                                        AppRadius.pill,
                                                    border: Border.all(
                                                      color: brand.c200,
                                                    ),
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                    "#$tag",
                                                    style: AppTypography
                                                        .buttonSmall
                                                        .copyWith(
                                                          color: brand.c500,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            )
                                            .toList(growable: false),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_showMoreMenu)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _dismissMoreMenu,
              child: const SizedBox.expand(),
            ),
          ),
        if (_showMoreMenu && latest != null)
          Positioned(
            top: 52,
            right: 20,
            child: AppDropdownMenu(
              size: AppDropdownMenuSize.lg,
              items: <AppDropdownItem>[
                AppDropdownItem(
                  label: "수정",
                  state: _selectedMoreMenuIndex == 0
                      ? AppDropdownItemState.selected
                      : AppDropdownItemState.defaultState,
                  onTap: () => _handleMoreMenuTap(
                    index: 0,
                    action: () => _openEditScreen(latest),
                  ),
                ),
                AppDropdownItem(
                  label: "삭제",
                  state: _selectedMoreMenuIndex == 1
                      ? AppDropdownItemState.selected
                      : AppDropdownItemState.defaultState,
                  onTap: () => _handleMoreMenuTap(
                    index: 1,
                    action: () => _deleteRecordWithPopup(latest),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  DateTime? _displayDateForRecord(TodayQuestionRecord? record) {
    if (record == null) {
      return null;
    }
    final String? key = record.questionDateKey?.trim();
    if (key != null && key.length == 8) {
      final int? year = int.tryParse(key.substring(0, 4));
      final int? month = int.tryParse(key.substring(4, 6));
      final int? day = int.tryParse(key.substring(6, 8));
      if (year != null && month != null && day != null) {
        return DateTime(year, month, day);
      }
    }
    return toKst(record.createdAt);
  }

  BoxDecoration _buildCardDecoration(BrandScale brand) {
    return BoxDecoration(
      borderRadius: AppRadius.br24,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          brand.c50.withValues(alpha: 0.68),
          AppNeutralColors.white.withValues(alpha: 0.42),
          brand.c100.withValues(alpha: 0.58),
        ],
        stops: const <double>[0, 0.44, 1],
      ),
      border: Border.all(color: brand.c50.withValues(alpha: 0.88), width: 1),
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: brand.c300.withValues(alpha: 0.16),
          offset: const Offset(0, 6),
          blurRadius: 14,
          spreadRadius: -6,
        ),
      ],
    );
  }

  BoxDecoration _buildCardHighlightDecoration(BrandScale brand) {
    return BoxDecoration(
      borderRadius: AppRadius.br24,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          AppNeutralColors.white.withValues(alpha: 0.18),
          brand.c50.withValues(alpha: 0.14),
          brand.c100.withValues(alpha: 0.06),
          Colors.transparent,
        ],
        stops: const <double>[0, 0.24, 0.58, 1],
      ),
    );
  }

  List<Color> _answerScrollFadeColors(BrandScale brand) {
    return <Color>[
      brand.c50.withValues(alpha: 0),
      brand.c50.withValues(alpha: 0.28),
      brand.c100.withValues(alpha: 0.64),
    ];
  }
}

class _QuestionWrittenSpeechBubble extends StatelessWidget {
  const _QuestionWrittenSpeechBubble({
    required this.text,
    required this.color,
    this.tailDirection = _SpeechTailDirection.right,
  });

  final String text;
  final Color color;
  final _SpeechTailDirection tailDirection;

  @override
  Widget build(BuildContext context) {
    if (tailDirection == _SpeechTailDirection.down) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.all(
                Radius.circular(AppSpacing.s12 + AppSpacing.s2),
              ),
              boxShadow: AppElevation.level1,
            ),
            child: Text(
              text,
              style: AppTypography.bodySmallMedium.copyWith(
                color: color == AppNeutralColors.white
                    ? AppNeutralColors.grey700
                    : AppNeutralColors.white,
              ),
            ),
          ),
          CustomPaint(
            size: const Size(10, 6),
            painter: _SpeechDownTailPainter(color),
          ),
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.all(
              Radius.circular(AppSpacing.s12 + AppSpacing.s2),
            ),
            boxShadow: AppElevation.level1,
          ),
          child: Text(
            text,
            style: AppTypography.bodySmallMedium.copyWith(
              color: color == AppNeutralColors.white
                  ? AppNeutralColors.grey700
                  : AppNeutralColors.white,
            ),
          ),
        ),
        CustomPaint(
          size: const Size(6, 10),
          painter: _SpeechRightTailPainter(color),
        ),
      ],
    );
  }
}

class _SpeechDownTailPainter extends CustomPainter {
  _SpeechDownTailPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = color;
    final Path path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TopCharacterDecorations extends StatefulWidget {
  const _TopCharacterDecorations({
    required this.bubbleColor,
    required this.recordCount,
  });

  final Color bubbleColor;
  final int recordCount;

  @override
  State<_TopCharacterDecorations> createState() =>
      _TopCharacterDecorationsState();
}

class _TopCharacterDecorationsState extends State<_TopCharacterDecorations>
    with TickerProviderStateMixin {
  static const List<String> _messages = <String>[
    "오늘의 답변을 작성했어요!",
    "소중한 하루가 쌓였어요!",
    "꾸준한 당신을 칭찬해요!",
  ];
  static const double _fishFrameSize = 128;
  static const double _baseFishVisualSize = 172;
  static const double _treeDecorHeight = 110;

  late final AnimationController _fishController;
  late final Animation<double> _fishDy;
  late final Animation<double> _treeSway;
  Timer? _messageTimer;
  int _messageIndex = 0;

  @override
  void initState() {
    super.initState();
    _fishController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat(reverse: true);
    _fishDy = Tween<double>(begin: 2, end: -6).animate(
      CurvedAnimation(parent: _fishController, curve: Curves.easeInOut),
    );
    _treeSway = Tween<double>(begin: -1, end: 1).animate(
      CurvedAnimation(parent: _fishController, curve: Curves.easeInOutSine),
    );
    _messageTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _messageIndex = (_messageIndex + 1) % _messages.length;
      });
    });
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _fishController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final HomeCharacterType characterType = resolveHomeCharacterType(
      context.appBrandScale,
    );
    final int growthRecordCount = homeGrowthRecordCountForCharacter(
      characterType: characterType,
      totalRecordCount: widget.recordCount,
    );
    final HomeFishGrowthLevel growthLevel = homeFishGrowthLevelForRecordCount(
      growthRecordCount,
    );
    final bool isTreeCharacter = characterType == HomeCharacterType.tree;
    final bool useTreeLeafPulse =
        isTreeCharacter && _homeTreeUsesLeafPulse(growthLevel);
    final String characterAssetPath = HomeCharacterAssets.assetForRecordCount(
      characterType,
      growthRecordCount,
    );
    final double fishVisualSize = _homeFishVisualSizeForRecordCount(
      growthRecordCount,
      _baseFishVisualSize,
    );
    final double decorHeight = isTreeCharacter ? _treeDecorHeight : 152;
    return SizedBox(
      width: 350,
      height: decorHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          if (!isTreeCharacter)
            Positioned(
              left: 0,
              bottom: 0,
              child: Image.asset(
                HomeScreen._decoSeaweedAsset,
                width: 80,
                height: 120,
                fit: BoxFit.contain,
                errorBuilder: (_, error, stackTrace) => const SizedBox.shrink(),
              ),
            ),
          if (!isTreeCharacter)
            Positioned(
              left: 40,
              top: 70,
              child: Transform.rotate(
                angle: 4.43 * 3.141592653589793 / 180,
                child: Image.asset(
                  HomeScreen._decoCrabAsset,
                  width: 70,
                  height: 70,
                  fit: BoxFit.contain,
                  errorBuilder: (_, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              ),
            ),
          Positioned(
            left: isTreeCharacter ? 18 : null,
            right: isTreeCharacter ? null : 108,
            top: isTreeCharacter ? 58 : 26,
            child: _QuestionWrittenSpeechBubble(
              text: _messages[_messageIndex],
              color: widget.bubbleColor,
            ),
          ),
          Positioned(
            left: isTreeCharacter ? null : 236,
            right: isTreeCharacter ? 0 : null,
            top: isTreeCharacter ? 0 : 2,
            child: AnimatedBuilder(
              animation: _fishController,
              builder: (BuildContext context, Widget? child) {
                final Widget characterImage = SizedBox(
                  width: _fishFrameSize,
                  height: _fishFrameSize,
                  child: OverflowBox(
                    maxWidth: fishVisualSize,
                    maxHeight: fishVisualSize,
                    child: _HomeHeroFishImage(
                      characterType: characterType,
                      growthLevel: growthLevel,
                      assetPath: characterAssetPath,
                      size: fishVisualSize,
                      fallbackFontSize: 48,
                      treeLeafAngle: isTreeCharacter && !useTreeLeafPulse
                          ? _treeSway.value *
                                _homeTreeSwayMaxAngleForLevel(growthLevel)
                          : 0,
                      treeLeafScale: useTreeLeafPulse
                          ? _homeTreeLeafScaleForLevel(
                              growthLevel,
                              _treeSway.value,
                            )
                          : 1,
                    ),
                  ),
                );
                if (isTreeCharacter) {
                  return characterImage;
                }
                return Transform.translate(
                  offset: Offset(0, _fishDy.value),
                  child: characterImage,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeechRightTailPainter extends CustomPainter {
  _SpeechRightTailPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = color;
    final Path path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RecordStreakSection extends StatelessWidget {
  const _RecordStreakSection();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<TodayQuestionRecord>>(
      valueListenable: TodayQuestionStore.instance,
      builder: (BuildContext context, List<TodayQuestionRecord> records, _) {
        final int streak = TodayQuestionStore.instance.consecutiveRecordDays;
        if (streak < 2) {
          return const SizedBox.shrink();
        }
        return const Column(
          children: <Widget>[
            _RecordStreakBar(),
            SizedBox(height: AppSpacing.s32),
          ],
        );
      },
    );
  }
}

class _RecordStreakBar extends StatelessWidget {
  const _RecordStreakBar();

  @override
  Widget build(BuildContext context) {
    final int streak = TodayQuestionStore.instance.consecutiveRecordDays;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: AppNeutralColors.white,
        borderRadius: AppRadius.br16,
        boxShadow: AppElevation.level1,
      ),
      child: Column(
        children: <Widget>[
          AppEmojiText(
            "🔥연속 $streak일째 기록 중",
            textAlign: TextAlign.center,
            style: AppTypography.bodySmallSemiBold.copyWith(
              color: AppNeutralColors.grey900,
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayRecordSection extends StatefulWidget {
  const _TodayRecordSection();

  @override
  State<_TodayRecordSection> createState() => _TodayRecordSectionState();
}

class _TodayRecordSectionState extends State<_TodayRecordSection>
    with WidgetsBindingObserver {
  static const double _recordCardWidth = 350;
  static const double _recordCardGap = 12;
  static const String _hiddenRecordsPrefsKey =
      "today_records_hidden_record_ids";
  static const String _blockedAuthorsPrefsKey = "today_records_blocked_authors";
  static const String _likedRecordIdsPrefsKey =
      "today_records_liked_record_ids";
  static const double _recordCardHeight = 154;
  String _todayKey = kstDateKeyNow();
  Set<String> _likedRecordIds = <String>{};
  Set<String> _togglingLikeRecordIds = <String>{};
  Map<String, int> _likeCountOverrides = <String, int>{};

  Timer? _dateRefreshTimer;
  PageController? _pageController;
  double? _lastViewportFraction;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleDateRefreshTimer();
    unawaited(_loadLikedRecordIds());
  }

  void _scheduleDateRefreshTimer() {
    _dateRefreshTimer?.cancel();
    _dateRefreshTimer = Timer(durationUntilNextKstDateChange(), () {
      if (!mounted) {
        return;
      }
      _refreshTodayKeyByDateChange();
      _scheduleDateRefreshTimer();
    });
  }

  void _refreshTodayKeyByDateChange() {
    final String currentKey = kstDateKeyNow();
    if (currentKey == _todayKey) {
      return;
    }
    setState(() {
      _todayKey = currentKey;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshTodayKeyByDateChange();
      _scheduleDateRefreshTimer();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dateRefreshTimer?.cancel();
    _pageController?.dispose();
    super.dispose();
  }

  PageController _resolveController(double viewportFraction) {
    final bool shouldRecreate =
        _pageController == null || _lastViewportFraction != viewportFraction;
    if (!shouldRecreate) {
      return _pageController!;
    }
    final int initialPage = _pageController?.hasClients == true
        ? (_pageController!.page?.round() ?? _pageController!.initialPage)
        : (_pageController?.initialPage ?? 0);
    _pageController?.dispose();
    _pageController = PageController(
      initialPage: initialPage,
      viewportFraction: viewportFraction,
    );
    _lastViewportFraction = viewportFraction;
    return _pageController!;
  }

  Future<List<PublicTodayRecord>> _loadVisiblePublicRecords() async {
    final List<PublicTodayRecord> fetchedRecords =
        await PublicTodayRecordsRepository.instance.fetchByDateKey(_todayKey);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final Set<String> hiddenRecordIds =
        (prefs.getStringList(_hiddenRecordsPrefsKey) ?? const <String>[])
            .toSet();
    final Set<String> blockedAuthors =
        (prefs.getStringList(_blockedAuthorsPrefsKey) ?? const <String>[])
            .toSet();

    return fetchedRecords
        .where((PublicTodayRecord item) {
          if (hiddenRecordIds.contains(_recordKey(item))) {
            return false;
          }
          if (blockedAuthors.contains(item.author)) {
            return false;
          }
          return true;
        })
        .toList(growable: false);
  }

  String _recordKey(PublicTodayRecord item) {
    return "${item.createdAt.millisecondsSinceEpoch}|${item.author}|${item.body}";
  }

  String _likeTargetId(PublicTodayRecord item) {
    if (item.canToggleLike) {
      return "${item.questionDateKey}/slot_${item.questionSlot}/${item.answerDocId}";
    }
    return _recordKey(item);
  }

  Future<void> _loadLikedRecordIds() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> saved =
        prefs.getStringList(_likedRecordIdsPrefsKey) ?? const <String>[];
    if (!mounted) {
      return;
    }
    setState(() {
      _likedRecordIds = saved.toSet();
    });
  }

  Future<void> _persistLikedRecordIds() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _likedRecordIdsPrefsKey,
      _likedRecordIds.toList(growable: false),
    );
  }

  Future<void> _toggleRecordLike(PublicTodayRecord record) async {
    if (!record.canToggleLike) {
      return;
    }
    final String likeTargetId = _likeTargetId(record);
    if (_togglingLikeRecordIds.contains(likeTargetId)) {
      return;
    }

    final bool wasLiked = _likedRecordIds.contains(likeTargetId);
    final int currentCount =
        _likeCountOverrides[likeTargetId] ?? record.likeCount;
    final bool nextLiked = !wasLiked;
    final int nextCount = nextLiked
        ? currentCount + 1
        : (currentCount > 0 ? currentCount - 1 : 0);
    final Set<String> previousLikedRecordIds = <String>{..._likedRecordIds};
    final Map<String, int> previousLikeCountOverrides = <String, int>{
      ..._likeCountOverrides,
    };

    setState(() {
      _togglingLikeRecordIds = <String>{
        ..._togglingLikeRecordIds,
        likeTargetId,
      };
      _likedRecordIds = <String>{..._likedRecordIds};
      if (nextLiked) {
        _likedRecordIds.add(likeTargetId);
      } else {
        _likedRecordIds.remove(likeTargetId);
      }
      _likeCountOverrides = <String, int>{
        ..._likeCountOverrides,
        likeTargetId: nextCount,
      };
    });

    try {
      final PublicRecordLikeResult result = await PublicTodayRecordsRepository
          .instance
          .toggleLike(record);
      if (!mounted) {
        return;
      }
      setState(() {
        _likedRecordIds = <String>{..._likedRecordIds};
        if (result.liked) {
          _likedRecordIds.add(likeTargetId);
        } else {
          _likedRecordIds.remove(likeTargetId);
        }
        _likeCountOverrides = <String, int>{
          ..._likeCountOverrides,
          likeTargetId: result.likeCount,
        };
        _togglingLikeRecordIds = <String>{..._togglingLikeRecordIds}
          ..remove(likeTargetId);
      });
      await _persistLikedRecordIds();
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _likedRecordIds = previousLikedRecordIds;
        _likeCountOverrides = previousLikeCountOverrides;
        _togglingLikeRecordIds = <String>{..._togglingLikeRecordIds}
          ..remove(likeTargetId);
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
              "좋아요를 반영하지 못했어요. 잠시 후 다시 시도해주세요.",
              style: AppTypography.captionMedium.copyWith(
                color: AppNeutralColors.white,
              ),
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<TodayQuestionRecord>>(
      valueListenable: TodayQuestionStore.instance,
      builder: (BuildContext context, List<TodayQuestionRecord> allRecords, Widget? child) {
        final int totalRecordCount = allRecords.length;
        return FutureBuilder<List<PublicTodayRecord>>(
          future: _loadVisiblePublicRecords(),
          builder:
              (
                BuildContext context,
                AsyncSnapshot<List<PublicTodayRecord>> snapshot,
              ) {
                final List<PublicTodayRecord> fetchedRecords =
                    snapshot.data ?? const <PublicTodayRecord>[];
                final String questionText =
                    TodayQuestionPromptStore.instance.value.currentQuestionText;
                final List<PublicTodayRecord> records = fetchedRecords
                    .take(5)
                    .toList(growable: false);
                final bool hasRecords = records.isNotEmpty;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    InkWell(
                      onTap: hasRecords
                          ? () async {
                              await HomeScreen.openTodayRecords(
                                context,
                                questionDateKey: _todayKey,
                                questionText: questionText,
                                initialRecords: fetchedRecords,
                              );
                              if (!mounted) {
                                return;
                              }
                              setState(() {});
                            }
                          : null,
                      borderRadius: BorderRadius.circular(8),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              "타인의 기록",
                              style: AppTypography.headingSmall.copyWith(
                                color: AppNeutralColors.grey900,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            size: 24,
                            color: AppNeutralColors.grey900,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (hasRecords)
                      LayoutBuilder(
                        builder: (BuildContext context, BoxConstraints constraints) {
                          final double listWidth = constraints.maxWidth;
                          final double viewportFraction =
                              ((_recordCardWidth + _recordCardGap) / listWidth)
                                  .clamp(0.0, 1.0);
                          final PageController controller = _resolveController(
                            viewportFraction,
                          );
                          return SizedBox(
                            height: _recordCardHeight + 6,
                            child: SizedBox(
                              width: listWidth,
                              child: SizedBox(
                                width: listWidth,
                                child: ScrollConfiguration(
                                  behavior: const MaterialScrollBehavior()
                                      .copyWith(
                                        dragDevices: <PointerDeviceKind>{
                                          PointerDeviceKind.touch,
                                          PointerDeviceKind.mouse,
                                          PointerDeviceKind.trackpad,
                                          PointerDeviceKind.stylus,
                                          PointerDeviceKind.invertedStylus,
                                        },
                                      ),
                                  child: PageView.builder(
                                    controller: controller,
                                    scrollDirection: Axis.horizontal,
                                    physics: const ClampingScrollPhysics(),
                                    clipBehavior: Clip.none,
                                    padEnds: true,
                                    itemCount: records.length,
                                    itemBuilder:
                                        (
                                          BuildContext context,
                                          int index,
                                        ) => Padding(
                                          padding: EdgeInsets.only(
                                            top: 3,
                                            bottom: 3,
                                            right: index == records.length - 1
                                                ? 0
                                                : _recordCardGap,
                                          ),
                                          child: _TodayRecordCard(
                                            key: ValueKey<String>(
                                              _likeTargetId(records[index]),
                                            ),
                                            record: records[index],
                                            isLiked: _likedRecordIds.contains(
                                              _likeTargetId(records[index]),
                                            ),
                                            likeCount:
                                                _likeCountOverrides[_likeTargetId(
                                                  records[index],
                                                )] ??
                                                records[index].likeCount,
                                            width: _recordCardWidth,
                                            onLikeTap: () => _toggleRecordLike(
                                              records[index],
                                            ),
                                            onTap: () async {
                                              final PublicRecordDetailResult?
                                              result =
                                                  await HomeScreen.openPublicRecordDetail(
                                                    context,
                                                    record: records[index],
                                                    questionDateKey: _todayKey,
                                                    questionText: questionText,
                                                  );
                                              if (!mounted || result == null) {
                                                return;
                                              }
                                              setState(() {});
                                            },
                                          ),
                                        ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    else
                      _TodayRecordEmptyCard(
                        recordCount: totalRecordCount,
                        onTap: () =>
                            HomeScreen.openTodayQuestionAnswer(context),
                      ),
                  ],
                );
              },
        );
      },
    );
  }
}

class _TodayRecordEmptyCard extends StatelessWidget {
  const _TodayRecordEmptyCard({required this.recordCount, required this.onTap});

  final int recordCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    final HomeCharacterType characterType = resolveHomeCharacterType(brand);
    final int growthRecordCount = homeGrowthRecordCountForCharacter(
      characterType: characterType,
      totalRecordCount: recordCount,
    );
    final String characterAssetPath = HomeCharacterAssets.assetForRecordCount(
      characterType,
      growthRecordCount,
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          height: 160,
          decoration: BoxDecoration(
            color: AppNeutralColors.white,
            borderRadius: AppRadius.br16,
            boxShadow: AppElevation.level1,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image.asset(
                characterAssetPath,
                width: 64,
                height: 64,
                fit: BoxFit.contain,
                errorBuilder: (_, error, stackTrace) {
                  return AppEmojiText(
                    characterType == HomeCharacterType.tree ? "🌳" : "🐟",
                    style: TextStyle(fontSize: 32),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.s8),
              Text(
                "오늘 첫 번째로 기록해보실래요?",
                style: AppTypography.bodySmallSemiBold.copyWith(
                  color: brand.c500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayRecordCard extends StatefulWidget {
  const _TodayRecordCard({
    super.key,
    required this.record,
    required this.isLiked,
    required this.likeCount,
    required this.width,
    required this.onLikeTap,
    required this.onTap,
  });

  final PublicTodayRecord record;
  final bool isLiked;
  final int likeCount;
  final double width;
  final Future<void> Function() onLikeTap;
  final Future<void> Function() onTap;

  @override
  State<_TodayRecordCard> createState() => _TodayRecordCardState();
}

class _TodayRecordCardState extends State<_TodayRecordCard> {
  int _burstKey = 0;
  late bool _displayIsLiked;
  late int _displayLikeCount;
  bool _isTogglingLike = false;

  @override
  void initState() {
    super.initState();
    _displayIsLiked = widget.isLiked;
    _displayLikeCount = widget.likeCount;
  }

  @override
  void didUpdateWidget(covariant _TodayRecordCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool recordChanged =
        oldWidget.record.answerDocId != widget.record.answerDocId ||
        oldWidget.record.questionDateKey != widget.record.questionDateKey ||
        oldWidget.record.questionSlot != widget.record.questionSlot;
    if (recordChanged || !_isTogglingLike) {
      _displayIsLiked = widget.isLiked;
      _displayLikeCount = widget.likeCount;
    }
  }

  Future<void> _handleLikeTap() async {
    if (_isTogglingLike || !widget.record.canToggleLike) {
      return;
    }
    final bool nextLiked = !_displayIsLiked;
    final int nextCount = nextLiked
        ? _displayLikeCount + 1
        : (_displayLikeCount > 0 ? _displayLikeCount - 1 : 0);
    if (nextLiked) {
      setState(() {
        _burstKey += 1;
      });
    }
    setState(() {
      _isTogglingLike = true;
      _displayIsLiked = nextLiked;
      _displayLikeCount = nextCount;
    });
    try {
      await widget.onLikeTap();
    } finally {
      if (mounted) {
        setState(() {
          _isTogglingLike = false;
          _displayIsLiked = widget.isLiked;
          _displayLikeCount = widget.likeCount;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    final String previewText = _toPreviewText(widget.record.body);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: AppRadius.br16,
        child: Container(
          width: widget.width,
          height: _TodayRecordSectionState._recordCardHeight,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppNeutralColors.white,
            borderRadius: AppRadius.br16,
            boxShadow: AppElevation.level1,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Text(
                  previewText,
                  style: AppTypography.bodyMediumMedium.copyWith(
                    color: AppNeutralColors.grey900,
                  ),
                  textHeightBehavior: const TextHeightBehavior(
                    applyHeightToFirstAscent: false,
                    applyHeightToLastDescent: false,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 3,
                ),
              ),
              const SizedBox(height: AppSpacing.s12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _handleLikeTap,
                        child: SizedBox(
                          height: 24,
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.centerLeft,
                            children: <Widget>[
                              if (_burstKey > 0)
                                Positioned(
                                  left: -3,
                                  top: -13,
                                  child: _HomeRecordLikeBurst(
                                    key: ValueKey<int>(_burstKey),
                                    color: brand.c500,
                                  ),
                                ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
                                  AppLikeIcon(
                                    selected: _displayIsLiked,
                                    size: AppIconSize.s20,
                                    color: _displayIsLiked
                                        ? brand.c500
                                        : brand.c300,
                                  ),
                                  const SizedBox(width: AppSpacing.s2),
                                  Text(
                                    "$_displayLikeCount",
                                    style: AppTypography.captionMedium.copyWith(
                                      color: brand.c500,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Flexible(
                    child: Text(
                      widget.record.author,
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: AppTypography.bodyMediumSemiBold.copyWith(
                        color: brand.c500,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _toPreviewText(String raw) {
    return raw.replaceAll("\n", " ");
  }
}

class _HomeRecordLikeBurst extends StatefulWidget {
  const _HomeRecordLikeBurst({super.key, required this.color});

  final Color color;

  @override
  State<_HomeRecordLikeBurst> createState() => _HomeRecordLikeBurstState();
}

class _HomeRecordLikeBurstState extends State<_HomeRecordLikeBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: 38,
        height: 38,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (BuildContext context, Widget? child) {
            final double progress = Curves.easeOutCubic.transform(
              _controller.value,
            );
            final double opacity = (1 - progress).clamp(0, 1);
            return Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                _HomeRecordBurstHeart(
                  color: widget.color,
                  opacity: opacity * 0.82,
                  size: 8,
                  offset: Offset(15 - (progress * 7), 18 - (progress * 21)),
                  rotation: -0.2,
                ),
                _HomeRecordBurstHeart(
                  color: widget.color,
                  opacity: opacity * 0.72,
                  size: 7,
                  offset: Offset(19 + (progress * 9), 20 - (progress * 18)),
                  rotation: 0.18,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HomeRecordBurstHeart extends StatelessWidget {
  const _HomeRecordBurstHeart({
    required this.color,
    required this.opacity,
    required this.size,
    required this.offset,
    required this.rotation,
  });

  final Color color;
  final double opacity;
  final double size;
  final Offset offset;
  final double rotation;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: offset.dx,
      top: offset.dy,
      child: Opacity(
        opacity: opacity,
        child: Transform.rotate(
          angle: rotation,
          child: AppLikeIcon(selected: true, size: size, color: color),
        ),
      ),
    );
  }
}

class _TodayMeSection extends StatefulWidget {
  const _TodayMeSection();

  static const List<String> _moodOptions = <String>[
    "매우 좋아요 ✨",
    "좋아요 ⭐",
    "보통이에요 〰️",
    "나빠요 🌧️",
    "매우 나빠요 ⚡",
  ];
  static const List<String> _energyOptions = <String>[
    "에너지가 넘쳐요 ⚡",
    "꽤 괜찮아요 ☀️",
    "평소와 같아요 〰️",
    "조금 지쳤어요 🌙",
    "방전 직전이에요 🪫",
  ];
  static const List<String> _stressOptions = <String>[
    "편안해요 🌿",
    "가벼운 편이에요 🍃",
    "보통이에요 〰️",
    "조금 있어요 🌫️",
    "한계에요 🌪️",
  ];

  @override
  State<_TodayMeSection> createState() => _TodayMeSectionState();
}

class _TodayMeSectionState extends State<_TodayMeSection>
    with WidgetsBindingObserver {
  static const double _cardWidth = 350;
  static const double _cardGap = 12;
  static const double _cardShadowInset = 8;
  static const double _cardsViewportWidth = 370;

  PageController? _pageController;
  double? _lastViewportFraction;
  Timer? _dateRefreshTimer;
  String _lastKstDateKey = kstDateKeyNow();
  int _currentCardIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    DailyCheckinStore.instance.initialize();
    _scheduleDateRefreshTimer();
  }

  void _scheduleDateRefreshTimer() {
    _dateRefreshTimer?.cancel();
    _dateRefreshTimer = Timer(durationUntilNextKstDateChange(), () {
      unawaited(_refreshCheckinByDateChange());
      if (!mounted) {
        return;
      }
      _scheduleDateRefreshTimer();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshCheckinByDateChange());
      _scheduleDateRefreshTimer();
    }
  }

  void _showSavedToast() {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Center(child: AppToastMessage(text: "저장됐어요")),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
          backgroundColor: Colors.transparent,
          elevation: 0,
          padding: EdgeInsets.zero,
          margin: EdgeInsets.fromLTRB(50, 0, 50, 98),
        ),
      );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dateRefreshTimer?.cancel();
    _pageController?.dispose();
    super.dispose();
  }

  Future<void> _refreshCheckinByDateChange() async {
    final String currentKey = kstDateKeyNow();
    if (currentKey == _lastKstDateKey) {
      return;
    }
    _lastKstDateKey = currentKey;
    await DailyCheckinStore.instance.reloadToday();
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  PageController _resolveController(double viewportFraction) {
    final bool shouldRecreate =
        _pageController == null || _lastViewportFraction != viewportFraction;
    if (!shouldRecreate) {
      return _pageController!;
    }
    final int initialPage = _pageController?.hasClients == true
        ? (_pageController!.page?.round() ?? _pageController!.initialPage)
        : (_pageController?.initialPage ?? 0);
    _pageController?.dispose();
    _pageController = PageController(
      initialPage: initialPage,
      viewportFraction: viewportFraction,
    );
    _lastViewportFraction = viewportFraction;
    return _pageController!;
  }

  void _handleMetricOptionTap({
    required DailyCheckinMetric metric,
    required int selectedIndex,
    required int cardIndex,
    required int totalCards,
  }) {
    unawaited(
      DailyCheckinStore.instance.saveSelection(
        metric: metric,
        selectedIndex: selectedIndex,
      ),
    );
    _showSavedToast();
    if (cardIndex >= totalCards - 1) {
      return;
    }
    final PageController? controller = _pageController;
    if (controller == null || !controller.hasClients) {
      return;
    }
    unawaited(
      controller.animateToPage(
        cardIndex + 1,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DailyCheckinRecord?>(
      valueListenable: DailyCheckinStore.instance,
      builder:
          (BuildContext context, DailyCheckinRecord? checkin, Widget? child) {
            final BrandScale brand = context.appBrandScale;
            return LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double listWidth = constraints.maxWidth;
                final double viewportWidth = _cardsViewportWidth > listWidth
                    ? _cardsViewportWidth
                    : listWidth;
                final double viewportFraction =
                    ((_cardWidth + _cardGap) / viewportWidth).clamp(0.0, 1.0);
                final double contentLeadingInset =
                    viewportWidth > (_cardWidth + _cardGap)
                    ? (viewportWidth - (_cardWidth + _cardGap)) / 2
                    : 0;
                final PageController controller = _resolveController(
                  viewportFraction,
                );
                final List<Widget> cards = <Widget>[
                  _TodayMetricCard(
                    kind: _TodayMetricCardKind.mood,
                    titlePrefix: "",
                    highlightedWord: "기분",
                    titleSuffix: "은 어떤가요?",
                    subtitle: "오늘 지속적인 하루 기분을 골라주세요",
                    cardWidth: _cardWidth,
                    options: _TodayMeSection._moodOptions,
                    highlightColor: brand.c500,
                    selectedBackgroundColor: brand.c100,
                    selectedBorderColor: brand.c500,
                    defaultBorderColor: brand.c200,
                    selectedIndex: checkin?.moodIndex,
                    onOptionTap: (int index) {
                      _handleMetricOptionTap(
                        metric: DailyCheckinMetric.mood,
                        selectedIndex: index,
                        cardIndex: 0,
                        totalCards: 3,
                      );
                    },
                  ),
                  _TodayMetricCard(
                    kind: _TodayMetricCardKind.energy,
                    titlePrefix: "지금 ",
                    highlightedWord: "에너지",
                    titleSuffix: "는 어떤가요?",
                    subtitle: "오늘 하루 컨디션 상태를 골라주세요",
                    cardWidth: _cardWidth,
                    options: _TodayMeSection._energyOptions,
                    highlightColor: const Color(0xFFED87E5),
                    selectedBackgroundColor: const Color(0xFFFDF7FF),
                    selectedBorderColor: const Color(0xFFD9C8FF),
                    defaultBorderColor: const Color(0xFFEEE1F3),
                    selectedIndex: checkin?.energyIndex,
                    onOptionTap: (int index) {
                      _handleMetricOptionTap(
                        metric: DailyCheckinMetric.energy,
                        selectedIndex: index,
                        cardIndex: 1,
                        totalCards: 3,
                      );
                    },
                  ),
                  _TodayMetricCard(
                    kind: _TodayMetricCardKind.stress,
                    titlePrefix: "지금 ",
                    highlightedWord: "스트레스",
                    titleSuffix: "는 어떤가요?",
                    subtitle: "오늘 하루 머릿속은 어떤가요?",
                    cardWidth: _cardWidth,
                    options: _TodayMeSection._stressOptions,
                    highlightColor: const Color(0xFFFF9F45),
                    selectedBackgroundColor: const Color(0xFFFFFAF5),
                    selectedBorderColor: const Color(0xFFFFD7B5),
                    defaultBorderColor: const Color(0xFFFFF1E6),
                    selectedIndex: checkin?.stressIndex,
                    onOptionTap: (int index) {
                      _handleMetricOptionTap(
                        metric: DailyCheckinMetric.stress,
                        selectedIndex: index,
                        cardIndex: 2,
                        totalCards: 3,
                      );
                    },
                  ),
                ];
                final bool hasCompletedAllMetrics =
                    checkin?.moodIndex != null &&
                    checkin?.energyIndex != null &&
                    checkin?.stressIndex != null;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.only(left: contentLeadingInset),
                      child: Text(
                        "오늘의 나는 어떤가요?",
                        style: AppTypography.headingSmall.copyWith(
                          color: AppNeutralColors.grey900,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s16),
                    if (!hasCompletedAllMetrics) ...<Widget>[
                      Padding(
                        padding: EdgeInsets.only(left: contentLeadingInset),
                        child: _TodayMetricProgressBar(
                          currentStep: _currentCardIndex + 1,
                          totalSteps: cards.length,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s16),
                    ],
                    SizedBox(
                      height: 425 + (_cardShadowInset * 2),
                      child: OverflowBox(
                        alignment: Alignment.topLeft,
                        minWidth: viewportWidth,
                        maxWidth: viewportWidth,
                        child: SizedBox(
                          width: viewportWidth,
                          child: PageView.builder(
                            controller: controller,
                            scrollDirection: Axis.horizontal,
                            physics: const ClampingScrollPhysics(),
                            clipBehavior: Clip.none,
                            padEnds: true,
                            onPageChanged: (int index) {
                              if (_currentCardIndex == index) {
                                return;
                              }
                              setState(() {
                                _currentCardIndex = index;
                              });
                            },
                            itemCount: cards.length,
                            itemBuilder: (BuildContext context, int index) {
                              return Padding(
                                padding: EdgeInsets.only(
                                  top: _cardShadowInset,
                                  bottom: _cardShadowInset,
                                  right: index == cards.length - 1
                                      ? 0
                                      : _cardGap,
                                ),
                                child: Align(
                                  alignment: Alignment.topLeft,
                                  child: cards[index],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    if (hasCompletedAllMetrics) ...<Widget>[
                      const SizedBox(height: AppSpacing.s16),
                      Padding(
                        padding: EdgeInsets.only(left: contentLeadingInset),
                        child: _TodayMetricCompletionCard(checkin: checkin!),
                      ),
                    ],
                  ],
                );
              },
            );
          },
    );
  }
}

enum _TodayMetricCardKind { mood, energy, stress }

class _TodayMetricCard extends StatelessWidget {
  const _TodayMetricCard({
    required this.kind,
    required this.titlePrefix,
    required this.highlightedWord,
    required this.titleSuffix,
    required this.subtitle,
    required this.cardWidth,
    required this.options,
    required this.highlightColor,
    required this.selectedBackgroundColor,
    required this.selectedBorderColor,
    required this.defaultBorderColor,
    required this.onOptionTap,
    this.selectedIndex,
  });

  final _TodayMetricCardKind kind;
  final String titlePrefix;
  final String highlightedWord;
  final String titleSuffix;
  final String subtitle;
  final double cardWidth;
  final List<String> options;
  final Color highlightColor;
  final Color selectedBackgroundColor;
  final Color selectedBorderColor;
  final Color defaultBorderColor;
  final int? selectedIndex;
  final ValueChanged<int> onOptionTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: cardWidth,
      height: 425,
      decoration: BoxDecoration(
        color: AppNeutralColors.white,
        borderRadius: AppRadius.br16,
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0F000000),
            offset: Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppRadius.br16,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: <Widget>[
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: AppTypography.headingSmall.copyWith(
                        color: AppNeutralColors.grey900,
                      ),
                      children: <TextSpan>[
                        TextSpan(text: titlePrefix),
                        TextSpan(
                          text: highlightedWord,
                          style: AppTypography.headingSmall.copyWith(
                            color: highlightColor,
                          ),
                        ),
                        TextSpan(text: titleSuffix),
                      ],
                    ),
                  ),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmallMedium.copyWith(
                      color: AppNeutralColors.grey400,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s24),
              SizedBox(
                height: 288,
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List<Widget>.generate(options.length, (int i) {
                    final bool isLast = i == options.length - 1;
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: isLast ? 0 : AppSpacing.s12,
                      ),
                      child: _ChoicePill(
                        text: options[i],
                        selected: selectedIndex == i,
                        selectedBackgroundColor: selectedBackgroundColor,
                        selectedBorderColor: selectedBorderColor,
                        defaultBorderColor: defaultBorderColor,
                        onTap: () => onOptionTap(i),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoicePill extends StatelessWidget {
  const _ChoicePill({
    required this.text,
    required this.onTap,
    required this.selectedBackgroundColor,
    required this.selectedBorderColor,
    required this.defaultBorderColor,
    this.selected = false,
  });

  final String text;
  final VoidCallback onTap;
  final Color selectedBackgroundColor;
  final Color selectedBorderColor;
  final Color defaultBorderColor;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected ? selectedBackgroundColor : AppNeutralColors.white,
          borderRadius: AppRadius.pill,
          border: Border.all(
            color: selected ? selectedBorderColor : defaultBorderColor,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: AppRadius.pill,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadius.pill,
            child: Container(
              height: 48,
              padding: EdgeInsets.only(left: 24, right: selected ? 16 : 24),
              alignment: Alignment.centerLeft,
              child: Row(
                children: <Widget>[
                  AppEmojiText(
                    text,
                    style: AppTypography.buttonMedium.copyWith(
                      color: AppNeutralColors.grey800,
                    ),
                  ),
                  if (selected) ...<Widget>[
                    const Spacer(),
                    Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: selectedBorderColor,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TodayMetricProgressBar extends StatelessWidget {
  const _TodayMetricProgressBar({
    required this.currentStep,
    required this.totalSteps,
  });

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    final double progress = totalSteps == 0 ? 0 : currentStep / totalSteps;
    return SizedBox(
      width: 350,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            "질문 $currentStep/$totalSteps",
            style: AppTypography.captionSmall.copyWith(
              color: AppNeutralColors.grey400,
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          ClipRRect(
            borderRadius: AppRadius.pill,
            child: SizedBox(
              height: 6,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  ColoredBox(color: brand.c100),
                  FractionallySizedBox(
                    widthFactor: progress.clamp(0.0, 1.0),
                    alignment: Alignment.centerLeft,
                    child: ColoredBox(color: brand.c400),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayMetricCompletionCard extends StatelessWidget {
  const _TodayMetricCompletionCard({required this.checkin});

  final DailyCheckinRecord checkin;

  static const List<String> _rowQuestions = <String>[
    "오늘 나의 기분은?",
    "오늘 나의 에너지는?",
    "오늘 나의 스트레스는?",
  ];

  String _optionLabel(List<String> options, int? index) {
    if (index == null || index < 0 || index >= options.length) {
      return "-";
    }
    return options[index];
  }

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    final List<String> answers = <String>[
      _optionLabel(_TodayMeSection._moodOptions, checkin.moodIndex),
      _optionLabel(_TodayMeSection._energyOptions, checkin.energyIndex),
      _optionLabel(_TodayMeSection._stressOptions, checkin.stressIndex),
    ];

    return Container(
      width: 350,
      constraints: const BoxConstraints(minHeight: 161),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      decoration: BoxDecoration(
        color: brand.c100,
        borderRadius: AppRadius.br16,
        border: Border.all(color: brand.c400),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0A000000),
            offset: Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.check_rounded, size: 24, color: brand.c500),
              const SizedBox(width: AppSpacing.s8),
              Text(
                "모든 감정 질문에 답변했습니다!",
                style: AppTypography.heading2XSmall.copyWith(color: brand.c500),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s16),
          Column(
            children: List<Widget>.generate(_rowQuestions.length, (int index) {
              final bool isLast = index == _rowQuestions.length - 1;
              return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 9),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        _rowQuestions[index],
                        style: AppTypography.bodySmallSemiBold.copyWith(
                          color: AppNeutralColors.grey700,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s12),
                    AppEmojiText(
                      answers[index],
                      textAlign: TextAlign.right,
                      style: AppTypography.bodySmallSemiBold.copyWith(
                        color: AppNeutralColors.grey700,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _InviteFriendsBanner extends StatelessWidget {
  const _InviteFriendsBanner();

  String? _inviteStoreUrl(BuildContext context) {
    return switch (Theme.of(context).platform) {
      TargetPlatform.iOS => HomeScreen._iosInviteStoreUrl,
      TargetPlatform.android => HomeScreen._androidInviteStoreUrl,
      _ => null,
    };
  }

  Future<void> _copyInviteLink(BuildContext context) async {
    final String? inviteStoreUrl = _inviteStoreUrl(context);
    if (inviteStoreUrl == null) {
      return;
    }

    await Clipboard.setData(ClipboardData(text: inviteStoreUrl));

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Center(child: AppToastMessage(text: "친구 초대 링크가 복사되었어요")),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    final bool canCopyInviteLink = _inviteStoreUrl(context) != null;
    final String inviteBannerAsset = resolveHomeInviteBannerAsset(brand);
    final String inviteBannerFallbackEmoji =
        brand.c500 == AppBrandThemes.green.c500 ? "🌳" : "🐟";
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: canCopyInviteLink ? () => _copyInviteLink(context) : null,
        borderRadius: AppRadius.br16,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 76),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          decoration: BoxDecoration(
            color: brand.c100,
            borderRadius: AppRadius.br16,
            boxShadow: AppElevation.level1,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  "친구를 초대해\n기록을 함께 나눠보세요!",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.heading2XSmall.copyWith(
                    color: AppNeutralColors.grey900,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              Image.asset(
                inviteBannerAsset,
                width: 94,
                height: 58,
                fit: BoxFit.contain,
                errorBuilder: (_, error, stackTrace) {
                  return SizedBox(
                    width: 94,
                    height: 58,
                    child: Center(
                      child: AppEmojiText(
                        inviteBannerFallbackEmoji,
                        style: const TextStyle(fontSize: 30),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
