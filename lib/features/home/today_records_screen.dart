import "dart:async";
import "dart:math";

import "package:flutter/material.dart";

import "../../design_system/design_system.dart";

class TodayRecordsScreen extends StatefulWidget {
  const TodayRecordsScreen({super.key});

  @override
  State<TodayRecordsScreen> createState() => _TodayRecordsScreenState();
}

class _TodayRecordsScreenState extends State<TodayRecordsScreen>
    with WidgetsBindingObserver {
  bool _isLoading = true;
  List<_TodayRecordItem> _records = const <_TodayRecordItem>[];
  Timer? _hourlyRefreshTimer;
  DateTime _lastRefreshedAt = DateTime.now();

  static const List<_TodayRecordRawItem> _allRecords = <_TodayRecordRawItem>[
    _TodayRecordRawItem(
      body:
          "올해는 꼭 해외여행을 다녀오고 싶습니다.\n코로나 이후로 한 번도 비행기를 타본 적이\n없어서, 짧게라도 일본 교토에 가서 벚꽃 시즌을\n직접 보고 사진을 남기는 게 목표예요.",
      author: "익명의 호랑이님 답변",
      isPublic: true,
      sentimentScore: 0.68,
      hasBlockedWords: false,
    ),
    _TodayRecordRawItem(
      body:
          "올해는 오랫동안 연락하지 못했던 대학 친구에게 먼저 연락해서 꼭 만나고 싶습니다. 연락이\n끊긴 지 벌써 몇 년이 되었는데, 다시 좋은 인연을 이어가고 싶어요.",
      author: "물먹은 하마님 답변",
      isPublic: true,
      sentimentScore: 0.41,
      hasBlockedWords: false,
    ),
    _TodayRecordRawItem(
      body: "기타로 노래 한 곡 완주하기",
      author: "수영하는 라마님 답변",
      isPublic: true,
      sentimentScore: 0.32,
      hasBlockedWords: false,
    ),
    _TodayRecordRawItem(
      body:
          "올해는 글쓰기를 꾸준히 이어가고 싶어요. 블로그에 짧은 글이라도 10편 이상은 쓰고, 나중에\n모으면 작은 에세이집으로 엮어보고 싶습니다. 제 생각을 정리하고 기록으로 남기는 습관을 만들고 싶어요.",
      author: "무서운 고양이님 답변",
      isPublic: true,
      sentimentScore: 0.52,
      hasBlockedWords: false,
    ),
    _TodayRecordRawItem(
      body: "하루 20분 독서 습관 만들기",
      author: "익명의 여우님 답변",
      isPublic: true,
      sentimentScore: 0.27,
      hasBlockedWords: false,
    ),
    _TodayRecordRawItem(
      body: "나를 위한 운동 루틴 30일 도전",
      author: "웃는 토끼님 답변",
      isPublic: true,
      sentimentScore: 0.48,
      hasBlockedWords: false,
    ),
    _TodayRecordRawItem(
      body: "감정이 많이 무거워서 오늘은 아무것도 하기 싫어요.",
      author: "익명의 고슴도치님 답변",
      isPublic: true,
      sentimentScore: -0.29,
      hasBlockedWords: false,
    ),
    _TodayRecordRawItem(
      body: "올해는 가족과 더 자주 대화하는 시간을 만들고 싶어요.",
      author: "익명의 사슴님 답변",
      isPublic: true,
      sentimentScore: 0.36,
      hasBlockedWords: false,
    ),
    _TodayRecordRawItem(
      body: "공개 설정이 아니라 개인 기록으로만 남겼어요.",
      author: "익명의 너구리님 답변",
      isPublic: false,
      sentimentScore: 0.21,
      hasBlockedWords: false,
    ),
    _TodayRecordRawItem(
      body: "올해는 일주일에 한 번 새로운 장소를 걸어보려 해요.",
      author: "익명의 고양이님 답변",
      isPublic: true,
      sentimentScore: 0.44,
      hasBlockedWords: false,
    ),
    _TodayRecordRawItem(
      body: "타인을 향한 모욕 표현이 포함된 문장",
      author: "익명의 늑대님 답변",
      isPublic: true,
      sentimentScore: -0.12,
      hasBlockedWords: true,
    ),
    _TodayRecordRawItem(
      body: "올해는 그림 그리기를 꾸준히 해보고 싶어요.",
      author: "익명의 펭귄님 답변",
      isPublic: true,
      sentimentScore: 0.39,
      hasBlockedWords: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadRecords();
    _startHourlyRefreshTimer();
  }

  Future<void> _loadRecords() async {
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) {
      return;
    }
    final DateTime now = DateTime.now();
    final List<_TodayRecordItem> visibleRecords = _allRecords
        .where(_isVisiblePublicRecord)
        .map((item) => _TodayRecordItem(body: item.body, author: item.author))
        .toList(growable: false);
    final List<_TodayRecordItem> sampledRecords = _sampleRecords(
      visibleRecords: visibleRecords,
      now: now,
    );
    setState(() {
      _records = sampledRecords;
      _isLoading = false;
      _lastRefreshedAt = now;
    });
  }

  bool _isVisiblePublicRecord(_TodayRecordRawItem item) {
    if (!item.isPublic) {
      return false;
    }
    if (item.hasBlockedWords) {
      return false;
    }
    return item.sentimentScore >= -0.25;
  }

  List<_TodayRecordItem> _sampleRecords({
    required List<_TodayRecordItem> visibleRecords,
    required DateTime now,
  }) {
    if (visibleRecords.isEmpty) {
      return const <_TodayRecordItem>[];
    }
    final int minCount = visibleRecords.length < 5 ? visibleRecords.length : 5;
    final int maxCount = visibleRecords.length < 10
        ? visibleRecords.length
        : 10;
    final Random random = Random(
      now.year * 1000000 + now.month * 10000 + now.day * 100 + now.hour,
    );
    final List<_TodayRecordItem> shuffled = List<_TodayRecordItem>.from(
      visibleRecords,
    )..shuffle(random);
    final int count = minCount == maxCount
        ? minCount
        : minCount + random.nextInt(maxCount - minCount + 1);
    return shuffled.take(count).toList(growable: false);
  }

  void _startHourlyRefreshTimer() {
    _hourlyRefreshTimer?.cancel();
    _hourlyRefreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) {
        return;
      }
      _refreshIfHourChanged();
    });
  }

  Future<void> _refreshIfHourChanged() async {
    final DateTime now = DateTime.now();
    final bool changed =
        now.year != _lastRefreshedAt.year ||
        now.month != _lastRefreshedAt.month ||
        now.day != _lastRefreshedAt.day ||
        now.hour != _lastRefreshedAt.hour;
    if (!changed) {
      return;
    }
    setState(() {
      _isLoading = true;
    });
    await _loadRecords();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshIfHourChanged();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _hourlyRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    return Scaffold(
      backgroundColor: brand.bg,
      body: SafeArea(
        child: _isLoading
            ? const _RecordsLoadingView()
            : _RecordsListView(records: _records),
      ),
    );
  }
}

