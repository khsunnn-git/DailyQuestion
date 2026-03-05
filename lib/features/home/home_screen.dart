import "dart:async";

import "package:flutter/gestures.dart";
import "package:flutter/material.dart";

import "../../core/kst_date_time.dart";
import "../../design_system/design_system.dart";
import "../bucket/bucket_list_screen.dart";
import "../more/more_settings_screen.dart";
import "annual_record_screen.dart";
import "my_record_detail_screen.dart";
import "my_records_screen.dart";
import "public_today_records_repository.dart";
import "../question/today_question_answer_screen.dart";
import "../question/today_question_prompt_store.dart";
import "../question/today_question_store.dart";
import "daily_checkin_store.dart";
import "today_records_screen.dart";

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const String _heroFishAsset =
      "assets/images/home/home_character_fish_blue.png";
  static const String _decoSeaweedAsset =
      "assets/images/home/home_deco_seaweed_blue.png";
  static const String _decoCrabAsset =
      "assets/images/home/home_deco_crab_blue.png";
  static const String _decoBubbleAsset =
      "assets/images/home/home_deco_bubble_blue.png";
  static const String _inviteBannerAsset =
      "assets/images/home/home_banner_invite_fish_blue.png";

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

  static void openTodayRecords(
    BuildContext context, {
    String? questionDateKey,
    String? questionText,
    List<PublicTodayRecord> initialRecords = const <PublicTodayRecord>[],
  }) {
    Navigator.of(context).push(
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
                  if (index == 1) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (_) => const BucketListScreen(),
                      ),
                    );
                    return;
                  }
                  if (index == 2) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (_) => const MyRecordsScreen(),
                      ),
                    );
                    return;
                  }
                  if (index == 3) {
                    MoreSettingsScreen.open(context, replace: true);
                  }
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
  Timer? _minuteTimer;
  String _lastKstDateKey = kstDateKeyNow();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    TodayQuestionPromptStore.instance.initialize();
    _minuteTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _refreshByKstDateChange();
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
      _refreshByKstDateChange();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _minuteTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    return Container(
      decoration: BoxDecoration(
        color: brand.c100,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: AppElevation.level2,
      ),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      child: ValueListenableBuilder<List<TodayQuestionRecord>>(
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
              return Column(
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
                    _TopCharacterDecorations(bubbleColor: brand.c500),
                  ] else ...<Widget>[const _QuestionBeforeRecordCard()],
                ],
              );
            },
      ),
    );
  }
}

enum _SpeechTailDirection { right, down }

