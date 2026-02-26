import "dart:math" as math;
import "dart:async";

import "package:flutter/material.dart";

import "../../design_system/design_system.dart";

class BucketCategorySelection {
  const BucketCategorySelection({required this.name, required this.color});

  final String name;
  final Color color;
}

class BucketCategoryResult {
  const BucketCategoryResult({
    required this.categories,
    required this.selected,
  });

  final List<BucketCategorySelection> categories;
  final BucketCategorySelection? selected;
}

enum _CategoryMenuAction { edit, delete }

class BucketCategoryEmptyScreen extends StatefulWidget {
  const BucketCategoryEmptyScreen({
    super.key,
    this.initialCategories = const <BucketCategorySelection>[],
    this.initialSelectedName,
  });

  final List<BucketCategorySelection> initialCategories;
  final String? initialSelectedName;

  @override
  State<BucketCategoryEmptyScreen> createState() =>
      _BucketCategoryEmptyScreenState();
}

class _BucketCategoryEmptyScreenState extends State<BucketCategoryEmptyScreen> {
  static const int _maxCategoryCount = 12;
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

  late final List<BucketCategorySelection> _categories;
  String? _selectedName;

  @override
  void initState() {
    super.initState();
    _categories = List<BucketCategorySelection>.from(widget.initialCategories);
    _selectedName = widget.initialSelectedName;
  }

  BucketCategorySelection? get _selectedCategory {
    for (final BucketCategorySelection category in _categories) {
      if (category.name == _selectedName) {
        return category;
      }
    }
    return null;
  }

  void _popWithResult() {
    Navigator.of(context).pop(
      BucketCategoryResult(
        categories: List<BucketCategorySelection>.unmodifiable(_categories),
        selected: _selectedCategory,
      ),
    );
  }

