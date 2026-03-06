import "dart:math" as math;

import "package:cloud_firestore/cloud_firestore.dart";
import "package:flutter/gestures.dart";
import "package:flutter/material.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../../design_system/design_system.dart";
import "../bucket/bucket_list_screen.dart";
import "../profile/user_profile_prefs.dart";
import "home_screen.dart";
import "../more/more_settings_screen.dart";
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
    _loadInstallMonth();
    _loadNickname();
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
                          const _RecordHeroDecor(),
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
                          _MonthlyKeywordPieCard(
                            selectedYear: _selectedYear,
                            selectedMonth: _selectedMonth,
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
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AppNavigationBar(
                currentIndex: 2,
                onTap: (int index) {
                  if (index == 0) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute<void>(
                        builder: (_) => const HomeScreen(),
                      ),
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
    final DateTime installMonth = _monthOnly(installDate);
    await prefs.setInt(_installMonthKey, installMonth.millisecondsSinceEpoch);
    if (!mounted) return;
    setState(() {
      _installDate = installDate;
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
  static const double _cardGap = 12;
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
                .where(
                  (TodayQuestionRecord item) =>
                      item.createdAt.year == widget.selectedYear &&
                      item.createdAt.month == widget.selectedMonth,
                )
                .toList(growable: false);

            final Map<int, TodayQuestionRecord> recordByDay =
                <int, TodayQuestionRecord>{};
            for (final TodayQuestionRecord item in monthRecords) {
              recordByDay[item.createdAt.day] = item;
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
              return const SizedBox(height: 458);
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
                              height: 458,
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
      height: 458,
      child: Stack(
        children: <Widget>[
          GestureDetector(
            onTap: _openDetailFromCard,
            behavior: HitTestBehavior.opaque,
            child: Container(
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
                  if (!isEmptyState && item.tags.isNotEmpty)
                    const SizedBox(height: AppSpacing.s16),
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
        title: "벌써 $streak번째 날이에요!\n너무 멋져요!🔥",
        body: "연속기록을 이어가면 \n월말에 리포트를 받아볼 수 있어요!",
      );
    }
    if (missingDays == 1) {
      return const _StreakCardCopy(
        title: "오늘도 내 생각을 적어볼까요?",
        body: "하루하루 당신의 생각을 기다리고 있어요! 🥰",
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

enum _AiReportPeriod { monthly, quarterly, yearly }

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

class _AiReportEntryCardState extends State<_AiReportEntryCard> {
  _AiReportPeriod _selected = _AiReportPeriod.monthly;

  _AiReportUiData _dataFor(_AiReportPeriod period) {
    final String monthLabel = "${widget.selectedMonth}월";
    final int quarter = ((widget.selectedMonth - 1) ~/ 3) + 1;
    final int year = widget.selectedYear;

    switch (period) {
      case _AiReportPeriod.monthly:
        return _AiReportUiData(
          summaryTitle: "$monthLabel 요약",
          summaryBody:
              "$monthLabel 초반에는 기록이 뜸했지만, 중반 이후부터 기록 빈도가 올라가며 만족도·에너지 흐름이 안정됐어요. "
              "버킷리스트 12개 중 4개를 완료하며 작은 성취가 꾸준히 쌓이고 있어요.",
          insightBody:
              "기분이 좋은 날엔 산책·음악·짧은 휴식이 반복적으로 등장했어요. 반대로 스트레스가 높았던 날엔 미루기와 수면 불규칙 키워드가 함께 나타났어요.",
          actions: const <String>[
            "점심시간에 10분 산책을 해보세요.",
            "일정을 작은 단위로 나눠 먼저 1개만 시작해보세요.",
            "주 1회 동료와 커피 한 잔 대화 시간을 만들어보세요.",
          ],
        );
      case _AiReportPeriod.quarterly:
        return _AiReportUiData(
          summaryTitle: "$quarter분기 요약",
          summaryBody:
              "최근 3개월 동안 기록 리듬이 점차 안정되며 감정 기복 폭이 줄었어요. "
              "버킷리스트는 30개가 추가됐고 11개를 완료했어요.",
          insightBody:
              "관심사 중심축이 바뀌고 있어요. 1월에는 '수영 배우기'를 자주 언급했지만 최근에는 '마라톤 도전하기'가 반복되며 목표 영역이 확장됐어요.",
          actions: const <String>[
            "분기 목표를 1개 핵심 목표와 2개 보조 목표로 구분해보세요.",
            "완료한 버킷리스트를 주 1회 회고하며 다음 행동으로 연결해보세요.",
            "스트레스가 높은 주에는 휴식 일정을 먼저 달력에 고정해보세요.",
          ],
        );
      case _AiReportPeriod.yearly:
        return _AiReportUiData(
          summaryTitle: "$year년 요약",
          summaryBody:
              "올해는 기록량과 자기이해가 함께 성장한 해였어요. 감정 기록, 질문 답변, 버킷리스트 데이터가 쌓이며 나만의 패턴이 선명해졌어요.",
          insightBody:
              "질문 답변 비교에서 목표의 결이 진화했어요. 작년에는 '설악산'을, 올해는 '한라산'을 답하며 도전의 난이도와 실행 의지가 함께 높아졌어요.",
          actions: const <String>[
            "올해 가장 만족도가 높았던 습관 1개를 내년 고정 루틴으로 지정해보세요.",
            "연간 목표는 상반기/하반기로 나눠 실행 체크포인트를 만드세요.",
            "연말 회고에서 '잘한 점 3개, 줄일 점 1개'만 간단히 정리해보세요.",
          ],
        );
    }
  }

  bool _isMonthClosed({
    required int year,
    required int month,
    required DateTime now,
  }) {
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime lastDayOfMonth = DateTime(year, month + 1, 0);
    return !today.isBefore(lastDayOfMonth);
  }

  @override
  Widget build(BuildContext context) {
    final _AiReportUiData data = _dataFor(_selected);
    final DateTime now = DateTime.now();
    final bool monthlyEnabled = _isMonthClosed(
      year: widget.selectedYear,
      month: widget.selectedMonth,
      now: now,
    );
    final bool quarterlyEnabled =
        monthlyEnabled && widget.selectedMonth % 3 == 0;
    final bool yearlyEnabled =
        monthlyEnabled && widget.selectedMonth == DateTime.december;

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
          "월간/분기/연간 기준으로 AI 리포트를 생성해요.",
          style: AppTypography.bodySmallMedium.copyWith(
            color: AppNeutralColors.grey400,
          ),
        ),
        const SizedBox(height: AppSpacing.s24),
        Row(
          children: <Widget>[
            _AiPeriodChip(
              label: "월간",
              enabled: monthlyEnabled,
              selected: monthlyEnabled && _selected == _AiReportPeriod.monthly,
              onTap: () => setState(() => _selected = _AiReportPeriod.monthly),
            ),
            const SizedBox(width: AppSpacing.s8),
            _AiPeriodChip(
              label: "분기",
              enabled: quarterlyEnabled,
              selected:
                  quarterlyEnabled && _selected == _AiReportPeriod.quarterly,
              onTap: () =>
                  setState(() => _selected = _AiReportPeriod.quarterly),
            ),
            const SizedBox(width: AppSpacing.s8),
            _AiPeriodChip(
              label: "연간",
              enabled: yearlyEnabled,
              selected: yearlyEnabled && _selected == _AiReportPeriod.yearly,
              onTap: () => setState(() => _selected = _AiReportPeriod.yearly),
            ),
          ],
        ),
        if (!monthlyEnabled) ...<Widget>[
          const SizedBox(height: AppSpacing.s24),
          const _AiDataAlert(message: "아직 데이터가 부족합니다.\n월말까지 기다려주세요!"),
        ] else if (_selected == _AiReportPeriod.quarterly &&
            !quarterlyEnabled) ...<Widget>[
          const SizedBox(height: AppSpacing.s24),
          const _AiDataAlert(message: "분기 리포트는 3·6·9·12월 말에 생성돼요."),
        ] else if (_selected == _AiReportPeriod.yearly &&
            !yearlyEnabled) ...<Widget>[
          const SizedBox(height: AppSpacing.s24),
          const _AiDataAlert(message: "연간 리포트는 12월 말에 생성돼요."),
        ] else ...<Widget>[
          const SizedBox(height: AppSpacing.s16),
          _AiReportPreviewCard(
            iconAsset: MyRecordsScreen._profileInsightAsset,
            title: data.summaryTitle,
            body: data.summaryBody,
          ),
          const SizedBox(height: AppSpacing.s12),
          _AiReportPreviewCard(
            iconAsset: MyRecordsScreen._profileInterestAsset,
            title: "인사이트",
            body: data.insightBody,
          ),
          const SizedBox(height: AppSpacing.s12),
          _AiReportPreviewCard(
            iconAsset: MyRecordsScreen._profileBucketlistAsset,
            title: "이렇게 해볼까요?",
            body: data.actions.map((String action) => "• $action").join("\n"),
          ),
        ],
      ],
    );
  }
}

class _AiDataAlert extends StatelessWidget {
  const _AiDataAlert({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 200,
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: AppTypography.bodyMediumRegular.copyWith(
            color: AppNeutralColors.grey500,
          ),
        ),
      ),
    );
  }
}

class _AiPeriodChip extends StatelessWidget {
  const _AiPeriodChip({
    required this.label,
    required this.enabled,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: AppRadius.pill,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s20,
          vertical: AppSpacing.s6,
        ),
        decoration: BoxDecoration(
          color: selected && enabled ? brand.c100 : AppNeutralColors.grey50,
          borderRadius: AppRadius.pill,
          border: selected && enabled
              ? Border.all(color: brand.c500, width: 1)
              : Border.all(color: Colors.transparent, width: 1),
          boxShadow: AppElevation.level1,
        ),
        child: Text(
          label,
          style: AppTypography.bodySmallSemiBold.copyWith(
            color: selected && enabled ? brand.c500 : AppNeutralColors.grey200,
          ),
        ),
      ),
    );
  }
}

class _AiReportPreviewCard extends StatelessWidget {
  const _AiReportPreviewCard({
    required this.iconAsset,
    required this.title,
    required this.body,
  });

  final String iconAsset;
  final String title;
  final String body;

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
                child: Image.asset(iconAsset, width: 50, height: 50),
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s8,
                  vertical: AppSpacing.s2,
                ),
                decoration: BoxDecoration(
                  color: AppSemanticColors.info100,
                  borderRadius: AppRadius.pill,
                ),
                child: Text(
                  "AI",
                  style: AppTypography.captionSmall.copyWith(color: brand.c500),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s20),
          Text(
            body,
            style: AppTypography.bodyMediumRegular.copyWith(
              color: AppNeutralColors.grey900,
            ),
          ),
        ],
      ),
    );
  }
}

