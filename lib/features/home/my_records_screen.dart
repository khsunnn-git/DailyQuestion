import "dart:math" as math;

import "package:flutter/gestures.dart";
import "package:flutter/material.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../../design_system/design_system.dart";
import "../bucket/bucket_list_screen.dart";
import "../question/today_question_answer_screen.dart";
import "../question/today_question_store.dart";
import "annual_record_screen.dart";
import "my_record_detail_screen.dart";

class MyRecordsScreen extends StatefulWidget {
  const MyRecordsScreen({super.key});

  static const String _recordHeroDecoAsset =
      "assets/images/record/my_record_hero_deco.png";
  static const String _profileInsightAsset =
      "assets/images/record/profile_insight.png";
  static const String _profileInterestAsset =
      "assets/images/record/profile_interest.png";
  static const String _profileBucketlistAsset =
      "assets/images/record/profile_bucketlist.png";
  static const String _profilePatternAsset =
      "assets/images/record/profile_record_pattern.png";
  static const String _profileChangesAsset =
      "assets/images/record/profile_changes.png";

  static const int _temporaryLastDay = 24;
  static const String _defaultQuestion = "오늘 가장 기억에 남는 순간은 무엇인가요?";
  static const String _unansweredMessage = "아직 열어보지 않은 질문입니다.";
  static const int _debugMockRecordYear = 2025;
  static const int _debugMockRecordMonth = 8;
  static const int _debugMockRecordDay = 24;

  static const List<_MonthlyRecordPreview>
  _seedMonthlyPreviews = <_MonthlyRecordPreview>[
    _MonthlyRecordPreview(
      day: 22,
      date: "22일 월요일",
      question: "내가 가장 사랑하는 것들에 대해 적어보세요",
      body: "우리 가족이 제일 소중하다.",
      tags: <String>[],
    ),
    _MonthlyRecordPreview(
      day: 23,
      date: "23일 화요일",
      question: "요즘 하루 루틴은 어떻게되나요?",
      body: "아침에 일어나서 샤워하고 커피사러 같이 강아지랑 나갔다가 바이브코딩하는게 요즘 일상이야",
      tags: <String>["바이브코딩 완성하기"],
    ),
    _MonthlyRecordPreview(
      day: 24,
      date: "24일 수요일",
      question: "올해 안에 꼭 해보고 싶은 일\n하나는 무엇인가요?",
      body:
          "올해는 꼭 제주도 한라산에 올라가 백록담을 직접 보고 싶어. 예전부터 사진으로만 보던 푸른 호수를 실제로 보고 싶다는 마음이 있었어요.",
      tags: <String>["제주도 한라산 가기"],
    ),
  ];

  static const List<_RecordListItem> _recordItems = <_RecordListItem>[
    _RecordListItem(
      day: "25",
      weekday: "화",
      text: "올해 꼭 해 보고 싶은 일 하나는 무엇인가요?",
      isCompleted: true,
    ),
    _RecordListItem(
      day: "24",
      weekday: "월",
      text: "요즘 무척 휴식을 원하나요?",
      isCompleted: true,
    ),
    _RecordListItem(
      day: "23",
      weekday: "일",
      text: "다른 사람에게 나를 어떻게 기억해줬으면 하나요?",
      isCompleted: true,
    ),
    _RecordListItem(
      day: "22",
      weekday: "토",
      text: "3년 뒤의 나, 스스로에게 어떤 말을 해주고 싶나요?",
      isCompleted: false,
    ),
    _RecordListItem(
      day: "21",
      weekday: "금",
      text: "최근에 누군가에게 고마웠던 순간을 떠올려 보세요.",
      isCompleted: false,
    ),
    _RecordListItem(
      day: "20",
      weekday: "목",
      text: "최근에 나를 가장 웃게 만든 일은 무엇인가요?",
      isCompleted: false,
    ),
    _RecordListItem(
      day: "19",
      weekday: "수",
      text: "지금 가장 바꾸고 싶은 습관은 무엇인가요?",
      isCompleted: false,
    ),
    _RecordListItem(
      day: "18",
      weekday: "화",
      text: "오늘 나에게 고맙다고 말해주고 싶은 점은?",
      isCompleted: false,
    ),
    _RecordListItem(
      day: "17",
      weekday: "월",
      text: "요즘 스스로를 가장 잘 돌본 순간은 언제인가요?",
      isCompleted: false,
    ),
    _RecordListItem(
      day: "16",
      weekday: "일",
      text: "이번 주에 꼭 해내고 싶은 작은 목표는?",
      isCompleted: false,
    ),
  ];

  static String questionTextForDay(int day) {
    if (day <= 0) {
      return _defaultQuestion;
    }
    return _recordItems[(day - 1) % _recordItems.length].text;
  }

  static TodayQuestionRecord? debugMockRecordForMonth({
    required int year,
    required int month,
  }) {
    if (year != _debugMockRecordYear || month != _debugMockRecordMonth) {
      return null;
    }
    return TodayQuestionRecord(
      createdAt: DateTime(
        _debugMockRecordYear,
        _debugMockRecordMonth,
        _debugMockRecordDay,
        12,
      ),
      answer:
          "올해는 꼭 제주도 한라산에 올라가 백록담을 직접 보고 싶어. "
          "예전부터 사진으로만 보던 풍경을 실제로 보고 싶었어.",
      author: "나의 기록",
      bucketTags: const <String>["제주도 한라산 가기"],
      isPublic: false,
    );
  }

  static List<TodayQuestionRecord> debugAnnualMockRecords({
    required DateTime baseDate,
  }) {
    if (baseDate.month != _debugMockRecordMonth ||
        baseDate.day != _debugMockRecordDay ||
        baseDate.year != _debugMockRecordYear) {
      return const <TodayQuestionRecord>[];
    }

    return <TodayQuestionRecord>[
      TodayQuestionRecord(
        createdAt: DateTime(
          _debugMockRecordYear - 1,
          baseDate.month,
          baseDate.day,
          12,
        ),
        answer:
            "스페인에 가서 성지순례를 다녀오고 싶어. 사람들도 많이 만나고 나 자신에 대해 좀 더 알아갈 수 있는 시간이 될 것 같아.",
        author: "나의 기록",
        isPublic: false,
      ),
      TodayQuestionRecord(
        createdAt: DateTime(
          _debugMockRecordYear - 2,
          baseDate.month,
          baseDate.day,
          12,
        ),
        answer: "기타로 노래 한 곡 완주하기",
        author: "나의 기록",
        isPublic: false,
      ),
    ];
  }

  static const List<_ProfileCardItem> _profileItems = <_ProfileCardItem>[
    _ProfileCardItem(
      iconAsset: _profileInsightAsset,
      title: "인사이트",
      body:
          "지난 30일 동안 당신은 여행과 자기계발에 가장 많은 관심을 보였습니다. 당신은 도전을 좋아하고, 새로운 경험(여행/학습)을 통해 성취감을 얻는 사람으로 보입니다.",
    ),
    _ProfileCardItem(
      iconAsset: _profileInterestAsset,
      title: "관심사",
      body: "당신의 목표가 1월에는 ‘수영배우기’를 닮았다면 최근에는 ‘마라톤 도전하기’로 변경되며 관심이 확장되었습니다.",
    ),
    _ProfileCardItem(
      iconAsset: _profileBucketlistAsset,
      title: "버킷리스트",
      body: "30일동안 버킷리스트 12개가 추가되었고, 이 중 4개를 완료했습니다.",
    ),
    _ProfileCardItem(
      iconAsset: _profilePatternAsset,
      title: "기록패턴",
      body:
          "30일 동안 83% 참여율을 보였고, 주말에 답변 누락이 잦았습니다. 주로 늦은 저녁 8~11시 사이에 답변을 작성했습니다.",
    ),
    _ProfileCardItem(
      iconAsset: _profileChangesAsset,
      title: "1년간 변화",
      body: "올해는 꼭 등반해보고 싶은 산?에 ‘한라산’을, 작년에는 ‘설악산’을 답했어요.",
    ),
  ];

