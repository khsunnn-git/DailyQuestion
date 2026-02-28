import "dart:async";

import "package:flutter/material.dart";
import "package:isar/isar.dart";

import "../../core/kst_date_time.dart";
import "../../data/local_db/entities/bucket_item_entity.dart";
import "../../data/local_db/local_database.dart";
import "../../design_system/design_system.dart";
import "streak_completion_screen.dart";
import "today_question_prompt_store.dart";
import "today_question_store.dart";

class TodayQuestionAnswerScreen extends StatefulWidget {
  const TodayQuestionAnswerScreen({
    super.key,
    this.editingRecord,
    this.initialDate,
    this.headerTitle,
    this.questionText,
    this.questionSlot,
  });

  final TodayQuestionRecord? editingRecord;
  final DateTime? initialDate;
  final String? headerTitle;
  final String? questionText;
  final int? questionSlot;

  @override
  State<TodayQuestionAnswerScreen> createState() =>
      _TodayQuestionAnswerScreenState();
}

class _TodayQuestionAnswerScreenState extends State<TodayQuestionAnswerScreen> {
  static const String _allCategoryName = "ALL";
  static const Color _allCategoryColor = AppNeutralColors.grey100;
  bool _isPublic = false;
  int _polishUsedCount = 0;
  bool _showPolishLoading = false;
  final List<String> _bucketTags = <String>[];
  final List<String> _initialBucketTags = <String>[];
  final TextEditingController _answerController = TextEditingController();
  final FocusNode _answerFocusNode = FocusNode();

  bool get _hasInput => _answerController.text.trim().isNotEmpty;

  bool get _canPolish =>
      _effectiveCharCount(_answerController.text) >= 5 && _polishUsedCount < 3;

  String _normalizeBucketTag(String value) {
    return value.replaceAll(RegExp(r"\s+"), " ").trim();
  }