class _AiReportUiData {
  const _AiReportUiData({
    required this.summaryTitle,
    required this.summaryBody,
    required this.insightBody,
    required this.actions,
  });

  final String summaryTitle;
  final String summaryBody;
  final String insightBody;
  final List<String> actions;
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

class _MonthlyKeywordPieCard extends StatelessWidget {
  const _MonthlyKeywordPieCard({
    required this.selectedYear,
    required this.selectedMonth,
  });

  final int selectedYear;
  final int selectedMonth;

  static const List<Color> _sliceColors = <Color>[
    Color(0xFF0069D6),
    Color(0xFF017AF7),
    Color(0xFF86CAFF),
    Color(0xFFB6E2FF),
    Color(0xFFD3EEFF),
  ];

  static const Set<String> _stopWords = <String>{
    "오늘",
    "이번",
    "그리고",
    "그냥",
    "계속",
    "많이",
    "말고",
    "진짜",
    "조금",
    "약간",
    "아직",
    "이미",
    "먼저",
    "다시",
    "또",
    "더",
    "덜",
    "자꾸",
    "바로",
    "돼요",
    "되요",
    "되고",
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
    "요즘",
    "지금",
  };
  static const Set<String> _lowInfoWords = <String>{
    "사람",
    "하루",
    "기분",
    "마음",
    "생각",
    "시간",
    "요즘",
    "오늘",
    "이번",
    "상태",
  };
  static const Set<String> _domainBoostWords = <String>{
    "행복",
    "기쁨",
    "설렘",
    "불안",
    "우울",
    "외로움",
    "스트레스",
    "안정",
    "가족",
    "친구",
    "연인",
    "엄마",
    "아빠",
    "동생",
    "고양이",
    "강아지",
    "운동",
    "공부",
    "산책",
    "여행",
    "취업",
    "이직",
    "퇴사",
    "건강",
    "독서",
    "기록",
    "집",
    "회사",
    "학교",
    "카페",
    "병원",
  };