  @override
  State<MyRecordsScreen> createState() => _MyRecordsScreenState();
}

class _MyRecordsScreenState extends State<MyRecordsScreen> {
  static const String _installMonthKey = "my_records_install_month";
  static const int _debugInstallYear = 2024;
  static const int _debugInstallMonth = 8;

  int _selectedYear = 2025;
  int _selectedMonth = 8;
  late DateTime _maxMonth;
  DateTime? _installMonth = DateTime(_debugInstallYear, _debugInstallMonth);

  @override
  void initState() {
    super.initState();
    final DateTime now = DateTime.now();
    _maxMonth = DateTime(now.year, now.month);
    _loadInstallMonth();
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
                  bottom:
                      AppNavigationBar.totalHeight(context) + AppSpacing.s20,
                ),
                child: Column(
                  children: <Widget>[
                    _TopMainPanel(
                      brand: brand,
                      selectedYear: _selectedYear,
                      selectedMonth: _selectedMonth,
                      onTapYearMonth: _handleTapYearMonth,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const _RecordReportHeader(),
                          const SizedBox(height: AppSpacing.s32),
                          const _RecordHeroDecor(),
                          const SizedBox(height: AppSpacing.s32),
                          const _StreakCard(),
                          const SizedBox(height: AppSpacing.s32),
                          _PastRecordsSection(
                            selectedYear: _selectedYear,
                            selectedMonth: _selectedMonth,
                            minMonth: _installMonth ?? _maxMonth,
                            maxMonth: _maxMonth,
                          ),
                          const SizedBox(height: AppSpacing.s32),
                          _MonthReportSection(
                            selectedYear: _selectedYear,
                            selectedMonth: _selectedMonth,
                          ),
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
                currentIndex: 2,
                onTap: (int index) {
                  if (index == 0) {
                    Navigator.of(
                      context,
                    ).popUntil((Route<dynamic> route) => route.isFirst);
                    return;
                  }
                  if (index == 1) {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const BucketListScreen(),
                      ),
                    );
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

  Future<void> _handleTapYearMonth() async {
    final DateTime minMonth = _installMonth ?? _maxMonth;
    final DateTime initialMonth = _clampMonth(
      DateTime(_selectedYear, _selectedMonth),
      minMonth,
      _maxMonth,
    );
    final _YearMonthSelection? picked =
        await showGeneralDialog<_YearMonthSelection>(
          context: context,
          barrierColor: const Color(0x40000000),
          barrierDismissible: true,
          barrierLabel: "year-month-picker",
          transitionDuration: const Duration(milliseconds: 120),
          pageBuilder:
              (
                BuildContext context,
                Animation<double> animation,
                Animation<double> secondaryAnimation,
              ) {
                return _YearMonthPickerDialog(
                  initialYear: initialMonth.year,
                  initialMonth: initialMonth.month,
                  minMonth: minMonth,
                  maxMonth: _maxMonth,
                );
              },
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
                    curve: Curves.easeOut,
                  ),
                  child: child,
                );
              },
        );
    if (!mounted || picked == null) return;
    setState(() {
      _selectedYear = picked.year;
      _selectedMonth = picked.month;
    });
  }

  Future<void> _loadInstallMonth() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int savedMillis = DateTime(
      _debugInstallYear,
      _debugInstallMonth,
    ).millisecondsSinceEpoch;
    await prefs.setInt(_installMonthKey, savedMillis);
    final DateTime installMonth = _monthOnly(
      DateTime.fromMillisecondsSinceEpoch(savedMillis),
    );
    if (!mounted) return;
    setState(() {
      _installMonth = installMonth;
      final DateTime selected = _clampMonth(
        DateTime(_selectedYear, _selectedMonth),
        installMonth,
        _maxMonth,
      );
      _selectedYear = selected.year;
      _selectedMonth = selected.month;
    });
  }

  DateTime _monthOnly(DateTime value) => DateTime(value.year, value.month);

  DateTime _clampMonth(DateTime value, DateTime min, DateTime max) {
    final DateTime month = _monthOnly(value);
    if (month.isBefore(min)) return min;
    if (month.isAfter(max)) return max;
    return month;
  }
}

class _TopMainPanel extends StatelessWidget {
  const _TopMainPanel({
    required this.brand,
    required this.selectedYear,
    required this.selectedMonth,
    required this.onTapYearMonth,
  });

  final BrandScale brand;
  final int selectedYear;
  final int selectedMonth;
  final VoidCallback onTapYearMonth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: brand.c100,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: AppElevation.level2,
      ),
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 32),
      child: Column(
        children: <Widget>[
          const SizedBox(height: AppHeaderTokens.topInset),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppHeaderTokens.horizontalPadding,
            ),
            child: SizedBox(
              height: AppHeaderTokens.height,
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.arrow_back, size: 24),
                      color: AppNeutralColors.grey900,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "나의 기록",
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
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: GestureDetector(
              onTap: onTapYearMonth,
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: <Widget>[
                  Text(
                    "$selectedYear.${selectedMonth.toString().padLeft(2, "0")}",
                    style: AppTypography.headingSmall.copyWith(
                      color: AppNeutralColors.grey900,
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    size: 20,
                    color: AppNeutralColors.grey900,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          _MonthlyPreviewStrip(
            selectedYear: selectedYear,
            selectedMonth: selectedMonth,
          ),
        ],
      ),
    );
  }
}

class _MonthlyPreviewStrip extends StatefulWidget {
  const _MonthlyPreviewStrip({
    required this.selectedYear,
    required this.selectedMonth,
  });

  final int selectedYear;
  final int selectedMonth;

  @override
  State<_MonthlyPreviewStrip> createState() => _MonthlyPreviewStripState();
}

class _MonthlyPreviewStripState extends State<_MonthlyPreviewStrip> {
  static const double _cardWidth = 350;
  static const double _cardGap = 12;
  static const double _lastCardRightAdjust = 6;

