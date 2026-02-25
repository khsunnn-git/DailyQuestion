import "package:flutter/material.dart";

import "../../design_system/design_system.dart";
import "../question/today_question_answer_screen.dart";
import "../question/today_question_store.dart";
import "my_records_screen.dart";

class MyRecordDetailScreen extends StatefulWidget {
  const MyRecordDetailScreen({super.key, required this.record});

  final TodayQuestionRecord record;

  @override
  State<MyRecordDetailScreen> createState() => _MyRecordDetailScreenState();
}

class _MyRecordDetailScreenState extends State<MyRecordDetailScreen> {
  late final List<String> _bucketTags;
  late String _answer;
  late bool _isPublic;
  bool _showMoreMenu = false;
  int? _selectedMoreMenuIndex;
  int? _armedDeleteTagIndex;

  @override
  void initState() {
    super.initState();
    _bucketTags = widget.record.bucketTags.isNotEmpty
        ? List<String>.from(widget.record.bucketTags)
        : (widget.record.bucketTag == null ||
              widget.record.bucketTag!.trim().isEmpty)
        ? <String>[]
        : <String>[widget.record.bucketTag!.trim()];
    _answer = widget.record.answer;
    _isPublic = widget.record.isPublic;
  }

  void _dismissMoreMenu() {
    if (!_showMoreMenu) {
      return;
    }
    setState(() {
      _showMoreMenu = false;
      _selectedMoreMenuIndex = null;
    });
  }

  void _toggleMoreMenu() {
    setState(() {
      _showMoreMenu = !_showMoreMenu;
      if (_showMoreMenu) {
        _selectedMoreMenuIndex = null;
      }
    });
  }

