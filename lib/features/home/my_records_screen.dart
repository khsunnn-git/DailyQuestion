import "dart:async";

import "package:cloud_firestore/cloud_firestore.dart";
import "package:flutter/gestures.dart";
import "package:flutter/material.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../../core/kst_date_time.dart";
import "../../design_system/design_system.dart";
import "../bucket/bucket_list_screen.dart";
import "ai_report_period_defaults.dart";
import "my_records_visibility.dart";
import "../navigation/main_tab_shell.dart";
import "../profile/user_profile_events.dart";
import "../profile/user_profile_prefs.dart";
import "home_character_assets.dart";
import "home_fish_growth.dart";
import "home_screen.dart";
import "home_theme_progression.dart";
import "../more/more_settings_screen.dart";
import "../question/today_question_answer_screen.dart";
import "../question/today_question_store.dart";
import "../report/ai_report_cache_store.dart";
import "../report/ai_report_timeline.dart";
import "../report/period_report_aggregation_service.dart";
import "../report/report_api_client.dart";
import "../report/report_aggregation_service.dart";
import "../report/report_models.dart";
import "annual_record_screen.dart";
import "my_record_detail_screen.dart";

class MyRecordsScreen extends StatefulWidget {
  const MyRecordsScreen({super.key, this.showNavigationBar = true});

  final bool showNavigationBar;

  static const String _recordHeroDecoAsset =
      "assets/images/record/my_record_hero_deco.webp";
  static const String _profileBucketlistAsset =
      "assets/images/record/profile_bucketlist.webp";
  static const String _profileInsightAsset =
      "assets/images/record/profile_insight.webp";
  static const String _profileRecordPatternAsset =
      "assets/images/record/profile_record_pattern.webp";

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

  static int lastVisibleDayOfMonth({
    required int year,
    required int month,
    required bool hasRecordForToday,
  }) {
    final DateTime now = DateTime.now();
    final bool isCurrentMonth = year == now.year && month == now.month;
    if (!isCurrentMonth) {
      return DateTime(year, month + 1, 0).day;
    }
    return now.day;
  }

  static int firstVisibleDayOfMonth({
    required int year,
    required int month,
    DateTime? installDate,
  }) {
    if (installDate == null) {
      return 1;
    }
    if (installDate.year == year && installDate.month == month) {
      return installDate.day;
    }
    return 1;
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

  @override
  State<MyRecordsScreen> createState() => _MyRecordsScreenState();
}

class _MyRecordsScreenState extends State<MyRecordsScreen> {
  static const String _installMonthKey = "my_records_install_month";
  static const String _installDateKey = "my_records_install_date";
  static const String _installDateSchemaVersionKey =
      "my_records_install_date_schema_version";
  static const int _installDateSchemaVersion = 1;
  static const double _bottomShadowBuffer = 8;

  late int _selectedYear;
  late int _selectedMonth;
  late DateTime _maxMonth;
  DateTime? _installMonth;
  DateTime? _installDate;
  String _nickname = "{닉네임}";

  @override
  void initState() {
    super.initState();
    final DateTime now = DateTime.now();
    _selectedYear = now.year;
    _selectedMonth = now.month;
    _maxMonth = DateTime(now.year, now.month);
    TodayQuestionStore.instance.addListener(_handleRecordsChanged);
    UserProfileEvents.nicknameRevision.addListener(_handleNicknameChanged);
    _loadInstallMonth();
    _loadNickname();
  }