  Future<void> _saveRecord() async {
    try {
      final bool isEditMode = widget.editingRecord != null;
      final DateTime promptDate = TodayQuestionPromptStore.instance.value.date;
      final DateTime baseDate = widget.initialDate ?? promptDate;
      final DateTime normalizedRecordDate = DateTime(
        baseDate.year,
        baseDate.month,
        baseDate.day,
        12,
      );
      final DateTime? targetDate = isEditMode ? null : normalizedRecordDate;
      final int resolvedQuestionSlot = _resolveQuestionSlot();
      final String resolvedQuestionText =
          widget.questionText ??
          TodayQuestionPromptStore.instance.value.currentQuestionText;
      final DateTime groupDate = normalizedRecordDate;
      final TodayQuestionRecord? savedRecord = isEditMode
          ? await TodayQuestionStore.instance.updateRecord(
              createdAt: widget.editingRecord!.createdAt,
              answer: _answerController.text,
              isPublic: _isPublic,
              bucketTags: _bucketTags,
            )
          : await TodayQuestionStore.instance.saveRecord(
              answer: _answerController.text,
              isPublic: _isPublic,
              bucketTags: _bucketTags,
              createdAt: targetDate,
              questionSlot: resolvedQuestionSlot,
              questionDateKey: kstDateKeyFromDateTime(groupDate),
              questionText: resolvedQuestionText,
            );

      if (savedRecord == null) {
        return;
      }
      await _syncBucketListItems(
        previousTags: _initialBucketTags,
        nextTags: _bucketTags,
        createdAt: savedRecord.createdAt,
      );

      if (isEditMode) {
        if (!mounted) {
          return;
        }
        Navigator.of(context).pop(savedRecord);
        return;
      }

      final DateTime now = nowInKst();
      final DateTime resolvedDate = widget.initialDate ?? now;
      final bool isTodayTarget = isSameKstDate(resolvedDate, now);
      final int streak = TodayQuestionStore.instance.consecutiveRecordDays;
      if (!mounted) {
        return;
      }
      if (isTodayTarget && streak >= 2) {
        final List<bool> weeklyCompleted = TodayQuestionStore.instance
            .weeklyCompletion();
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => StreakCompletionScreen(
              streakDays: streak,
              weeklyCompleted: weeklyCompleted,
            ),
          ),
        );
      }
      if (!mounted) {
        return;
      }
      Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
    } catch (_) {
      _showBucketToastMessage("저장 중 오류가 발생했어요. 다시 시도해주세요.");
    }
  }

  int _resolveQuestionSlot() {
    if (widget.questionSlot != null) {
      return widget.questionSlot!.clamp(0, 2);
    }
    return 0;
  }

  @override
  void initState() {
    super.initState();
    if (widget.questionText == null) {
      unawaited(TodayQuestionPromptStore.instance.initialize());
    }
    final TodayQuestionRecord? editingRecord = widget.editingRecord;
    if (editingRecord != null) {
      _answerController.text = editingRecord.answer;
      _isPublic = editingRecord.isPublic;
      if (editingRecord.bucketTags.isNotEmpty) {
        _bucketTags.addAll(editingRecord.bucketTags);
      } else if (editingRecord.bucketTag != null &&
          editingRecord.bucketTag!.trim().isNotEmpty) {
        _bucketTags.add(editingRecord.bucketTag!.trim());
      }
      _initialBucketTags.addAll(_bucketTags);
    }
    _answerController.addListener(_handleAnswerChanged);
  }

  Future<void> _syncBucketListItems({
    required List<String> previousTags,
    required List<String> nextTags,
    required DateTime createdAt,
  }) async {
    final List<String> before = previousTags
        .map((String e) => e.trim())
        .where((String e) => e.isNotEmpty)
        .toList(growable: false);
    final List<String> after = nextTags
        .map((String e) => e.trim())
        .where((String e) => e.isNotEmpty)
        .toList(growable: false);
    final Map<String, int> beforeCount = _toCountMap(before);
    final Map<String, int> afterCount = _toCountMap(after);

    final List<String> toAdd = <String>[];
    for (final MapEntry<String, int> entry in afterCount.entries) {
      final int delta = entry.value - (beforeCount[entry.key] ?? 0);
      for (int i = 0; i < delta; i++) {
        toAdd.add(entry.key);
      }
    }

    final List<String> toDelete = <String>[];
    for (final MapEntry<String, int> entry in beforeCount.entries) {
      final int delta = entry.value - (afterCount[entry.key] ?? 0);
      for (int i = 0; i < delta; i++) {
        toDelete.add(entry.key);
      }
    }

    if (toAdd.isEmpty && toDelete.isEmpty) {
      return;
    }

    final isar = await LocalDatabase.instance.isar;
    await isar.writeTxn(() async {
      for (final String tag in toAdd) {
        final BucketItemEntity entity = BucketItemEntity();
        entity.title = tag;
        entity.category = _allCategoryName;
        entity.categoryColorValue = _allCategoryColor.toARGB32();
        entity.createdAt = createdAt;
        entity.dueDate = null;
        entity.isCompleted = false;
        entity.updatedAt = nowInKst();
        await isar.bucketItemEntitys.put(entity);
      }

      for (final String tag in toDelete) {
        final BucketItemEntity? target = await isar.bucketItemEntitys
            .filter()
            .titleEqualTo(tag)
            .categoryEqualTo(_allCategoryName)
            .isCompletedEqualTo(false)
            .findFirst();
        if (target == null) {
          continue;
        }
        await isar.bucketItemEntitys.delete(target.id);
      }
    });
  }

  Map<String, int> _toCountMap(List<String> values) {
    final Map<String, int> result = <String, int>{};
    for (final String value in values) {
      result.update(value, (int existing) => existing + 1, ifAbsent: () => 1);
    }
    return result;
  }

  void _handleAnswerChanged() {
    setState(() {});
  }

  int _effectiveCharCount(String text) {
    return text.replaceAll(RegExp(r"\s+"), "").length;
  }

  String _buildPolishedText(String text) {
    final String normalized = text.trim();
    if (normalized.isEmpty) {
      return normalized;
    }
    final String cleaned = normalized
        .replaceAll("  ", " ")
        .replaceAll("..", ".")
        .replaceAll("\n\n\n", "\n\n");
    return _toPoliteKorean(cleaned);
  }

  String _toPoliteKorean(String text) {
    String result = text.trim();
    if (result.isEmpty) {
      return result;
    }

    result = result.replaceAll("싶어.", "싶어요.");
    result = result.replaceAll("했어.", "했어요.");
    result = result.replaceAll("이야.", "입니다.");
    result = result.replaceAll("거야.", "거예요.");

    if (!result.endsWith("요.") &&
        !result.endsWith("니다.") &&
        !result.endsWith("?")) {
      if (result.endsWith(".")) {
        result = "${result.substring(0, result.length - 1)}요.";
      } else {
        result = "$result요.";
      }
    }
    return result;
  }

  Future<String> _requestPolishSuggestion({
    required String text,
    required int requestCount,
  }) async {
    Timer? indicatorTimer;
    try {
      indicatorTimer = Timer(const Duration(seconds: 5), () {
        if (!mounted) {
          return;
        }
        setState(() {
          _showPolishLoading = true;
        });
      });

      final String result = await Future<String>.delayed(
        const Duration(milliseconds: 220),
        () {
          final String base = _buildPolishedText(text);
          if (requestCount == 2) {
            return base.replaceAll("싶어요.", "싶습니다.");
          }
          if (requestCount == 3) {
            return base.replaceAll("싶어요.", "싶습니다.").replaceAll("거예요.", "것입니다.");
          }
          return base;
        },
      ).timeout(const Duration(seconds: 12));

      return result;
    } finally {
      indicatorTimer?.cancel();
      if (mounted && _showPolishLoading) {
        setState(() {
          _showPolishLoading = false;
        });
      }
    }
  }

  void _showPolishToast(String message) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  void _showBucketToastMessage(String message) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Center(child: AppToastMessage(text: message)),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.transparent,
          elevation: 0,
          padding: EdgeInsets.zero,
          margin: const EdgeInsets.fromLTRB(50, 0, 50, 98),
        ),
      );
  }

  void _showBucketToast() {
    _showBucketToastMessage("버킷리스트에 추가되었습니다✨");
  }

  void _showBucketRemovedToast() {
    _showBucketToastMessage("버킷리스트가 삭제되었습니다.");
  }

  Future<T?> _showDesignBottomSheet<T>({
    required BuildContext context,
    required Widget Function(BuildContext context, double keyboardInset)
    builder,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      barrierColor: AppPopupTokens.dimmed,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (BuildContext sheetContext) {
        final double keyboardInset = MediaQuery.of(
          sheetContext,
        ).viewInsets.bottom;
        return DecoratedBox(
          decoration: const BoxDecoration(
            color: AppNeutralColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: AppPopupTokens.bottomSheetShadow,
          ),
          child: builder(sheetContext, keyboardInset),
        );
      },
    );
  }

  Future<void> _openPolishBottomSheet(BuildContext context) async {
    if (!_canPolish) {
      return;
    }
    // Keep keyboard closed while using polish / retry flow.
    FocusManager.instance.primaryFocus?.unfocus();
    if (_answerFocusNode.hasFocus) {
      _answerFocusNode.unfocus();
    }
    final String originalText = _answerController.text;
    final int requestCount = _polishUsedCount + 1;

    String polishedText;
    try {
      polishedText = await _requestPolishSuggestion(
        text: originalText,
        requestCount: requestCount,
      );
    } on TimeoutException {
      _showPolishToast("지금은 다듬을 수 없어요. 잠시 후 다시 시도해주세요.");
      return;
    } catch (_) {
      _showPolishToast("지금은 다듬을 수 없어요. 잠시 후 다시 시도해주세요.");
      return;
    }

    if (!context.mounted) {
      return;
    }

    setState(() {
      _polishUsedCount = requestCount;
    });

    if (polishedText.trim() == originalText.trim()) {
      _showPolishToast("이미 자연스러운 문장이에요");
      return;
    }

    final String? action = await _showDesignBottomSheet<String>(
      context: context,
      builder: (BuildContext context, double keyboardInset) {
        final BrandScale brand = context.appBrandScale;
        final int displayCount = _polishUsedCount.clamp(1, 3);
        final bool canRetry = _polishUsedCount < 3;
        return Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 48 + keyboardInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppNeutralColors.grey300,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s20),
              Text(
                "문장을 이렇게 다듬어 봤어요.",
                style: AppTypography.headingSmall.copyWith(
                  color: AppNeutralColors.grey900,
                ),
              ),
              const SizedBox(height: AppSpacing.s20),
              Container(
                constraints: const BoxConstraints(minHeight: 100),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppNeutralColors.grey50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  polishedText,
                  style: AppTypography.bodyMediumMedium.copyWith(
                    color: AppNeutralColors.grey900,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s20),
              SizedBox(
                height: 56,
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop("keep"),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                          backgroundColor: AppNeutralColors.grey100,
                          overlayColor: Colors.transparent,
                          splashFactory: NoSplash.splashFactory,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          "원문유지",
                          style: AppTypography.buttonLarge.copyWith(
                            color: AppNeutralColors.grey600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s8),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop("apply"),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                          backgroundColor: brand.c500,
                          overlayColor: Colors.transparent,
                          splashFactory: NoSplash.splashFactory,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          "적용하기",
                          style: AppTypography.buttonLarge.copyWith(
                            color: AppNeutralColors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.s20),
              TextButton(
                onPressed: canRetry
                    ? () => Navigator.of(context).pop("retry")
                    : null,
                style: TextButton.styleFrom(
                  foregroundColor: AppNeutralColors.grey600,
                  textStyle: AppTypography.buttonSmall,
                ),
                child: Text("다시 다듬기($displayCount/3)"),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || action == null) {
      return;
    }

    if (action == "retry" && _canPolish) {
      if (!context.mounted) {
        return;
      }
      FocusManager.instance.primaryFocus?.unfocus();
      if (_answerFocusNode.hasFocus) {
        _answerFocusNode.unfocus();
      }
      await _openPolishBottomSheet(context);
      return;
    }

    if (action == "apply") {
      _answerController.text = polishedText;
      _answerController.selection = TextSelection.fromPosition(
        TextPosition(offset: _answerController.text.length),
      );
    }
  }

  Future<void> _openBucketBottomSheet(BuildContext context) async {
    String draftBucketText = "";

    final String? bucketText = await _showDesignBottomSheet<String>(
      context: context,
      builder: (BuildContext context, double keyboardInset) {
        final BrandScale brand = context.appBrandScale;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final bool canSave = _normalizeBucketTag(
              draftBucketText,
            ).isNotEmpty;
            return Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 48 + keyboardInset),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: 48,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppNeutralColors.grey300,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s20),
                  Text(
                    "이 질문을 통해 얻은 버킷리스트가 있나요?",
                    style: AppTypography.headingSmall.copyWith(
                      color: AppNeutralColors.grey900,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Text(
                    "이곳에 작성한 내용은 버킷리스트에\n자동으로 저장됩니다.",
                    style: AppTypography.bodyMediumRegular.copyWith(
                      color: AppNeutralColors.grey500,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s20),
                  Container(
                    constraints: const BoxConstraints(
                      minHeight: AppInputTokens.textAreaInputPreviewHeight,
                    ),
                    decoration: BoxDecoration(
                      color: AppNeutralColors.grey50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: TextField(
                      autofocus: true,
                      cursorColor: AppNeutralColors.grey900,
                      minLines: 3,
                      maxLines: 3,
                      style: AppTypography.bodyMediumMedium.copyWith(
                        color: AppNeutralColors.grey900,
                      ),
                      onChanged: (String value) {
                        draftBucketText = value;
                        setModalState(() {});
                      },
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        focusColor: Colors.transparent,
                        hintText: "간단한 버킷리스트를 남겨보세요.",
                        hintStyle: AppTypography.bodyMediumMedium.copyWith(
                          color: AppNeutralColors.grey300,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  SizedBox(
                    height: 56,
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: FilledButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(56),
                              backgroundColor: AppNeutralColors.grey100,
                              overlayColor: Colors.transparent,
                              splashFactory: NoSplash.splashFactory,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              "다음에 할게요",
                              style: AppTypography.buttonLarge.copyWith(
                                color: AppNeutralColors.grey600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s8),
                        Expanded(
                          child: FilledButton(
                            onPressed: canSave
                                ? () => Navigator.of(
                                    context,
                                  ).pop(_normalizeBucketTag(draftBucketText))
                                : null,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(56),
                              backgroundColor: brand.c500,
                              disabledBackgroundColor: brand.c300,
                              disabledForegroundColor: AppNeutralColors.white,
                              overlayColor: Colors.transparent,
                              splashFactory: NoSplash.splashFactory,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              "저장하기",
                              style: AppTypography.buttonLarge.copyWith(
                                color: AppNeutralColors.white,
                              ),
                            ),
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

    if (!mounted || bucketText == null) {
      return;
    }
    final String normalized = _normalizeBucketTag(bucketText);
    if (normalized.isEmpty) {
      return;
    }
    setState(() {
      _bucketTags.add(normalized);
    });
    _showBucketToast();
  }

  @override
  void dispose() {
    _answerController.removeListener(_handleAnswerChanged);
    _answerController.dispose();
    _answerFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    final DateTime now = nowInKst();
    final double safeBottomInset = MediaQuery.of(context).viewPadding.bottom;
    final DateTime displayDate =
        widget.editingRecord?.createdAt ?? widget.initialDate ?? now;
    final String headerTitle = widget.headerTitle ?? "오늘의 질문";
    final String questionText =
        widget.questionText ??
        TodayQuestionPromptStore.instance.value.currentQuestionText;
    final String currentDate =
        "${displayDate.year.toString().padLeft(4, "0")}."
        "${displayDate.month.toString().padLeft(2, "0")}."
        "${displayDate.day.toString().padLeft(2, "0")}";
    final double bucketTagMaxWidth =
        MediaQuery.of(context).size.width - (AppSpacing.s20 * 2) - 56;
    return Scaffold(
      backgroundColor: brand.bg,
      body: Padding(
        padding: EdgeInsets.zero,
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s20,
                  70,
                  AppSpacing.s20,
                  AppSpacing.s20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              Navigator.of(context).popUntil(
                                (Route<dynamic> route) => route.isFirst,
                              );
                            },
                            child: Text(
                              headerTitle,
                              textAlign: TextAlign.center,
                              style: AppTypography.headingXSmall.copyWith(
                                color: AppNeutralColors.grey900,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s24),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s8,
                      ),
                      child: Column(
                        children: <Widget>[
                          Text(
                            questionText,
                            textAlign: TextAlign.center,
                            style: AppTypography.headingLarge.copyWith(
                              color: AppNeutralColors.grey900,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.s8),
                          Text(
                            currentDate,
                            style: AppTypography.bodySmallSemiBold.copyWith(
                              color: AppNeutralColors.grey900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s24),
                    AppEditableTextArea(
                      controller: _answerController,
                      focusNode: _answerFocusNode,
                      hintText: "무엇이든 가볍게 적어보세요",
                      height: 369,
                      backgroundColor: brand.bg,
                      borderColor: brand.c400,
                    ),
                    const SizedBox(height: AppSpacing.s24),
                    SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: _canPolish
                            ? () => _openPolishBottomSheet(context)
                            : null,
                        style: ButtonStyle(
                          backgroundColor:
                              WidgetStateProperty.resolveWith<Color>((
                                Set<WidgetState> states,
                              ) {
                                if (states.contains(WidgetState.disabled)) {
                                  return Color.alphaBlend(
                                    AppTransparentColors.light64,
                                    brand.c200,
                                  );
                                }
                                return brand.c100;
                              }),
                          side: WidgetStateProperty.resolveWith<BorderSide>((
                            Set<WidgetState> states,
                          ) {
                            if (states.contains(WidgetState.disabled)) {
                              return BorderSide.none;
                            }
                            return BorderSide(color: brand.c200);
                          }),
                          foregroundColor:
                              WidgetStateProperty.resolveWith<Color>((
                                Set<WidgetState> states,
                              ) {
                                if (states.contains(WidgetState.disabled)) {
                                  return brand.c300;
                                }
                                return brand.c500;
                              }),
                          shape: const WidgetStatePropertyAll<OutlinedBorder>(
                            StadiumBorder(),
                          ),
                          textStyle: const WidgetStatePropertyAll<TextStyle>(
                            AppTypography.buttonMedium,
                          ),
                          elevation: const WidgetStatePropertyAll<double>(0),
                        ),
                        child: Text(
                          _polishUsedCount >= 3
                              ? "✨ 문장다듬기를 모두 사용하셨어요."
                              : "✨ 문장을 매끄럽게 다듬어줄까요?",
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s24),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.s8,
                      ),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppNeutralColors.grey100),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            "버킷리스트",
                            style: AppTypography.headingXSmall.copyWith(
                              color: AppNeutralColors.grey900,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.s6),
                          Text(
                            "이 질문을 통해 생각난 목표가 있나요?",
                            style: AppTypography.captionMedium.copyWith(
                              color: AppNeutralColors.grey600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _bucketTags.isEmpty
                          ? Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _openBucketBottomSheet(context),
                                borderRadius: BorderRadius.circular(999),
                                child: Container(
                                  height: 38,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.s16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: brand.c100,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(color: brand.c200),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Text(
                                        "추가하기",
                                        style: AppTypography.buttonSmall
                                            .copyWith(color: brand.c500),
                                      ),
                                      const SizedBox(width: AppSpacing.s4),
                                      Icon(
                                        Icons.add,
                                        size: 16,
                                        color: brand.c500,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : Wrap(
                              spacing: AppSpacing.s8,
                              runSpacing: AppSpacing.s8,
                              children: <Widget>[
                                ..._bucketTags.asMap().entries.map((
                                  MapEntry<int, String> entry,
                                ) {
                                  return Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onLongPress: () {
                                        setState(() {
                                          _bucketTags.removeAt(entry.key);
                                        });
                                        _showBucketRemovedToast();
                                      },
                                      borderRadius: BorderRadius.circular(999),
                                      child: _QuestionBucketTagChip(
                                        text: entry.value,
                                        maxWidth: bucketTagMaxWidth,
                                      ),
                                    ),
                                  );
                                }),
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () =>
                                        _openBucketBottomSheet(context),
                                    borderRadius: BorderRadius.circular(999),
                                    child: Container(
                                      width: 38,
                                      height: 38,
                                      padding: const EdgeInsets.all(
                                        AppSpacing.s8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: brand.c100,
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        border: Border.all(color: brand.c200),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          Icons.add,
                                          size: 16,
                                          color: brand.c500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: AppSpacing.s16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.s8,
                      ),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppNeutralColors.grey100),
                        ),
                      ),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  "전체공개",
                                  style: AppTypography.headingXSmall.copyWith(
                                    color: AppNeutralColors.grey900,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.s6),
                                Text(
                                  "모든 사용자에게 익명으로 내 글을 공개합니다.",
                                  style: AppTypography.captionMedium.copyWith(
                                    color: AppNeutralColors.grey600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AppIconToggle(
                            value: _isPublic,
                            onChanged: (bool value) {
                              setState(() {
                                _isPublic = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      height: 60,
                      child: FilledButton(
                        onPressed: _hasInput ? _saveRecord : null,
                        style: ButtonStyle(
                          backgroundColor:
                              WidgetStateProperty.resolveWith<Color>((
                                Set<WidgetState> states,
                              ) {
                                if (states.contains(WidgetState.disabled)) {
                                  return brand.c300;
                                }
                                if (states.contains(WidgetState.hovered)) {
                                  return brand.c600;
                                }
                                return brand.c500;
                              }),
                          overlayColor: WidgetStatePropertyAll<Color>(
                            AppNeutralColors.white.withValues(alpha: 0.08),
                          ),
                          shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.s8,
                              ),
                            ),
                          ),
                        ),
                        child: Text(
                          "저장하기",
                          style: AppTypography.buttonLarge.copyWith(
                            color: AppNeutralColors.white,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: safeBottomInset + 8),
                  ],
                ),
              ),
            ),
            if (_showPolishLoading)
              Positioned.fill(
                child: Container(
                  color: const Color(0x3D000000),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      CircularProgressIndicator(
                        color: brand.c500,
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: AppSpacing.s12),
                      Text(
                        "문장을 다듬는 중이에요...",
                        style: AppTypography.bodySmallMedium.copyWith(
                          color: AppNeutralColors.grey900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _QuestionBucketTagChip extends StatelessWidget {
  const _QuestionBucketTagChip({required this.text, required this.maxWidth});

  final String text;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      height: 38,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s12,
        vertical: AppSpacing.s8,
      ),
      decoration: BoxDecoration(
        color: context.appBrandScale.c500,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            "# ",
            style: AppTypography.bodySmallMedium.copyWith(
              color: AppNeutralColors.white,
            ),
          ),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmallMedium.copyWith(
                color: AppNeutralColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