  static const Set<String> _nonNounSuffixes = <String>{
    "하다",
    "했다",
    "해요",
    "합니다",
    "되는",
    "되다",
    "됐다",
    "이다",
    "예요",
    "어요",
    "아요",
    "네요",
    "하게",
    "하며",
    "같다",
    "같은",
    "좋다",
    "좋은",
    "싶다",
    "싶은",
    "하기",
    "가기",
    "보기",
    "먹기",
    "듣기",
    "한다",
    "된다",
    "했다가",
    "하려",
    "하려고",
    "하도록",
    "되도록",
    "시키다",
    "시킨다",
    "시키는",
    "시키고",
    "하기로",
    "되기로",
    "하려면",
    "된다면",
    "되게",
    "할수록",
    "될수록",
    "해보자",
    "해보기",
    "고",
    "어",
    "나",
  };

  static const List<String> _verbLikeFragments = <String>[
    "하도록",
    "되도록",
    "하려고",
    "하려",
    "한다",
    "된다",
    "했다",
    "되고",
    "되는",
    "되게",
    "하기로",
    "되기로",
    "하려면",
    "한다면",
    "된다면",
    "할수록",
    "될수록",
    "해보자",
    "해보기",
    "하며",
    "하면",
  ];

  static const List<String> _josaSuffixes = <String>[
    "으로부터",
    "에게서",
    "이라서",
    "라서",
    "에서",
    "에게",
    "으로",
    "처럼",
    "보다",
    "까지",
    "부터",
    "하고",
    "이며",
    "이고",
    "이나",
    "거나",
    "라도",
    "만의",
    "은",
    "는",
    "이",
    "가",
    "을",
    "를",
    "에",
    "도",
    "만",
    "와",
    "과",
    "랑",
    "야",
  ];

