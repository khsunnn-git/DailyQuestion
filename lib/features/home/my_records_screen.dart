import "package:flutter/gestures.dart";
import "package:flutter/material.dart";

import "../../design_system/design_system.dart";
import "../question/today_question_store.dart";

class MyRecordsScreen extends StatelessWidget {
  const MyRecordsScreen({super.key});

  static const String _recordStarAsset =
      "assets/images/record/record_star_img.png";
  static const String _recordReportAsset =
      "assets/images/record/record_report_img.png";
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
  static const String _characterAsset =
      "assets/images/home/home_character_fish_blue.png";

  static const int _selectedYear = 2025;
  static const int _selectedMonth = 8;
  static const int _temporaryLastDay = 24;
  static const String _defaultQuestion = "오늘 가장 기억에 남는 순간은 무엇인가요?";
  static const String _unansweredMessage = "아직 열어보지 않은 질문입니다.";

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
    _RecordListItem(day: "15", text: "올해 꼭 해 보고 싶은 일 하나는 무엇인가요?"),
    _RecordListItem(day: "24", text: "요즘 무척 휴식을 원하나요?"),
    _RecordListItem(day: "23", text: "다른 사람에게 나를 어떻게 기억해줬으면 하나요?"),
    _RecordListItem(day: "22", text: "3년 뒤의 나, 스스로에게 어떤 말을 해주고 싶나요?"),
    _RecordListItem(day: "21", text: "최근에 누군가에게 고마웠던 순간을 떠올려 보세요."),
  ];

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
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    return Scaffold(
      backgroundColor: brand.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 390),
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 96),
                    child: Column(
                      children: <Widget>[
                        _TopMainPanel(brand: brand),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const <Widget>[
                              _RecordReportHeader(),
                              SizedBox(height: AppSpacing.s8),
                              _RecordHeroDecor(),
                              SizedBox(height: AppSpacing.s8),
                              _StreakCard(),
                              SizedBox(height: AppSpacing.s8),
                              _PastRecordsCard(),
                              SizedBox(height: AppSpacing.s48),
                              _MonthReportSection(),
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
        ),
      ),
    );
  }
}

class _TopMainPanel extends StatelessWidget {
  const _TopMainPanel({required this.brand});

  final BrandScale brand;

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
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 32),
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              height: 65,
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
          const SizedBox(height: AppSpacing.s16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              children: <Widget>[
                Text(
                  "${MyRecordsScreen._selectedYear}.${MyRecordsScreen._selectedMonth.toString().padLeft(2, "0")}",
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
          const SizedBox(height: AppSpacing.s16),
          const _MonthlyPreviewStrip(),
        ],
      ),
    );
  }
}

class _MonthlyPreviewStrip extends StatefulWidget {
  const _MonthlyPreviewStrip();

  @override
  State<_MonthlyPreviewStrip> createState() => _MonthlyPreviewStripState();
}

class _MonthlyPreviewStripState extends State<_MonthlyPreviewStrip> {
  static const double _cardWidth = 350;
  static const double _cardGap = 12;

