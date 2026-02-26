import "package:flutter/material.dart";

import "../../design_system/design_system.dart";
import "bucket_category_empty_screen.dart";
import "bucket_save_success_screen.dart";

class BucketCreatedItem {
  const BucketCreatedItem({
    required this.title,
    required this.categoryName,
    required this.categoryColor,
    required this.createdAt,
    required this.isCompleted,
    this.dueDate,
  });

  final String title;
  final String categoryName;
  final Color categoryColor;
  final DateTime createdAt;
  final bool isCompleted;
  final DateTime? dueDate;
}

class BucketAddResult {
  const BucketAddResult({required this.item, required this.categories});

  final BucketCreatedItem item;
  final List<BucketCategorySelection> categories;
}

class BucketAddScreen extends StatefulWidget {
  const BucketAddScreen({
    super.key,
    this.initialCategories = const <BucketCategorySelection>[],
    this.initialItem,
    this.isEditing = false,
  });

  final List<BucketCategorySelection> initialCategories;
  final BucketCreatedItem? initialItem;
  final bool isEditing;

  @override
  State<BucketAddScreen> createState() => _BucketAddScreenState();
}

class _BucketAddScreenState extends State<BucketAddScreen> {
  late final TextEditingController _titleController;
  bool _isCompleted = false;
  late final List<BucketCategorySelection> _categories;
  BucketCategorySelection? _selectedCategory;
  DateTime? _selectedDueDate;