  PageController? _pageController;
  bool _didSetInitialPage = false;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<TodayQuestionRecord>>(
      valueListenable: TodayQuestionStore.instance,
      builder:
          (BuildContext context, List<TodayQuestionRecord> records, Widget? _) {
            final DateTime monthStart = DateTime(
              widget.selectedYear,
              widget.selectedMonth,
              1,
            );
            final DateTime monthEnd = DateTime(
              widget.selectedYear,
              widget.selectedMonth + 1,
              0,
            );

            final Map<int, TodayQuestionRecord> recordByDay =
                <int, TodayQuestionRecord>{
                  for (final TodayQuestionRecord item in records)
                    if (!item.createdAt.isBefore(monthStart) &&
                        !item.createdAt.isAfter(monthEnd))
                      item.createdAt.day: item,
                };
            final TodayQuestionRecord? debugMock =
                MyRecordsScreen.debugMockRecordForMonth(
                  year: widget.selectedYear,
                  month: widget.selectedMonth,
                );
            if (debugMock != null) {
              recordByDay.putIfAbsent(debugMock.createdAt.day, () => debugMock);
            }
            final Map<int, _MonthlyRecordPreview> seedByDay =
                <int, _MonthlyRecordPreview>{
                  for (final _MonthlyRecordPreview item
                      in MyRecordsScreen._seedMonthlyPreviews)
                    item.day: item,
                };

            int latestDay = 0;
            if (recordByDay.isNotEmpty) {
              latestDay = recordByDay.keys.reduce(
                (int a, int b) => a > b ? a : b,
              );
            } else if (seedByDay.isNotEmpty) {
              latestDay = seedByDay.keys.reduce(
                (int a, int b) => a > b ? a : b,
              );
            }
            latestDay = MyRecordsScreen._temporaryLastDay;

            if (latestDay <= 0) {
              return const SizedBox(height: 458);
            }

            final List<_MonthlyRecordPreview> previews =
                List<_MonthlyRecordPreview>.generate(latestDay, (int index) {
                  final int day = index + 1;
                  final String weekday = _weekdayKorean(
                    DateTime(
                      widget.selectedYear,
                      widget.selectedMonth,
                      day,
                    ).weekday,
                  );
                  final TodayQuestionRecord? record = recordByDay[day];
                  final _MonthlyRecordPreview? seed = seedByDay[day];

                  if (record != null) {
                    final List<String> tags = record.bucketTags.isNotEmpty
                        ? record.bucketTags
                        : (record.bucketTag == null ||
                              record.bucketTag!.trim().isEmpty)
                        ? const <String>[]
                        : <String>[record.bucketTag!.trim()];
                    return _MonthlyRecordPreview(
                      day: day,
                      date: seed?.date ?? "$day일 $weekday",
                      question:
                          seed?.question ??
                          MyRecordsScreen.questionTextForDay(day),
                      body: record.answer,
                      tags: tags,
                      record: record,
                      year: widget.selectedYear,
                      month: widget.selectedMonth,
                    );
                  }
                  if (seed != null) {
                    return _MonthlyRecordPreview(
                      day: seed.day,
                      date: seed.date,
                      question: seed.question,
                      body: seed.body,
                      tags: seed.tags,
                      record: seed.record,
                      year: widget.selectedYear,
                      month: widget.selectedMonth,
                    );
                  }
                  return _MonthlyRecordPreview(
                    day: day,
                    date: "$day일 $weekday",
                    question: MyRecordsScreen.questionTextForDay(day),
                    body: MyRecordsScreen._unansweredMessage,
                    tags: const <String>[],
                    year: widget.selectedYear,
                    month: widget.selectedMonth,
                  );
                }, growable: false);

            WidgetsBinding.instance.addPostFrameCallback((_) {
              final PageController? controller = _pageController;
              if (_didSetInitialPage ||
                  controller == null ||
                  !controller.hasClients) {
                return;
              }
              controller.jumpToPage(previews.length - 1);
              _currentPage = previews.length - 1;
              _didSetInitialPage = true;
            });

            return LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double viewportWidth = constraints.maxWidth;
                final double viewportFraction =
                    viewportWidth > (_cardWidth + _cardGap)
                    ? (_cardWidth + _cardGap) / viewportWidth
                    : 1.0;
                _pageController ??= PageController(
                  viewportFraction: viewportFraction,
                );

                return SizedBox(
                  height: 458,
                  child: ScrollConfiguration(
                    behavior: const MaterialScrollBehavior().copyWith(
                      dragDevices: <PointerDeviceKind>{
                        PointerDeviceKind.touch,
                        PointerDeviceKind.mouse,
                        PointerDeviceKind.trackpad,
                        PointerDeviceKind.stylus,
                        PointerDeviceKind.invertedStylus,
                      },
                    ),
                    child: PageView.builder(
                      controller: _pageController,
                      physics: const PageScrollPhysics(),
                      padEnds: true,
                      onPageChanged: (int index) {
                        if (_currentPage == index) return;
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      itemCount: previews.length,
                      itemBuilder: (BuildContext context, int index) {
                        final bool isLatestCard = index == previews.length - 1;
                        return Align(
                          alignment: isLatestCard
                              ? Alignment.centerRight
                              : Alignment.center,
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: isLatestCard ? _lastCardRightAdjust : 0,
                            ),
                            child: _MonthlyPreviewCard(item: previews[index]),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            );
          },
    );
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  String _weekdayKorean(int weekday) {
    const List<String> values = <String>[
      "월요일",
      "화요일",
      "수요일",
      "목요일",
      "금요일",
      "토요일",
      "일요일",
    ];
    return values[weekday - 1];
  }
}

class _MonthlyPreviewCard extends StatefulWidget {
  const _MonthlyPreviewCard({required this.item});

  final _MonthlyRecordPreview item;

  @override
  State<_MonthlyPreviewCard> createState() => _MonthlyPreviewCardState();
}

class _MonthlyPreviewCardState extends State<_MonthlyPreviewCard> {
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
    setState(() {
      _selectedMoreMenuIndex = index;
    });
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) {
      return;
    }
    await action();
  }

  Future<void> _openEditScreen() async {
    final TodayQuestionRecord? record = widget.item.record;
    _dismissMoreMenu();
    if (record == null || !mounted) {
      return;
    }
    await Navigator.of(context).push<TodayQuestionRecord>(
      MaterialPageRoute<TodayQuestionRecord>(
        builder: (_) => TodayQuestionAnswerScreen(editingRecord: record),
      ),
    );
  }

  Future<void> _deleteRecordWithPopup() async {
    final TodayQuestionRecord? record = widget.item.record;
    _dismissMoreMenu();
    if (record == null || !mounted) {
      return;
    }

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
                    backgroundColor: context.appBrandScale.c500,
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
    await TodayQuestionStore.instance.deleteRecord(createdAt: record.createdAt);
  }

  DateTime _baseDate() {
    final _MonthlyRecordPreview item = widget.item;
    final DateTime now = DateTime.now();
    return item.record?.createdAt ??
        DateTime(item.year ?? now.year, item.month ?? now.month, item.day, 12);
  }

  List<AnnualRecordEntry> _buildAnnualEntries() {
    final _MonthlyRecordPreview item = widget.item;
    final DateTime baseDate = _baseDate();
    final Map<int, AnnualRecordEntry> byYear = <int, AnnualRecordEntry>{};

    if (item.body != MyRecordsScreen._unansweredMessage) {
      final String currentDateLabel =
          "${baseDate.year.toString().padLeft(4, "0")}."
          "${baseDate.month.toString().padLeft(2, "0")}."
          "${baseDate.day.toString().padLeft(2, "0")} 기록";
      byYear[baseDate.year] = AnnualRecordEntry(
        year: baseDate.year,
        answer: item.body,
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

  Future<void> _openQuestionHistory(List<AnnualRecordEntry> entries) async {
    final _MonthlyRecordPreview item = widget.item;
    final int baseYear = _baseDate().year;
    final int pastYearCount = entries
        .where((entry) => entry.year < baseYear)
        .length;
    if (pastYearCount == 0) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AnnualRecordScreen(
          question: item.question,
          entries: entries,
          continuousYears: entries.length,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final _MonthlyRecordPreview item = widget.item;
    final BrandScale brand = context.appBrandScale;
    final List<AnnualRecordEntry> annualEntries = _buildAnnualEntries();
    final int baseYear = _baseDate().year;
    final bool hasPastYearRecord = annualEntries.any(
      (AnnualRecordEntry entry) => entry.year < baseYear,
    );
    return SizedBox(
      width: _MonthlyPreviewStripState._cardWidth,
      height: 458,
      child: Stack(
        children: <Widget>[
          Container(
            width: _MonthlyPreviewStripState._cardWidth,
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
                          onPressed: hasPastYearRecord
                              ? () => _openQuestionHistory(annualEntries)
                              : null,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints.tightFor(
                            width: 24,
                            height: 24,
                          ),
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            Icons.history,
                            size: 24,
                            color: hasPastYearRecord
                                ? brand.c500
                                : AppNeutralColors.grey300,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            item.date,
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
                            onPressed: _toggleMoreMenu,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints.tightFor(
                              width: 24,
                              height: 24,
                            ),
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(
                              Icons.more_horiz,
                              size: 24,
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
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.s16),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppNeutralColors.grey50),
                    ),
                  ),
                  child: Text(
                    item.question,
                    textAlign: TextAlign.center,
                    style: AppTypography.headingMediumExtraBold.copyWith(
                      color: AppNeutralColors.grey900,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s16),
                Expanded(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      item.body,
                      textAlign: TextAlign.left,
                      style: AppTypography.bodyLargeRegular.copyWith(
                        color: AppNeutralColors.grey800,
                      ),
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                if (item.tags.isNotEmpty)
                  SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: item.tags
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
                                    style: AppTypography.buttonSmall.copyWith(
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
                if (item.tags.isNotEmpty)
                  const SizedBox(height: AppSpacing.s16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox.shrink(),
                ),
              ],
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
          if (_showMoreMenu)
            Positioned(
              top: 80,
              right: 0,
              child: AppDropdownMenu(
                size: AppDropdownMenuSize.lg,
                items: <AppDropdownItem>[
                  AppDropdownItem(
                    label: "수정",
                    state: _selectedMoreMenuIndex == 0
                        ? AppDropdownItemState.selected
                        : AppDropdownItemState.defaultState,
                    onTap: () =>
                        _handleMoreMenuTap(index: 0, action: _openEditScreen),
                  ),
                  AppDropdownItem(
                    label: "삭제",
                    state: _selectedMoreMenuIndex == 1
                        ? AppDropdownItemState.selected
                        : AppDropdownItemState.defaultState,
                    onTap: () => _handleMoreMenuTap(
                      index: 1,
                      action: _deleteRecordWithPopup,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _RecordReportHeader extends StatelessWidget {
  const _RecordReportHeader();

  static const String _nickname = "꼬물꼬물물고기뽀글이";

  String _limitedNickname() {
    if (_nickname.length <= 10) {
      return _nickname;
    }
    return _nickname.substring(0, 10);
  }

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    final String nickname = _limitedNickname();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              nickname,
              style: AppTypography.headingLarge.copyWith(color: brand.c500),
            ),
            Text(
              "님의",
              style: AppTypography.headingLarge.copyWith(
                color: AppNeutralColors.grey900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          "기록리포트",
          style: AppTypography.headingLarge.copyWith(
            color: AppNeutralColors.grey900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "그동안 기록한 내용을 요약해 보여드립니다.",
          style: AppTypography.bodySmallMedium.copyWith(
            color: AppNeutralColors.grey400,
          ),
        ),
      ],
    );
  }
}

class _RecordHeroDecor extends StatelessWidget {
  const _RecordHeroDecor();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 300,
      child: Align(
        alignment: Alignment.centerRight,
        child: Transform.translate(
          offset: const Offset(40, 0),
          child: SizedBox(
            width: 500,
            height: 300,
            child: Image.asset(
              MyRecordsScreen._recordHeroDecoAsset,
              width: 500,
              height: 300,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard();

  DateTime _dateOnly(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }

  _StreakCardCopy _resolveCopy({
    required int missingDays,
    required int streak,
    required bool hasRecords,
  }) {
    if (!hasRecords) {
      return const _StreakCardCopy(
        title: "설레이는 첫 날!❤️\n함께 기록해볼까요?",
        body: "오늘부터 쌓아가는 하루의 하나 질문으로\n스스로에 대해 알아가봐요!",
      );
    }
    if (missingDays <= 0) {
      return _StreakCardCopy(
        title: "연속 $streak일째\n기록을 완료했어요!🔥",
        body: "어제의 질문도 작성하면 연속 기록을\n이어갈 수 있어요!",
      );
    }
    if (missingDays == 1) {
      return const _StreakCardCopy(
        title: "앗,😮\n어제 질문이 비어 있어요!",
        body: "어제의 질문도 작성하면 연속 기록을\n이어갈 수 있어요!",
      );
    }
    if (missingDays >= 7) {
      return const _StreakCardCopy(
        title: "오늘부터\n새롭게 시작해볼까요?",
        body: "연속 7일 이상 쉬면 연속 기록이 초기화돼요!\n나의 지난 기록에서 질문들을 작성해보세요!",
      );
    }
    if (missingDays >= 5) {
      return const _StreakCardCopy(
        title: "기다렸어요!\n오늘 하루 더 함께 알아가요!",
        body: "연속 7일 이상 쉬면 연속 기록이 초기화돼요!\n나의 지난 기록에서 질문들을 작성해보세요!",
      );
    }
    return _StreakCardCopy(
      title: "최근 $missingDays일 동안\n기록이 없어요!",
      body: "나의 지난 기록에서 그동안 놓친 질문들을 작성하고\n연속 출석을 완료하세요!",
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<TodayQuestionRecord>>(
      valueListenable: TodayQuestionStore.instance,
      builder: (BuildContext context, List<TodayQuestionRecord> records, _) {
        final int streak = TodayQuestionStore.instance.consecutiveRecordDays;
        final DateTime now = _dateOnly(DateTime.now());
        final DateTime? latestDate = records.isEmpty
            ? null
            : _dateOnly(records.first.createdAt);
        final int missingDays = latestDate == null
            ? 0
            : now.difference(latestDate).inDays;
        final _StreakCardCopy copy = _resolveCopy(
          missingDays: missingDays,
          streak: streak,
          hasRecords: records.isNotEmpty,
        );
        final List<bool> weeklyDone = TodayQuestionStore.instance
            .weeklyCompletion(referenceDate: latestDate);
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          decoration: BoxDecoration(
            color: AppNeutralColors.white,
            borderRadius: AppRadius.br16,
            boxShadow: AppElevation.level1,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                copy.title,
                style: AppTypography.headingLarge.copyWith(
                  color: AppNeutralColors.grey900,
                ),
              ),
              const SizedBox(height: AppSpacing.s4),
              Text(
                copy.body,
                style: AppTypography.bodySmallRegular.copyWith(
                  color: AppNeutralColors.grey600,
                ),
              ),
              const SizedBox(height: AppSpacing.s12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  _StreakDay(label: "월", done: weeklyDone[0]),
                  _StreakDay(label: "화", done: weeklyDone[1]),
                  _StreakDay(label: "수", done: weeklyDone[2]),
                  _StreakDay(label: "목", done: weeklyDone[3]),
                  _StreakDay(label: "금", done: weeklyDone[4]),
                  _StreakDay(label: "토", done: weeklyDone[5]),
                  _StreakDay(label: "일", done: weeklyDone[6]),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StreakCardCopy {
  const _StreakCardCopy({required this.title, required this.body});

  final String title;
  final String body;
}

class _StreakDay extends StatelessWidget {
  const _StreakDay({required this.label, required this.done});

  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          label,
          style: AppTypography.bodySmallMedium.copyWith(
            color: AppNeutralColors.grey900,
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done
                ? AppSemanticColors.success500
                : AppNeutralColors.grey100,
            border: done
                ? Border.all(color: AppSemanticColors.success600, width: 1)
                : null,
          ),
          child: done
              ? const Icon(Icons.star, size: 20, color: AppNeutralColors.white)
              : null,
        ),
      ],
    );
  }
}

class _PastRecordsSection extends StatefulWidget {
  const _PastRecordsSection({
    required this.selectedYear,
    required this.selectedMonth,
    required this.minMonth,
    required this.maxMonth,
  });

  final int selectedYear;
  final int selectedMonth;
  final DateTime minMonth;
  final DateTime maxMonth;

  @override
  State<_PastRecordsSection> createState() => _PastRecordsSectionState();
}

class _PastRecordsSectionState extends State<_PastRecordsSection> {
  static const int _pageSize = 5;
  int _visibleCount = _pageSize;

  @override
  void didUpdateWidget(covariant _PastRecordsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedYear != widget.selectedYear ||
        oldWidget.selectedMonth != widget.selectedMonth) {
      _visibleCount = _pageSize;
    }
  }

  void _showMore(int total) {
    final int next = _visibleCount + _pageSize;
    setState(() {
      _visibleCount = next > total ? total : next;
    });
  }

  Future<void> _openPastRecordsScreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _PastRecordsListScreen(
          initialYear: widget.selectedYear,
          initialMonth: widget.selectedMonth,
          minMonth: widget.minMonth,
          maxMonth: widget.maxMonth,
        ),
      ),
    );
  }

  int _lastVisibleDayOfMonth() {
    final DateTime now = DateTime.now();
    if (widget.selectedYear == now.year && widget.selectedMonth == now.month) {
      return now.day;
    }
    return DateTime(widget.selectedYear, widget.selectedMonth + 1, 0).day;
  }

  String _weekdayLabel(DateTime date) {
    const List<String> labels = <String>["월", "화", "수", "목", "금", "토", "일"];
    return labels[date.weekday - 1];
  }

  String _questionForDay(int day) {
    return MyRecordsScreen.questionTextForDay(day);
  }

  @override
  Widget build(BuildContext context) {
    final AppButtonMetrics smallButtonMetrics = AppButtonTokens.metrics(
      AppButtonSize.small,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _openPastRecordsScreen,
                  borderRadius: AppRadius.br8,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.s4,
                    ),
                    child: Text(
                      "나의 지난 기록",
                      style: AppTypography.headingSmall.copyWith(
                        color: AppNeutralColors.grey900,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _openPastRecordsScreen,
                borderRadius: AppRadius.pill,
                child: const Padding(
                  padding: EdgeInsets.all(AppSpacing.s4),
                  child: Icon(
                    Icons.chevron_right,
                    size: 24,
                    color: AppNeutralColors.grey900,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s24),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppNeutralColors.white,
            borderRadius: AppRadius.br16,
            boxShadow: AppElevation.level1,
          ),
          child: ValueListenableBuilder<List<TodayQuestionRecord>>(
            valueListenable: TodayQuestionStore.instance,
            builder:
                (BuildContext context, List<TodayQuestionRecord> records, _) {
                  final int lastDay = _lastVisibleDayOfMonth();
                  final Map<int, TodayQuestionRecord> recordByDay =
                      <int, TodayQuestionRecord>{};
                  for (final TodayQuestionRecord record in records) {
                    if (record.createdAt.year != widget.selectedYear ||
                        record.createdAt.month != widget.selectedMonth) {
                      continue;
                    }
                    recordByDay.putIfAbsent(record.createdAt.day, () => record);
                  }
                  final TodayQuestionRecord? debugMock =
                      MyRecordsScreen.debugMockRecordForMonth(
                        year: widget.selectedYear,
                        month: widget.selectedMonth,
                      );
                  if (debugMock != null) {
                    recordByDay.putIfAbsent(
                      debugMock.createdAt.day,
                      () => debugMock,
                    );
                  }

                  final List<_RecordListItem> monthlyItems =
                      List<_RecordListItem>.generate(lastDay, (int index) {
                        final int day = lastDay - index;
                        return _RecordListItem(
                          day: day.toString().padLeft(2, "0"),
                          weekday: _weekdayLabel(
                            DateTime(
                              widget.selectedYear,
                              widget.selectedMonth,
                              day,
                            ),
                          ),
                          text: _questionForDay(day),
                          isCompleted: recordByDay.containsKey(day),
                        );
                      }, growable: false);

                  final int total = monthlyItems.length;
                  final int visibleCount = _visibleCount > total
                      ? total
                      : _visibleCount;
                  final bool hasMore = visibleCount < total;

                  return Column(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s8,
                          vertical: AppSpacing.s16,
                        ),
                        child: Column(
                          children: <Widget>[
                            for (int i = 0; i < visibleCount; i++)
                              _PastRecordRow(
                                item: monthlyItems[i],
                                isLast: i == visibleCount - 1,
                                onTap: () {
                                  final int day = int.parse(
                                    monthlyItems[i].day,
                                  );
                                  final DateTime selectedDate = DateTime(
                                    widget.selectedYear,
                                    widget.selectedMonth,
                                    day,
                                  );
                                  if (recordByDay.containsKey(day)) {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => MyRecordDetailScreen(
                                          record: recordByDay[day]!,
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => TodayQuestionAnswerScreen(
                                        initialDate: selectedDate,
                                        headerTitle: "지난 질문",
                                        questionText: monthlyItems[i].text,
                                      ),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                      if (hasMore) ...<Widget>[
                        const SizedBox(height: AppSpacing.s8),
                        Align(
                          alignment: Alignment.center,
                          child: TextButton(
                            onPressed: () => _showMore(total),
                            style: TextButton.styleFrom(
                              minimumSize: Size(0, smallButtonMetrics.height),
                              padding: EdgeInsets.symmetric(
                                horizontal:
                                    smallButtonMetrics.horizontalPadding,
                              ),
                              foregroundColor: AppNeutralColors.grey600,
                              textStyle: smallButtonMetrics.textStyle,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Text("더보기"),
                                SizedBox(width: AppSpacing.s4),
                                Icon(Icons.keyboard_arrow_down, size: 16),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s12),
                      ],
                    ],
                  );
                },
          ),
        ),
      ],
    );
  }
}

class _PastRecordsListScreen extends StatefulWidget {
  const _PastRecordsListScreen({
    required this.initialYear,
    required this.initialMonth,
    required this.minMonth,
    required this.maxMonth,
  });

  final int initialYear;
  final int initialMonth;
  final DateTime minMonth;
  final DateTime maxMonth;

  @override
  State<_PastRecordsListScreen> createState() => _PastRecordsListScreenState();
}

class _PastRecordsListScreenState extends State<_PastRecordsListScreen> {
  late int _selectedYear;
  late int _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialYear;
    _selectedMonth = widget.initialMonth;
  }

  Future<void> _handleTapYearMonth() async {
    final _YearMonthSelection? picked =
        await showGeneralDialog<_YearMonthSelection>(
          context: context,
          barrierColor: const Color(0x40000000),
          barrierDismissible: true,
          barrierLabel: "year-month-picker",
          transitionDuration: const Duration(milliseconds: 120),
          pageBuilder:
              (
                BuildContext context,
                Animation<double> animation,
                Animation<double> secondaryAnimation,
              ) {
                return _YearMonthPickerDialog(
                  initialYear: _selectedYear,
                  initialMonth: _selectedMonth,
                  minMonth: widget.minMonth,
                  maxMonth: widget.maxMonth,
                );
              },
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
                    curve: Curves.easeOut,
                  ),
                  child: child,
                );
              },
        );
    if (!mounted || picked == null) return;
    setState(() {
      _selectedYear = picked.year;
      _selectedMonth = picked.month;
    });
  }

  int _lastVisibleDayOfMonth() {
    final DateTime now = DateTime.now();
    if (_selectedYear == now.year && _selectedMonth == now.month) {
      return now.day;
    }
    return DateTime(_selectedYear, _selectedMonth + 1, 0).day;
  }

  String _weekdayLabel(DateTime date) {
    const List<String> labels = <String>["월", "화", "수", "목", "금", "토", "일"];
    return labels[date.weekday - 1];
  }

  String _questionForDay(int day) {
    return MyRecordsScreen.questionTextForDay(day);
  }

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    return Scaffold(
      backgroundColor: brand.bg,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: ValueListenableBuilder<List<TodayQuestionRecord>>(
              valueListenable: TodayQuestionStore.instance,
              builder: (BuildContext context, List<TodayQuestionRecord> records, _) {
                final int lastDay = _lastVisibleDayOfMonth();
                final Map<int, TodayQuestionRecord> recordByDay =
                    <int, TodayQuestionRecord>{};
                for (final TodayQuestionRecord record in records) {
                  if (record.createdAt.year != _selectedYear ||
                      record.createdAt.month != _selectedMonth) {
                    continue;
                  }
                  recordByDay.putIfAbsent(record.createdAt.day, () => record);
                }
                final TodayQuestionRecord? debugMock =
                    MyRecordsScreen.debugMockRecordForMonth(
                      year: _selectedYear,
                      month: _selectedMonth,
                    );
                if (debugMock != null) {
                  recordByDay.putIfAbsent(
                    debugMock.createdAt.day,
                    () => debugMock,
                  );
                }

                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.s20,
                    49 + AppSpacing.s20,
                    AppSpacing.s20,
                    AppNavigationBar.totalHeight(context) + AppSpacing.s20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: IconButton(
                              onPressed: () => Navigator.of(context).maybePop(),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints.tightFor(
                                width: 24,
                                height: 24,
                              ),
                              icon: const Icon(
                                Icons.arrow_back,
                                color: AppNeutralColors.grey900,
                                size: 24,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              "나의 지난기록",
                              textAlign: TextAlign.center,
                              style: AppTypography.headingXSmall.copyWith(
                                color: AppNeutralColors.grey900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 24, height: 24),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s24),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _handleTapYearMonth,
                          borderRadius: AppRadius.br8,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.s12,
                              vertical: AppSpacing.s8,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Text(
                                  "${_selectedYear.toString().padLeft(4, "0")}."
                                  "${_selectedMonth.toString().padLeft(2, "0")}",
                                  style: AppTypography.headingSmall.copyWith(
                                    color: AppNeutralColors.grey900,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.s4),
                                const Icon(
                                  Icons.keyboard_arrow_down,
                                  size: 20,
                                  color: AppNeutralColors.grey900,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s16),
                      for (int day = 1; day <= lastDay; day++)
                        _PastRecordsListRow(
                          item: _RecordListItem(
                            day: day.toString().padLeft(2, "0"),
                            weekday: _weekdayLabel(
                              DateTime(_selectedYear, _selectedMonth, day),
                            ),
                            text: _questionForDay(day),
                            isCompleted: recordByDay.containsKey(day),
                          ),
                          isLast: day == lastDay,
                          onTap: () {
                            final DateTime selectedDate = DateTime(
                              _selectedYear,
                              _selectedMonth,
                              day,
                            );
                            final String selectedQuestion = _questionForDay(
                              day,
                            );
                            if (recordByDay.containsKey(day)) {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => MyRecordDetailScreen(
                                    record: recordByDay[day]!,
                                  ),
                                ),
                              );
                              return;
                            }
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => TodayQuestionAnswerScreen(
                                  initialDate: selectedDate,
                                  headerTitle: "지난 질문",
                                  questionText: selectedQuestion,
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AppNavigationBar(
              currentIndex: 2,
              onTap: (int index) {
                if (index == 0) {
                  Navigator.of(
                    context,
                  ).popUntil((Route<dynamic> route) => route.isFirst);
                  return;
                }
                if (index == 1) {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const BucketListScreen(),
                    ),
                  );
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
                AppNavigationBarItemData(label: "더보기", icon: Icons.more_horiz),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PastRecordsListRow extends StatelessWidget {
  const _PastRecordsListRow({
    required this.item,
    required this.isLast,
    this.onTap,
  });

  final _RecordListItem item;
  final bool isLast;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color contentColor = item.isCompleted
        ? AppNeutralColors.grey900
        : AppNeutralColors.grey400;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.s16),
          decoration: BoxDecoration(
            border: isLast
                ? null
                : const Border(
                    bottom: BorderSide(
                      color: AppNeutralColors.grey200,
                      width: 0.4,
                    ),
                  ),
          ),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 23,
                child: Column(
                  children: <Widget>[
                    Text(
                      item.day,
                      style: AppTypography.heading2XSmall.copyWith(
                        color: contentColor,
                      ),
                    ),
                    Text(
                      item.weekday,
                      style: AppTypography.captionSmall.copyWith(
                        color: contentColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s20),
              Expanded(
                child: Text(
                  item.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMediumMedium.copyWith(
                    color: contentColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PastRecordRow extends StatelessWidget {
  const _PastRecordRow({required this.item, required this.isLast, this.onTap});

  final _RecordListItem item;
  final bool isLast;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color contentColor = item.isCompleted
        ? AppNeutralColors.grey900
        : AppNeutralColors.grey400;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.s16),
          decoration: BoxDecoration(
            border: isLast
                ? null
                : const Border(
                    bottom: BorderSide(
                      color: AppNeutralColors.grey200,
                      width: 0.4,
                    ),
                  ),
          ),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 23,
                child: Column(
                  children: <Widget>[
                    Text(
                      item.day,
                      style: AppTypography.heading2XSmall.copyWith(
                        color: contentColor,
                      ),
                    ),
                    Text(
                      item.weekday,
                      style: AppTypography.captionSmall.copyWith(
                        color: contentColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s20),
              Expanded(
                child: Text(
                  item.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMediumMedium.copyWith(
                    color: contentColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthReportSection extends StatelessWidget {
  const _MonthReportSection({
    required this.selectedYear,
    required this.selectedMonth,
  });

  final int selectedYear;
  final int selectedMonth;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          "$selectedMonth월 리포트",
          style: AppTypography.headingSmall.copyWith(
            color: AppNeutralColors.grey900,
          ),
        ),
        const SizedBox(height: AppSpacing.s24),
        _WeeklyKeywordPieCard(
          selectedYear: selectedYear,
          selectedMonth: selectedMonth,
          title: "최근 7일 키워드",
        ),
        const SizedBox(height: AppSpacing.s32),
        ...MyRecordsScreen._profileItems.map(
          (item) => _ProfileCard(item: item),
        ),
      ],
    );
  }
}

class _WeeklyKeywordPieCard extends StatelessWidget {
  const _WeeklyKeywordPieCard({
    required this.selectedYear,
    required this.selectedMonth,
    required this.title,
  });

  final int selectedYear;
  final int selectedMonth;
  final String title;

  static const List<Color> _sliceColors = <Color>[
    Color(0xFFB6E2FF),
    Color(0xFFD4EEFF),
    Color(0xFFD6E7F3),
    Color(0xFFE8EEF4),
  ];

  static const Set<String> _stopWords = <String>{
    "오늘",
    "이번",
    "그리고",
    "그냥",
    "정말",
    "너무",
    "같은",
    "대한",
    "에서",
    "으로",
    "하다",
    "했다",
    "하고",
    "있다",
    "없다",
    "나는",
    "내가",
    "우리",
  };

  static const List<_KeywordSlice> _sampleSlices = <_KeywordSlice>[
    _KeywordSlice(label: "여행", count: 5, color: Color(0xFFB6E2FF)),
    _KeywordSlice(label: "가족", count: 4, color: Color(0xFFD4EEFF)),
    _KeywordSlice(label: "건강", count: 3, color: Color(0xFFD6E7F3)),
    _KeywordSlice(label: "성장", count: 2, color: Color(0xFFE8EEF4)),
  ];

  List<_KeywordSlice> _buildKeywordSlices(List<TodayQuestionRecord> records) {
    final DateTime monthEnd = DateTime(selectedYear, selectedMonth + 1, 0);
    final DateTime start = monthEnd.subtract(const Duration(days: 6));
    final DateTime end = DateTime(
      monthEnd.year,
      monthEnd.month,
      monthEnd.day,
      23,
      59,
      59,
    );

    final Iterable<TodayQuestionRecord> weeklyRecords = records.where(
      (TodayQuestionRecord item) =>
          !item.createdAt.isBefore(start) && !item.createdAt.isAfter(end),
    );

    final Map<String, int> counter = <String, int>{};
    for (final TodayQuestionRecord record in weeklyRecords) {
      final List<String> bucketKeywords = record.bucketTags.isNotEmpty
          ? record.bucketTags
          : (record.bucketTag == null || record.bucketTag!.trim().isEmpty)
          ? const <String>[]
          : <String>[record.bucketTag!.trim()];

      if (bucketKeywords.isNotEmpty) {
        for (final String keyword in bucketKeywords) {
          final String normalized = keyword.trim();
          if (normalized.isEmpty) continue;
          counter[normalized] = (counter[normalized] ?? 0) + 1;
        }
        continue;
      }

      final Iterable<String> tokens = RegExp(
        r"[가-힣A-Za-z0-9]{2,}",
      ).allMatches(record.answer).map((Match m) => m.group(0) ?? "");
      for (final String token in tokens) {
        final String normalized = token.trim();
        if (normalized.isEmpty || _stopWords.contains(normalized)) {
          continue;
        }
        counter[normalized] = (counter[normalized] ?? 0) + 1;
      }
    }

    final List<MapEntry<String, int>> top = counter.entries.toList()
      ..sort((MapEntry<String, int> a, MapEntry<String, int> b) {
        if (b.value != a.value) return b.value.compareTo(a.value);
        return a.key.compareTo(b.key);
      });
    final List<_KeywordSlice> result = List<_KeywordSlice>.generate(
      top.length > 4 ? 4 : top.length,
      (int index) {
        final MapEntry<String, int> item = top[index];
        return _KeywordSlice(
          label: item.key,
          count: item.value,
          color: _sliceColors[index % _sliceColors.length],
        );
      },
    );

    int sampleIndex = 0;
    while (result.length < 4) {
      final _KeywordSlice sample =
          _sampleSlices[sampleIndex % _sampleSlices.length];
      final bool exists = result.any((item) => item.label == sample.label);
      if (!exists) {
        result.add(
          _KeywordSlice(
            label: sample.label,
            count: sample.count,
            color: _sliceColors[result.length % _sliceColors.length],
          ),
        );
      }
      sampleIndex += 1;
      if (sampleIndex > 10) break;
    }

    if (result.isEmpty) {
      return _sampleSlices;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<TodayQuestionRecord>>(
      valueListenable: TodayQuestionStore.instance,
      builder: (BuildContext context, List<TodayQuestionRecord> records, _) {
        final List<_KeywordSlice> slices = _buildKeywordSlices(records);
        final int total = slices.fold(
          0,
          (int acc, _KeywordSlice item) => acc + item.count,
        );

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppNeutralColors.white,
            borderRadius: AppRadius.br16,
            boxShadow: AppElevation.level1,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: AppTypography.headingXSmall.copyWith(
                  color: AppNeutralColors.grey900,
                ),
              ),
              const SizedBox(height: AppSpacing.s40),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.s40),
                child: Center(
                  child: SizedBox(
                    width: 168,
                    height: 168,
                    child: CustomPaint(
                      size: const Size(168, 168),
                      painter: _KeywordPieChartPainter(slices: slices),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s40),
              Column(
                children: slices
                    .map((_KeywordSlice slice) {
                      final String ratio = ((slice.count / total) * 100)
                          .toStringAsFixed(0);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.s8),
                        child: Row(
                          children: <Widget>[
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: slice.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.s8),
                            Expanded(
                              child: Text(
                                slice.label,
                                style: AppTypography.bodyMediumRegular.copyWith(
                                  color: AppNeutralColors.grey900,
                                ),
                              ),
                            ),
                            Text(
                              "$ratio% (${slice.count})",
                              style: AppTypography.bodySmallRegular.copyWith(
                                color: AppNeutralColors.grey600,
                              ),
                            ),
                          ],
                        ),
                      );
                    })
                    .toList(growable: false),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _KeywordSlice {
  const _KeywordSlice({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;
}

class _KeywordPieChartPainter extends CustomPainter {
  const _KeywordPieChartPainter({required this.slices});

  final List<_KeywordSlice> slices;

  @override
  void paint(Canvas canvas, Size size) {
    final int total = slices.fold(
      0,
      (int acc, _KeywordSlice e) => acc + e.count,
    );
    if (total == 0) return;

    final double strokeWidth = 60;
    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final Offset center = Offset(size.width / 2, size.height / 2);
    final double labelRadius = (size.width / 2);
    double startAngle = -math.pi / 2;
    for (final _KeywordSlice slice in slices) {
      final double sweep = (slice.count / total) * math.pi * 2;
      paint.color = slice.color;
      canvas.drawArc(rect, startAngle, sweep, false, paint);

      final double labelAngle = startAngle + (sweep / 2);
      final Offset labelOffset = Offset(
        center.dx + math.cos(labelAngle) * labelRadius,
        center.dy + math.sin(labelAngle) * labelRadius,
      );
      final TextPainter labelPainter = TextPainter(
        text: TextSpan(
          text: slice.label,
          style: AppTypography.captionSmall.copyWith(
            color: AppNeutralColors.grey400,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();
      labelPainter.paint(
        canvas,
        Offset(
          labelOffset.dx - (labelPainter.width / 2),
          labelOffset.dy - (labelPainter.height / 2),
        ),
      );

      startAngle += sweep;
    }

    final Paint holePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = AppNeutralColors.white;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      (size.width / 2) - (strokeWidth / 2),
      holePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _KeywordPieChartPainter oldDelegate) {
    if (oldDelegate.slices.length != slices.length) return true;
    for (int i = 0; i < slices.length; i++) {
      final _KeywordSlice a = slices[i];
      final _KeywordSlice b = oldDelegate.slices[i];
      if (a.label != b.label || a.count != b.count || a.color != b.color) {
        return true;
      }
    }
    return false;
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.item});

  final _ProfileCardItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.s32),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppNeutralColors.white,
        borderRadius: AppRadius.br16,
        boxShadow: AppElevation.level1,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: context.appBrandScale.c100,
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              item.iconAsset,
              width: 50,
              height: 50,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: AppSpacing.s20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.title,
                  style: AppTypography.headingXSmall.copyWith(
                    color: AppNeutralColors.grey900,
                  ),
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  item.body,
                  style: AppTypography.bodyMediumRegular.copyWith(
                    color: AppNeutralColors.grey900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlyRecordPreview {
  const _MonthlyRecordPreview({
    required this.day,
    required this.date,
    required this.question,
    required this.body,
    required this.tags,
    this.record,
    this.year,
    this.month,
  });

  final int day;
  final String date;
  final String question;
  final String body;
  final List<String> tags;
  final TodayQuestionRecord? record;
  final int? year;
  final int? month;
}

class _RecordListItem {
  const _RecordListItem({
    required this.day,
    required this.weekday,
    required this.text,
    required this.isCompleted,
  });

  final String day;
  final String weekday;
  final String text;
  final bool isCompleted;
}

class _ProfileCardItem {
  const _ProfileCardItem({
    required this.iconAsset,
    required this.title,
    required this.body,
  });

  final String iconAsset;
  final String title;
  final String body;
}

class _YearMonthSelection {
  const _YearMonthSelection({required this.year, required this.month});

  final int year;
  final int month;
}

class _YearMonthPickerDialog extends StatefulWidget {
  const _YearMonthPickerDialog({
    required this.initialYear,
    required this.initialMonth,
    required this.minMonth,
    required this.maxMonth,
  });

  final int initialYear;
  final int initialMonth;
  final DateTime minMonth;
  final DateTime maxMonth;

  @override
  State<_YearMonthPickerDialog> createState() => _YearMonthPickerDialogState();
}

class _YearMonthPickerDialogState extends State<_YearMonthPickerDialog> {
  late int _selectedYear;
  late int _selectedMonth;
  late FixedExtentScrollController _yearController;
  late FixedExtentScrollController _monthController;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialYear;
    _selectedMonth = widget.initialMonth;
    _yearController = FixedExtentScrollController(
      initialItem: _yearValues.indexOf(_selectedYear),
    );
    _monthController = FixedExtentScrollController(
      initialItem: _monthValuesForYear(_selectedYear).indexOf(_selectedMonth),
    );
  }

  @override
  void dispose() {
    _yearController.dispose();
    _monthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<int> years = _yearValues;
    final List<int> months = _monthValuesForYear(_selectedYear);

    return Material(
      type: MaterialType.transparency,
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 156),
          child: Container(
            width: 350,
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            decoration: BoxDecoration(
              color: AppNeutralColors.white,
              borderRadius: AppRadius.br24,
              boxShadow: AppElevation.level3,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  "$_selectedYear년 $_selectedMonth월",
                  textAlign: TextAlign.center,
                  style: AppTypography.heading2XSmall.copyWith(
                    color: AppNeutralColors.grey900,
                  ),
                ),
                const SizedBox(height: AppSpacing.s24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    _WheelPickerColumn<int>(
                      width: 86,
                      itemExtent: 40,
                      controller: _yearController,
                      values: years,
                      selectedValue: _selectedYear,
                      labelBuilder: (int value) => "$value년",
                      onSelectedItemChanged: (int value) {
                        setState(() {
                          _selectedYear = value;
                          final List<int> nextMonths = _monthValuesForYear(
                            _selectedYear,
                          );
                          if (!nextMonths.contains(_selectedMonth)) {
                            _selectedMonth = nextMonths.first;
                          }
                          _monthController.dispose();
                          _monthController = FixedExtentScrollController(
                            initialItem: nextMonths.indexOf(_selectedMonth),
                          );
                        });
                      },
                    ),
                    const SizedBox(width: 44),
                    _WheelPickerColumn<int>(
                      width: 48,
                      itemExtent: 40,
                      controller: _monthController,
                      values: months,
                      selectedValue: _selectedMonth,
                      labelBuilder: (int value) => "$value월",
                      onSelectedItemChanged: (int value) {
                        setState(() {
                          _selectedMonth = value;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        "닫기",
                        style: AppTypography.buttonLarge.copyWith(
                          color: AppNeutralColors.grey500,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s16),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(
                          _YearMonthSelection(
                            year: _selectedYear,
                            month: _selectedMonth,
                          ),
                        );
                      },
                      child: Text(
                        "확인",
                        style: AppTypography.buttonLarge.copyWith(
                          color: context.appBrandScale.c500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<int> get _yearValues {
    return List<int>.generate(
      widget.maxMonth.year - widget.minMonth.year + 1,
      (int index) => widget.minMonth.year + index,
      growable: false,
    );
  }

  List<int> _monthValuesForYear(int year) {
    int start = 1;
    int end = 12;
    if (year == widget.minMonth.year) {
      start = widget.minMonth.month;
    }
    if (year == widget.maxMonth.year) {
      end = widget.maxMonth.month;
    }
    return List<int>.generate(end - start + 1, (int index) => start + index);
  }
}

class _WheelPickerColumn<T> extends StatelessWidget {
  const _WheelPickerColumn({
    required this.width,
    required this.itemExtent,
    required this.controller,
    required this.values,
    required this.selectedValue,
    required this.labelBuilder,
    required this.onSelectedItemChanged,
  });

  final double width;
  final double itemExtent;
  final FixedExtentScrollController controller;
  final List<T> values;
  final T selectedValue;
  final String Function(T value) labelBuilder;
  final ValueChanged<T> onSelectedItemChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: itemExtent * 5,
      child: Stack(
        children: <Widget>[
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                height: itemExtent * 1.2,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[AppNeutralColors.white, Color(0x00FFFFFF)],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                height: itemExtent * 1.2,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[Color(0x00FFFFFF), AppNeutralColors.white],
                  ),
                ),
              ),
            ),
          ),
          ListWheelScrollView.useDelegate(
            controller: controller,
            physics: const FixedExtentScrollPhysics(),
            itemExtent: itemExtent,
            perspective: 0.003,
            diameterRatio: 4.5,
            onSelectedItemChanged: (int index) {
              onSelectedItemChanged(values[index]);
            },
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: values.length,
              builder: (BuildContext context, int index) {
                if (index < 0 || index >= values.length) return null;
                final T value = values[index];
                final bool selected = value == selectedValue;
                return Center(
                  child: Text(
                    labelBuilder(value),
                    textAlign: TextAlign.center,
                    style: AppTypography.headingLarge.copyWith(
                      color: selected
                          ? AppNeutralColors.grey900
                          : AppNeutralColors.grey200,
                    ),
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