  Future<void> _handleMoreMenuTap({
    required int index,
    required Future<void> Function() action,
  }) async {
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedMoreMenuIndex = index;
    });
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) {
      return;
    }
    await action();
  }

  void _showBucketRemovedToast() {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Center(child: AppToastMessage(text: "버킷리스트가 삭제되었습니다.")),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
          backgroundColor: Colors.transparent,
          elevation: 0,
          padding: EdgeInsets.zero,
          margin: EdgeInsets.fromLTRB(50, 0, 50, 98),
        ),
      );
  }

  void _removeTag(int index) {
    if (index < 0 || index >= _bucketTags.length) {
      return;
    }
    setState(() {
      _bucketTags.removeAt(index);
    });
    TodayQuestionStore.instance.updateRecordBucketTags(
      createdAt: widget.record.createdAt,
      bucketTags: _bucketTags,
    );
    _showBucketRemovedToast();
  }

  void _armTagDelete(int index) {
    if (index < 0 || index >= _bucketTags.length) {
      return;
    }
    setState(() {
      _armedDeleteTagIndex = index;
    });
  }

  void _handleTagTap(int index) {
    if (_armedDeleteTagIndex == index) {
      _removeTag(index);
      setState(() {
        _armedDeleteTagIndex = null;
      });
    }
  }

  Future<void> _openEditScreen() async {
    _dismissMoreMenu();
    final TodayQuestionRecord seedRecord = TodayQuestionRecord(
      createdAt: widget.record.createdAt,
      answer: _answer,
      author: widget.record.author,
      bucketTag: _bucketTags.isEmpty ? null : _bucketTags.last,
      bucketTags: List<String>.from(_bucketTags),
      isPublic: _isPublic,
    );

    final TodayQuestionRecord? updatedRecord = await Navigator.of(context)
        .push<TodayQuestionRecord>(
          MaterialPageRoute<TodayQuestionRecord>(
            builder: (_) =>
                TodayQuestionAnswerScreen(editingRecord: seedRecord),
          ),
        );

    if (!mounted || updatedRecord == null) {
      return;
    }
    setState(() {
      _answer = updatedRecord.answer;
      _isPublic = updatedRecord.isPublic;
      _bucketTags
        ..clear()
        ..addAll(updatedRecord.bucketTags);
    });
  }

  Future<void> _deleteRecordWithPopup() async {
    _dismissMoreMenu();
    if (!mounted) {
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: AppPopupTokens.dimmed,
      builder: (BuildContext dialogContext) {
        return Center(
          child: AppPopup(
            width: AppPopupTokens.maxWidth,
            title: "질문과 내용 모두\n삭제하시겠습니까?",
            body: "삭제해도 질문에 대한 답변은\n언제든 다시 작성 할 수 있어요",
            actions: <Widget>[
              SizedBox(
                width: 100,
                height: 56,
                child: FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppNeutralColors.grey100,
                    foregroundColor: AppNeutralColors.grey600,
                    surfaceTintColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    overlayColor: Colors.transparent,
                    splashFactory: NoSplash.splashFactory,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.s8),
                    ),
                    textStyle: AppTypography.buttonLarge,
                    padding: EdgeInsets.zero,
                  ),
                  child: Text(
                    "취소",
                    style: AppTypography.buttonLarge.copyWith(
                      color: AppNeutralColors.grey600,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 170,
                height: 56,
                child: FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: context.appBrandScale.c500,
                    foregroundColor: AppNeutralColors.white,
                    surfaceTintColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    overlayColor: Colors.transparent,
                    splashFactory: NoSplash.splashFactory,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.s8),
                    ),
                    textStyle: AppTypography.buttonLarge,
                    padding: EdgeInsets.zero,
                  ),
                  child: Text(
                    "삭제하기",
                    style: AppTypography.buttonLarge.copyWith(
                      color: AppNeutralColors.white,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || confirmed != true) {
      return;
    }

    final bool removed = TodayQuestionStore.instance.deleteRecord(
      createdAt: widget.record.createdAt,
    );
    if (!mounted) {
      return;
    }
    if (removed) {
      Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    final DateTime createdAt = widget.record.createdAt;
    final String createdDate =
        "${createdAt.year.toString().padLeft(4, "0")}."
        "${createdAt.month.toString().padLeft(2, "0")}."
        "${createdAt.day.toString().padLeft(2, "0")}";

    return Scaffold(
      backgroundColor: brand.bg,
      body: Padding(
        padding: EdgeInsets.zero,
        child: Stack(
          children: <Widget>[
                Positioned.fill(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.s20,
                      49,
                      AppSpacing.s20,
                      AppNavigationBar.totalHeight(context) + AppSpacing.s20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: IconButton(
                                onPressed: () =>
                                    Navigator.of(context).maybePop(),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints.tightFor(
                                  width: 24,
                                  height: 24,
                                ),
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: AppNeutralColors.grey900,
                                  size: 24,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                createdDate,
                                textAlign: TextAlign.center,
                                style: AppTypography.headingXSmall.copyWith(
                                  color: AppNeutralColors.grey900,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: IconButton(
                                onPressed: _toggleMoreMenu,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints.tightFor(
                                  width: 24,
                                  height: 24,
                                ),
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(
                                  Icons.more_horiz,
                                  color: AppNeutralColors.grey400,
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.s24),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.s24,
                          ),
                          child: Container(
                            width: 300,
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.s8,
                              AppSpacing.s24,
                              AppSpacing.s8,
                              AppSpacing.s24,
                            ),
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: AppNeutralColors.grey100,
                                ),
                              ),
                            ),
                            child: Text(
                              "올해 안에 꼭 해보고 싶은 일\n하나는 무엇인가요?",
                              textAlign: TextAlign.center,
                              style: AppTypography.headingLarge.copyWith(
                                color: AppNeutralColors.grey900,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s24),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.s24,
                          ),
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 370),
                            alignment: Alignment.topLeft,
                            child: Text(
                              _answer,
                              style: AppTypography.bodyLargeRegular.copyWith(
                                color: AppNeutralColors.grey800,
                                height: 1.8,
                              ),
                            ),
                          ),
                        ),
                        if (_bucketTags.isNotEmpty) ...<Widget>[
                          const SizedBox(height: AppSpacing.s24),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.s24,
                            ),
                            child: SizedBox(
                              width: 300,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.s8,
                                ),
                                decoration: const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: AppNeutralColors.grey100,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  "버킷리스트",
                                  style: AppTypography.headingXSmall.copyWith(
                                    color: AppNeutralColors.grey900,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.s8),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.s24,
                            ),
                            child: SizedBox(
                              width: 300,
                              child: Wrap(
                                spacing: AppSpacing.s8,
                                runSpacing: AppSpacing.s8,
                                children: _bucketTags
                                    .asMap()
                                    .entries
                                    .map((MapEntry<int, String> entry) {
                                      final int index = entry.key;
                                      final String tag = entry.value;
                                      return Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onLongPress: () =>
                                              _armTagDelete(index),
                                          onTap: () => _handleTagTap(index),
                                          borderRadius: AppRadius.pill,
                                          child: Container(
                                            height: 38,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: AppSpacing.s12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: brand.c500,
                                              borderRadius: AppRadius.pill,
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: <Widget>[
                                                Text(
                                                  "#$tag",
                                                  style: AppTypography
                                                      .buttonSmall
                                                      .copyWith(
                                                        color: AppNeutralColors
                                                            .white,
                                                      ),
                                                ),
                                                if (_armedDeleteTagIndex ==
                                                    index) ...<Widget>[
                                                  const SizedBox(
                                                    width: AppSpacing.s6,
                                                  ),
                                                  Container(
                                                    width: 20,
                                                    height: 20,
                                                    decoration:
                                                        const BoxDecoration(
                                                          color:
                                                              AppNeutralColors
                                                                  .white,
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                    child: Icon(
                                                      Icons.close,
                                                      size: 16,
                                                      color: brand.c500,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    })
                                    .toList(growable: false),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (_showMoreMenu)
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: _dismissMoreMenu,
                      child: const SizedBox.expand(),
                    ),
                  ),
                if (_showMoreMenu)
                  Positioned(
                    top: 70,
                    right: AppSpacing.s28,
                    child: AppDropdownMenu(
                      size: AppDropdownMenuSize.lg,
                      items: <AppDropdownItem>[
                        AppDropdownItem(
                          label: "수정",
                          state: _selectedMoreMenuIndex == 0
                              ? AppDropdownItemState.selected
                              : AppDropdownItemState.defaultState,
                          onTap: () => _handleMoreMenuTap(
                            index: 0,
                            action: _openEditScreen,
                          ),
                        ),
                        AppDropdownItem(
                          label: "삭제",
                          state: _selectedMoreMenuIndex == 1
                              ? AppDropdownItemState.selected
                              : AppDropdownItemState.defaultState,
                          onTap: () => _handleMoreMenuTap(
                            index: 1,
                            action: _deleteRecordWithPopup,
                          ),
                        ),
                      ],
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