class _RecordsLoadingView extends StatelessWidget {
  const _RecordsLoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: AppNeutralColors.grey500,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: AppSpacing.s56),
          Text(
            "사람들의 생각을 불러오는 중입니다.",
            style: AppTypography.headingSmall.copyWith(
              color: AppNeutralColors.grey900,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordsListView extends StatelessWidget {
  const _RecordsListView({required this.records});

  final List<_TodayRecordItem> records;

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 390),
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s20,
                  AppSpacing.s20,
                  AppSpacing.s20,
                  96,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            color: AppNeutralColors.grey900,
                            size: 22,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                        Expanded(
                          child: Text(
                            "오늘의 기록",
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
                        const SizedBox(width: 40),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s8,
                        vertical: AppSpacing.s24,
                      ),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: brand.c200)),
                      ),
                      child: Column(
                        children: <Widget>[
                          Text(
                            "올해 안에 꼭 해보고 싶은 일\n하나는 무엇인가요?",
                            textAlign: TextAlign.center,
                            style: AppTypography.headingLarge.copyWith(
                              color: AppNeutralColors.grey900,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.s16),
                          Text(
                            "NNN째 기록중",
                            style: AppTypography.bodySmallRegular.copyWith(
                              color: AppNeutralColors.grey600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s16),
                    ...records.map((item) => _FullRecordCard(item: item)),
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
    );
  }
}

class _TodayRecordItem {
  const _TodayRecordItem({required this.body, required this.author});

  final String body;
  final String author;
}

class _TodayRecordRawItem {
  const _TodayRecordRawItem({
    required this.body,
    required this.author,
    required this.isPublic,
    required this.sentimentScore,
    required this.hasBlockedWords,
  });

  final String body;
  final String author;
  final bool isPublic;
  final double sentimentScore;
  final bool hasBlockedWords;
}

class _FullRecordCard extends StatelessWidget {
  const _FullRecordCard({required this.item});

  final _TodayRecordItem item;

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.s16),
      padding: const EdgeInsets.all(AppSpacing.s32),
      decoration: BoxDecoration(
        color: AppNeutralColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppElevation.level1,
      ),
      child: Column(
        children: <Widget>[
          Text(
            item.body,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMediumMedium.copyWith(
              color: AppNeutralColors.grey900,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.s24),
          Text(
            item.author,
            style: AppTypography.bodySmallSemiBold.copyWith(color: brand.c500),
          ),
        ],
      ),
    );
  }
}
