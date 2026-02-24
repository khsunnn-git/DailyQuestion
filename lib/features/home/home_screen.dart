import "dart:async";

import "package:flutter/gestures.dart";
import "package:flutter/material.dart";

import "../../design_system/design_system.dart";
import "../question/today_question_answer_screen.dart";
import "../question/today_question_store.dart";
import "today_records_data_source.dart";
import "today_records_screen.dart";

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const String _heroFishAsset =
      "assets/images/home/home_character_fish_blue.png";
  static const String _bannerFishbowlAsset =
      "assets/images/home/home_banner_fishbowl_blue.png";
  static const String _decoSeaweedAsset =
      "assets/images/home/home_deco_seaweed_blue.png";
  static const String _decoCrabAsset =
      "assets/images/home/home_deco_crab_blue.png";

  static void openTodayQuestionAnswer(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const TodayQuestionAnswerScreen(),
      ),
    );
  }

  static void openTodayRecords(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const TodayRecordsScreen()));
  }

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
                    padding: const EdgeInsets.only(bottom: 84),
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
                              _TodayRecordSection(),
                              const SizedBox(height: AppSpacing.s40),
                              _AquariumBanner(),
                              const SizedBox(height: AppSpacing.s40),
                              _OneLineReportCard(),
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

class _TopQuestionPanel extends StatelessWidget {
  const _TopQuestionPanel();

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: brand.c100,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: AppElevation.level2,
      ),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: ValueListenableBuilder<List<TodayQuestionRecord>>(
        valueListenable: TodayQuestionStore.instance,
        builder:
            (
              BuildContext context,
              List<TodayQuestionRecord> records,
              Widget? child,
            ) {
              final bool hasRecord = records.isNotEmpty;
              return Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const SizedBox(width: 24, height: 24),
                      Expanded(
                        child: Text(
                          "Daily Question",
                          textAlign: TextAlign.center,
                          style:
                              textTheme.titleMedium?.copyWith(
                                color: AppNeutralColors.grey900,
                              ) ??
                              AppTypography.headingXSmall.copyWith(
                                color: AppNeutralColors.grey900,
                              ),
                        ),
                      ),
                      const SizedBox(width: 24, height: 24),
                    ],
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

class _QuestionBeforeRecordCardState extends State<_QuestionBeforeRecordCard> {
  static const List<String> _messages = <String>[
    "오늘은 아직 답변하지 않았어요",
    "무엇이든 가볍게 적어보세요",
  ];
  int _messageIndex = 0;
  Timer? _messageTimer;

  @override
  void initState() {
    super.initState();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s8,
            vertical: AppSpacing.s24,
          ),
          child: Text(
            "올해 안에 꼭 해보고 싶은 일\n하나는 무엇인가요?",
            textAlign: TextAlign.center,
            style: AppTypography.headingLarge.copyWith(
              color: AppNeutralColors.grey900,
            ),
          ),
        ),
        _QuestionWrittenSpeechBubble(
          text: _messages[_messageIndex],
          color: AppNeutralColors.white,
          tailDirection: _SpeechTailDirection.down,
        ),
        const SizedBox(height: AppSpacing.s24),
        Image.asset(
          HomeScreen._heroFishAsset,
          width: 150,
          height: 150,
          fit: BoxFit.contain,
          errorBuilder: (_, error, stackTrace) {
            return const Text("🐟", style: TextStyle(fontSize: 64));
          },
        ),
        const SizedBox(height: AppSpacing.s24),
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
            foregroundColor: brand.c500,
            textStyle: AppTypography.buttonSmall,
          ),
          child: const Text("새로운 질문 받기"),
        ),
        const SizedBox(height: AppSpacing.s24),
        SizedBox(
          width: double.infinity,
          height: 60,
          child: FilledButton(
            onPressed: () => HomeScreen.openTodayQuestionAnswer(context),
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
  }
}