class _QuestionBeforeRecordCard extends StatefulWidget {
  const _QuestionBeforeRecordCard();

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
                              child: Image.asset(
                                HomeScreen._heroFishAsset,
                                width: 150,
                                height: 150,
                                fit: BoxFit.contain,
                                errorBuilder: (_, error, stackTrace) {
                                  return const Center(
                                    child: Text(
                                      "🐟",
                                      style: TextStyle(fontSize: 64),
                                    ),
                                  );
                                },
                              ),
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
  bool _showMoreMenu = false;
  int? _selectedMoreMenuIndex;

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
            child: Container(
              width: double.infinity,
              height: 458,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
              decoration: BoxDecoration(
                color: AppNeutralColors.white,
                borderRadius: AppRadius.br24,
                boxShadow: AppElevation.level1,
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
                            constraints: const BoxConstraints.tightFor(
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
                              style: AppTypography.bodyMediumSemiBold.copyWith(
                                color: brand.c500,
                              ),
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
                              constraints: const BoxConstraints.tightFor(
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
                        bottom: BorderSide(color: AppNeutralColors.grey50),
                      ),
                    ),
                    child: Text(
                      questionText,
                      textAlign: TextAlign.center,
                      style: AppTypography.headingMediumExtraBold.copyWith(
                        color: AppNeutralColors.grey900,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  Expanded(
                    child: Text(
                      answerText,
                      textAlign: TextAlign.left,
                      style: AppTypography.bodyLargeRegular.copyWith(
                        color: AppNeutralColors.grey800,
                      ),
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (bucketTags.isNotEmpty)
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
                            children: bucketTags
                                .map(
                                  (String tag) => Padding(
                                    padding: const EdgeInsets.only(
                                      right: AppSpacing.s6,
                                    ),
                                    child: Container(
                                      height: 38,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.s16,
                                      ),
                                      decoration: BoxDecoration(
                                        color: brand.c100,
                                        borderRadius: AppRadius.pill,
                                        border: Border.all(color: brand.c200),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        "#$tag",
                                        style: AppTypography.buttonSmall
                                            .copyWith(color: brand.c500),
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
  const _TopCharacterDecorations({required this.bubbleColor});

  final Color bubbleColor;

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
    return SizedBox(
      width: 350,
      height: 140,
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
            top: 0,
            child: AnimatedBuilder(
              animation: _fishController,
              builder: (BuildContext context, Widget? child) {
                return Transform.translate(
                  offset: Offset(0, _fishDy.value),
                  child: Image.asset(
                    HomeScreen._heroFishAsset,
                    width: 140,
                    height: 140,
                    fit: BoxFit.contain,
                    errorBuilder: (_, error, stackTrace) {
                      return const SizedBox(
                        width: 140,
                        height: 140,
                        child: Center(
                          child: Text("🐟", style: TextStyle(fontSize: 48)),
                        ),
                      );
                    },
                  ),
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

class _TodayRecordSectionState extends State<_TodayRecordSection> {
  static const double _recordCardWidth = 350;
  static const double _recordCardGap = 12;
  String _todayKey = kstDateKeyNow();

  Timer? _dateRefreshTimer;
  PageController? _pageController;
  double? _lastViewportFraction;

  @override
  void initState() {
    super.initState();
    _dateRefreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) {
        return;
      }
      final String currentKey = kstDateKeyNow();
      if (currentKey == _todayKey) {
        return;
      }
      setState(() {
        _todayKey = currentKey;
      });
    });
  }

  @override
  void dispose() {
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

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<TodayQuestionRecord>>(
      valueListenable: TodayQuestionStore.instance,
      builder:
          (BuildContext context, List<TodayQuestionRecord> _, Widget? child) {
            return FutureBuilder<List<PublicTodayRecord>>(
              future: PublicTodayRecordsRepository.instance.fetchByDateKey(
                _todayKey,
              ),
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
                              ? () => HomeScreen.openTodayRecords(
                                  context,
                                  questionDateKey: _todayKey,
                                  questionText: TodayQuestionPromptStore
                                      .instance
                                      .value
                                      .currentQuestionText,
                                  initialRecords: fetchedRecords,
                                )
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
  const _TodayRecordEmptyCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
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
                HomeScreen._heroFishAsset,
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

class _TodayMeSectionState extends State<_TodayMeSection> {
  static const double _cardWidth = 350;
  static const double _cardGap = 12;
  static const double _cardShadowInset = 8;

  PageController? _pageController;
  double? _lastViewportFraction;

  @override
  void initState() {
    super.initState();
    DailyCheckinStore.instance.initialize();
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          "오늘의 나",
          style: AppTypography.headingSmall.copyWith(
            color: AppNeutralColors.grey900,
          ),
        ),
        const SizedBox(height: AppSpacing.s2),
        Text(
          "매일 입력하면 더욱 자세한 리포트를 받으실 수 있어요",
          style: AppTypography.bodySmallMedium.copyWith(
            color: AppNeutralColors.grey400,
          ),
        ),
        const SizedBox(height: AppSpacing.s16),
        ValueListenableBuilder<DailyCheckinRecord?>(
          valueListenable: DailyCheckinStore.instance,
          builder:
              (
                BuildContext context,
                DailyCheckinRecord? checkin,
                Widget? child,
              ) {
                return LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final double listWidth = constraints.maxWidth;
                    final double viewportFraction =
                        ((_cardWidth + _cardGap) / listWidth).clamp(0.0, 1.0);
                    final PageController controller = _resolveController(
                      viewportFraction,
                    );
                    final List<Widget> cards = <Widget>[
                      _TodayMetricCard(
                        kind: _TodayMetricCardKind.mood,
                        highlightedWord: "기분",
                        subtitle: "지속적인 하루 기분을 골라주세요",
                        backgroundAsset:
                            "assets/images/home/home_card_mood_bg_blue.png",
                        fallbackColor: Color(0xFFD3EEFF),
                        cardWidth: _cardWidth,
                        options: _TodayMeSection._moodOptions,
                        highlightColor: Color(0xFF017AF7),
                        selectedBorderColor: Color(0xFF86CAFF),
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
                        highlightedWord: "에너지",
                        subtitle: "지속적인 컨디션 상태를 골라주세요",
                        backgroundAsset:
                            "assets/images/home/home_card_energy_bg_lilac.png",
                        fallbackColor: Color(0xFFD9C8FF),
                        cardWidth: _cardWidth,
                        options: _TodayMeSection._energyOptions,
                        highlightColor: Color(0xFFED87E5),
                        selectedBorderColor: Color(0xFFD9C8FF),
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
                        highlightedWord: "스트레스",
                        subtitle: "오늘 머릿속은 어떤가요?",
                        backgroundAsset:
                            "assets/images/home/home_card_stress_bg_orange.png",
                        fallbackColor: Color(0xFFFFD7B5),
                        cardWidth: _cardWidth,
                        options: _TodayMeSection._stressOptions,
                        highlightColor: Color(0xFFFF9F45),
                        selectedBorderColor: Color(0xFFFFD7B5),
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
                    return SizedBox(
                      height: 394 + (_cardShadowInset * 2),
                      child: OverflowBox(
                        alignment: Alignment.topLeft,
                        minWidth: listWidth,
                        maxWidth: listWidth,
                        child: SizedBox(
                          width: listWidth,
                          child: PageView.builder(
                            controller: controller,
                            scrollDirection: Axis.horizontal,
                            physics: const ClampingScrollPhysics(),
                            clipBehavior: Clip.none,
                            padEnds: true,
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
                                child: cards[index],
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
        ),
      ],
    );
  }
}

enum _TodayMetricCardKind { mood, energy, stress }

class _TodayMetricCard extends StatelessWidget {
  const _TodayMetricCard({
    required this.kind,
    required this.highlightedWord,
    required this.subtitle,
    required this.backgroundAsset,
    required this.fallbackColor,
    required this.cardWidth,
    required this.options,
    required this.highlightColor,
    required this.selectedBorderColor,
    required this.onOptionTap,
    this.selectedIndex,
  });

  final _TodayMetricCardKind kind;
  final String highlightedWord;
  final String subtitle;
  final String backgroundAsset;
  final Color fallbackColor;
  final double cardWidth;
  final List<String> options;
  final Color highlightColor;
  final Color selectedBorderColor;
  final int? selectedIndex;
  final ValueChanged<int> onOptionTap;

  @override
  Widget build(BuildContext context) {
    final ({double width, double height, double opacity})
    bgRect = switch (kind) {
      _TodayMetricCardKind.mood => (width: 221, height: 250, opacity: 0.3),
      _TodayMetricCardKind.energy => (width: 182, height: 276, opacity: 0.3),
      _TodayMetricCardKind.stress => (width: 186, height: 282, opacity: 0.3),
    };

    return Container(
      width: cardWidth,
      height: 393,
      decoration: BoxDecoration(
        borderRadius: AppRadius.br16,
        boxShadow: AppElevation.level2,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.br16,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            ColoredBox(color: fallbackColor),
            ColoredBox(color: Colors.white.withValues(alpha: 0.8)),
            Positioned(
              right: 0,
              bottom: 0,
              width: bgRect.width,
              height: bgRect.height,
              child: Opacity(
                opacity: bgRect.opacity,
                child: Image.asset(
                  backgroundAsset,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.red.withValues(alpha: 0.12),
                    alignment: Alignment.center,
                    child: const Icon(Icons.image_not_supported_outlined),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      RichText(
                        text: TextSpan(
                          style: AppTypography.headingSmall.copyWith(
                            color: AppNeutralColors.grey900,
                          ),
                          children: <TextSpan>[
                            const TextSpan(text: "오늘 하루 "),
                            TextSpan(
                              text: highlightedWord,
                              style: AppTypography.headingSmall.copyWith(
                                color: highlightColor,
                              ),
                            ),
                            const TextSpan(text: "는 어떤가요?"),
                          ],
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmallMedium.copyWith(
                          color: AppNeutralColors.grey400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s32),
                  SizedBox(
                    height: 243,
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
                            selectedBorderColor: selectedBorderColor,
                            onTap: () => onOptionTap(i),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoicePill extends StatelessWidget {
  const _ChoicePill({
    required this.text,
    required this.onTap,
    required this.selectedBorderColor,
    this.selected = false,
  });

  final String text;
  final VoidCallback onTap;
  final Color selectedBorderColor;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: Material(
        color: AppNeutralColors.white,
        borderRadius: AppRadius.pill,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.pill,
          child: Container(
            height: 39,
            padding: EdgeInsets.only(left: 24, right: selected ? 16 : 24),
            decoration: BoxDecoration(
              borderRadius: AppRadius.pill,
              border: Border.all(
                color: selected ? selectedBorderColor : const Color(0xFFF8FDFF),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  text,
                  style: AppTypography.buttonSmall.copyWith(
                    color: AppNeutralColors.grey800,
                  ),
                ),
                if (selected) ...<Widget>[
                  const SizedBox(width: 4),
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