  PageController? _pageController;
  bool _didSetInitialPage = false;

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
              MyRecordsScreen._selectedYear,
              MyRecordsScreen._selectedMonth,
              1,
            );
            final DateTime monthEnd = DateTime(
              MyRecordsScreen._selectedYear,
              MyRecordsScreen._selectedMonth + 1,
              0,
            );

            final Map<int, TodayQuestionRecord> recordByDay =
                <int, TodayQuestionRecord>{
                  for (final TodayQuestionRecord item in records)
                    if (!item.createdAt.isBefore(monthStart) &&
                        !item.createdAt.isAfter(monthEnd))
                      item.createdAt.day: item,
                };
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
                      MyRecordsScreen._selectedYear,
                      MyRecordsScreen._selectedMonth,
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
                          seed?.question ?? MyRecordsScreen._defaultQuestion,
                      body: record.answer,
                      tags: tags,
                    );
                  }
                  if (seed != null) {
                    return seed;
                  }
                  return _MonthlyRecordPreview(
                    day: day,
                    date: "$day일 $weekday",
                    question: MyRecordsScreen._defaultQuestion,
                    body: MyRecordsScreen._unansweredMessage,
                    tags: const <String>[],
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
                      itemCount: previews.length,
                      itemBuilder: (BuildContext context, int index) {
                        return Align(
                          alignment: Alignment.center,
                          child: _MonthlyPreviewCard(item: previews[index]),
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

class _MonthlyPreviewCard extends StatelessWidget {
  const _MonthlyPreviewCard({required this.item});

  final _MonthlyRecordPreview item;

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    return Container(
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
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.history,
                    size: 24,
                    color: AppNeutralColors.grey300,
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
                  const Icon(
                    Icons.more_horiz,
                    size: 24,
                    color: AppNeutralColors.grey300,
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
                          padding: const EdgeInsets.only(right: AppSpacing.s6),
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
          if (item.tags.isNotEmpty) const SizedBox(height: AppSpacing.s16),
          const Align(
            alignment: Alignment.centerLeft,
            child: SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _RecordReportHeader extends StatelessWidget {
  const _RecordReportHeader();

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: brand.c100,
                borderRadius: AppRadius.pill,
              ),
              child: Text(
                "꼬물꼬물물고기뽀글이",
                style: AppTypography.headingLarge.copyWith(color: brand.c500),
              ),
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
      height: 150,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned(
            left: 0,
            top: 0,
            child: Image.asset(
              MyRecordsScreen._recordStarAsset,
              width: 70,
              height: 70,
            ),
          ),
          Positioned(
            left: 6,
            top: 93,
            child: Image.asset(
              MyRecordsScreen._recordReportAsset,
              width: 94,
              height: 113,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            left: 66,
            top: 19,
            child: SizedBox(
              width: 150,
              height: 150,
              child: Stack(
                children: <Widget>[
                  Positioned(
                    left: 34,
                    bottom: 14,
                    child: Container(
                      width: 82,
                      height: 13,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Image.asset(
                      MyRecordsScreen._characterAsset,
                      fit: BoxFit.contain,
                    ),
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

class _StreakCard extends StatelessWidget {
  const _StreakCard();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<TodayQuestionRecord>>(
      valueListenable: TodayQuestionStore.instance,
      builder: (BuildContext context, List<TodayQuestionRecord> records, _) {
        final int streak = TodayQuestionStore.instance.consecutiveRecordDays;
        final DateTime? latestDate = records.isEmpty
            ? null
            : records.first.createdAt;
        final List<bool> weeklyDone = TodayQuestionStore.instance
            .weeklyCompletion(referenceDate: latestDate);
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
                "연속 $streak일째\n기록을 완료했어요!🔥",
                style: AppTypography.headingLarge.copyWith(
                  color: AppNeutralColors.grey900,
                ),
              ),
              const SizedBox(height: AppSpacing.s4),
              Text(
                "어제의 질문도 작성하면 연속 기록을\n이어갈 수 있어요!",
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
              ? const Icon(Icons.star, size: 20, color: Color(0xFFFFB200))
              : null,
        ),
      ],
    );
  }
}

class _PastRecordsCard extends StatelessWidget {
  const _PastRecordsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppNeutralColors.white,
        borderRadius: AppRadius.br16,
        boxShadow: AppElevation.level1,
      ),
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: <Widget>[
                Text(
                  "나의 지난 기록",
                  style: AppTypography.bodyMediumSemiBold.copyWith(
                    color: AppNeutralColors.grey900,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: AppNeutralColors.grey900,
                ),
              ],
            ),
          ),
          for (int i = 0; i < MyRecordsScreen._recordItems.length; i++)
            _PastRecordRow(
              item: MyRecordsScreen._recordItems[i],
              isLast: i == MyRecordsScreen._recordItems.length - 1,
            ),
          Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.s8,
              bottom: AppSpacing.s12,
            ),
            child: Text(
              "더보기  ˅",
              style: AppTypography.captionSmall.copyWith(
                color: AppNeutralColors.grey600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PastRecordRow extends StatelessWidget {
  const _PastRecordRow({required this.item, required this.isLast});

  final _RecordListItem item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: AppNeutralColors.grey50)),
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 24,
            child: Text(
              item.day,
              style: AppTypography.captionSmall.copyWith(
                color: AppNeutralColors.grey600,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: Text(
              item.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmallRegular.copyWith(
                color: AppNeutralColors.grey900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthReportSection extends StatelessWidget {
  const _MonthReportSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          "8월 리포트",
          style: AppTypography.heading2XSmall.copyWith(
            color: AppNeutralColors.grey900,
          ),
        ),
        const SizedBox(height: AppSpacing.s12),
        const _KeywordBubbleCard(),
        const SizedBox(height: AppSpacing.s12),
        ...MyRecordsScreen._profileItems.map(
          (item) => _ProfileCard(item: item),
        ),
      ],
    );
  }
}

class _KeywordBubbleCard extends StatelessWidget {
  const _KeywordBubbleCard();

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppNeutralColors.white,
        borderRadius: AppRadius.br16,
        boxShadow: AppElevation.level1,
      ),
      child: SizedBox(
        height: 232,
        child: Stack(
          children: <Widget>[
            Text(
              "8월 키워드",
              style: AppTypography.heading2XSmall.copyWith(
                color: AppNeutralColors.grey900,
              ),
            ),
            Positioned(
              left: 0,
              top: 24,
              child: _KeywordBubble(
                label: "가족",
                count: "10회 언급",
                size: 110,
                color: const Color(0xFFD4EEFF),
              ),
            ),
            Positioned(
              left: 96,
              top: 12,
              child: _KeywordBubble(
                label: "여행",
                count: "9+회 언급",
                size: 96,
                color: brand.c200,
                selected: true,
              ),
            ),
            const Positioned(
              right: 8,
              top: 76,
              child: _KeywordBubble(
                label: "취업",
                count: "3회 언급",
                size: 90,
                color: Color(0xFFB6E2FF),
              ),
            ),
            const Positioned(
              left: 118,
              top: 114,
              child: _KeywordBubble(
                label: "회복",
                count: "4회 언급",
                size: 70,
                color: Color(0xFFD6E7F3),
              ),
            ),
            const Positioned(
              left: 40,
              bottom: 0,
              child: _KeywordBubble(
                label: "러닝",
                count: "3회 언급",
                size: 90,
                color: Color(0xFFE8EEF4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KeywordBubble extends StatelessWidget {
  const _KeywordBubble({
    required this.label,
    required this.count,
    required this.size,
    required this.color,
    this.selected = false,
  });

  final String label;
  final String count;
  final double size;
  final Color color;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.85),
        border: selected
            ? Border.all(color: const Color(0xFF91D5FF), width: 1)
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            label,
            style: AppTypography.bodyLargeSemiBold.copyWith(
              color: selected
                  ? const Color(0xFF017AF7)
                  : AppNeutralColors.grey900,
            ),
          ),
          Text(
            count,
            style: AppTypography.captionSmall.copyWith(
              color: AppNeutralColors.grey600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.item});

  final _ProfileCardItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.s12),
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
  });

  final int day;
  final String date;
  final String question;
  final String body;
  final List<String> tags;
}

class _RecordListItem {
  const _RecordListItem({required this.day, required this.text});

  final String day;
  final String text;
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