  void _showMaxCategoryToast() {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Center(
            child: AppToastMessage(text: "카테고리 최대 생성 개수 12개를\n초과하였습니다."),
          ),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
          backgroundColor: Colors.transparent,
          elevation: 0,
          padding: EdgeInsets.zero,
          margin: EdgeInsets.fromLTRB(50, 0, 50, 98),
        ),
      );
  }

  Future<BucketCategorySelection?> _openCategoryBottomSheet(
    BuildContext context, {
    BucketCategorySelection? initialCategory,
  }) async {
    final TextEditingController nameController = TextEditingController(
      text: initialCategory?.name ?? "",
    );
    int? selectedColorIndex = initialCategory == null
        ? null
        : _accentColors.indexOf(initialCategory.color);
    if (selectedColorIndex != null && selectedColorIndex < 0) {
      selectedColorIndex = null;
    }
    final bool isEditMode = initialCategory != null;
    bool showColorToast = false;
    Timer? toastTimer;

    final BucketCategorySelection?
    result = await showModalBottomSheet<BucketCategorySelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0xB8000000),
      builder: (BuildContext context) {
        final BrandScale brand = context.appBrandScale;
        final Set<String> existingNames = _categories
            .where(
              (BucketCategorySelection e) =>
                  e.name.trim().toLowerCase() !=
                  (initialCategory?.name.trim().toLowerCase() ?? ""),
            )
            .map((BucketCategorySelection e) => e.name.trim().toLowerCase())
            .toSet();

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final String trimmedName = nameController.text.trim();
            final bool hasCategoryName = trimmedName.isNotEmpty;
            final bool isDuplicate =
                hasCategoryName &&
                existingNames.contains(trimmedName.toLowerCase());
            final bool canSubmitName = hasCategoryName && !isDuplicate;
            final bool canAdd = canSubmitName && selectedColorIndex != null;
            final double keyboardInset = MediaQuery.of(
              context,
            ).viewInsets.bottom;
            final AppButtonMetrics buttonMetrics = AppButtonTokens.metrics(
              AppButtonSize.medium,
            );
            void showMissingColorToast() {
              toastTimer?.cancel();
              setModalState(() {
                showColorToast = true;
              });
              toastTimer = Timer(const Duration(seconds: 2), () {
                if (!context.mounted) {
                  return;
                }
                setModalState(() {
                  showColorToast = false;
                });
              });
            }

            Widget colorRow(int start) {
              final List<Color> rowColors = _accentColors.sublist(
                start,
                math.min(start + 6, _accentColors.length),
              );
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: rowColors.asMap().entries.map((
                  MapEntry<int, Color> e,
                ) {
                  final int index = start + e.key;
                  final bool selected = selectedColorIndex == index;
                  return GestureDetector(
                    onTap: () {
                      setModalState(() {
                        selectedColorIndex = index;
                      });
                    },
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: Stack(
                        alignment: Alignment.center,
                        children: <Widget>[
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: e.value,
                            ),
                          ),
                          if (selected)
                            const Icon(
                              Icons.check_rounded,
                              size: 20,
                              color: AppNeutralColors.white,
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            }

            return AnimatedPadding(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(bottom: keyboardInset),
              child: Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.s20,
                      AppSpacing.s16,
                      AppSpacing.s20,
                      AppSpacing.s48,
                    ),
                    decoration: const BoxDecoration(
                      color: AppNeutralColors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(AppSpacing.s16),
                        topRight: Radius.circular(AppSpacing.s16),
                      ),
                      boxShadow: AppElevation.level1,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Align(
                          child: Container(
                            width: 48,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppNeutralColors.grey300,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.s16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s20),
                        Text(
                          "버킷리스트 카테고리를 적어보세요",
                          style: AppTypography.headingSmall.copyWith(
                            color: AppNeutralColors.grey900,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s20),
                        Row(
                          children: <Widget>[
                            Text(
                              "카테고리명",
                              style: AppTypography.captionLarge.copyWith(
                                color: AppNeutralColors.grey900,
                              ),
                            ),
                            Text(
                              "*",
                              style: AppTypography.bodyMediumMedium.copyWith(
                                color: brand.c500,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 44,
                          child: TextField(
                            controller: nameController,
                            autofocus: true,
                            onChanged: (_) => setModalState(() {}),
                            cursorColor: brand.c500,
                            style: AppTypography.bodyMediumMedium.copyWith(
                              color: AppNeutralColors.grey900,
                            ),
                            decoration: InputDecoration(
                              hintText: "플레이스홀더",
                              hintStyle: AppTypography.bodyMediumMedium
                                  .copyWith(color: AppNeutralColors.grey300),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              hoverColor: Colors.transparent,
                              contentPadding: EdgeInsets.zero,
                              suffixIcon: hasCategoryName && !isDuplicate
                                  ? Icon(
                                      Icons.check_rounded,
                                      size: 20,
                                      color: brand.c500,
                                    )
                                  : null,
                              suffixIconConstraints:
                                  const BoxConstraints.tightFor(
                                    width: 20,
                                    height: 20,
                                  ),
                            ),
                          ),
                        ),
                        Container(
                          height: 1,
                          color: isDuplicate
                              ? AppSemanticColors.error500
                              : hasCategoryName
                              ? brand.c500
                              : AppNeutralColors.grey900,
                        ),
                        if (isDuplicate) ...<Widget>[
                          const SizedBox(height: AppSpacing.s4),
                          Text(
                            "같은 이름의 카테고리는 만들 수 없어요.",
                            style: AppTypography.captionMedium.copyWith(
                              color: AppSemanticColors.error500,
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.s20),
                        Row(
                          children: <Widget>[
                            Text(
                              "색상",
                              style: AppTypography.captionLarge.copyWith(
                                color: AppNeutralColors.grey900,
                              ),
                            ),
                            Text(
                              "*",
                              style: AppTypography.bodyMediumMedium.copyWith(
                                color: brand.c500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.s8),
                        SizedBox(
                          height: 80,
                          child: Stack(
                            alignment: Alignment.center,
                            children: <Widget>[
                              Column(
                                children: <Widget>[
                                  colorRow(0),
                                  const SizedBox(height: AppSpacing.s8),
                                  colorRow(6),
                                ],
                              ),
                              if (showColorToast)
                                const AppToastMessage(
                                  text: "카테고리 색상을 추가해주세요😀",
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s20),
                        SizedBox(
                          height: 48,
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: FilledButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppNeutralColors.grey100,
                                    overlayColor: Colors.transparent,
                                    splashFactory: NoSplash.splashFactory,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: buttonMetrics.radius,
                                    ),
                                  ),
                                  child: Text(
                                    "취소",
                                    style: buttonMetrics.textStyle.copyWith(
                                      color: AppNeutralColors.grey600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.s8),
                              Expanded(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: !canAdd && canSubmitName
                                      ? showMissingColorToast
                                      : null,
                                  child: FilledButton(
                                    onPressed: canAdd
                                        ? () {
                                            Navigator.of(context).pop(
                                              BucketCategorySelection(
                                                name: trimmedName,
                                                color:
                                                    _accentColors[selectedColorIndex!],
                                              ),
                                            );
                                          }
                                        : null,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: brand.c500,
                                      disabledBackgroundColor: Color.alphaBlend(
                                        AppTransparentColors.light64,
                                        brand.c500,
                                      ),
                                      foregroundColor: AppNeutralColors.white,
                                      disabledForegroundColor: brand.c100,
                                      overlayColor: Colors.transparent,
                                      splashFactory: NoSplash.splashFactory,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: buttonMetrics.radius,
                                      ),
                                    ),
                                    child: Text(
                                      isEditMode ? "수정" : "추가",
                                      style: buttonMetrics.textStyle,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    toastTimer?.cancel();

    nameController.dispose();
    return result;
  }

  Future<void> _onCategoryMenuSelected(
    _CategoryMenuAction action,
    BucketCategorySelection category,
  ) async {
    if (action == _CategoryMenuAction.edit) {
      final BucketCategorySelection? edited = await _openCategoryBottomSheet(
        context,
        initialCategory: category,
      );
      if (edited == null || !mounted) {
        return;
      }
      setState(() {
        final int index = _categories.indexWhere(
          (BucketCategorySelection e) => e.name == category.name,
        );
        if (index >= 0) {
          _categories[index] = edited;
          if (_selectedName == category.name) {
            _selectedName = edited.name;
          }
        }
      });
      return;
    }

    setState(() {
      _categories.removeWhere(
        (BucketCategorySelection e) => e.name == category.name,
      );
      if (_selectedName == category.name) {
        _selectedName = null;
      }
    });
  }

  Future<void> _openCategoryMenu({
    required BucketCategorySelection category,
    required Offset anchor,
  }) async {
    int? selectedIndex;
    final _CategoryMenuAction?
    action = await showGeneralDialog<_CategoryMenuAction>(
      context: context,
      barrierDismissible: true,
      barrierLabel: "dismiss",
      barrierColor: Colors.transparent,
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
            final Size screen = MediaQuery.of(dialogContext).size;
            const double horizontalSafeMargin = 20;
            const double verticalGapFromIcon = 8;
            final double menuWidth = AppDropdownTokens.menuStyle(
              AppDropdownMenuSize.lg,
            ).width;
            final double top = anchor.dy + verticalGapFromIcon;
            final double preferredLeft =
                anchor.dx - menuWidth + (AppSpacing.s24 / 2);
            final double left = preferredLeft.clamp(
              horizontalSafeMargin,
              screen.width - horizontalSafeMargin - menuWidth,
            );
            return StatefulBuilder(
              builder: (BuildContext context, StateSetter setModalState) {
                Future<void> selectAndClose(
                  int index,
                  _CategoryMenuAction value,
                ) async {
                  setModalState(() {
                    selectedIndex = index;
                  });
                  await Future<void>.delayed(const Duration(milliseconds: 120));
                  if (!context.mounted) {
                    return;
                  }
                  Navigator.of(context).pop(value);
                }

                return Stack(
                  children: <Widget>[
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () => Navigator.of(dialogContext).pop(),
                        child: const SizedBox.expand(),
                      ),
                    ),
                    Positioned(
                      top: top,
                      left: left,
                      child: FadeTransition(
                        opacity: animation,
                        child: Material(
                          color: Colors.transparent,
                          child: AppDropdownMenu(
                            size: AppDropdownMenuSize.lg,
                            items: <AppDropdownItem>[
                              AppDropdownItem(
                                label: "수정",
                                state: selectedIndex == 0
                                    ? AppDropdownItemState.selected
                                    : AppDropdownItemState.defaultState,
                                onTap: () =>
                                    selectAndClose(0, _CategoryMenuAction.edit),
                              ),
                              AppDropdownItem(
                                label: "삭제",
                                state: selectedIndex == 1
                                    ? AppDropdownItemState.selected
                                    : AppDropdownItemState.defaultState,
                                onTap: () => selectAndClose(
                                  1,
                                  _CategoryMenuAction.delete,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
    );
    if (action == null || !mounted) {
      return;
    }
    await _onCategoryMenuSelected(action, category);
  }

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    final bool canCreateMore = _categories.length < _maxCategoryCount;

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
                  onPressed: _popWithResult,
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
                    "카테고리",
                    textAlign: TextAlign.center,
                    style: AppTypography.headingXSmall.copyWith(
                      color: AppNeutralColors.grey900,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s24, height: AppSpacing.s24),
              ],
            ),
            const SizedBox(height: AppSpacing.s48),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s16,
                vertical: AppSpacing.s8,
              ),
              decoration: BoxDecoration(
                color: AppNeutralColors.white,
                borderRadius: BorderRadius.circular(AppSpacing.s12),
                boxShadow: AppElevation.level1,
              ),
              child: Column(
                children: <Widget>[
                  if (_categories.isNotEmpty)
                    ..._categories.map((BucketCategorySelection category) {
                      final bool selected = category.name == _selectedName;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedName = category.name;
                          });
                          _popWithResult();
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.s16,
                          ),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: AppNeutralColors.grey100,
                              ),
                            ),
                          ),
                          child: Row(
                            children: <Widget>[
                              SizedBox(
                                width: AppSpacing.s20,
                                height: AppSpacing.s20,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: <Widget>[
                                    Container(
                                      width: AppSpacing.s20,
                                      height: AppSpacing.s20,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: category.color,
                                      ),
                                    ),
                                    if (selected)
                                      const Icon(
                                        Icons.check_rounded,
                                        size: 14,
                                        color: AppNeutralColors.white,
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSpacing.s6),
                              Expanded(
                                child: Text(
                                  category.name,
                                  style: AppTypography.bodyMediumSemiBold
                                      .copyWith(
                                        color: AppNeutralColors.grey900,
                                      ),
                                ),
                              ),
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {},
                                onTapDown: (TapDownDetails details) {
                                  _openCategoryMenu(
                                    category: category,
                                    anchor: details.globalPosition,
                                  );
                                },
                                child: const SizedBox(
                                  width: AppSpacing.s24,
                                  height: AppSpacing.s24,
                                  child: Icon(
                                    Icons.more_vert,
                                    size: AppSpacing.s24,
                                    color: AppNeutralColors.grey500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  GestureDetector(
                    onTap: canCreateMore
                        ? () async {
                            final BucketCategorySelection? selection =
                                await _openCategoryBottomSheet(context);
                            if (selection == null || !mounted) {
                              return;
                            }
                            setState(() {
                              _categories.add(selection);
                              _selectedName = selection.name;
                            });
                          }
                        : _showMaxCategoryToast,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.s16,
                      ),
                      child: Row(
                        children: <Widget>[
                          Icon(
                            Icons.add,
                            size: AppSpacing.s24,
                            color: canCreateMore
                                ? brand.c500
                                : AppNeutralColors.grey300,
                          ),
                          const SizedBox(width: AppSpacing.s6),
                          Text(
                            "카테고리 추가",
                            style: AppTypography.bodyMediumSemiBold.copyWith(
                              color: canCreateMore
                                  ? AppNeutralColors.grey900
                                  : AppNeutralColors.grey300,
                            ),
                          ),
                        ],
                      ),
                    ),
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