  List<_KeywordSlice> _buildKeywordSlices(List<TodayQuestionRecord> records) {
    final Iterable<TodayQuestionRecord> monthlyRecords = records.where(
      (TodayQuestionRecord item) =>
          item.createdAt.year == selectedYear &&
          item.createdAt.month == selectedMonth,
    );

    final Map<String, int> counter = <String, int>{};
    for (final TodayQuestionRecord record in monthlyRecords) {
      final List<String> bucketKeywords = record.bucketTags.isNotEmpty
          ? record.bucketTags
          : (record.bucketTag == null || record.bucketTag!.trim().isEmpty)
          ? const <String>[]
          : <String>[record.bucketTag!.trim()];

      for (final String keyword in bucketKeywords) {
        final List<String> nouns = _extractNouns(keyword);
        for (final String noun in nouns) {
          int score = 2;
          if (_domainBoostWords.contains(noun)) {
            score += 1;
          }
          if (_lowInfoWords.contains(noun)) {
            score -= 1;
          }
          _addScore(counter, noun, score);
        }
        for (final _CompoundToken compound in _buildCompoundNouns(nouns)) {
          int score = compound.size >= 3 ? 4 : 3;
          if (_domainBoostWords.contains(compound.text)) {
            score += 1;
          }
          _addScore(counter, compound.text, score);
        }
      }

      final List<String> nouns = _extractNouns(record.answer);
      for (final String noun in nouns) {
        int score = 1;
        if (_domainBoostWords.contains(noun)) {
          score += 1;
        }
        if (_lowInfoWords.contains(noun)) {
          score -= 1;
        }
        _addScore(counter, noun, score);
      }
      for (final _CompoundToken compound in _buildCompoundNouns(nouns)) {
        int score = compound.size >= 3 ? 3 : 2;
        if (_domainBoostWords.contains(compound.text)) {
          score += 1;
        }
        _addScore(counter, compound.text, score);
      }
    }

    final List<MapEntry<String, int>> top = _removeSubTokens(counter).entries
        .where((MapEntry<String, int> e) => e.value > 0)
        .toList()
      ..sort((MapEntry<String, int> a, MapEntry<String, int> b) {
        if (b.value != a.value) return b.value.compareTo(a.value);
        final int aWordCount = _wordCount(a.key);
        final int bWordCount = _wordCount(b.key);
        if (bWordCount != aWordCount) return bWordCount.compareTo(aWordCount);
        return a.key.compareTo(b.key);
      });

    final List<_KeywordSlice> result = List<_KeywordSlice>.generate(
      top.length > _sliceColors.length ? _sliceColors.length : top.length,
      (int index) {
        final MapEntry<String, int> item = top[index];
        return _KeywordSlice(
          label: item.key,
          count: item.value,
          color: _sliceColors[index % _sliceColors.length],
        );
      },
    );
    return result;
  }