class _QuestionWrittenPreviewCard extends StatelessWidget {
  const _QuestionWrittenPreviewCard();

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    final TodayQuestionRecord? latest =
        TodayQuestionStore.instance.latestRecord;
    final DateTime now = latest?.createdAt ?? DateTime.now();
    final List<String> weekdays = <String>[
      "월요일",
      "화요일",
      "수요일",
      "목요일",
      "금요일",
      "토요일",
      "일요일",
    ];
    final String currentDate = "${now.day}일 ${weekdays[now.weekday - 1]}";
    final String answerText =
        latest?.answer ??
        "올해는 꼭 제주도 한라산에 올라가 백록담을 직접 보고 싶어. "
            "예전부터 사진으로만 보던 그 푸른 호수를 실제로 내 눈으로 담아보고 싶다는 마음이 있었거든요...";
    final List<String> bucketTags = latest == null
        ? const <String>[]
        : latest.bucketTags.isNotEmpty
        ? latest.bucketTags
        : (latest.bucketTag == null || latest.bucketTag!.trim().isEmpty)
        ? const <String>[]
        : <String>[latest.bucketTag!.trim()];
    return Container(
      width: double.infinity,
      height: 458,
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
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
                  Icon(
                    Icons.history,
                    size: AppSpacing.s24,
                    color: AppNeutralColors.grey400,
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
                  const Icon(
                    Icons.more_horiz,
                    size: AppSpacing.s24,
                    color: AppNeutralColors.grey400,
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
              "올해 안에 꼭 해보고 싶은 일\n하나는 무엇인가요?",
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
              textAlign: TextAlign.center,
              style: AppTypography.bodyLargeRegular.copyWith(
                color: AppNeutralColors.grey800,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (bucketTags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s16),
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
            ),
        ],
      ),
    );
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
    return Align(
      alignment: Alignment.center,
      child: Row(
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
      ),
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

class _TopCharacterDecorations extends StatelessWidget {
  const _TopCharacterDecorations({required this.bubbleColor});

  final Color bubbleColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 350,
      height: 132,
      child: Stack(
        children: <Widget>[
          Positioned(
            left: 4,
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
            left: 47,
            bottom: 0,
            child: Image.asset(
              HomeScreen._decoCrabAsset,
              width: 70,
              height: 70,
              fit: BoxFit.contain,
              errorBuilder: (_, error, stackTrace) => const SizedBox.shrink(),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 18,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                _QuestionWrittenSpeechBubble(
                  text: "오늘의 질문을 적었어요!",
                  color: bubbleColor,
                ),
                const SizedBox(width: AppSpacing.s8),
                Image.asset(
                  HomeScreen._heroFishAsset,
                  width: 108.4,
                  height: 108.4,
                  fit: BoxFit.contain,
                  errorBuilder: (_, error, stackTrace) {
                    return const SizedBox(
                      width: 108.4,
                      height: 108.4,
                      child: Center(
                        child: Text("🐟", style: TextStyle(fontSize: 48)),
                      ),
                    );
                  },
                ),
              ],
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
            SizedBox(height: AppSpacing.s24),
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
    final String subMessage = streak >= 7
        ? "벌써 일주일 째 기록 중이에요!"
        : "꾸준한 당신이 멋져요!";
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
          const SizedBox(height: AppSpacing.s4),
          Text(
            subMessage,
            textAlign: TextAlign.center,
            style: AppTypography.captionMedium.copyWith(
              color: AppNeutralColors.grey600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayRecordSection extends StatelessWidget {
  const _TodayRecordSection();

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return ValueListenableBuilder<List<TodayQuestionRecord>>(
      valueListenable: TodayQuestionStore.instance,
      builder: (BuildContext context, List<TodayQuestionRecord> saved, _) {
        final List<_TodayRecordData> myPublicRecords = saved
            .where((TodayQuestionRecord item) => item.isPublic)
            .map(
              (TodayQuestionRecord item) => _TodayRecordData(
                body: _toPreviewText(item.answer),
                name: item.author,
              ),
            )
            .toList(growable: false);
        final List<_TodayRecordData> otherRecords =
            TodayRecordsDataSource.visiblePublicRecords()
                .take(3)
                .map(
                  (OtherTodayRecord item) => _TodayRecordData(
                    body: _toPreviewText(item.body),
                    name: item.author,
                  ),
                )
                .toList(growable: false);
        final List<_TodayRecordData> records = <_TodayRecordData>[
          ...myPublicRecords,
          ...otherRecords,
        ];
        final bool hasRecords = records.isNotEmpty;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (hasRecords)
              InkWell(
                onTap: () => HomeScreen.openTodayRecords(context),
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        "오늘의 기록",
                        style:
                            textTheme.titleLarge?.copyWith(
                              color: AppNeutralColors.grey900,
                            ) ??
                            AppTypography.headingSmall.copyWith(
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
              )
            else
              Text(
                "오늘의 기록",
                style:
                    textTheme.titleLarge?.copyWith(
                      color: AppNeutralColors.grey900,
                    ) ??
                    AppTypography.headingSmall.copyWith(
                      color: AppNeutralColors.grey900,
                    ),
              ),
            const SizedBox(height: 17),
            if (hasRecords)
              SizedBox(
                height: 154,
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
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const ClampingScrollPhysics(),
                    itemBuilder: (context, index) => _TodayRecordCard(
                      record: records[index],
                      width: records.length == 1 ? 350 : 320,
                    ),
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: AppSpacing.s8),
                    itemCount: records.length,
                  ),
                ),
              )
            else
              _TodayRecordEmptyCard(
                onTap: () => HomeScreen.openTodayQuestionAnswer(context),
              ),
          ],
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
          height: 154,
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

class _AquariumBanner extends StatelessWidget {
  const _AquariumBanner();

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 4, 20, 4),
      decoration: BoxDecoration(
        color: brand.c200,
        borderRadius: AppRadius.br16,
        boxShadow: AppElevation.level1,
      ),
      child: Row(
        children: <Widget>[
          RichText(
            text: TextSpan(
              children: <TextSpan>[
                TextSpan(
                  text: "나만의 어항 ",
                  style: AppTypography.headingSmall.copyWith(
                    color: AppNeutralColors.grey900,
                  ),
                ),
                TextSpan(
                  text: "가꾸기",
                  style: AppTypography.bodyXLargeSemiBold.copyWith(
                    color: AppNeutralColors.grey900,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Image.asset(
            HomeScreen._bannerFishbowlAsset,
            width: 80,
            height: 80,
            fit: BoxFit.contain,
            errorBuilder: (_, error, stackTrace) {
              return const SizedBox(
                width: 80,
                height: 80,
                child: Center(
                  child: Text("🐠", style: TextStyle(fontSize: 34)),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _OneLineReportCard extends StatelessWidget {
  const _OneLineReportCard();

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    const List<String> tags = <String>["여행 ✈️", "독서📚", "사람🤝️"];
    return Container(
      width: double.infinity,
      height: 278,
      padding: const EdgeInsets.fromLTRB(22, 29, 22, 20),
      decoration: BoxDecoration(
        color: brand.c50,
        borderRadius: AppRadius.br16,
        boxShadow: AppElevation.level1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                "나의 한 줄 리포트",
                style: AppTypography.heading2XSmall.copyWith(color: brand.c500),
              ),
              const SizedBox(height: AppSpacing.s8),
              Text(
                "최근 당신의 답변에는\n‘자기 성장 키워드’가 가장 많았어요",
                style: AppTypography.headingMediumExtraBold.copyWith(
                  color: AppNeutralColors.grey900,
                ),
                maxLines: 2,
              ),
            ],
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.s12),
            child: SizedBox(
              width: double.infinity,
              height: 40,
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
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  itemBuilder: (context, index) =>
                      _KeywordChip(text: tags[index]),
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: AppSpacing.s8),
                  itemCount: tags.length,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KeywordChip extends StatelessWidget {
  const _KeywordChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppNeutralColors.white,
        borderRadius: AppRadius.pill,
        border: Border.all(color: brand.c200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text(
            "#",
            style: AppTypography.bodyMediumSemiBold.copyWith(color: brand.c500),
          ),
          Text(
            text,
            style: AppTypography.bodyMediumSemiBold.copyWith(
              color: AppNeutralColors.grey900,
            ),
          ),
        ],
      ),
    );
  }
}
