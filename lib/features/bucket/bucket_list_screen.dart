import "package:flutter/material.dart";

import "../../design_system/design_system.dart";
import "bucket_add_screen.dart";
import "bucket_category_empty_screen.dart";
import "../home/my_records_screen.dart";

class BucketListScreen extends StatefulWidget {
  const BucketListScreen({super.key});

  @override
  State<BucketListScreen> createState() => _BucketListScreenState();
}

class _BucketListScreenState extends State<BucketListScreen> {
  static const String _emptyBucketAsset =
      "assets/images/bucket/bucketlist_empty_state_note.png";
  int _selectedTabIndex = 0;
  final List<_BucketEntry> _entries = <_BucketEntry>[];
  final List<BucketCategorySelection> _customCategories =
      <BucketCategorySelection>[];

  List<String> get _tabs {
    return <String>[
      "ALL",
      ..._customCategories.map((BucketCategorySelection e) => e.name),
      "완료🎉",
    ];
  }

  int get _safeSelectedTabIndex {
    final int lastIndex = _tabs.length - 1;
    if (_selectedTabIndex < 0) {
      return 0;
    }
    if (_selectedTabIndex > lastIndex) {
      return lastIndex;
    }
    return _selectedTabIndex;
  }

  List<_BucketEntry> get _filteredEntries {
    final int selectedTab = _safeSelectedTabIndex;
    if (selectedTab == 0) {
      return _entries;
    }
    if (selectedTab == _tabs.length - 1) {
      return _entries.where((_BucketEntry e) => e.isCompleted).toList();
    }
    if (selectedTab > 0 && selectedTab < _tabs.length - 1) {
      return _entries
          .where((_BucketEntry e) => e.category == _tabs[selectedTab])
          .toList();
    }
    return <_BucketEntry>[];
  }