  List<String> _extractNouns(String text) {
    final List<String> result = <String>[];
    final Iterable<String> tokens = RegExp(
      r"[가-힣A-Za-z0-9]{2,}",
    ).allMatches(text).map((Match m) => m.group(0) ?? "");
    for (final String token in tokens) {
      final String? noun = _normalizeNounToken(token);
      if (noun == null || _stopWords.contains(noun)) {
        continue;
      }
      result.add(noun);
    }
    return result;
  }

  List<_CompoundToken> _buildCompoundNouns(List<String> nouns) {
    if (nouns.length < 2) {
      return const <_CompoundToken>[];
    }
    final Set<String> dedupe = <String>{};
    final List<_CompoundToken> result = <_CompoundToken>[];
    for (int size = 2; size <= 3; size++) {
      if (nouns.length < size) {
        break;
      }
      for (int i = 0; i <= nouns.length - size; i++) {
        final String text = nouns.sublist(i, i + size).join(" ");
        if (dedupe.add(text)) {
          result.add(_CompoundToken(text: text, size: size));
        }
      }
    }
    return result;
  }

  Map<String, int> _removeSubTokens(Map<String, int> source) {
    final List<MapEntry<String, int>> all = source.entries.toList();
    final Map<String, int> result = <String, int>{};
    for (final MapEntry<String, int> item in all) {
      final bool remove = all.any((MapEntry<String, int> other) {
        if (identical(item, other) || item.key == other.key) {
          return false;
        }
        final bool contained =
            other.key.length > item.key.length && other.key.contains(item.key);
        final bool stronger = other.value >= item.value && _wordCount(other.key) > 1;
        return contained && stronger;
      });
      if (!remove) {
        result[item.key] = item.value;
      }
    }
    return result;
  }

  int _wordCount(String text) => text.split(" ").where((String w) => w.isNotEmpty).length;

  void _addScore(Map<String, int> counter, String token, int amount) {
    if (amount == 0) {
      return;
    }
    counter[token] = (counter[token] ?? 0) + amount;
  }

  String? _normalizeNounToken(String token) {
    String value = token.trim();
    if (value.length < 2) {
      return null;
    }
    value = value.toLowerCase();
    if (value.startsWith("같")) {
      return null;
    }
    for (final String suffix in _josaSuffixes) {
      if (value.length > suffix.length + 1 && value.endsWith(suffix)) {
        value = value.substring(0, value.length - suffix.length);
        break;
      }
    }
    if (!_isLikelyNoun(value)) {
      return null;
    }
    for (final String fragment in _verbLikeFragments) {
      if (value == fragment ||
          value.endsWith(fragment) ||
          value.contains(fragment)) {
        return null;
      }
    }
    for (final String noise in <String>["계속", "많이", "말고", "돼요", "되요", "되고"]) {
      if (value.contains(noise)) {
        return null;
      }
    }
    return value;
  }

