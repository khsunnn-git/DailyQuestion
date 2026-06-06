import "dart:async";

import "package:flutter/material.dart";

import "../../design_system/design_system.dart";

class BucketRecommendationItem {
  const BucketRecommendationItem({
    required this.title,
    required this.category,
    required this.color,
  });

  final String title;
  final String category;
  final Color color;

  String get key => "$category::$title";
}

class BucketRecommendationScreen extends StatefulWidget {
  const BucketRecommendationScreen({
    super.key,
    required this.onAddRecommendation,
  });

  final Future<bool> Function(BucketRecommendationItem item)
  onAddRecommendation;

  @override
  State<BucketRecommendationScreen> createState() =>
      _BucketRecommendationScreenState();
}

class _BucketRecommendationScreenState
    extends State<BucketRecommendationScreen> {
  static const List<String> _categories = <String>[
    "여행",
    "운동",
    "자기계발",
    "취미",
    "저축",
  ];
  static const Map<String, List<String>> _recommendations =
      <String, List<String>>{
        "여행": <String>[
          "혼자 떠나는 1박 2일 여행 해보기 🐣",
          "한 달 동안 낯선 도시에서 살아보기 🏙️",
          "여행지에서 로컬 음식 3가지 이상 먹어보기 🥘",
          "여행 다녀온 뒤 포토북 만들기 📸",
          "부모님과 함께 추억 여행 가기 🧑‍🧑‍🧒‍🧒",
          "혼자 해외여행 도전해보기 🗺️",
          "새벽 비행기 타고 즉흥 여행 떠나기 🛫",
        ],
        "운동": <String>[
          "한 달 동안 주 3회 이상 운동 꾸준히 하기 ✅",
          "마라톤 5km 완주해보기 🏃‍♀️🏃‍♂️",
          "아침 운동 습관 들여보기 💪",
          "등산해서 정상 올라가기 ⛰️",
          "수영 배우기 🤿",
          "배드민턴, 테니스 같은 새로운 운동 해보기 🎾",
          "필라테스나 요가 한 달 체험해보기 🧘‍♀️",
        ],
        "자기계발": <String>[
          "한 달에 책 1권 이상 읽기 📚",
          "매일 10분이라도 영어 공부하기 📖",
          "배우고 싶었던 자격증이나 강의 도전하기 📑",
          "아침 30분 일찍 일어나기 ☀️",
          "한 달 동안 SNS 사용 시간 줄여보기 📱",
          "혼자 영화나 전시 보러 가보기 🎞️",
          "새로운 언어 한 가지 배워보기 🧐",
        ],
        "취미": <String>[
          "그림이나 캘리그래피 배워보기 🎨",
          "악기 한 곡 완주해보기 🎹",
          "한 달 동안 사진 기록 남기기 📷",
          "도자기나 공예 원데이 클래스 가보기 🧶",
          "좋아하는 장르 영화 10편 보기 🎬",
          "나만의 플레이리스트 만들기 🎧",
          "주말마다 새로운 카페 탐방하기 ☕",
        ],
        "저축": <String>[
          "사고 싶었던 물건 대신 저축해보기 💰",
          "여행 자금 따로 모아보기 💵",
          "한 달 소비 내역 기록하기 📝",
          "적금 하나 새로 시작하기 🧧",
          "월급이나 용돈의 10% 이상 저축하기",
          "가계부 꾸준히 써보기",
          "1년 뒤를 위한 버킷리스트 통장 만들기",
        ],
      };
  static const List<Color> _accentColors = <Color>[
    AppAccentColors.mint,
    AppAccentColors.sky,
    AppAccentColors.coral,
    AppAccentColors.lemon,
    AppAccentColors.lavender,
    AppAccentColors.peach,
    AppAccentColors.oliveMist,
    AppAccentColors.cyanBreeze,
    AppAccentColors.rosePetal,
    AppAccentColors.plumMilk,
    AppAccentColors.periwinkle,
    AppAccentColors.softMocha,
  ];

  int _selectedCategoryIndex = 0;
  late final PageController _pageController;
  late final ScrollController _categoryScrollController;
  final Set<String> _addedItemKeys = <String>{};

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _categoryScrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _showToast("추천된 버킷리스트를 추가하고\n다양한 활동을 경험해보세요!");
    });
  }

  @override
  void dispose() {
    _categoryScrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Color _categoryColor(String category) {
    int hash = 0;
    for (final int codeUnit in category.codeUnits) {
      hash = (hash * 31 + codeUnit) & 0x7fffffff;
    }
    return _accentColors[hash % _accentColors.length];
  }

  List<BucketRecommendationItem> _itemsFor(String category) {
    final Color color = _categoryColor(category);
    return (_recommendations[category] ?? const <String>[])
        .map(
          (String title) => BucketRecommendationItem(
            title: title,
            category: category,
            color: color,
          ),
        )
        .toList(growable: false);
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Center(child: AppToastMessage(text: message)),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  void _selectCategory(int index) {
    if (_selectedCategoryIndex != index) {
      setState(() {
        _selectedCategoryIndex = index;
      });
    }
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    }
    _scrollSelectedCategoryIntoView(index);
  }

  void _scrollSelectedCategoryIntoView(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_categoryScrollController.hasClients) {
        return;
      }
      final double maxOffset =
          _categoryScrollController.position.maxScrollExtent;
      final double targetOffset = (index * 76.0).clamp(0.0, maxOffset);
      _categoryScrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _addItem(BucketRecommendationItem item) async {
    if (_addedItemKeys.contains(item.key)) {
      return;
    }
    final bool added = await widget.onAddRecommendation(item);
    if (!mounted) {
      return;
    }
    if (!added) {
      setState(() {
        _addedItemKeys.add(item.key);
      });
      _showToast("이미 추가된 버킷리스트입니다.");
      return;
    }
    setState(() {
      _addedItemKeys.add(item.key);
    });
    _showToast("버킷리스트가 추가되었습니다.");
  }

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;

    return Scaffold(
      backgroundColor: brand.bg,
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(top: AppHeaderTokens.topInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SizedBox(
                height: AppHeaderTokens.height,
                child: Row(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.s20),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => Navigator.of(context).pop(),
                        child: const SizedBox(
                          width: AppSpacing.s24,
                          height: AppSpacing.s24,
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            size: AppSpacing.s20,
                            color: AppNeutralColors.grey900,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        "추천 버킷리스트",
                        textAlign: TextAlign.center,
                        style: AppTypography.headingXSmall.copyWith(
                          color: AppNeutralColors.grey900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 44),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.s16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s20),
                child: SingleChildScrollView(
                  controller: _categoryScrollController,
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.asMap().entries.map((
                      MapEntry<int, String> entry,
                    ) {
                      return Padding(
                        padding: EdgeInsets.only(
                          right: entry.key == _categories.length - 1
                              ? 0
                              : AppSpacing.s8,
                        ),
                        child: _RecommendationCategoryChip(
                          label: entry.value,
                          selected: entry.key == _selectedCategoryIndex,
                          onTap: () => _selectCategory(entry.key),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s32),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _categories.length,
                  onPageChanged: (int index) {
                    setState(() {
                      _selectedCategoryIndex = index;
                    });
                    _scrollSelectedCategoryIntoView(index);
                  },
                  itemBuilder: (BuildContext context, int categoryIndex) {
                    final List<BucketRecommendationItem> items = _itemsFor(
                      _categories[categoryIndex],
                    );
                    return ListView.separated(
                      key: PageStorageKey<String>(
                        "bucket-recommendation-$categoryIndex",
                      ),
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.s20,
                        0,
                        AppSpacing.s20,
                        AppSpacing.s32,
                      ),
                      itemCount: items.length,
                      separatorBuilder: (_, int index) =>
                          const SizedBox(height: AppSpacing.s12),
                      itemBuilder: (BuildContext context, int index) {
                        final BucketRecommendationItem item = items[index];
                        return _RecommendationListItem(
                          item: item,
                          added: _addedItemKeys.contains(item.key),
                          onTap: () => unawaited(_addItem(item)),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecommendationCategoryChip extends StatelessWidget {
  const _RecommendationCategoryChip({
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
        decoration: BoxDecoration(
          color: selected ? brand.c100 : AppNeutralColors.white,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: selected ? brand.c500 : AppNeutralColors.grey100,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.bodySmallSemiBold.copyWith(
              color: selected ? brand.c500 : AppNeutralColors.grey600,
            ),
          ),
        ),
      ),
    );
  }
}

class _RecommendationListItem extends StatelessWidget {
  const _RecommendationListItem({
    required this.item,
    required this.added,
    required this.onTap,
  });

  final BucketRecommendationItem item;
  final bool added;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 54),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s24,
          AppSpacing.s16,
          AppSpacing.s16,
          AppSpacing.s16,
        ),
        decoration: BoxDecoration(
          color: AppNeutralColors.white,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.buttonSmall.copyWith(
                  color: AppNeutralColors.grey800,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s12),
            Icon(
              added ? Icons.check : Icons.add,
              size: AppSpacing.s24,
              color: brand.c500,
            ),
          ],
        ),
      ),
    );
  }
}