  @override
  void dispose() {
    TodayQuestionStore.instance.removeListener(_handleRecordsChanged);
    UserProfileEvents.nicknameRevision.removeListener(_handleNicknameChanged);
    super.dispose();
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
                      AppNavigationBar.totalHeight(context) +
                      AppSpacing.s32 +
                      _bottomShadowBuffer,
                ),
                child: Column(
                  children: <Widget>[
                    _TopMainPanel(
                      brand: brand,
                      selectedYear: _selectedYear,
                      selectedMonth: _selectedMonth,
                      installDate: _installDate,
                      onTapYearMonth: _handleTapYearMonth,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _RecordReportHeader(nickname: _nickname),
                          const SizedBox(height: AppSpacing.s32),
                          _RecordHeroDecor(brand: brand),
                          const SizedBox(height: AppSpacing.s32),
                          const _StreakCard(),
                          const SizedBox(height: AppSpacing.s32),
                          _PastRecordsSection(
                            selectedYear: _selectedYear,
                            selectedMonth: _selectedMonth,
                            installDate: _installDate,
                            minMonth: _installMonth ?? _maxMonth,
                            maxMonth: _maxMonth,
                          ),
                          const SizedBox(height: AppSpacing.s32),
                          _AiReportEntryCard(
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
            if (widget.showNavigationBar)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: AppNavigationBar(
                  currentIndex: 2,
                  onTap: (int index) {
                    if (index == 2) {
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
    final DateTime now = DateTime.now();
    final int schemaVersion = prefs.getInt(_installDateSchemaVersionKey) ?? 0;
    int? savedMillis = prefs.getInt(_installDateKey);
    if (schemaVersion < _installDateSchemaVersion || savedMillis == null) {
      savedMillis = DateTime(
        now.year,
        now.month,
        now.day,
      ).millisecondsSinceEpoch;
      await prefs.setInt(_installDateKey, savedMillis);
      await prefs.setInt(
        _installDateSchemaVersionKey,
        _installDateSchemaVersion,
      );
    }
    final DateTime storedDate = DateTime.fromMillisecondsSinceEpoch(
      savedMillis,
    );
    final DateTime installDate = DateTime(
      storedDate.year,
      storedDate.month,
      storedDate.day,
    );
    final DateTime resolvedInstallDate =
        resolveMyRecordsVisibleStartDate(
          storedInstallDate: installDate,
          records: TodayQuestionStore.instance.value,
        ) ??
        installDate;
    final DateTime installMonth = _monthOnly(resolvedInstallDate);
    await _persistInstallDate(
      prefs: prefs,
      installDate: resolvedInstallDate,
      installMonth: installMonth,
    );
    if (!mounted) return;
    setState(() {
      _installDate = resolvedInstallDate;
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

  void _handleRecordsChanged() {
    unawaited(_syncVisibleStartDateWithRecords());
  }

  void _handleNicknameChanged() {
    unawaited(_loadNickname());
  }

  Future<void> _syncVisibleStartDateWithRecords() async {
    final DateTime? nextInstallDate = resolveMyRecordsVisibleStartDate(
      storedInstallDate: _installDate,
      records: TodayQuestionStore.instance.value,
    );
    if (nextInstallDate == null) {
      return;
    }
    final DateTime normalized = DateTime(
      nextInstallDate.year,
      nextInstallDate.month,
      nextInstallDate.day,
    );
    if (_installDate != null &&
        normalized.millisecondsSinceEpoch ==
            _installDate!.millisecondsSinceEpoch) {
      return;
    }

    final DateTime installMonth = _monthOnly(normalized);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await _persistInstallDate(
      prefs: prefs,
      installDate: normalized,
      installMonth: installMonth,
    );

    if (!mounted) {
      return;
    }
    setState(() {
      _installDate = normalized;
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

  Future<void> _loadNickname() async {
    final String? saved = await UserProfilePrefs.getNickname();
    if (!mounted) {
      return;
    }
    final String trimmed = saved?.trim() ?? "";
    setState(() {
      _nickname = trimmed.isEmpty ? "{닉네임}" : trimmed;
    });
  }

  DateTime _monthOnly(DateTime value) => DateTime(value.year, value.month);

  Future<void> _persistInstallDate({
    required SharedPreferences prefs,
    required DateTime installDate,
    required DateTime installMonth,
  }) async {
    await prefs.setInt(_installDateKey, installDate.millisecondsSinceEpoch);
    await prefs.setInt(_installMonthKey, installMonth.millisecondsSinceEpoch);
    await prefs.setInt(_installDateSchemaVersionKey, _installDateSchemaVersion);
  }

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
    required this.installDate,
    required this.onTapYearMonth,
  });

  final BrandScale brand;
  final int selectedYear;
  final int selectedMonth;
  final DateTime? installDate;
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
                  const SizedBox(width: 24, height: 24),
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
            installDate: installDate,
          ),
        ],
      ),
    );
  }
}

class _PastQuestionDb {
  static final Map<String, String> _questionCache = <String, String>{};
  static final Map<String, Future<Map<int, String>>> _monthLoadCache =
      <String, Future<Map<int, String>>>{};

  static Future<Map<int, String>> loadMonthQuestions({
    required int year,
    required int month,
    required int lastDay,
  }) {
    final String monthKey =
        "$year-${month.toString().padLeft(2, "0")}-$lastDay";
    return _monthLoadCache.putIfAbsent(monthKey, () async {
      final Map<int, String> questionsByDay = <int, String>{};
      for (int day = 1; day <= lastDay; day++) {
        final DateTime targetDate = DateTime(year, month, day);
        final String? question = await _fetchQuestionForDate(targetDate);
        if (question == null || question.trim().isEmpty) {
          continue;
        }
        questionsByDay[day] = question.trim();
      }
      return questionsByDay;
    });
  }

  static String resolveQuestion({
    required int day,
    required Map<int, String> questionsByDay,
    TodayQuestionRecord? record,
  }) {
    final String? recordQuestion = record?.questionText?.trim();
    if (recordQuestion != null && recordQuestion.isNotEmpty) {
      return recordQuestion;
    }
    final String? dbQuestion = questionsByDay[day]?.trim();
    if (dbQuestion != null && dbQuestion.isNotEmpty) {
      return dbQuestion;
    }
    return MyRecordsScreen.questionTextForDay(day);
  }

  static Future<String?> _fetchQuestionForDate(DateTime date) async {
    final int dayOfYear = _dayOfYear(date);
    final String cacheKey = _cacheKey(year: date.year, dayOfYear: dayOfYear);
    final String? cached = _questionCache[cacheKey];
    if (cached != null) {
      return cached;
    }

    try {
      final CollectionReference<Map<String, dynamic>> ref = FirebaseFirestore
          .instance
          .collection("daily_questions");

      final List<String> docIds = <String>[
        "$dayOfYear",
        dayOfYear.toString().padLeft(3, "0"),
      ];
      for (final String id in docIds) {
        final DocumentSnapshot<Map<String, dynamic>> snapshot = await ref
            .doc(id)
            .get();
        final String? base = _extractBaseQuestion(snapshot.data());
        if (base != null) {
          _questionCache[cacheKey] = base;
          return base;
        }
      }

      final QuerySnapshot<Map<String, dynamic>> query = await ref
          .where("dayOfYear", isEqualTo: dayOfYear)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        final String? base = _extractBaseQuestion(query.docs.first.data());
        if (base != null) {
          _questionCache[cacheKey] = base;
          return base;
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  static String? _extractBaseQuestion(Map<String, dynamic>? data) {
    if (data == null) {
      return null;
    }
    final String? base = (data["base"] as String?)?.trim();
    if (base == null || base.isEmpty) {
      return null;
    }
    return base;
  }

  static String _cacheKey({required int year, required int dayOfYear}) {
    return "$year-$dayOfYear";
  }

  static int _dayOfYear(DateTime date) {
    return date.difference(DateTime(date.year, 1, 1)).inDays + 1;
  }
}

class _MonthlyPreviewStrip extends StatefulWidget {
  const _MonthlyPreviewStrip({
    required this.selectedYear,
    required this.selectedMonth,
    required this.installDate,
  });

  final int selectedYear;
  final int selectedMonth;
  final DateTime? installDate;

  @override
  State<_MonthlyPreviewStrip> createState() => _MonthlyPreviewStripState();
}

class _MonthlyPreviewStripState extends State<_MonthlyPreviewStrip> {
  static const double _cardWidth = 350;
  static const double _cardHeight = 458;
  static const double _cardGap = 12;
  static const double _cardShadowInset = 8;
  static const double _cardViewportHeight =
      _cardHeight + (_cardShadowInset * 2);
  static const double _lastCardRightAdjust = 6;

  PageController? _pageController;
  bool _didSetInitialPage = false;
  int _currentPage = 0;
  String? _lastMonthRecordSyncKey;

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
            final List<TodayQuestionRecord> monthRecords = records
                .where((TodayQuestionRecord item) {
                  final DateTime displayDate = myRecordsDisplayDate(item);
                  return displayDate.year == widget.selectedYear &&
                      displayDate.month == widget.selectedMonth;
                })
                .toList(growable: false);

            final Map<int, TodayQuestionRecord> recordByDay =
                <int, TodayQuestionRecord>{};
            for (final TodayQuestionRecord item in monthRecords) {
              recordByDay[myRecordsDisplayDate(item).day] = item;
            }
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

            final DateTime now = DateTime.now();
            final bool isCurrentMonth =
                widget.selectedYear == now.year &&
                widget.selectedMonth == now.month;
            final int latestDay = MyRecordsScreen.lastVisibleDayOfMonth(
              year: widget.selectedYear,
              month: widget.selectedMonth,
              hasRecordForToday:
                  isCurrentMonth && recordByDay.containsKey(now.day),
            );
            final int firstDay = MyRecordsScreen.firstVisibleDayOfMonth(
              year: widget.selectedYear,
              month: widget.selectedMonth,
              installDate: widget.installDate,
            );

            if (latestDay <= 0 || firstDay > latestDay) {
              return const SizedBox(height: _cardViewportHeight);
            }
            return FutureBuilder<Map<int, String>>(
              future: _PastQuestionDb.loadMonthQuestions(
                year: widget.selectedYear,
                month: widget.selectedMonth,
                lastDay: latestDay,
              ),
              initialData: const <int, String>{},
              builder:
                  (
                    BuildContext context,
                    AsyncSnapshot<Map<int, String>> questionSnapshot,
                  ) {
                    final Map<int, String> monthQuestions =
                        questionSnapshot.data ?? const <int, String>{};
                    final List<_MonthlyRecordPreview>
                    previews = List<_MonthlyRecordPreview>.generate(
                      latestDay - firstDay + 1,
                      (int index) {
                        final int day = firstDay + index;
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
                            question: _PastQuestionDb.resolveQuestion(
                              day: day,
                              questionsByDay: monthQuestions,
                              record: record,
                            ),
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
                            question: _PastQuestionDb.resolveQuestion(
                              day: day,
                              questionsByDay: monthQuestions,
                              record: seed.record,
                            ),
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
                          question: _PastQuestionDb.resolveQuestion(
                            day: day,
                            questionsByDay: monthQuestions,
                          ),
                          body: MyRecordsScreen._unansweredMessage,
                          tags: const <String>[],
                          year: widget.selectedYear,
                          month: widget.selectedMonth,
                        );
                      },
                      growable: false,
                    );

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      final PageController? controller = _pageController;
                      if (controller == null || !controller.hasClients) {
                        return;
                      }
                      final TodayQuestionRecord? latestMonthRecord =
                          monthRecords.isEmpty ? null : monthRecords.first;
                      final String? syncKey = latestMonthRecord == null
                          ? null
                          : "${widget.selectedYear}-${widget.selectedMonth}"
                                "-${latestMonthRecord.createdAt.millisecondsSinceEpoch}"
                                "-${latestMonthRecord.answer.hashCode}";
                      final bool shouldSyncToRight =
                          !_didSetInitialPage ||
                          _lastMonthRecordSyncKey != syncKey;
                      if (!shouldSyncToRight || previews.isEmpty) {
                        return;
                      }
                      controller.jumpToPage(previews.length - 1);
                      _currentPage = previews.length - 1;
                      _didSetInitialPage = true;
                      _lastMonthRecordSyncKey = syncKey;
                    });

                    return LayoutBuilder(
                      builder:
                          (BuildContext context, BoxConstraints constraints) {
                            final double viewportWidth = constraints.maxWidth;
                            final double viewportFraction =
                                viewportWidth > (_cardWidth + _cardGap)
                                ? (_cardWidth + _cardGap) / viewportWidth
                                : 1.0;
                            _pageController ??= PageController(
                              viewportFraction: viewportFraction,
                            );

                            return SizedBox(
                              height: _cardViewportHeight,
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
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                        final bool isLatestCard =
                                            index == previews.length - 1;
                                        return Align(
                                          alignment: isLatestCard
                                              ? Alignment.centerRight
                                              : Alignment.center,
                                          child: Padding(
                                            padding: EdgeInsets.only(
                                              top: _cardShadowInset,
                                              bottom: _cardShadowInset,
                                              right: isLatestCard
                                                  ? _lastCardRightAdjust
                                                  : 0,
                                            ),
                                            child: _MonthlyPreviewCard(
                                              item: previews[index],
                                            ),
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

  bool get _isEmptyState =>
      widget.item.record == null ||
      widget.item.body == MyRecordsScreen._unansweredMessage;

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
        .where((TodayQuestionRecord record) {
          final DateTime displayDate = myRecordsDisplayDate(record);
          return displayDate.month == baseDate.month &&
              displayDate.day == baseDate.day &&
              displayDate.year <= baseDate.year;
        })
        .toList(growable: false);
    final List<TodayQuestionRecord> mergedSameDay = <TodayQuestionRecord>[
      ...sameDay,
      ...MyRecordsScreen.debugAnnualMockRecords(baseDate: baseDate),
    ];
    for (final TodayQuestionRecord record in mergedSameDay) {
      final DateTime displayDate = myRecordsDisplayDate(record);
      byYear.putIfAbsent(displayDate.year, () {
        final String dateLabel =
            "${displayDate.year.toString().padLeft(4, "0")}."
            "${displayDate.month.toString().padLeft(2, "0")}."
            "${displayDate.day.toString().padLeft(2, "0")} 기록";
        return AnnualRecordEntry(
          year: displayDate.year,
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

  Future<void> _openWriteScreenForEmpty() async {
    if (!mounted) {
      return;
    }
    final _MonthlyRecordPreview item = widget.item;
    final DateTime now = DateTime.now();
    final DateTime selectedDate = DateTime(
      item.year ?? now.year,
      item.month ?? now.month,
      item.day,
    );
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => TodayQuestionAnswerScreen(
          initialDate: selectedDate,
          headerTitle: "지난 질문",
          questionText: item.question,
        ),
      ),
    );
  }

  Future<void> _openDetailFromCard() async {
    if (!mounted) {
      return;
    }
    if (_showMoreMenu) {
      _dismissMoreMenu();
      return;
    }
    final TodayQuestionRecord? record = widget.item.record;
    if (record != null) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => MyRecordDetailScreen(record: record),
        ),
      );
      return;
    }
    await _openWriteScreenForEmpty();
  }

  @override
  Widget build(BuildContext context) {
    final _MonthlyRecordPreview item = widget.item;
    final BrandScale brand = context.appBrandScale;
    final List<AnnualRecordEntry> annualEntries = _buildAnnualEntries();
    final int baseYear = _baseDate().year;
    final bool isEmptyState = _isEmptyState;
    final bool hasPastYearRecord = annualEntries.any(
      (AnnualRecordEntry entry) => entry.year < baseYear,
    );
    return SizedBox(
      width: _MonthlyPreviewStripState._cardWidth,
      height: _MonthlyPreviewStripState._cardHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          GestureDetector(
            onTap: _openDetailFromCard,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: _MonthlyPreviewStripState._cardWidth,
              height: _MonthlyPreviewStripState._cardHeight,
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
                            child: isEmptyState
                                ? const SizedBox.shrink()
                                : IconButton(
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
                  if (!isEmptyState) const SizedBox(height: AppSpacing.s16),
                  if (!isEmptyState)
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
                        item.question,
                        textAlign: TextAlign.center,
                        style: AppTypography.headingMediumExtraBold.copyWith(
                          color: AppNeutralColors.grey900,
                        ),
                      ),
                    ),
                  if (!isEmptyState) const SizedBox(height: AppSpacing.s16),
                  if (isEmptyState)
                    Expanded(
                      child: Column(
                        children: <Widget>[
                          Expanded(
                            child: Center(
                              child: Text(
                                MyRecordsScreen._unansweredMessage,
                                textAlign: TextAlign.center,
                                style: AppTypography.bodyLargeRegular.copyWith(
                                  color: AppNeutralColors.grey300,
                                ),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: OutlinedButton(
                              onPressed: _openWriteScreenForEmpty,
                              style: OutlinedButton.styleFrom(
                                backgroundColor: AppNeutralColors.white,
                                foregroundColor: brand.c400,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.full,
                                  ),
                                ),
                                side: BorderSide(color: brand.c400),
                                minimumSize: const Size(0, 38),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.s16,
                                  vertical: 0,
                                ),
                                textStyle: AppTypography.buttonSmall,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Text(
                                    "질문 열어보기",
                                    style: AppTypography.buttonSmall.copyWith(
                                      color: brand.c400,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.s4),
                                  Icon(
                                    Icons.chevron_right,
                                    size: 16,
                                    color: brand.c400,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (!isEmptyState)
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
                  if (!isEmptyState && item.tags.isNotEmpty)
                    const SizedBox(height: AppSpacing.s16),
                  if (!isEmptyState && item.tags.isNotEmpty)
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
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
          if (_showMoreMenu && !isEmptyState)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _dismissMoreMenu,
                child: const SizedBox.expand(),
              ),
            ),
          if (_showMoreMenu && !isEmptyState)
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
  const _RecordReportHeader({required this.nickname});

  final String nickname;

  String _limitedNickname() {
    if (nickname.length <= 10) {
      return nickname;
    }
    return nickname.substring(0, 10);
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

class _RecordHeroDecor extends StatefulWidget {
  const _RecordHeroDecor({required this.brand});

  final BrandScale brand;

  @override
  State<_RecordHeroDecor> createState() => _RecordHeroDecorState();
}

class _RecordHeroDecorState extends State<_RecordHeroDecor>
    with SingleTickerProviderStateMixin {
  static const double _homeHeroBaseVisualSize = 172;
  static const double _recordHeroVisualScale = 1.14;
  static const double _recordHeroVisualBaseSize =
      _homeHeroBaseVisualSize * _recordHeroVisualScale;

  late final AnimationController _treeController;
  late final Animation<double> _treeSway;

  bool get _isGreenTheme => widget.brand.c500 == AppBrandThemes.green.c500;

  @override
  void initState() {
    super.initState();
    _treeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat(reverse: true);
    _treeSway = Tween<double>(begin: -1, end: 1).animate(
      CurvedAnimation(parent: _treeController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _treeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isGreenTheme) {
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

    return ValueListenableBuilder<List<TodayQuestionRecord>>(
      valueListenable: TodayQuestionStore.instance,
      builder:
          (BuildContext context, List<TodayQuestionRecord> records, Widget? _) {
            final int recordCount = records.length;
            final int growthRecordCount = homeGrowthRecordCountForCharacter(
              characterType: HomeCharacterType.tree,
              totalRecordCount: recordCount,
            );
            final HomeFishGrowthLevel growthLevel =
                homeFishGrowthLevelForRecordCount(growthRecordCount);
            final bool useTreeLeafPulse = _recordHeroTreeUsesLeafPulse(
              growthLevel,
            );
            final double visualSize = _recordHeroVisualSizeForRecordCount(
              growthRecordCount,
              _recordHeroVisualBaseSize,
            );

            return SizedBox(
              width: double.infinity,
              height: 230,
              child: SizedBox(
                width: 350,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: AnimatedBuilder(
                      animation: _treeController,
                      builder: (BuildContext context, Widget? child) {
                        final Widget characterImage = _RecordHeroTreeCharacter(
                          growthLevel: growthLevel,
                          size: visualSize,
                          fallbackFontSize: 52,
                          treeLeafAngle: useTreeLeafPulse
                              ? 0
                              : _treeSway.value *
                                    _recordHeroTreeSwayMaxAngleForLevel(
                                      growthLevel,
                                    ),
                          treeLeafScale: useTreeLeafPulse
                              ? _recordHeroTreeLeafScaleForLevel(
                                  growthLevel,
                                  _treeSway.value,
                                )
                              : 1,
                        );
                        return characterImage;
                      },
                    ),
                  ),
                ),
              ),
            );
          },
    );
  }
}

class _RecordHeroTreeCharacter extends StatelessWidget {
  const _RecordHeroTreeCharacter({
    required this.growthLevel,
    required this.size,
    required this.fallbackFontSize,
    this.treeLeafAngle = 0,
    this.treeLeafScale = 1,
  });

  final HomeFishGrowthLevel growthLevel;
  final double size;
  final double fallbackFontSize;
  final double treeLeafAngle;
  final double treeLeafScale;

  @override
  Widget build(BuildContext context) {
    final _RecordSplitTreeAssetConfig splitTreeConfig = switch (growthLevel) {
      HomeFishGrowthLevel.level1 => _RecordSplitTreeAssetConfig(
        baseAssetPath: HomeCharacterAssets.treeLevel1Base,
        leafAssetPath: HomeCharacterAssets.treeLevel1Leaf,
        leafYOffsetFactor: 0.02,
        leafRotationAlignment: const Alignment(0.0, 0.36),
        leafScaleAlignment: const Alignment(0.0, 0.36),
        leafScaleCompensationFactor: 0,
      ),
      HomeFishGrowthLevel.level2 => _RecordSplitTreeAssetConfig(
        baseAssetPath: HomeCharacterAssets.treeLevel2Base,
        leafAssetPath: HomeCharacterAssets.treeLevel2Leaf,
        leafYOffsetFactor: 0.008,
        leafRotationAlignment: const Alignment(0.0, 0.42),
        leafScaleAlignment: const Alignment(0.0, 0.42),
        leafScaleCompensationFactor: 0,
      ),
      HomeFishGrowthLevel.level3 => _RecordSplitTreeAssetConfig(
        baseAssetPath: HomeCharacterAssets.treeLevel3Base,
        leafAssetPath: HomeCharacterAssets.treeLevel3Leaf,
        leafYOffsetFactor: 0.008,
        leafRotationAlignment: const Alignment(0.0, 0.5),
        leafScaleAlignment: const Alignment(0.0, 0.5),
        leafScaleCompensationFactor: 0,
      ),
      HomeFishGrowthLevel.level4 => _RecordSplitTreeAssetConfig(
        baseAssetPath: HomeCharacterAssets.treeLevel4Base,
        leafAssetPath: HomeCharacterAssets.treeLevel4Leaf,
        leafYOffsetFactor: 0,
        leafRotationAlignment: const Alignment(0.0, 0.5),
        leafScaleAlignment: const Alignment(0.0, 0.86),
        leafScaleCompensationFactor: 0.7,
      ),
      HomeFishGrowthLevel.level5 => _RecordSplitTreeAssetConfig(
        baseAssetPath: HomeCharacterAssets.treeLevel5Base,
        leafAssetPath: HomeCharacterAssets.treeLevel5Leaf,
        leafYOffsetFactor: 0,
        leafRotationAlignment: const Alignment(0.0, 0.5),
        leafScaleAlignment: const Alignment(0.0, 0.86),
        leafScaleCompensationFactor: 0.7,
      ),
      HomeFishGrowthLevel.level6 => _RecordSplitTreeAssetConfig(
        baseAssetPath: HomeCharacterAssets.treeLevel6Base,
        leafAssetPath: HomeCharacterAssets.treeLevel6Leaf,
        leafYOffsetFactor: 0,
        leafRotationAlignment: const Alignment(0.0, 0.5),
        leafScaleAlignment: const Alignment(0.0, 0.86),
        leafScaleCompensationFactor: 0.7,
      ),
    };
    final double leafYOffset = size * splitTreeConfig.leafYOffsetFactor;
    final double leafPulseCompensation =
        (treeLeafScale - 1) *
        size *
        splitTreeConfig.leafScaleCompensationFactor;
    return SizedBox(
      key: ValueKey<String>(
        "record-tree-split-${growthLevel.name}-${splitTreeConfig.leafAssetPath}",
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
}

class _RecordSplitTreeAssetConfig {
  const _RecordSplitTreeAssetConfig({
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

double _recordHeroVisualSizeForRecordCount(int recordCount, double baseSize) {
  final HomeFishGrowthLevel level = homeFishGrowthLevelForRecordCount(
    recordCount,
  );
  if (level == HomeFishGrowthLevel.level6) {
    return baseSize * 0.9;
  }
  return baseSize;
}

double _recordHeroTreeSwayMaxAngleForLevel(HomeFishGrowthLevel level) {
  return switch (level) {
    HomeFishGrowthLevel.level1 => 0.095,
    HomeFishGrowthLevel.level2 => 0.082,
    HomeFishGrowthLevel.level3 => 0.05,
    HomeFishGrowthLevel.level4 => 0.04,
    HomeFishGrowthLevel.level5 => 0.034,
    HomeFishGrowthLevel.level6 => 0.018,
  };
}

bool _recordHeroTreeUsesLeafPulse(HomeFishGrowthLevel level) {
  return switch (level) {
    HomeFishGrowthLevel.level4 || HomeFishGrowthLevel.level5 => true,
    _ => false,
  };
}

double _recordHeroTreeLeafScaleForLevel(
  HomeFishGrowthLevel level,
  double swayValue,
) {
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
        title: "설레이는 첫 날!\n함께 기록해볼까요?",
        body: "오늘부터 쌓아가는 하루의 하나 질문으로\n스스로에 대해 알아가봐요!",
      );
    }
    if (missingDays <= 0) {
      return _StreakCardCopy(
        title: "벌써 $streak번째 날이에요!\n너무 멋져요!",
        body: "연속기록을 이어가면 \n월말에 리포트를 받아볼 수 있어요!",
      );
    }
    if (missingDays == 1) {
      return const _StreakCardCopy(
        title: "오늘도 내 생각을 적어볼까요?",
        body: "하루하루 당신의 생각을 기다리고 있어요 ✨",
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
        title: "기다려요!\n오늘 하루 더 함께 알아가요!",
        body: "연속 7일 이상 쉬면 연속 기록이 초기화돼요!\n나의 지난 기록에서 질문들을 작성해보세요!",
      );
    }
    return _StreakCardCopy(
      title: "최근 $missingDays일 동안\n기록이 없어요!",
      body: "나의 지난 기록에서 그동안 놓친 질문들을 작성하고\n연속 출석을 완료하세요!",
    );
  }

  List<AppStreakStarState> _buildWeekStates({
    required List<TodayQuestionRecord> records,
  }) {
    final DateTime today = _dateOnly(nowInKst());
    final DateTime monday = today.subtract(Duration(days: today.weekday - 1));
    if (records.isEmpty) {
      return List<AppStreakStarState>.filled(
        7,
        AppStreakStarState.defaultState,
      );
    }

    final Set<DateTime> recordedDays = records
        .map(myRecordsDisplayDate)
        .map(_dateOnly)
        .where((DateTime day) => !day.isBefore(monday) && !day.isAfter(today))
        .toSet();

    return List<AppStreakStarState>.generate(7, (int index) {
      final DateTime day = monday.add(Duration(days: index));
      if (recordedDays.contains(day)) {
        return AppStreakStarState.success;
      }
      if (day.isBefore(today)) {
        return AppStreakStarState.missed;
      }
      return AppStreakStarState.defaultState;
    }, growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<TodayQuestionRecord>>(
      valueListenable: TodayQuestionStore.instance,
      builder: (BuildContext context, List<TodayQuestionRecord> records, _) {
        final int streak = TodayQuestionStore.instance.consecutiveRecordDays;
        final DateTime now = _dateOnly(nowInKst());
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
        final List<AppStreakStarState> weekStates = _buildWeekStates(
          records: records,
        );
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
              AppEmojiText(
                copy.title,
                style: AppTypography.headingLarge.copyWith(
                  color: AppNeutralColors.grey900,
                ),
              ),
              const SizedBox(height: AppSpacing.s4),
              AppEmojiText(
                copy.body,
                style: AppTypography.bodySmallRegular.copyWith(
                  color: AppNeutralColors.grey600,
                ),
              ),
              const SizedBox(height: AppSpacing.s12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  _StreakDay(label: "월", state: weekStates[0]),
                  _StreakDay(label: "화", state: weekStates[1]),
                  _StreakDay(label: "수", state: weekStates[2]),
                  _StreakDay(label: "목", state: weekStates[3]),
                  _StreakDay(label: "금", state: weekStates[4]),
                  _StreakDay(label: "토", state: weekStates[5]),
                  _StreakDay(label: "일", state: weekStates[6]),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

enum _AiReportPeriod { weekly, monthly, quarterly, yearly }

enum _AiSecondaryChipState { selected, defaultState, disabled }

class _AiSecondaryChipData {
  const _AiSecondaryChipData({
    required this.label,
    required this.state,
    this.onTap,
  });

  final String label;
  final _AiSecondaryChipState state;
  final VoidCallback? onTap;
}

class _AiReportEntryCard extends StatefulWidget {
  const _AiReportEntryCard({
    required this.selectedYear,
    required this.selectedMonth,
  });

  final int selectedYear;
  final int selectedMonth;

  @override
  State<_AiReportEntryCard> createState() => _AiReportEntryCardState();
}

class _AiReportEntryCardState extends State<_AiReportEntryCard>
    with WidgetsBindingObserver {
  _AiReportPeriod _selected = _AiReportPeriod.weekly;
  bool _didUserSelectPeriod = false;
  final ReportAggregationService _weeklyAggregationService =
      const ReportAggregationService();
  final PeriodReportAggregationService _periodAggregationService =
      const PeriodReportAggregationService();
  final ReportApiClient _apiClient = ReportApiClient();
  final AiReportCacheStore _cacheStore = const AiReportCacheStore();
  final Map<String, CachedAiReportEntry> _cachedReports =
      <String, CachedAiReportEntry>{};
  final Map<String, _AiGeneratedReportLoadState> _reportStates =
      <String, _AiGeneratedReportLoadState>{};
  String? _selectedWeeklyOptionId;
  int? _selectedMonthlyMonth;
  int? _selectedQuarter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selected = _defaultSelectedPeriod(now: nowInKst());
    unawaited(_bootstrapAiReports());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncDefaultSelectedPeriodIfNeeded();
      setState(() {
        _syncTimelineSelections();
      });
      unawaited(_ensureSelectedReportLoaded());
    }
  }

  @override
  void didUpdateWidget(covariant _AiReportEntryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedYear != widget.selectedYear ||
        oldWidget.selectedMonth != widget.selectedMonth) {
      _didUserSelectPeriod = false;
      setState(() {
        _selected = _defaultSelectedPeriod(now: nowInKst());
        _selectedWeeklyOptionId = null;
        _selectedMonthlyMonth = null;
        _selectedQuarter = null;
        _syncTimelineSelections(force: true);
      });
      unawaited(_ensureSelectedReportLoaded(forceRefresh: true));
    }
  }

  Future<void> _bootstrapAiReports() async {
    await TodayQuestionStore.instance.initialize();
    final Map<String, CachedAiReportEntry> cached = await _cacheStore.readAll();
    if (!mounted) {
      return;
    }
    setState(() {
      _cachedReports
        ..clear()
        ..addAll(cached);
      _reportStates
        ..clear()
        ..addEntries(
          cached.entries.map(
            (MapEntry<String, CachedAiReportEntry> entry) =>
                MapEntry<String, _AiGeneratedReportLoadState>(
                  entry.key,
                  _AiGeneratedReportLoadState.success(
                    report: entry.value.report,
                    payload: entry.value.payload,
                    generatedAt: entry.value.generatedAt,
                  ),
                ),
          ),
        );
      _syncTimelineSelections(force: true);
    });
    await _ensureSelectedReportLoaded(forceRefresh: true);
  }

  _AiReportPeriod _defaultSelectedPeriod({required DateTime now}) {
    return shouldDefaultAiReportToMonthly(
          year: widget.selectedYear,
          month: widget.selectedMonth,
          now: now,
        )
        ? _AiReportPeriod.monthly
        : _AiReportPeriod.weekly;
  }

  void _syncDefaultSelectedPeriodIfNeeded() {
    if (_didUserSelectPeriod) {
      return;
    }
    final _AiReportPeriod next = _defaultSelectedPeriod(now: nowInKst());
    if (next == _selected || !mounted) {
      return;
    }
    setState(() {
      _selected = next;
      _syncTimelineSelections();
    });
  }

  void _handlePeriodTap(_AiReportPeriod period) {
    setState(() {
      _didUserSelectPeriod = true;
      _selected = period;
      _syncTimelineSelections();
    });
    unawaited(_ensureSelectedReportLoaded(forceRefresh: true));
  }

  void _handleSecondaryChipTap(AiReportTimelineOption option) {
    if (!option.enabled) {
      return;
    }
    setState(() {
      switch (_selected) {
        case _AiReportPeriod.weekly:
          _selectedWeeklyOptionId = option.id;
        case _AiReportPeriod.monthly:
          _selectedMonthlyMonth = option.startDate.month;
        case _AiReportPeriod.quarterly:
          _selectedQuarter = _quarterFromMonth(option.startDate.month);
        case _AiReportPeriod.yearly:
          break;
      }
    });
    unawaited(_ensureSelectedReportLoaded(forceRefresh: true));
  }

  DateTime _firstRecordDate() {
    DateTime? earliest;
    for (final TodayQuestionRecord record
        in TodayQuestionStore.instance.value) {
      final DateTime displayDate = myRecordsDisplayDate(record);
      final DateTime normalized = DateTime(
        displayDate.year,
        displayDate.month,
        displayDate.day,
      );
      if (earliest == null || normalized.isBefore(earliest)) {
        earliest = normalized;
      }
    }
    return earliest ?? DateTime(widget.selectedYear, widget.selectedMonth, 1);
  }

  List<AiReportTimelineOption> _weeklyOptions() {
    return buildWeeklyAiReportTimelineOptions(
      year: widget.selectedYear,
      month: widget.selectedMonth,
      now: nowInKst(),
    );
  }

  List<AiReportTimelineOption> _monthlyOptions() {
    return buildMonthlyAiReportTimelineOptions(
      year: widget.selectedYear,
      firstRecordDate: _firstRecordDate(),
      now: nowInKst(),
    );
  }

  List<AiReportTimelineOption> _quarterlyOptions() {
    return buildQuarterlyAiReportTimelineOptions(
      year: widget.selectedYear,
      firstRecordDate: _firstRecordDate(),
      now: nowInKst(),
    );
  }

  AiReportTimelineOption _yearlyOption() {
    return buildYearlyAiReportTimelineOption(
      year: widget.selectedYear,
      now: nowInKst(),
    );
  }

  void _syncTimelineSelections({bool force = false}) {
    final List<AiReportTimelineOption> weeklyOptions = _weeklyOptions();
    final List<AiReportTimelineOption> monthlyOptions = _monthlyOptions();
    final List<AiReportTimelineOption> quarterlyOptions = _quarterlyOptions();

    if (force ||
        !weeklyOptions.any(
          (AiReportTimelineOption option) =>
              option.id == _selectedWeeklyOptionId,
        )) {
      _selectedWeeklyOptionId =
          _defaultWeeklyOption(weeklyOptions)?.id ?? _selectedWeeklyOptionId;
    }

    if (force ||
        !monthlyOptions.any(
          (AiReportTimelineOption option) =>
              option.startDate.month == _selectedMonthlyMonth,
        )) {
      _selectedMonthlyMonth =
          _defaultMonthlyOption(monthlyOptions)?.startDate.month ??
          _selectedMonthlyMonth;
    }

    if (force ||
        !quarterlyOptions.any(
          (AiReportTimelineOption option) =>
              _quarterFromMonth(option.startDate.month) == _selectedQuarter,
        )) {
      _selectedQuarter = _defaultQuarterlyOption(quarterlyOptions) == null
          ? _selectedQuarter
          : _quarterFromMonth(
              _defaultQuarterlyOption(quarterlyOptions)!.startDate.month,
            );
    }
  }

  AiReportTimelineOption? _defaultWeeklyOption(
    List<AiReportTimelineOption> options,
  ) {
    for (int index = options.length - 1; index >= 0; index--) {
      final AiReportTimelineOption option = options[index];
      if (option.enabled) {
        return option;
      }
    }
    return options.isEmpty ? null : options.first;
  }

  AiReportTimelineOption? _defaultMonthlyOption(
    List<AiReportTimelineOption> options,
  ) {
    for (final AiReportTimelineOption option in options) {
      if (option.startDate.month == widget.selectedMonth && option.enabled) {
        return option;
      }
    }
    for (int index = options.length - 1; index >= 0; index--) {
      if (options[index].enabled) {
        return options[index];
      }
    }
    return options.isEmpty ? null : options.first;
  }

  AiReportTimelineOption? _defaultQuarterlyOption(
    List<AiReportTimelineOption> options,
  ) {
    final int selectedQuarter = _quarterFromMonth(widget.selectedMonth);
    for (final AiReportTimelineOption option in options) {
      if (_quarterFromMonth(option.startDate.month) == selectedQuarter &&
          option.enabled) {
        return option;
      }
    }
    for (int index = options.length - 1; index >= 0; index--) {
      if (options[index].enabled) {
        return options[index];
      }
    }
    return options.isEmpty ? null : options.first;
  }

  String _weeklyRangeLabel(DateTime start, DateTime end) {
    final String startMonth = start.month.toString().padLeft(2, "0");
    final String startDay = start.day.toString().padLeft(2, "0");
    final String endMonth = end.month.toString().padLeft(2, "0");
    final String endDay = end.day.toString().padLeft(2, "0");
    return "$startMonth.$startDay - $endMonth.$endDay";
  }

  String _nextGenerationLabel(DateTime dateTime) {
    final List<String> weekdays = <String>["월", "화", "수", "목", "금", "토", "일"];
    final String month = dateTime.month.toString().padLeft(2, "0");
    final String day = dateTime.day.toString().padLeft(2, "0");
    final String weekday = weekdays[dateTime.weekday - 1];
    final String hour = dateTime.hour.toString().padLeft(2, "0");
    final String minute = dateTime.minute.toString().padLeft(2, "0");
    return "$month.$day($weekday) $hour:$minute";
  }

  int _quarterFromMonth(int month) => ((month - 1) ~/ 3) + 1;

  AiReportTimelineOption? _selectedWeeklyOption() {
    for (final AiReportTimelineOption option in _weeklyOptions()) {
      if (option.id == _selectedWeeklyOptionId) {
        return option;
      }
    }
    return _defaultWeeklyOption(_weeklyOptions());
  }

  AiReportTimelineOption? _selectedMonthlyOption() {
    for (final AiReportTimelineOption option in _monthlyOptions()) {
      if (option.startDate.month == _selectedMonthlyMonth) {
        return option;
      }
    }
    return _defaultMonthlyOption(_monthlyOptions());
  }

  AiReportTimelineOption? _selectedQuarterlyOption() {
    for (final AiReportTimelineOption option in _quarterlyOptions()) {
      if (_quarterFromMonth(option.startDate.month) == _selectedQuarter) {
        return option;
      }
    }
    return _defaultQuarterlyOption(_quarterlyOptions());
  }

  AiReportTimelineOption? _selectedTimelineOption() {
    return switch (_selected) {
      _AiReportPeriod.weekly => _selectedWeeklyOption(),
      _AiReportPeriod.monthly => _selectedMonthlyOption(),
      _AiReportPeriod.quarterly => _selectedQuarterlyOption(),
      _AiReportPeriod.yearly => _yearlyOption(),
    };
  }

  _AiReportTarget? _selectedTarget() {
    final AiReportTimelineOption? option = _selectedTimelineOption();
    if (option == null) {
      return null;
    }

    final String summaryTitle = switch (_selected) {
      _AiReportPeriod.weekly =>
        "${_weeklyRangeLabel(option.startDate, option.endDate)} 요약",
      _AiReportPeriod.monthly => "${option.startDate.month}월 요약",
      _AiReportPeriod.quarterly =>
        "${_quarterFromMonth(option.startDate.month)}분기 요약",
      _AiReportPeriod.yearly => "${option.startDate.year}년 요약",
    };

    final String actionTitle = switch (_selected) {
      _AiReportPeriod.yearly => "내년엔 이렇게 해볼까요?",
      _ => "이렇게 해볼까요?",
    };

    return _AiReportTarget(
      cacheKey: option.id,
      period: _selected,
      startDate: option.startDate,
      endDate: option.endDate,
      generatedAt: option.generatedAt,
      summaryTitle: summaryTitle,
      actionTitle: actionTitle,
      enabled: option.enabled,
    );
  }

  Future<void> _ensureSelectedReportLoaded({bool forceRefresh = false}) async {
    final _AiReportTarget? target = _selectedTarget();
    if (target == null || !target.enabled) {
      return;
    }

    final CachedAiReportEntry? cachedEntry = _cachedReports[target.cacheKey];
    final _AiGeneratedReportLoadState current =
        _reportStates[target.cacheKey] ??
        const _AiGeneratedReportLoadState.idle();
    if (!forceRefresh &&
        current.status == _AiGeneratedReportLoadStatus.loading) {
      return;
    }
    if (!forceRefresh &&
        current.status == _AiGeneratedReportLoadStatus.success &&
        !_shouldRefreshStaleAiReport(current.report)) {
      return;
    }

    if (!forceRefresh &&
        cachedEntry != null &&
        !_shouldRefreshStaleAiReport(cachedEntry.report)) {
      setState(() {
        _reportStates[target.cacheKey] = _AiGeneratedReportLoadState.success(
          report: cachedEntry.report,
          payload: cachedEntry.payload,
          generatedAt: cachedEntry.generatedAt,
        );
      });
      return;
    }

    setState(() {
      _reportStates[target.cacheKey] =
          const _AiGeneratedReportLoadState.loading();
    });

    try {
      late final ReportAnalyzePayload payload;
      late final WeeklyAiReport report;

      debugPrint(
        "[ai_report] request api ${target.cacheKey} "
        "period=${target.period.name} force=$forceRefresh",
      );

      switch (target.period) {
        case _AiReportPeriod.weekly:
          final WeeklyAggregationSnapshot snapshot =
              await _weeklyAggregationService.buildWeeklySnapshotForWindow(
                startDate: target.startDate,
                endDate: target.endDate,
              );
          payload = snapshot.payload;
          final WeeklyAiReport fallbackReport = snapshot.recordedDays < 3
              ? _weeklyAggregationService.buildCompactLocalFallbackReport(
                  snapshot,
                )
              : _weeklyAggregationService.buildLocalFallbackReport(snapshot);
          try {
            report = await _fetchWeeklyReport(snapshot);
          } catch (error) {
            debugPrint(
              "[ai_report] weekly api failed; use personalized fallback "
              "${target.cacheKey}: $error",
            );
            report = cachedEntry?.report.isFromOpenAi == true
                ? cachedEntry!.report
                : fallbackReport;
          }
        case _AiReportPeriod.monthly:
        case _AiReportPeriod.quarterly:
        case _AiReportPeriod.yearly:
          final ReportPeriod period = switch (target.period) {
            _AiReportPeriod.monthly => ReportPeriod.monthly,
            _AiReportPeriod.quarterly => ReportPeriod.quarterly,
            _AiReportPeriod.yearly => ReportPeriod.yearly,
            _AiReportPeriod.weekly => throw StateError("weekly not supported"),
          };
          payload = await _periodAggregationService.buildPayloadForSelection(
            period: period,
            year: target.startDate.year,
            month: target.startDate.month,
          );
          final WeeklyAiReport fallbackReport = _periodAggregationService
              .buildLocalFallbackReport(
                payload: payload,
                period: period,
                year: target.startDate.year,
                month: target.startDate.month,
              );
          try {
            report = await _fetchCalendarReport(payload: payload);
          } catch (error) {
            debugPrint(
              "[ai_report] calendar api failed; use personalized fallback "
              "${target.cacheKey}: $error",
            );
            report = cachedEntry?.report.isFromOpenAi == true
                ? cachedEntry!.report
                : fallbackReport;
          }
      }

      final CachedAiReportEntry entry = CachedAiReportEntry(
        cacheKey: target.cacheKey,
        periodKey: target.period.name,
        generatedAt: target.generatedAt,
        startDate: target.startDate,
        endDate: target.endDate,
        payload: payload,
        report: report,
      );
      await _cacheStore.upsert(entry);
      if (!mounted) {
        return;
      }
      setState(() {
        _cachedReports[target.cacheKey] = entry;
        _reportStates[target.cacheKey] = _AiGeneratedReportLoadState.success(
          report: report,
          payload: payload,
          generatedAt: target.generatedAt,
        );
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      if (cachedEntry != null) {
        setState(() {
          _reportStates[target.cacheKey] = _AiGeneratedReportLoadState.success(
            report: cachedEntry.report,
            payload: cachedEntry.payload,
            generatedAt: cachedEntry.generatedAt,
          );
        });
        return;
      }
      setState(() {
        _reportStates[target.cacheKey] =
            const _AiGeneratedReportLoadState.error(
              "실제 AI 분석 리포트가 아직 준비되지 않았어요. 생성 시점 이후 다시 확인해주세요.",
            );
      });
    }
  }

  Future<WeeklyAiReport> _fetchWeeklyReport(
    WeeklyAggregationSnapshot snapshot,
  ) async {
    final WeeklyAiReport report = await _apiClient.analyzeOpenAiOnly(
      snapshot.payload,
    );
    return _weeklyAggregationService.tuneWeeklyReport(
      report: report,
      snapshot: snapshot,
    );
  }

  Future<WeeklyAiReport> _fetchCalendarReport({
    required ReportAnalyzePayload payload,
  }) async {
    return _apiClient.analyzeOpenAiOnly(payload);
  }

  bool _shouldRefreshStaleAiReport(WeeklyAiReport? report) {
    return _apiClient.isConfigured && !(report?.isFromOpenAi ?? false);
  }

  String _scheduleBannerMessage() {
    final AiReportTimelineOption? option = _selectedTimelineOption();
    switch (_selected) {
      case _AiReportPeriod.weekly:
        if (option == null) {
          return "주간 리포트는 매주 일요일 08:00에 반영돼요";
        }
        return "${_weeklyRangeLabel(option.startDate, option.endDate)} 기록은 "
            "${_nextGenerationLabel(option.generatedAt)}에 반영돼요";
      case _AiReportPeriod.monthly:
        return "매월 기록은 매달 말일 08:00에 반영돼요";
      case _AiReportPeriod.quarterly:
        return "매 분기 기록은 분기 말일 8:00에 생성됩니다.";
      case _AiReportPeriod.yearly:
        return "기록은 매년 말일 8:00에 자동생성 됩니다.";
    }
  }

  String _unavailablePeriodMessage(_AiReportPeriod period) {
    switch (period) {
      case _AiReportPeriod.weekly:
        return "주간 리포트는 해당 월에 생성된 주차부터 순서대로 확인할 수 있어요.";
      case _AiReportPeriod.monthly:
        return "월간 리포트는 기록이 쌓인 달의 말일 08:00 이후에 확인할 수 있어요.";
      case _AiReportPeriod.quarterly:
        return "분기 리포트는 3·6·9·12월 말일 08:00 이후에 확인할 수 있어요.";
      case _AiReportPeriod.yearly:
        return "연간 리포트는 12월 말일 08:00 이후에 확인할 수 있어요.";
    }
  }

  List<_AiSecondaryChipData> _secondaryChips() {
    final List<AiReportTimelineOption> options = switch (_selected) {
      _AiReportPeriod.weekly => _weeklyOptions(),
      _AiReportPeriod.monthly => _monthlyOptions(),
      _AiReportPeriod.quarterly => _quarterlyOptions(),
      _AiReportPeriod.yearly => <AiReportTimelineOption>[_yearlyOption()],
    };

    final String? selectedId = _selectedTimelineOption()?.id;
    return options
        .map((AiReportTimelineOption option) {
          return _AiSecondaryChipData(
            label: option.label,
            state: option.id == selectedId
                ? _AiSecondaryChipState.selected
                : option.enabled
                ? _AiSecondaryChipState.defaultState
                : _AiSecondaryChipState.disabled,
            onTap: option.enabled
                ? () => _handleSecondaryChipTap(option)
                : null,
          );
        })
        .toList(growable: false);
  }

  Widget _buildSummaryCard({
    required String title,
    required WeeklyAiReport report,
  }) {
    return _AiReportPreviewCard(
      iconAsset: MyRecordsScreen._profileRecordPatternAsset,
      title: title,
      showAiBadge: report.isFromOpenAi,
      body: AppEmojiText(
        report.summary,
        style: AppTypography.bodyMediumRegular.copyWith(
          color: AppNeutralColors.grey900,
        ),
      ),
    );
  }

  Widget _buildInsightCard(WeeklyAiReport report) {
    final List<String> lines = report.insights.isEmpty
        ? const <String>["아직 인사이트가 없어요."]
        : report.insights;
    return _AiReportPreviewCard(
      iconAsset: MyRecordsScreen._profileInsightAsset,
      title: "인사이트",
      showAiBadge: report.isFromOpenAi,
      body: _AiReportTextGroup(lines: lines),
    );
  }

  Widget _buildActionCard(WeeklyAiReport report) {
    final List<String> lines = report.actions.isEmpty
        ? const <String>["아직 제안이 없어요."]
        : report.actions;
    return _AiReportPreviewCard(
      iconAsset: MyRecordsScreen._profileBucketlistAsset,
      title: _selectedTarget()?.actionTitle ?? "이렇게 해볼까요?",
      showAiBadge: report.isFromOpenAi,
      body: _AiReportTextGroup(lines: lines, bulleted: true),
    );
  }

  Widget _buildSelectedReportContent() {
    final _AiReportTarget? target = _selectedTarget();
    if (target == null) {
      return _AiDataAlert(message: _unavailablePeriodMessage(_selected));
    }

    final _AiGeneratedReportLoadState state =
        _reportStates[target.cacheKey] ??
        const _AiGeneratedReportLoadState.idle();

    if (state.status == _AiGeneratedReportLoadStatus.loading ||
        state.status == _AiGeneratedReportLoadStatus.idle) {
      return const SizedBox(
        width: double.infinity,
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.status == _AiGeneratedReportLoadStatus.error ||
        state.report == null) {
      return _AiDataAlert(
        message: state.errorMessage ?? "AI 리포트를 아직 준비하지 못했어요.",
      );
    }

    final WeeklyAiReport report = state.report!;
    final bool compactWeekly =
        target.period == _AiReportPeriod.weekly && state.isCompact;

    if (compactWeekly) {
      return Column(
        children: <Widget>[
          _buildSummaryCard(title: target.summaryTitle, report: report),
          if (report.actions.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.s24),
            _buildActionCard(report),
          ],
        ],
      );
    }

    return Column(
      children: <Widget>[
        _buildSummaryCard(title: target.summaryTitle, report: report),
        const SizedBox(height: AppSpacing.s24),
        _buildInsightCard(report),
        const SizedBox(height: AppSpacing.s24),
        _buildActionCard(report),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final AiReportTimelineOption? selectedOption = _selectedTimelineOption();
    final bool hasEnabledOption = switch (_selected) {
      _AiReportPeriod.weekly => _weeklyOptions().any(
        (AiReportTimelineOption option) => option.enabled,
      ),
      _AiReportPeriod.monthly => _monthlyOptions().any(
        (AiReportTimelineOption option) => option.enabled,
      ),
      _AiReportPeriod.quarterly => _quarterlyOptions().any(
        (AiReportTimelineOption option) => option.enabled,
      ),
      _AiReportPeriod.yearly => _yearlyOption().enabled,
    };

    final Widget content =
        hasEnabledOption && (selectedOption?.enabled ?? false)
        ? _buildSelectedReportContent()
        : _AiDataAlert(message: _unavailablePeriodMessage(_selected));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          "AI 리포트",
          style: AppTypography.headingSmall.copyWith(
            color: AppNeutralColors.grey900,
          ),
        ),
        const SizedBox(height: AppSpacing.s2),
        Text(
          "주간/월간/분기/연간 기준으로 AI 리포트를 생성해요.",
          style: AppTypography.bodySmallMedium.copyWith(
            color: AppNeutralColors.grey400,
          ),
        ),
        const SizedBox(height: AppSpacing.s24),
        _AiPrimaryTabBar(selected: _selected, onChanged: _handlePeriodTap),
        const SizedBox(height: AppSpacing.s8),
        _AiSecondaryChipRow(chips: _secondaryChips()),
        const SizedBox(height: AppSpacing.s24),
        _AiScheduleBanner(message: _scheduleBannerMessage()),
        const SizedBox(height: AppSpacing.s24),
        content,
      ],
    );
  }
}

class _AiDataAlert extends StatelessWidget {
  const _AiDataAlert({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s20,
        vertical: AppSpacing.s24,
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: AppTypography.bodyMediumRegular.copyWith(
          color: AppNeutralColors.grey500,
        ),
      ),
    );
  }
}

class _AiScheduleBanner extends StatelessWidget {
  const _AiScheduleBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: brand.c100,
        borderRadius: AppRadius.br16,
      ),
      child: Text(
        message,
        style: AppTypography.bodySmallRegular.copyWith(
          color: AppNeutralColors.grey800,
        ),
      ),
    );
  }
}

String _aiReportPeriodLabel(_AiReportPeriod period) {
  return switch (period) {
    _AiReportPeriod.weekly => "주간",
    _AiReportPeriod.monthly => "월간",
    _AiReportPeriod.quarterly => "분기",
    _AiReportPeriod.yearly => "연간",
  };
}

class _AiPrimaryTabBar extends StatelessWidget {
  const _AiPrimaryTabBar({required this.selected, required this.onChanged});

  final _AiReportPeriod selected;
  final ValueChanged<_AiReportPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        border: Border(bottom: AppTabTokens.containerBottomBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: _AiReportPeriod.values
            .map(
              (_AiReportPeriod period) => _AiPrimaryTabButton(
                label: _aiReportPeriodLabel(period),
                selected: selected == period,
                onTap: () => onChanged(period),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _AiPrimaryTabButton extends StatelessWidget {
  const _AiPrimaryTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    final AppTabButtonStyle style = AppTabTokens.style(
      selected ? AppControlState.selected : AppControlState.defaultState,
    );
    final Color textColor = selected ? brand.c500 : style.textColor;
    final Color borderColor = selected ? brand.c500 : style.borderColor;
    return InkWell(
      onTap: onTap,
      child: Container(
        width: AppTabTokens.width,
        padding: style.padding,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: borderColor,
              width: selected
                  ? AppTabTokens.selectedBottomBorderWidth
                  : AppSpacing.s0,
            ),
          ),
        ),
        child: Text(label, style: style.textStyle.copyWith(color: textColor)),
      ),
    );
  }
}

class _AiSecondaryChipRow extends StatelessWidget {
  const _AiSecondaryChipRow({required this.chips});

  final List<_AiSecondaryChipData> chips;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: List<Widget>.generate(chips.length, (int index) {
          return Padding(
            padding: EdgeInsets.only(
              right: index == chips.length - 1 ? AppSpacing.s0 : AppSpacing.s8,
            ),
            child: _AiSecondaryChip(data: chips[index]),
          );
        }),
      ),
    );
  }
}

class _AiSecondaryChip extends StatelessWidget {
  const _AiSecondaryChip({required this.data});

  final _AiSecondaryChipData data;

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    final bool isSelected = data.state == _AiSecondaryChipState.selected;
    final bool isDisabled = data.state == _AiSecondaryChipState.disabled;
    final Color backgroundColor = isSelected
        ? brand.c100
        : isDisabled
        ? AppNeutralColors.grey50
        : AppNeutralColors.white;
    final Color borderColor = isSelected ? brand.c500 : Colors.transparent;
    final Color textColor = isSelected
        ? brand.c500
        : isDisabled
        ? AppNeutralColors.grey200
        : AppNeutralColors.grey600;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.pill,
        onTap: isDisabled ? null : data.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s20,
            vertical: AppSpacing.s6,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: AppRadius.pill,
            border: Border.all(color: borderColor),
            boxShadow: AppElevation.level1,
          ),
          child: Text(
            data.label,
            style: AppTypography.bodySmallSemiBold.copyWith(color: textColor),
          ),
        ),
      ),
    );
  }
}

class _AiReportTextGroup extends StatelessWidget {
  const _AiReportTextGroup({required this.lines, this.bulleted = false});

  final List<String> lines;
  final bool bulleted;

  @override
  Widget build(BuildContext context) {
    final TextStyle style = AppTypography.bodyMediumRegular.copyWith(
      color: AppNeutralColors.grey900,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List<Widget>.generate(lines.length, (int index) {
        final Widget child = bulleted
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text("•", style: style),
                  const SizedBox(width: AppSpacing.s8),
                  Expanded(child: AppEmojiText(lines[index], style: style)),
                ],
              )
            : AppEmojiText(lines[index], style: style);

        return Padding(
          padding: EdgeInsets.only(
            bottom: index == lines.length - 1 ? AppSpacing.s0 : AppSpacing.s4,
          ),
          child: child,
        );
      }),
    );
  }
}

class _AiReportPreviewCard extends StatelessWidget {
  const _AiReportPreviewCard({
    required this.iconAsset,
    required this.title,
    required this.body,
    this.showAiBadge = false,
  });

  final String iconAsset;
  final String title;
  final Widget body;
  final bool showAiBadge;

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s24),
      decoration: BoxDecoration(
        color: AppNeutralColors.white,
        borderRadius: AppRadius.br16,
        boxShadow: AppElevation.level1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: brand.c100,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Image.asset(
                    iconAsset,
                    width: 34,
                    height: 34,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s20),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.headingXSmall.copyWith(
                    color: AppNeutralColors.grey900,
                  ),
                ),
              ),
              if (showAiBadge) const AppAiBadge(),
            ],
          ),
          const SizedBox(height: AppSpacing.s20),
          body,
        ],
      ),
    );
  }
}

enum _AiGeneratedReportLoadStatus { idle, loading, success, error }

class _AiGeneratedReportLoadState {
  const _AiGeneratedReportLoadState({
    required this.status,
    this.report,
    this.payload,
    this.generatedAt,
    this.errorMessage,
  });

  const _AiGeneratedReportLoadState.idle()
    : this(status: _AiGeneratedReportLoadStatus.idle);

  const _AiGeneratedReportLoadState.loading()
    : this(status: _AiGeneratedReportLoadStatus.loading);

  const _AiGeneratedReportLoadState.success({
    required WeeklyAiReport report,
    required ReportAnalyzePayload payload,
    required DateTime generatedAt,
  }) : this(
         status: _AiGeneratedReportLoadStatus.success,
         report: report,
         payload: payload,
         generatedAt: generatedAt,
       );

  const _AiGeneratedReportLoadState.error(String errorMessage)
    : this(
        status: _AiGeneratedReportLoadStatus.error,
        errorMessage: errorMessage,
      );

  final _AiGeneratedReportLoadStatus status;
  final WeeklyAiReport? report;
  final ReportAnalyzePayload? payload;
  final DateTime? generatedAt;
  final String? errorMessage;

  bool get isCompact {
    final ReportAnalyzePayload? currentPayload = payload;
    if (currentPayload == null) {
      return false;
    }
    final int? recordedDays = _metricInt(
      currentPayload.metrics["recorded_days"],
    );
    return (recordedDays ?? currentPayload.days.length) < 3;
  }

  static int? _metricInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.round();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }
}

class _AiReportTarget {
  const _AiReportTarget({
    required this.cacheKey,
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.generatedAt,
    required this.summaryTitle,
    required this.actionTitle,
    required this.enabled,
  });

  final String cacheKey;
  final _AiReportPeriod period;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime generatedAt;
  final String summaryTitle;
  final String actionTitle;
  final bool enabled;
}

class _StreakCardCopy {
  const _StreakCardCopy({required this.title, required this.body});

  final String title;
  final String body;
}

class _StreakDay extends StatelessWidget {
  const _StreakDay({required this.label, required this.state});

  final String label;
  final AppStreakStarState state;

  @override
  Widget build(BuildContext context) {
    final bool isSuccess = state == AppStreakStarState.success;
    final bool isMissed = state == AppStreakStarState.missed;
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
            color: AppCardTokens.streakStarBackground(state),
            border: AppCardTokens.streakStarBorder(state),
          ),
          child: isSuccess
              ? const Icon(Icons.star, size: 20, color: AppNeutralColors.white)
              : isMissed
              ? Text(
                  "?",
                  style: AppTypography.bodyMediumSemiBold.copyWith(
                    color: AppSemanticColors.success500,
                  ),
                )
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
    required this.installDate,
    required this.minMonth,
    required this.maxMonth,
  });

  final int selectedYear;
  final int selectedMonth;
  final DateTime? installDate;
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
          installDate: widget.installDate,
          minMonth: widget.minMonth,
          maxMonth: widget.maxMonth,
        ),
      ),
    );
  }

  int _lastVisibleDayOfMonth({required bool hasRecordForToday}) {
    return MyRecordsScreen.lastVisibleDayOfMonth(
      year: widget.selectedYear,
      month: widget.selectedMonth,
      hasRecordForToday: hasRecordForToday,
    );
  }

  String _weekdayLabel(DateTime date) {
    const List<String> labels = <String>["월", "화", "수", "목", "금", "토", "일"];
    return labels[date.weekday - 1];
  }

  String _questionForDay({
    required int day,
    required Map<int, String> monthQuestions,
    TodayQuestionRecord? record,
  }) {
    return _PastQuestionDb.resolveQuestion(
      day: day,
      questionsByDay: monthQuestions,
      record: record,
    );
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
                  final Map<int, TodayQuestionRecord> recordByDay =
                      <int, TodayQuestionRecord>{};
                  for (final TodayQuestionRecord record in records) {
                    final DateTime displayDate = myRecordsDisplayDate(record);
                    if (displayDate.year != widget.selectedYear ||
                        displayDate.month != widget.selectedMonth) {
                      continue;
                    }
                    recordByDay.putIfAbsent(displayDate.day, () => record);
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
                  final int lastDay = _lastVisibleDayOfMonth(
                    hasRecordForToday: recordByDay.containsKey(
                      DateTime.now().day,
                    ),
                  );
                  final int firstDay = MyRecordsScreen.firstVisibleDayOfMonth(
                    year: widget.selectedYear,
                    month: widget.selectedMonth,
                    installDate: widget.installDate,
                  );

                  return FutureBuilder<Map<int, String>>(
                    future: _PastQuestionDb.loadMonthQuestions(
                      year: widget.selectedYear,
                      month: widget.selectedMonth,
                      lastDay: lastDay,
                    ),
                    initialData: const <int, String>{},
                    builder:
                        (
                          BuildContext context,
                          AsyncSnapshot<Map<int, String>> questionSnapshot,
                        ) {
                          final Map<int, String> monthQuestions =
                              questionSnapshot.data ?? const <int, String>{};
                          if (firstDay > lastDay) {
                            return const SizedBox.shrink();
                          }
                          final List<_RecordListItem> monthlyItems =
                              List<_RecordListItem>.generate(
                                lastDay - firstDay + 1,
                                (int index) {
                                  final int day = lastDay - index;
                                  final bool isCompleted = recordByDay
                                      .containsKey(day);
                                  return _RecordListItem(
                                    day: day.toString().padLeft(2, "0"),
                                    weekday: _weekdayLabel(
                                      DateTime(
                                        widget.selectedYear,
                                        widget.selectedMonth,
                                        day,
                                      ),
                                    ),
                                    text: isCompleted
                                        ? _questionForDay(
                                            day: day,
                                            monthQuestions: monthQuestions,
                                            record: recordByDay[day],
                                          )
                                        : MyRecordsScreen._unansweredMessage,
                                    isCompleted: isCompleted,
                                  );
                                },
                                growable: false,
                              );

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
                                          final DateTime selectedDate =
                                              DateTime(
                                                widget.selectedYear,
                                                widget.selectedMonth,
                                                day,
                                              );
                                          final String selectedQuestion =
                                              _questionForDay(
                                                day: day,
                                                monthQuestions: monthQuestions,
                                                record: recordByDay[day],
                                              );
                                          if (recordByDay.containsKey(day)) {
                                            Navigator.of(context).push(
                                              MaterialPageRoute<void>(
                                                builder: (_) =>
                                                    MyRecordDetailScreen(
                                                      record: recordByDay[day]!,
                                                    ),
                                              ),
                                            );
                                            return;
                                          }
                                          Navigator.of(context).push(
                                            MaterialPageRoute<void>(
                                              builder: (_) =>
                                                  TodayQuestionAnswerScreen(
                                                    initialDate: selectedDate,
                                                    headerTitle: "지난 질문",
                                                    questionText:
                                                        selectedQuestion,
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
                                      minimumSize: Size(
                                        0,
                                        smallButtonMetrics.height,
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: smallButtonMetrics
                                            .horizontalPadding,
                                      ),
                                      foregroundColor: AppNeutralColors.grey600,
                                      textStyle: smallButtonMetrics.textStyle,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        Text("더보기"),
                                        SizedBox(width: AppSpacing.s4),
                                        Icon(
                                          Icons.keyboard_arrow_down,
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.s12),
                              ],
                            ],
                          );
                        },
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
    required this.installDate,
    required this.minMonth,
    required this.maxMonth,
  });

  final int initialYear;
  final int initialMonth;
  final DateTime? installDate;
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

  int _lastVisibleDayOfMonth({required bool hasRecordForToday}) {
    return MyRecordsScreen.lastVisibleDayOfMonth(
      year: _selectedYear,
      month: _selectedMonth,
      hasRecordForToday: hasRecordForToday,
    );
  }

  String _weekdayLabel(DateTime date) {
    const List<String> labels = <String>["월", "화", "수", "목", "금", "토", "일"];
    return labels[date.weekday - 1];
  }

  String _questionForDay({
    required int day,
    required Map<int, String> monthQuestions,
    TodayQuestionRecord? record,
  }) {
    return _PastQuestionDb.resolveQuestion(
      day: day,
      questionsByDay: monthQuestions,
      record: record,
    );
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
                final Map<int, TodayQuestionRecord> recordByDay =
                    <int, TodayQuestionRecord>{};
                for (final TodayQuestionRecord record in records) {
                  final DateTime displayDate = myRecordsDisplayDate(record);
                  if (displayDate.year != _selectedYear ||
                      displayDate.month != _selectedMonth) {
                    continue;
                  }
                  recordByDay.putIfAbsent(displayDate.day, () => record);
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
                final int lastDay = _lastVisibleDayOfMonth(
                  hasRecordForToday: recordByDay.containsKey(
                    DateTime.now().day,
                  ),
                );
                final int firstDay = MyRecordsScreen.firstVisibleDayOfMonth(
                  year: _selectedYear,
                  month: _selectedMonth,
                  installDate: widget.installDate,
                );

                return FutureBuilder<Map<int, String>>(
                  future: _PastQuestionDb.loadMonthQuestions(
                    year: _selectedYear,
                    month: _selectedMonth,
                    lastDay: lastDay,
                  ),
                  initialData: const <int, String>{},
                  builder:
                      (
                        BuildContext context,
                        AsyncSnapshot<Map<int, String>> questionSnapshot,
                      ) {
                        final Map<int, String> monthQuestions =
                            questionSnapshot.data ?? const <int, String>{};
                        if (firstDay > lastDay) {
                          return const SizedBox.shrink();
                        }
                        final int totalRows = lastDay - firstDay + 1;
                        return SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(
                            AppSpacing.s20,
                            49 + AppSpacing.s20,
                            AppSpacing.s20,
                            AppNavigationBar.totalHeight(context) +
                                AppSpacing.s20,
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
                                      onPressed: () =>
                                          Navigator.of(context).maybePop(),
                                      padding: EdgeInsets.zero,
                                      constraints:
                                          const BoxConstraints.tightFor(
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
                                      style: AppTypography.headingXSmall
                                          .copyWith(
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
                                          style: AppTypography.headingSmall
                                              .copyWith(
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
                              for (int index = 0; index < totalRows; index++)
                                _PastRecordsListRow(
                                  item: _RecordListItem(
                                    day: (lastDay - index).toString().padLeft(
                                      2,
                                      "0",
                                    ),
                                    weekday: _weekdayLabel(
                                      DateTime(
                                        _selectedYear,
                                        _selectedMonth,
                                        lastDay - index,
                                      ),
                                    ),
                                    text:
                                        recordByDay.containsKey(lastDay - index)
                                        ? _questionForDay(
                                            day: lastDay - index,
                                            monthQuestions: monthQuestions,
                                            record:
                                                recordByDay[lastDay - index],
                                          )
                                        : MyRecordsScreen._unansweredMessage,
                                    isCompleted: recordByDay.containsKey(
                                      lastDay - index,
                                    ),
                                  ),
                                  isLast: index == totalRows - 1,
                                  onTap: () {
                                    final int day = lastDay - index;
                                    final DateTime selectedDate = DateTime(
                                      _selectedYear,
                                      _selectedMonth,
                                      day,
                                    );
                                    final String selectedQuestion =
                                        _questionForDay(
                                          day: day,
                                          monthQuestions: monthQuestions,
                                          record: recordByDay[day],
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
                                        builder: (_) =>
                                            TodayQuestionAnswerScreen(
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
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
                    (Route<dynamic> route) => false,
                  );
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
        : AppNeutralColors.grey300;
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
        : AppNeutralColors.grey300;
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
