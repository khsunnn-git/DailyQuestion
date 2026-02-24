import "dart:async";

import "package:flutter/material.dart";

import "../../design_system/design_system.dart";
import "../question/today_question_store.dart";
import "today_records_data_source.dart";

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
    final List<_TodayRecordItem> sampledRecords =
        TodayRecordsDataSource.sampledVisibleRecords(now)
            .map(
              (item) => _TodayRecordItem(body: item.body, author: item.author),
            )
            .toList(growable: false);
    final List<_TodayRecordItem> myRecords = TodayQuestionStore.instance.value
        .where((TodayQuestionRecord item) => item.isPublic)
        .map(
          (TodayQuestionRecord item) =>
              _TodayRecordItem(body: item.answer, author: item.author),
        )
        .toList(growable: false);
    final List<_TodayRecordItem> mergedRecords = <_TodayRecordItem>[
      ...myRecords,
      ...sampledRecords,
    ];
    setState(() {
      _records = mergedRecords;
      _isLoading = false;
      _lastRefreshedAt = now;
    });
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
          const AppLoadingIndicator(),
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
                            "${records.length}명 기록중",
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
    );
  }
}

class _TodayRecordItem {
  const _TodayRecordItem({required this.body, required this.author});

  final String body;
  final String author;
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
        borderRadius: AppRadius.br16,
        boxShadow: AppElevation.level1,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            width: double.infinity,
            child: Text(
              item.body,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMediumMedium.copyWith(
                color: AppNeutralColors.grey900,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s24),
          SizedBox(
            width: double.infinity,
            child: Text(
              item.author,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmallSemiBold.copyWith(
                color: brand.c500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
