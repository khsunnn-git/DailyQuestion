import "package:flutter/gestures.dart";
import "package:flutter/material.dart";

import "../../design_system/design_system.dart";
import "../question/today_question_answer_screen.dart";
import "today_records_screen.dart";

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const String _heroFishAsset =
      "assets/images/home/home_character_fish_blue.png";
  static const String _bannerFishbowlAsset =
      "assets/images/home/home_banner_fishbowl_blue.png";

  static void openTodayQuestionAnswer(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const TodayQuestionAnswerScreen(),
      ),
    );
  }

  static void openTodayRecords(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const TodayRecordsScreen()),
    );
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
                            children: const <Widget>[
                              _RecordStreakBar(),
                              SizedBox(height: AppSpacing.s40),
                              _TodayRecordSection(),
                              SizedBox(height: AppSpacing.s40),
                              _AquariumBanner(),
                              SizedBox(height: AppSpacing.s40),
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
      child: Column(
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
          Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: <Color>[
                      AppNeutralColors.white.withValues(alpha: 0.8),
                      brand.c100.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
              Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s8,
                      vertical: AppSpacing.s24,
                    ),
                    child: Text(
                      "올해 안에 꼭 해보고 싶은 일\n하나는 무엇인가요?",
                      textAlign: TextAlign.center,
                      style:
                          textTheme.displayLarge?.copyWith(
                            color: AppNeutralColors.grey900,
                          ) ??
                          AppTypography.headingLarge.copyWith(
                            color: AppNeutralColors.grey900,
                          ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  const _SpeechBubble(text: "오늘은 아직 답변하지 않았어요"),
                  const SizedBox(height: AppSpacing.s12),
                  const _HeroFish(),
                  const SizedBox(height: AppSpacing.s12),
                  SizedBox(
                    height: 32,
                    child: TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.all(4),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: brand.c500,
                        textStyle: AppTypography.buttonSmall.copyWith(
                          color: brand.c500,
                        ),
                      ),
                      child: const Text("새로운 질문 받기"),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: FilledButton(
                      onPressed: () =>
                          HomeScreen.openTodayQuestionAnswer(context),
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
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroFish extends StatelessWidget {
  const _HeroFish();

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    return SizedBox(
      width: 150,
      height: 150,
      child: Stack(
        children: <Widget>[
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Image.asset(
              HomeScreen._heroFishAsset,
              width: 150,
              height: 150,
              fit: BoxFit.contain,
              errorBuilder: (_, error, stackTrace) {
                return const Center(
                  child: Text("🐟", style: TextStyle(fontSize: 64)),
                );
              },
            ),
          ),
          Positioned(left: 16, top: 12, child: _bubble(12, brand)),
          Positioned(left: 8, top: 30, child: _bubble(8, brand)),
          Positioned(left: 24, top: 42, child: _bubble(10, brand)),
        ],
      ),
    );
  }

  Widget _bubble(double size, BrandScale brand) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: brand.c300.withValues(alpha: 0.8),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppNeutralColors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: AppElevation.level1,
          ),
          child: Text(
            text,
            style: AppTypography.bodySmallMedium.copyWith(
              color: AppNeutralColors.grey700,
            ),
          ),
        ),
        CustomPaint(size: const Size(10, 6), painter: _SpeechTailPainter()),
      ],
    );
  }
}

class _SpeechTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = AppNeutralColors.white;
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

class _RecordStreakBar extends StatelessWidget {
  const _RecordStreakBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppNeutralColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppElevation.level1,
      ),
      child: Text(
        "🔥연속 7일째 기록중",
        textAlign: TextAlign.center,
        style: AppTypography.bodySmallSemiBold.copyWith(
          color: AppNeutralColors.grey900,
        ),
      ),
    );
  }
}

class _TodayRecordSection extends StatelessWidget {
  const _TodayRecordSection();

  @override
  Widget build(BuildContext context) {
    const List<_TodayRecordData> records = <_TodayRecordData>[
      _TodayRecordData(
        body:
            "올해는 꼭 해외여행을 다녀오고 싶습니다.\n코로나 이후로 한 번도 비행기를 타본 적이\n없어서, 짧게라도 일본 교토에 가서 벚꽃...",
        name: "익명의 호랑이님",
      ),
    ];
    final bool hasRecords = records.isNotEmpty;
    final TextTheme textTheme = Theme.of(context).textTheme;
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
                textTheme.titleLarge?.copyWith(color: AppNeutralColors.grey900) ??
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
                itemBuilder: (context, index) =>
                    _TodayRecordCard(record: records[index]),
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
            borderRadius: BorderRadius.circular(16),
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
  const _TodayRecordCard({required this.record});

  final _TodayRecordData record;

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    return Container(
      width: 320,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppNeutralColors.white,
        borderRadius: BorderRadius.circular(16),
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0F000000),
            offset: Offset(0, 2),
            blurRadius: 8,
          ),
        ],
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
    const List<String> tags = <String>["여행 ✈️", "독서📚", "사람🤝️", "습관⏰", "성장📈"];
    return Container(
      width: double.infinity,
      height: 278,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 32),
      decoration: BoxDecoration(
        color: brand.c50,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0F000000),
            offset: Offset(0, 2),
            blurRadius: 8,
          ),
        ],
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
              const SizedBox(height: AppSpacing.s16),
              Text(
                "최근 당신의 답변에는\n‘자기 성장 키워드’가 가장 많았어요",
                style: AppTypography.headingMediumExtraBold.copyWith(
                  color: AppNeutralColors.grey900,
                ),
                maxLines: 2,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s56),
          SizedBox(
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
        borderRadius: BorderRadius.circular(999),
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
