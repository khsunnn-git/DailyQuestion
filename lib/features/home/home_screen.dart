import "dart:async";
import "dart:ui" as ui;

import "package:flutter/gestures.dart";
import "package:flutter/material.dart";
import "package:isar/isar.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../../core/app_route_observer.dart";
import "../../core/kst_date_time.dart";
import "../../data/local_db/entities/bucket_item_entity.dart";
import "../../data/local_db/local_database.dart";
import "../../design_system/design_system.dart";
import "../navigation/main_tab_shell.dart";
import "annual_record_screen.dart";
import "my_record_detail_screen.dart";
import "home_character_assets.dart";
import "home_fish_growth.dart";
import "my_records_screen.dart";
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
  static const String _inviteBannerAsset =
      "assets/images/home/home_banner_invite_fish_blue.webp";
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
                    const SizedBox(height: AppSpacing.s40),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _RecordStreakSection(),
                          const _TodayMeSection(),
                          const SizedBox(height: AppSpacing.s32),
                          _TodayRecordSection(),
                          const SizedBox(height: AppSpacing.s32),
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
            final bool hasRecord =
                records.isNotEmpty &&
                TodayQuestionStore.instance.hasRecordForTodayKst;
            final int totalRecordCount = records.length;
            return Container(
              decoration: BoxDecoration(
                color: brand.c100,
                borderRadius: panelRadius,
                boxShadow: AppElevation.level2,
              ),
              child: ClipRRect(
                borderRadius: panelRadius,
                child: Stack(
                  children: <Widget>[
                    if (hasRecord)
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
                            const SizedBox(height: AppSpacing.s8),
                            _TopCharacterDecorations(
                              bubbleColor: brand.c500,
                              recordCount: totalRecordCount,
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
    with RouteAware {
  static const String _lastCelebratedLevelPrefsKey =
      "home_last_celebrated_fish_level";
  static const Duration _visibleDuration = Duration(seconds: 5);
  static const Duration _fadeDuration = Duration(milliseconds: 220);

  SharedPreferences? _prefs;
  int? _lastCelebratedLevelNumber;
  HomeFishGrowthLevel? _visibleLevel;
  PageRoute<dynamic>? _pageRoute;
  bool _isOverlayVisible = false;
  bool _isRouteVisible = false;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    TodayQuestionStore.instance.addListener(_handleRecordsChanged);
    unawaited(_prepare());
  }

  Future<void> _prepare() async {
    await TodayQuestionStore.instance.initialize();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final HomeFishGrowthLevel currentLevel = homeFishGrowthLevelForRecordCount(
      TodayQuestionStore.instance.value.length,
    );
    final int storedLevelNumber =
        prefs.getInt(_lastCelebratedLevelPrefsKey) ?? currentLevel.number;
    if (!prefs.containsKey(_lastCelebratedLevelPrefsKey)) {
      await prefs.setInt(_lastCelebratedLevelPrefsKey, storedLevelNumber);
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _prefs = prefs;
      _lastCelebratedLevelNumber = storedLevelNumber;
    });
    _evaluatePendingCelebration();
  }

  void _handleRecordsChanged() {
    _evaluatePendingCelebration();
  }

  void _evaluatePendingCelebration() {
    final SharedPreferences? prefs = _prefs;
    final int? lastCelebratedLevelNumber = _lastCelebratedLevelNumber;
    if (prefs == null || lastCelebratedLevelNumber == null) {
      return;
    }
    final HomeFishGrowthLevel currentLevel = homeFishGrowthLevelForRecordCount(
      TodayQuestionStore.instance.value.length,
    );
    if (!currentLevel.canCelebrate ||
        currentLevel.number <= lastCelebratedLevelNumber) {
      return;
    }
    if (!_isRouteVisible) {
      return;
    }
    _lastCelebratedLevelNumber = currentLevel.number;
    unawaited(prefs.setInt(_lastCelebratedLevelPrefsKey, currentLevel.number));
    _showOverlay(currentLevel);
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

  void _showOverlay(HomeFishGrowthLevel level) {
    _hideTimer?.cancel();
    if (!mounted) {
      return;
    }
    setState(() {
      _visibleLevel = level;
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
        });
      });
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    TodayQuestionStore.instance.removeListener(_handleRecordsChanged);
    if (_pageRoute != null) {
      appRouteObserver.unsubscribe(this);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final HomeFishGrowthLevel? visibleLevel = _visibleLevel;
    if (visibleLevel == null) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      ignoring: !_isOverlayVisible,
      child: AnimatedOpacity(
        opacity: _isOverlayVisible ? 1 : 0,
        duration: _fadeDuration,
        curve: Curves.easeOutCubic,
        child: _HomeLevelUpOverlay(level: visibleLevel),
      ),
    );
  }
}

class _HomeLevelUpOverlay extends StatelessWidget {
  const _HomeLevelUpOverlay({required this.level});

  final HomeFishGrowthLevel level;

  static const Color _scrimColor = Color(0xB8000000);
  static const Color _accentColor = Color(0xFFB6E2FF);

  @override
  Widget build(BuildContext context) {
    final String fishAssetPath = HomeCharacterAssets.levelUpOverlayAssetFor(
      HomeCharacterType.fish,
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
                  level.celebrationHeadline,
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
                  width: 285,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      Positioned(
                        left: 0,
                        top: 34,
                        child: Image.asset(
                          HomeCharacterAssets.levelUpConfettiLeft,
                          width: 88,
                          height: 131,
                          fit: BoxFit.contain,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 32,
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
                          fishAssetPath,
                          fit: BoxFit.contain,
                          errorBuilder: (_, error, stackTrace) {
                            return const Center(
                              child: Text("🐟", style: TextStyle(fontSize: 80)),
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

enum _SpeechTailDirection { right, down }

class _HomeHeroFishImage extends StatelessWidget {
  const _HomeHeroFishImage({
    required this.assetPath,
    required this.size,
    required this.fallbackFontSize,
  });

  final String assetPath;
  final double size;
  final double fallbackFontSize;

  @override
  Widget build(BuildContext context) {
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
              child: Text("🐟", style: TextStyle(fontSize: fallbackFontSize)),
            );
          },
        ),
      ),
    );
  }
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
    final String fishAssetPath = HomeCharacterAssets.assetForRecordCount(
      HomeCharacterType.fish,
      widget.recordCount,
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
                    child: SizedBox(
                      width: 150,
                      height: 150,
                      child: OverflowBox(
                        maxWidth: 212,
                        maxHeight: 212,
                        child: _HomeHeroFishImage(
                          assetPath: fishAssetPath,
                          size: 212,
                          fallbackFontSize: 72,
                        ),
                      ),
                    ),
                    builder: (BuildContext context, Widget? child) {
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
                              child: child,
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
  List<String> _fallbackBucketTags = const <String>[];
  int? _selectedMoreMenuIndex;
  String? _lastAnswerText;
  bool _pendingAnswerScrollSync = false;
  bool _pendingAnswerScrollReset = false;
  final ScrollController _answerScrollController = ScrollController();
  Object? _fallbackBucketTagsLoadedToken;
  Object? _fallbackBucketTagsActiveToken;
  bool _loadingFallbackBucketTags = false;

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

  void _ensureFallbackBucketTags({
    required TodayQuestionRecord? latest,
    required List<String> recordBucketTags,
  }) {
    if (latest == null || recordBucketTags.isNotEmpty) {
      return;
    }
    if (_loadingFallbackBucketTags &&
        identical(_fallbackBucketTagsActiveToken, latest)) {
      return;
    }
    if (identical(_fallbackBucketTagsLoadedToken, latest)) {
      return;
    }

    _loadingFallbackBucketTags = true;
    _fallbackBucketTagsActiveToken = latest;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_loadFallbackBucketTags(latest: latest));
    });
  }

  Future<void> _loadFallbackBucketTags({
    required TodayQuestionRecord latest,
  }) async {
    final isar = await LocalDatabase.instance.isar;
    final List<BucketItemEntity> items = await isar.bucketItemEntitys
        .where()
        .findAll();
    final Set<String> seen = <String>{};
    final List<String> tags = <String>[];

    for (final BucketItemEntity item in items) {
      final String title = item.title.trim();
      if (item.isCompleted || title.isEmpty) {
        continue;
      }
      if (!isSameKstDate(item.createdAt, latest.createdAt)) {
        continue;
      }
      if (seen.add(title)) {
        tags.add(title);
      }
    }

    if (!mounted || !identical(_fallbackBucketTagsActiveToken, latest)) {
      return;
    }

    _loadingFallbackBucketTags = false;
    setState(() {
      _fallbackBucketTagsLoadedToken = latest;
      _fallbackBucketTags = tags;
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
          content: Center(child: AppToastMessage(text: "😳이 질문은 아직 쌓이지 않았어요")),
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
    _ensureFallbackBucketTags(latest: latest, recordBucketTags: bucketTags);
    final List<String> visibleBucketTags = latest == null
        ? const <String>[]
        : bucketTags.isNotEmpty
        ? bucketTags
        : identical(_fallbackBucketTagsLoadedToken, latest)
        ? _fallbackBucketTags
        : const <String>[];

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

  late final AnimationController _fishController;
  late final Animation<double> _fishDy;
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
    final String fishAssetPath = HomeCharacterAssets.assetForRecordCount(
      HomeCharacterType.fish,
      widget.recordCount,
    );
    return SizedBox(
      width: 350,
      height: 152,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
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
                errorBuilder: (_, error, stackTrace) => const SizedBox.shrink(),
              ),
            ),
          ),
          Positioned(
            right: 108,
            top: 26,
            child: _QuestionWrittenSpeechBubble(
              text: _messages[_messageIndex],
              color: widget.bubbleColor,
            ),
          ),
          Positioned(
            left: 218,
            top: -14,
            child: AnimatedBuilder(
              animation: _fishController,
              child: SizedBox(
                width: 152,
                height: 152,
                child: OverflowBox(
                  maxWidth: 208,
                  maxHeight: 208,
                  child: _HomeHeroFishImage(
                    assetPath: fishAssetPath,
                    size: 208,
                    fallbackFontSize: 56,
                  ),
                ),
              ),
              builder: (BuildContext context, Widget? child) {
                return Transform.translate(
                  offset: Offset(0, _fishDy.value),
                  child: child,
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
          Text(
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
  String _todayKey = kstDateKeyNow();

  Timer? _dateRefreshTimer;
  PageController? _pageController;
  double? _lastViewportFraction;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleDateRefreshTimer();
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

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<TodayQuestionRecord>>(
      valueListenable: TodayQuestionStore.instance,
      builder:
          (
            BuildContext context,
            List<TodayQuestionRecord> allRecords,
            Widget? child,
          ) {
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
                    final List<_TodayRecordData> remoteRecords = fetchedRecords
                        .take(5)
                        .map(
                          (PublicTodayRecord item) => _TodayRecordData(
                            body: _toPreviewText(item.body),
                            name: item.author,
                          ),
                        )
                        .toList(growable: false);
                    final List<_TodayRecordData> records = remoteRecords;
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
                                    questionText: TodayQuestionPromptStore
                                        .instance
                                        .value
                                        .currentQuestionText,
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
                            builder:
                                (
                                  BuildContext context,
                                  BoxConstraints constraints,
                                ) {
                                  final double listWidth = constraints.maxWidth;
                                  final double viewportFraction =
                                      ((_recordCardWidth + _recordCardGap) /
                                              listWidth)
                                          .clamp(0.0, 1.0);
                                  final PageController controller =
                                      _resolveController(viewportFraction);
                                  return SizedBox(
                                    height: 160,
                                    child: SizedBox(
                                      width: listWidth,
                                      child: SizedBox(
                                        width: listWidth,
                                        child: ScrollConfiguration(
                                          behavior:
                                              const MaterialScrollBehavior()
                                                  .copyWith(
                                                    dragDevices:
                                                        <PointerDeviceKind>{
                                                          PointerDeviceKind
                                                              .touch,
                                                          PointerDeviceKind
                                                              .mouse,
                                                          PointerDeviceKind
                                                              .trackpad,
                                                          PointerDeviceKind
                                                              .stylus,
                                                          PointerDeviceKind
                                                              .invertedStylus,
                                                        },
                                                  ),
                                          child: PageView.builder(
                                            controller: controller,
                                            scrollDirection: Axis.horizontal,
                                            physics:
                                                const ClampingScrollPhysics(),
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
                                                    right:
                                                        index ==
                                                            records.length - 1
                                                        ? 0
                                                        : _recordCardGap,
                                                  ),
                                                  child: _TodayRecordCard(
                                                    record: records[index],
                                                    width: _recordCardWidth,
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

  String _toPreviewText(String raw) {
    final String singleLine = raw.replaceAll("\n", " ");
    if (singleLine.length <= 56) {
      return singleLine;
    }
    return "${singleLine.substring(0, 56)}...";
  }
}

class _TodayRecordEmptyCard extends StatelessWidget {
  const _TodayRecordEmptyCard({required this.recordCount, required this.onTap});

  final int recordCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    final String fishAssetPath = HomeCharacterAssets.assetForRecordCount(
      HomeCharacterType.fish,
      recordCount,
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
                fishAssetPath,
                width: 64,
                height: 64,
                fit: BoxFit.contain,
                errorBuilder: (_, error, stackTrace) {
                  return const Text("🐟", style: TextStyle(fontSize: 32));
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

class _TodayRecordData {
  const _TodayRecordData({required this.body, required this.name});

  final String body;
  final String name;
}

class _TodayRecordCard extends StatelessWidget {
  const _TodayRecordCard({required this.record, required this.width});

  final _TodayRecordData record;
  final double width;

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    return Container(
      width: width,
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
              record.body,
              style: AppTypography.bodyMediumMedium.copyWith(
                color: AppNeutralColors.grey900,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 3,
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              record.name,
              style: AppTypography.bodyMediumSemiBold.copyWith(
                color: brand.c500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayMeSection extends StatefulWidget {
  const _TodayMeSection();

  static const List<String> _moodOptions = <String>[
    "매우 좋아요😀",
    "좋아요😊",
    "보통이에요😐",
    "나빠요🙁",
    "매우 나빠요😫",
  ];
  static const List<String> _energyOptions = <String>[
    "에너지가 넘쳐요😀",
    "꽤 괜찮아요😊",
    "평소와 같아요😐",
    "조금 지쳤어요🙁",
    "방전 직전이에요😫",
  ];
  static const List<String> _stressOptions = <String>[
    "편안해요😀",
    "가벼운 편이에요😊",
    "보통이에요😐",
    "조금 있어요🙁",
    "한계에요😫",
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

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DailyCheckinRecord?>(
      valueListenable: DailyCheckinStore.instance,
      builder:
          (BuildContext context, DailyCheckinRecord? checkin, Widget? child) {
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
                    highlightColor: const Color(0xFF017AF7),
                    selectedBackgroundColor: const Color(0xFFF8FDFF),
                    selectedBorderColor: const Color(0xFF86CAFF),
                    defaultBorderColor: const Color(0xFFE9F6FF),
                    selectedIndex: checkin?.moodIndex,
                    onOptionTap: (int index) {
                      unawaited(
                        DailyCheckinStore.instance.saveSelection(
                          metric: DailyCheckinMetric.mood,
                          selectedIndex: index,
                        ),
                      );
                      _showSavedToast();
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
                      unawaited(
                        DailyCheckinStore.instance.saveSelection(
                          metric: DailyCheckinMetric.energy,
                          selectedIndex: index,
                        ),
                      );
                      _showSavedToast();
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
                      unawaited(
                        DailyCheckinStore.instance.saveSelection(
                          metric: DailyCheckinMetric.stress,
                          selectedIndex: index,
                        ),
                      );
                      _showSavedToast();
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
                  Text(
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
                    Text(
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

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    return Container(
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
            HomeScreen._inviteBannerAsset,
            width: 94,
            height: 58,
            fit: BoxFit.contain,
            errorBuilder: (_, error, stackTrace) {
              return const SizedBox(
                width: 94,
                height: 58,
                child: Center(
                  child: Text("🐟", style: TextStyle(fontSize: 30)),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