  Future<void> _openAddScreen() async {
    final BucketAddResult? result = await Navigator.of(context)
        .push<BucketAddResult>(
          MaterialPageRoute<BucketAddResult>(
            builder: (_) =>
                BucketAddScreen(initialCategories: _customCategories),
          ),
        );
    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _customCategories
        ..clear()
        ..addAll(result.categories);
      _entries.insert(
        0,
        _BucketEntry(
          title: result.item.title,
          category: result.item.categoryName,
          categoryColor: result.item.categoryColor,
          createdAt: result.item.createdAt,
          dueDate: result.item.dueDate,
          isCompleted: result.item.isCompleted,
        ),
      );
      _selectedTabIndex = 0;
    });
  }

  Future<void> _openCategoryScreen() async {
    final BucketCategoryResult? result = await Navigator.of(context)
        .push<BucketCategoryResult>(
          MaterialPageRoute<BucketCategoryResult>(
            builder: (_) =>
                BucketCategoryEmptyScreen(initialCategories: _customCategories),
          ),
        );
    if (result == null || !mounted) {
      return;
    }
    setState(() {
      _customCategories
        ..clear()
        ..addAll(result.categories);
    });
  }

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    final bool isEmpty = _entries.isEmpty;
    final double bottomInset =
        AppNavigationBar.totalHeight(context) + AppSpacing.s24;

    return Scaffold(
      backgroundColor: brand.bg,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.s20,
                49,
                AppSpacing.s20,
                isEmpty
                    ? AppNavigationBar.totalHeight(context) + 80
                    : bottomInset,
              ),
              child: isEmpty
                  ? _buildEmptyView(context)
                  : _buildMainView(context),
            ),
          ),
          if (isEmpty)
            Positioned(
              left: AppSpacing.s20,
              right: AppSpacing.s20,
              bottom: AppNavigationBar.totalHeight(context) + AppSpacing.s32,
              child: SizedBox(
                height: AppSpacing.s48,
                child: FilledButton(
                  onPressed: _openAddScreen,
                  style: FilledButton.styleFrom(
                    backgroundColor: brand.c500,
                    foregroundColor: AppNeutralColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.s8),
                    ),
                    textStyle: AppTypography.buttonMedium,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s24,
                    ),
                  ),
                  child: const Text("버킷리스트 추가"),
                ),
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AppNavigationBar(
              currentIndex: 1,
              onTap: (int index) {
                if (index == 0) {
                  Navigator.of(
                    context,
                  ).popUntil((Route<dynamic> route) => route.isFirst);
                  return;
                }
                if (index == 2) {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const MyRecordsScreen(),
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

  Widget _buildEmptyView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            const SizedBox(width: 24, height: 24),
            Expanded(
              child: Text(
                "버킷리스트",
                textAlign: TextAlign.center,
                style: AppTypography.headingXSmall.copyWith(
                  color: AppNeutralColors.grey900,
                ),
              ),
            ),
            const SizedBox(width: 24, height: 24),
          ],
        ),
        const Spacer(),
        Column(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s16,
                vertical: AppSpacing.s8,
              ),
              decoration: BoxDecoration(
                color: AppNeutralColors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: AppElevation.level1,
              ),
              child: Text(
                "오늘의 질문을 아직 저장된\n버킷리스트가 없어요 추가해볼까요?!",
                textAlign: TextAlign.center,
                style: AppTypography.bodySmallMedium.copyWith(
                  color: AppNeutralColors.grey700,
                ),
              ),
            ),
            CustomPaint(size: const Size(10, 6), painter: _BubbleTailPainter()),
            const SizedBox(height: AppSpacing.s16),
            Image.asset(
              _emptyBucketAsset,
              width: 140,
              height: 140,
              fit: BoxFit.contain,
            ),
          ],
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildMainView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            const SizedBox(width: 24, height: 24),
            Expanded(
              child: Text(
                "버킷리스트",
                textAlign: TextAlign.center,
                style: AppTypography.headingXSmall.copyWith(
                  color: AppNeutralColors.grey900,
                ),
              ),
            ),
            GestureDetector(
              onTap: _openAddScreen,
              child: const Icon(
                Icons.edit_outlined,
                size: AppSpacing.s24,
                color: AppNeutralColors.grey900,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s20),
        Row(
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _tabs.asMap().entries.map((
                    MapEntry<int, String> entry,
                  ) {
                    return Padding(
                      padding: EdgeInsets.only(
                        right: entry.key == _tabs.length - 1
                            ? 0
                            : AppSpacing.s8,
                      ),
                      child: _BucketTabChip(
                        label: entry.value,
                        selected: entry.key == _safeSelectedTabIndex,
                        onTap: () {
                          setState(() {
                            _selectedTabIndex = entry.key;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s8),
            GestureDetector(
              onTap: _openCategoryScreen,
              child: Container(
                width: 31,
                height: 31,
                decoration: BoxDecoration(
                  color: AppNeutralColors.white,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  boxShadow: AppElevation.level2,
                ),
                child: const Icon(
                  Icons.add,
                  size: 20,
                  color: AppNeutralColors.grey900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s32),
        Expanded(
          child: ListView.separated(
            itemCount: _filteredEntries.length,
            separatorBuilder: (_, int index) =>
                const SizedBox(height: AppSpacing.s16),
            itemBuilder: (BuildContext context, int index) {
              final _BucketEntry entry = _filteredEntries[index];
              return _BucketListCard(entry: entry);
            },
          ),
        ),
      ],
    );
  }
}

class _BucketEntry {
  const _BucketEntry({
    required this.title,
    required this.category,
    required this.categoryColor,
    required this.createdAt,
    this.dueDate,
    this.isCompleted = false,
  });

  final String title;
  final String category;
  final Color categoryColor;
  final DateTime createdAt;
  final DateTime? dueDate;
  final bool isCompleted;
}

class _BucketTabChip extends StatelessWidget {
  const _BucketTabChip({
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
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s20,
          vertical: AppSpacing.s6,
        ),
        decoration: BoxDecoration(
          color: selected ? brand.c100 : AppNeutralColors.white,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: selected ? Border.all(color: brand.c500) : null,
          boxShadow: AppElevation.level1,
        ),
        child: Text(
          label,
          style: AppTypography.bodySmallSemiBold.copyWith(
            color: selected ? brand.c500 : AppNeutralColors.grey600,
          ),
        ),
      ),
    );
  }
}

class _BucketListCard extends StatelessWidget {
  const _BucketListCard({required this.entry});

  final _BucketEntry entry;

  bool get _isNew =>
      DateTime.now().difference(entry.createdAt) < const Duration(days: 1);

  @override
  Widget build(BuildContext context) {
    final String dueText = entry.dueDate == null
        ? "-"
        : "${entry.dueDate!.year.toString().padLeft(4, "0")}."
              "${entry.dueDate!.month.toString().padLeft(2, "0")}."
              "${entry.dueDate!.day.toString().padLeft(2, "0")}";

    return Container(
      decoration: BoxDecoration(
        color: AppNeutralColors.white,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        boxShadow: AppElevation.level1,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      if (_isNew)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.s8,
                            vertical: AppSpacing.s2,
                          ),
                          decoration: BoxDecoration(
                            color: AppAccentColors.lemon,
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                          child: Text(
                            "NEW",
                            style: AppTypography.captionSmall.copyWith(
                              color: AppNeutralColors.grey900,
                            ),
                          ),
                        ),
                      if (_isNew) const SizedBox(width: AppSpacing.s4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s8,
                          vertical: AppSpacing.s2,
                        ),
                        decoration: BoxDecoration(
                          color: entry.categoryColor,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          entry.category,
                          style: AppTypography.captionSmall.copyWith(
                            color: AppNeutralColors.grey900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Text(
                    entry.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.heading2XSmall.copyWith(
                      color: AppNeutralColors.grey900,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s2),
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: AppNeutralColors.grey500,
                      ),
                      const SizedBox(width: AppSpacing.s4),
                      Text(
                        dueText,
                        style: AppTypography.bodySmallMedium.copyWith(
                          color: AppNeutralColors.grey500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.s8),
            const Icon(
              Icons.more_vert,
              size: AppSpacing.s24,
              color: AppNeutralColors.grey500,
            ),
          ],
        ),
      ),
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