  bool get _canSave =>
      _titleController.text.trim().isNotEmpty && _selectedCategory != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.initialItem?.title ?? "",
    );
    _categories = List<BucketCategorySelection>.from(widget.initialCategories);
    _isCompleted = widget.initialItem?.isCompleted ?? false;
    _selectedDueDate = widget.initialItem?.dueDate;
    final BucketCreatedItem? initialItem = widget.initialItem;
    if (initialItem != null) {
      final int existingIndex = _categories.indexWhere(
        (BucketCategorySelection e) => e.name == initialItem.categoryName,
      );
      if (existingIndex < 0) {
        _categories.add(
          BucketCategorySelection(
            name: initialItem.categoryName,
            color: initialItem.categoryColor,
          ),
        );
      }
      _selectedCategory = _categories.firstWhere(
        (BucketCategorySelection e) => e.name == initialItem.categoryName,
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;

    return Scaffold(
      backgroundColor: brand.bg,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s20,
          49,
          AppSpacing.s20,
          AppSpacing.s24,
        ),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back),
                  color: AppNeutralColors.grey900,
                  iconSize: AppSpacing.s24,
                  splashRadius: AppSpacing.s20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: AppSpacing.s24,
                    height: AppSpacing.s24,
                  ),
                ),
                Expanded(
                  child: Text(
                    "버킷리스트",
                    textAlign: TextAlign.center,
                    style: AppTypography.headingXSmall.copyWith(
                      color: AppNeutralColors.grey900,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s24, height: AppSpacing.s24),
              ],
            ),
            const SizedBox(height: AppSpacing.s40),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    _InputCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _RequiredTitle(label: "제목"),
                          const SizedBox(height: AppSpacing.s2),
                          SizedBox(
                            height: 42,
                            child: TextField(
                              controller: _titleController,
                              onChanged: (_) => setState(() {}),
                              cursorColor: brand.c500,
                              style: AppTypography.bodyMediumMedium.copyWith(
                                color: AppNeutralColors.grey900,
                              ),
                              decoration: InputDecoration(
                                hintText: "간단하게 버킷리스트를 작성해보세요.",
                                hintStyle: AppTypography.bodyMediumMedium
                                    .copyWith(color: AppNeutralColors.grey300),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                hoverColor: Colors.transparent,
                                contentPadding: EdgeInsets.zero,
                                suffixIcon: _titleController.text.trim().isEmpty
                                    ? null
                                    : GestureDetector(
                                        onTap: () {
                                          _titleController.clear();
                                          setState(() {});
                                        },
                                        child: Container(
                                          width: AppSpacing.s20,
                                          height: AppSpacing.s20,
                                          decoration: const BoxDecoration(
                                            color: AppNeutralColors.grey700,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            size: 14,
                                            color: AppNeutralColors.white,
                                          ),
                                        ),
                                      ),
                                suffixIconConstraints:
                                    const BoxConstraints.tightFor(
                                      width: AppSpacing.s20,
                                      height: AppSpacing.s20,
                                    ),
                              ),
                            ),
                          ),
                          Container(height: 1, color: AppNeutralColors.grey900),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s20),
                    _InputCard(
                      onTap: () async {
                        final BucketCategoryResult? result =
                            await Navigator.of(
                              context,
                            ).push<BucketCategoryResult>(
                              MaterialPageRoute<BucketCategoryResult>(
                                builder: (_) => BucketCategoryEmptyScreen(
                                  initialCategories: _categories,
                                  initialSelectedName: _selectedCategory?.name,
                                ),
                              ),
                            );
                        if (result == null || !mounted) {
                          return;
                        }
                        setState(() {
                          _categories
                            ..clear()
                            ..addAll(result.categories);
                          _selectedCategory = result.selected;
                        });
                      },
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                _RequiredTitle(label: "카테고리"),
                                const SizedBox(height: AppSpacing.s2),
                                Text(
                                  "나만의 카테고리를 설정해보세요.",
                                  style: AppTypography.bodySmallMedium.copyWith(
                                    color: AppNeutralColors.grey300,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_selectedCategory != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.s8,
                                vertical: AppSpacing.s2,
                              ),
                              decoration: BoxDecoration(
                                color: _selectedCategory!.color,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.full,
                                ),
                              ),
                              child: Text(
                                _selectedCategory!.name,
                                style: AppTypography.captionSmall.copyWith(
                                  color: AppNeutralColors.grey900,
                                ),
                              ),
                            ),
                          if (_selectedCategory != null)
                            const SizedBox(width: AppSpacing.s4),
                          const Icon(
                            Icons.chevron_right,
                            size: AppSpacing.s24,
                            color: AppNeutralColors.grey900,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s20),
                    _InputCard(
                      child: Column(
                        children: <Widget>[
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () async {
                              final DateTime? selected =
                                  await _showDdayCalendarPopup(context);
                              if (!mounted || selected == null) {
                                return;
                              }
                              setState(() {
                                _selectedDueDate = selected;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.s16,
                              ),
                              child: Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      "D-Day",
                                      style: AppTypography.bodyMediumSemiBold
                                          .copyWith(
                                            color: AppNeutralColors.grey900,
                                          ),
                                    ),
                                  ),
                                  Row(
                                    children: <Widget>[
                                      if (_selectedDueDate != null)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            right: AppSpacing.s4,
                                          ),
                                          child: Text(
                                            _formatDate(_selectedDueDate!),
                                            style: AppTypography.bodySmallMedium
                                                .copyWith(
                                                  color:
                                                      AppNeutralColors.grey500,
                                                ),
                                          ),
                                        ),
                                      const Icon(
                                        Icons.chevron_right,
                                        size: AppSpacing.s24,
                                        color: AppNeutralColors.grey900,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.s16),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      "버킷리스트 완료",
                                      style: AppTypography.bodyMediumSemiBold
                                          .copyWith(
                                            color: AppNeutralColors.grey900,
                                          ),
                                    ),
                                    const SizedBox(height: AppSpacing.s2),
                                    Text(
                                      "완료 리스트로 이동합니다.",
                                      style: AppTypography.bodySmallMedium
                                          .copyWith(
                                            color: AppNeutralColors.grey300,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: 58,
                                height: 58,
                                child: AppIconToggle(
                                  value: _isCompleted,
                                  onChanged: (bool value) {
                                    setState(() {
                                      _isCompleted = value;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s20),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: FilledButton(
                onPressed: _canSave
                    ? () async {
                        final NavigatorState navigator = Navigator.of(context);
                        await navigator.push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) => const BucketSaveSuccessScreen(),
                          ),
                        );
                        if (!mounted || _selectedCategory == null) {
                          return;
                        }
                        final DateTime createdAt =
                            widget.initialItem?.createdAt ?? DateTime.now();
                        navigator.pop(
                          BucketAddResult(
                            item: BucketCreatedItem(
                              title: _titleController.text.trim(),
                              categoryName: _selectedCategory!.name,
                              categoryColor: _selectedCategory!.color,
                              createdAt: createdAt,
                              isCompleted: _isCompleted,
                              dueDate: _selectedDueDate,
                            ),
                            categories:
                                List<BucketCategorySelection>.unmodifiable(
                                  _categories,
                                ),
                          ),
                        );
                      }
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: brand.c600,
                  disabledBackgroundColor: Color.alphaBlend(
                    AppTransparentColors.light64,
                    brand.c600,
                  ),
                  foregroundColor: AppNeutralColors.white,
                  disabledForegroundColor: brand.c100,
                  textStyle: AppTypography.buttonLarge,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.s8),
                  ),
                ),
                child: Text(widget.isEditing ? "수정하기" : "저장하기"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<DateTime?> _showDdayCalendarPopup(BuildContext context) async {
    final BrandScale brand = context.appBrandScale;
    final DateTime now = DateTime.now();
    final DateTime firstDate = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 1));
    final DateTime lastDate = DateTime(now.year + 10, 12, 31);
    final DateTime initial =
        (_selectedDueDate != null && !_selectedDueDate!.isBefore(firstDate))
        ? _selectedDueDate!
        : firstDate;
    DateTime selectedDate = initial;
    DateTime visibleMonth = DateTime(initial.year, initial.month, 1);
    bool isYearMonthMode = false;
    int pickerYear = visibleMonth.year;
    int pickerMonth = visibleMonth.month;
    final DateTime firstMonth = DateTime(firstDate.year, firstDate.month, 1);
    final DateTime lastMonth = DateTime(lastDate.year, lastDate.month, 1);
    final List<int> years = <int>[
      for (int y = firstDate.year; y <= lastDate.year; y++) y,
    ];
    final FixedExtentScrollController yearController =
        FixedExtentScrollController(initialItem: years.indexOf(pickerYear));
    final List<int> initialMonths = <int>[
      for (
        int m = pickerYear == firstDate.year ? firstDate.month : 1;
        m <= (pickerYear == lastDate.year ? lastDate.month : 12);
        m++
      )
        m,
    ];
    final FixedExtentScrollController monthController =
        FixedExtentScrollController(
          initialItem: initialMonths.indexOf(pickerMonth),
        );

    final DateTime? result = await showGeneralDialog<DateTime>(
      context: context,
      barrierDismissible: true,
      barrierLabel: "dismiss",
      barrierColor: const Color(0x3D000000),
      transitionDuration: const Duration(milliseconds: 120),
      pageBuilder:
          (
            BuildContext pageContext,
            Animation<double> primaryAnimation,
            Animation<double> secondaryAnimation,
          ) => const SizedBox.shrink(),
      transitionBuilder:
          (
            BuildContext dialogContext,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            return FadeTransition(
              opacity: animation,
              child: Material(
                type: MaterialType.transparency,
                child: Center(
                  child: Container(
                    width: 350,
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                    decoration: BoxDecoration(
                      color: AppNeutralColors.white,
                      borderRadius: BorderRadius.circular(AppSpacing.s24),
                    ),
                    child: StatefulBuilder(
                      builder: (BuildContext context, StateSetter setDialogState) {
                        final List<String> weekDays = <String>[
                          "일",
                          "월",
                          "화",
                          "수",
                          "목",
                          "금",
                          "토",
                        ];
                        final int firstWeekdayOffset =
                            DateTime(
                              visibleMonth.year,
                              visibleMonth.month,
                              1,
                            ).weekday %
                            7;
                        final int previousMonthDays = DateTime(
                          visibleMonth.year,
                          visibleMonth.month,
                          0,
                        ).day;
                        final int daysInMonth = DateTime(
                          visibleMonth.year,
                          visibleMonth.month + 1,
                          0,
                        ).day;
                        final bool canGoPrevMonth =
                            visibleMonth.year > firstMonth.year ||
                            (visibleMonth.year == firstMonth.year &&
                                visibleMonth.month > firstMonth.month);
                        final bool canGoNextMonth =
                            visibleMonth.year < lastMonth.year ||
                            (visibleMonth.year == lastMonth.year &&
                                visibleMonth.month < lastMonth.month);

                        Widget buildMonthArrow({
                          required IconData icon,
                          required bool enabled,
                          required VoidCallback onTap,
                        }) {
                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: enabled ? onTap : null,
                            child: SizedBox(
                              width: AppSpacing.s24,
                              height: AppSpacing.s24,
                              child: Icon(
                                icon,
                                size: AppSpacing.s24,
                                color: enabled
                                    ? AppNeutralColors.grey900
                                    : AppNeutralColors.grey300,
                              ),
                            ),
                          );
                        }

                        Widget buildActionLabel({
                          required String text,
                          required Color color,
                          required VoidCallback onTap,
                        }) {
                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: onTap,
                            child: SizedBox(
                              height: 32,
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.s4),
                                child: Center(
                                  child: Text(
                                    text,
                                    style: AppTypography.buttonLarge.copyWith(
                                      color: color,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }

                        Widget buildDayCell(int index) {
                          final int day = index - firstWeekdayOffset + 1;
                          final bool isLeadingFromPreviousMonth = day <= 0;
                          final bool isInMonth = day >= 1 && day <= daysInMonth;
                          if (!isLeadingFromPreviousMonth && !isInMonth) {
                            return const SizedBox(width: 42, height: 32);
                          }

                          final DateTime date;
                          final bool disabled;
                          final bool selected;
                          final int displayDay;
                          if (isLeadingFromPreviousMonth) {
                            displayDay =
                                previousMonthDays -
                                firstWeekdayOffset +
                                index +
                                1;
                            date = DateTime(
                              visibleMonth.year,
                              visibleMonth.month - 1,
                              displayDay,
                            );
                            disabled = true;
                            selected = false;
                          } else {
                            displayDay = day;
                            date = DateTime(
                              visibleMonth.year,
                              visibleMonth.month,
                              displayDay,
                            );
                            disabled = date.isBefore(firstDate);
                            selected =
                                date.year == selectedDate.year &&
                                date.month == selectedDate.month &&
                                date.day == selectedDate.day;
                          }

                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: disabled
                                ? null
                                : () {
                                    setDialogState(() {
                                      selectedDate = date;
                                    });
                                  },
                            child: SizedBox(
                              width: 42,
                              height: 32,
                              child: Center(
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: <Widget>[
                                    if (selected)
                                      Container(
                                        width: 30,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          color: brand.c500,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    Text(
                                      "$displayDay",
                                      style: AppTypography.bodySmallSemiBold
                                          .copyWith(
                                            color: selected
                                                ? AppNeutralColors.white
                                                : disabled
                                                ? AppNeutralColors.grey200
                                                : AppNeutralColors.grey500,
                                            decoration: TextDecoration.none,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }

                        Widget buildCalendarGrid() {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              SizedBox(
                                height: 34,
                                child: Row(
                                  children: weekDays
                                      .map(
                                        (String day) => Expanded(
                                          child: Center(
                                            child: Text(
                                              day,
                                              style: AppTypography.captionSmall
                                                  .copyWith(
                                                    fontWeight: FontWeight.w400,
                                                    height: 1.5,
                                                    color: AppNeutralColors
                                                        .grey600,
                                                    decoration:
                                                        TextDecoration.none,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.s6),
                              ...List<Widget>.generate(6, (int row) {
                                return Padding(
                                  padding: EdgeInsets.only(
                                    bottom: row == 5 ? 0 : AppSpacing.s6,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: List<Widget>.generate(7, (
                                      int col,
                                    ) {
                                      final int index = row * 7 + col;
                                      return buildDayCell(index);
                                    }),
                                  ),
                                );
                              }),
                            ],
                          );
                        }

                        Widget buildYearMonthPicker() {
                          int minMonth = 1;
                          int maxMonth = 12;
                          if (pickerYear == firstDate.year) {
                            minMonth = firstDate.month;
                          }
                          if (pickerYear == lastDate.year) {
                            maxMonth = lastDate.month;
                          }
                          final List<int> months = <int>[
                            for (int m = minMonth; m <= maxMonth; m++) m,
                          ];
                          if (pickerMonth < minMonth ||
                              pickerMonth > maxMonth) {
                            pickerMonth = minMonth;
                          }

                          return SizedBox(
                            height: 184,
                            child: Stack(
                              children: <Widget>[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    SizedBox(
                                      width: 86,
                                      child: ListWheelScrollView.useDelegate(
                                        controller: yearController,
                                        itemExtent: 40,
                                        perspective: 0.003,
                                        physics:
                                            const FixedExtentScrollPhysics(),
                                        onSelectedItemChanged: (int index) {
                                          setDialogState(() {
                                            pickerYear = years[index];
                                            int dynamicMinMonth = 1;
                                            int dynamicMaxMonth = 12;
                                            if (pickerYear == firstDate.year) {
                                              dynamicMinMonth = firstDate.month;
                                            }
                                            if (pickerYear == lastDate.year) {
                                              dynamicMaxMonth = lastDate.month;
                                            }
                                            if (pickerMonth < dynamicMinMonth) {
                                              pickerMonth = dynamicMinMonth;
                                            } else if (pickerMonth >
                                                dynamicMaxMonth) {
                                              pickerMonth = dynamicMaxMonth;
                                            }
                                            final List<int> newMonths = <int>[
                                              for (
                                                int m = dynamicMinMonth;
                                                m <= dynamicMaxMonth;
                                                m++
                                              )
                                                m,
                                            ];
                                            monthController.jumpToItem(
                                              newMonths.indexOf(pickerMonth),
                                            );
                                          });
                                        },
                                        childDelegate: ListWheelChildBuilderDelegate(
                                          builder:
                                              (
                                                BuildContext context,
                                                int index,
                                              ) {
                                                if (index < 0 ||
                                                    index >= years.length) {
                                                  return null;
                                                }
                                                final bool isSelected =
                                                    years[index] == pickerYear;
                                                return Align(
                                                  alignment:
                                                      Alignment.centerRight,
                                                  child: Text(
                                                    "${years[index]}년",
                                                    style: AppTypography
                                                        .headingLarge
                                                        .copyWith(
                                                          fontWeight:
                                                              FontWeight.w800,
                                                          color: isSelected
                                                              ? AppNeutralColors
                                                                    .grey900
                                                              : AppNeutralColors
                                                                    .grey200,
                                                          decoration:
                                                              TextDecoration
                                                                  .none,
                                                        ),
                                                  ),
                                                );
                                              },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 44),
                                    SizedBox(
                                      width: 48,
                                      child: ListWheelScrollView.useDelegate(
                                        controller: monthController,
                                        itemExtent: 40,
                                        perspective: 0.003,
                                        physics:
                                            const FixedExtentScrollPhysics(),
                                        onSelectedItemChanged: (int index) {
                                          setDialogState(() {
                                            pickerMonth = months[index];
                                          });
                                        },
                                        childDelegate: ListWheelChildBuilderDelegate(
                                          builder:
                                              (
                                                BuildContext context,
                                                int index,
                                              ) {
                                                if (index < 0 ||
                                                    index >= months.length) {
                                                  return null;
                                                }
                                                final bool isSelected =
                                                    months[index] ==
                                                    pickerMonth;
                                                return Center(
                                                  child: Text(
                                                    "${months[index]}월",
                                                    style: AppTypography
                                                        .headingLarge
                                                        .copyWith(
                                                          fontWeight:
                                                              FontWeight.w800,
                                                          color: isSelected
                                                              ? AppNeutralColors
                                                                    .grey900
                                                              : AppNeutralColors
                                                                    .grey200,
                                                          decoration:
                                                              TextDecoration
                                                                  .none,
                                                        ),
                                                  ),
                                                );
                                              },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                IgnorePointer(
                                  child: Align(
                                    alignment: Alignment.topCenter,
                                    child: Container(
                                      height: 42,
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: <Color>[
                                            AppNeutralColors.white,
                                            Color(0x00FFFFFF),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                IgnorePointer(
                                  child: Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Container(
                                      height: 40,
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: <Color>[
                                            Color(0x00FFFFFF),
                                            AppNeutralColors.white,
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                isYearMonthMode
                                    ? const SizedBox(
                                        width: AppSpacing.s24,
                                        height: AppSpacing.s24,
                                      )
                                    : buildMonthArrow(
                                        icon: Icons.chevron_left,
                                        enabled:
                                            canGoPrevMonth && !isYearMonthMode,
                                        onTap: () {
                                          setDialogState(() {
                                            visibleMonth = DateTime(
                                              visibleMonth.year,
                                              visibleMonth.month - 1,
                                              1,
                                            );
                                          });
                                        },
                                      ),
                                Expanded(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      setDialogState(() {
                                        isYearMonthMode = true;
                                        pickerYear = visibleMonth.year;
                                        pickerMonth = visibleMonth.month;
                                        final int yearIndex = years.indexOf(
                                          pickerYear,
                                        );
                                        if (yearIndex >= 0) {
                                          yearController.jumpToItem(yearIndex);
                                        }
                                        final int minMonth =
                                            pickerYear == firstDate.year
                                            ? firstDate.month
                                            : 1;
                                        final int maxMonth =
                                            pickerYear == lastDate.year
                                            ? lastDate.month
                                            : 12;
                                        final List<int> months = <int>[
                                          for (
                                            int m = minMonth;
                                            m <= maxMonth;
                                            m++
                                          )
                                            m,
                                        ];
                                        final int monthIndex = months.indexOf(
                                          pickerMonth,
                                        );
                                        if (monthIndex >= 0) {
                                          monthController.jumpToItem(
                                            monthIndex,
                                          );
                                        }
                                      });
                                    },
                                    child: Text(
                                      "${visibleMonth.year}년 ${visibleMonth.month}월",
                                      textAlign: TextAlign.center,
                                      style: AppTypography.heading2XSmall
                                          .copyWith(
                                            color: AppNeutralColors.grey900,
                                            decoration: TextDecoration.none,
                                          ),
                                    ),
                                  ),
                                ),
                                isYearMonthMode
                                    ? const SizedBox(
                                        width: AppSpacing.s24,
                                        height: AppSpacing.s24,
                                      )
                                    : buildMonthArrow(
                                        icon: Icons.chevron_right,
                                        enabled:
                                            canGoNextMonth && !isYearMonthMode,
                                        onTap: () {
                                          setDialogState(() {
                                            visibleMonth = DateTime(
                                              visibleMonth.year,
                                              visibleMonth.month + 1,
                                              1,
                                            );
                                          });
                                        },
                                      ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.s24),
                            SizedBox(
                              width: double.infinity,
                              child: isYearMonthMode
                                  ? buildYearMonthPicker()
                                  : buildCalendarGrid(),
                            ),
                            const SizedBox(height: AppSpacing.s24),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                buildActionLabel(
                                  text: "닫기",
                                  color: AppNeutralColors.grey500,
                                  onTap: () {
                                    Navigator.of(dialogContext).pop();
                                  },
                                ),
                                const SizedBox(width: AppSpacing.s16),
                                buildActionLabel(
                                  text: "확인",
                                  color: brand.c500,
                                  onTap: () {
                                    if (isYearMonthMode) {
                                      setDialogState(() {
                                        final DateTime newVisibleMonth =
                                            DateTime(
                                              pickerYear,
                                              pickerMonth,
                                              1,
                                            );
                                        visibleMonth = newVisibleMonth;
                                        final int maxDayInNewMonth = DateTime(
                                          pickerYear,
                                          pickerMonth + 1,
                                          0,
                                        ).day;
                                        final int targetDay =
                                            selectedDate.day > maxDayInNewMonth
                                            ? maxDayInNewMonth
                                            : selectedDate.day;
                                        final DateTime candidate = DateTime(
                                          pickerYear,
                                          pickerMonth,
                                          targetDay,
                                        );
                                        selectedDate =
                                            candidate.isBefore(firstDate)
                                            ? firstDate
                                            : candidate;
                                        isYearMonthMode = false;
                                      });
                                      return;
                                    }
                                    Navigator.of(
                                      dialogContext,
                                    ).pop(selectedDate);
                                  },
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          },
    );
    yearController.dispose();
    monthController.dispose();
    return result;
  }

  String _formatDate(DateTime date) {
    return "${date.year.toString().padLeft(4, "0")}."
        "${date.month.toString().padLeft(2, "0")}."
        "${date.day.toString().padLeft(2, "0")}";
  }
}

class _InputCard extends StatelessWidget {
  const _InputCard({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.s16),
        decoration: BoxDecoration(
          color: AppNeutralColors.white,
          borderRadius: BorderRadius.circular(AppSpacing.s12),
          boxShadow: AppElevation.level1,
        ),
        child: child,
      ),
    );
  }
}

class _RequiredTitle extends StatelessWidget {
  const _RequiredTitle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    return Row(
      children: <Widget>[
        Text(
          label,
          style: AppTypography.bodyMediumSemiBold.copyWith(
            color: AppNeutralColors.grey900,
          ),
        ),
        const SizedBox(width: AppSpacing.s2),
        Text(
          "*",
          style: AppTypography.bodyMediumMedium.copyWith(color: brand.c500),
        ),
      ],
    );
  }
}
