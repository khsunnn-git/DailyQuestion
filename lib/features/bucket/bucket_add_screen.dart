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
  });

  final List<BucketCategorySelection> initialCategories;

  @override
  State<BucketAddScreen> createState() => _BucketAddScreenState();
}

class _BucketAddScreenState extends State<BucketAddScreen> {
  late final TextEditingController _titleController;
  bool _isCompleted = false;
  late final List<BucketCategorySelection> _categories;
  BucketCategorySelection? _selectedCategory;

  bool get _canSave =>
      _titleController.text.trim().isNotEmpty && _selectedCategory != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _categories = List<BucketCategorySelection>.from(widget.initialCategories);
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
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      "D-Day",
                                      style: AppTypography.bodyMediumSemiBold
                                          .copyWith(
                                            color: AppNeutralColors.grey900,
                                          ),
                                    ),
                                    const SizedBox(height: AppSpacing.s2),
                                    Text(
                                      "완료 날짜를 선택할 수 있습니다.",
                                      style: AppTypography.bodySmallMedium
                                          .copyWith(
                                            color: AppNeutralColors.grey300,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                size: AppSpacing.s24,
                                color: AppNeutralColors.grey900,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.s32),
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
                              AppIconToggle(
                                value: _isCompleted,
                                onChanged: (bool value) {
                                  setState(() {
                                    _isCompleted = value;
                                  });
                                },
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
                        final DateTime createdAt = DateTime.now();
                        navigator.pop(
                          BucketAddResult(
                            item: BucketCreatedItem(
                              title: _titleController.text.trim(),
                              categoryName: _selectedCategory!.name,
                              categoryColor: _selectedCategory!.color,
                              createdAt: createdAt,
                              isCompleted: _isCompleted,
                              dueDate: null,
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
                child: const Text("저장하기"),
              ),
            ),
          ],
        ),
      ),
    );
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