  bool _isLikelyNoun(String token) {
    if (token.length < 2) return false;
    for (final String suffix in _nonNounSuffixes) {
      if (token.endsWith(suffix)) return false;
    }
    if (token.endsWith("히") || token.endsWith("게")) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<TodayQuestionRecord>>(
      valueListenable: TodayQuestionStore.instance,
      builder: (BuildContext context, List<TodayQuestionRecord> records, _) {
        final int monthlyRecordCount = records
            .where(
              (TodayQuestionRecord item) =>
                  item.createdAt.year == selectedYear &&
                  item.createdAt.month == selectedMonth &&
                  item.answer.trim().isNotEmpty,
            )
            .length;
        final List<_KeywordSlice> slices = _buildKeywordSlices(records);
        final bool showNoKeywordDonut =
            monthlyRecordCount == 0 || slices.isEmpty;
        final int total = math.max(
          1,
          slices.fold(0, (int acc, _KeywordSlice item) => acc + item.count),
        );

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
              Text(
                "$selectedMonth월 키워드",
                style: AppTypography.headingXSmall.copyWith(
                  color: AppNeutralColors.grey900,
                ),
              ),
              const SizedBox(height: AppSpacing.s16),
              if (showNoKeywordDonut)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.s24),
                  child: Column(
                    children: <Widget>[
                      Center(
                        child: SizedBox(
                          width: 180,
                          height: 180,
                          child: CustomPaint(
                            size: const Size(180, 180),
                            painter: const _KeywordNoDataDonutPainter(),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s12),
                      Text(
                        "아직 분석할 답변이 부족해요",
                        style: AppTypography.bodyMediumRegular.copyWith(
                          color: AppNeutralColors.grey500,
                        ),
                      ),
                    ],
                  ),
                )
              else ...<Widget>[
                Center(
                  child: SizedBox(
                    width: 180,
                    height: 180,
                    child: CustomPaint(
                      size: const Size(180, 180),
                      painter: _KeywordPieChartPainter(slices: slices),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s16),
                Column(
                  children: slices
                      .map((_KeywordSlice slice) {
                        final String ratio = ((slice.count / total) * 100)
                            .toStringAsFixed(0);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.s4),
                          child: Row(
                            children: <Widget>[
                              Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: slice.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.s4),
                              Expanded(
                                child: Text(
                                  slice.label,
                                  style: AppTypography.bodySmallRegular.copyWith(
                                    color: AppNeutralColors.grey900,
                                  ),
                                ),
                              ),
                              Text(
                                "$ratio%(${slice.count}건)",
                                style: AppTypography.bodySmallRegular.copyWith(
                                  color: AppNeutralColors.grey900,
                                ),
                              ),
                            ],
                          ),
                        );
                      })
                      .toList(growable: false),
                ),
              ],
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

class _CompoundToken {
  const _CompoundToken({required this.text, required this.size});

  final String text;
  final int size;
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
    final Rect rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    double startAngle = -math.pi / 2;
    for (final _KeywordSlice slice in slices) {
      final double sweep = (slice.count / total) * math.pi * 2;
      paint.color = slice.color;
      canvas.drawArc(rect, startAngle, sweep, false, paint);
      startAngle += sweep;
    }
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

class _KeywordNoDataDonutPainter extends CustomPainter {
  const _KeywordNoDataDonutPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double strokeWidth = 60;
    final Rect rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    final Paint ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt
      ..color = AppNeutralColors.grey100;

    canvas.drawArc(rect, 0, math.pi * 2, false, ringPaint);
  }

  @override
  bool shouldRepaint(covariant _KeywordNoDataDonutPainter oldDelegate) {
    return false;
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
