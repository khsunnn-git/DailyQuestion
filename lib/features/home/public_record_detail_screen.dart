import "dart:math" as math;

import "package:flutter/material.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../../design_system/design_system.dart";
import "public_record_report_repository.dart";
import "public_today_records_repository.dart";

enum PublicRecordDetailResult { hidden, blocked }

enum _PublicRecordMenuAction { report, hide, block }

class PublicRecordDetailOverlay extends StatefulWidget {
  const PublicRecordDetailOverlay({
    super.key,
    required this.record,
    required this.questionDateKey,
    required this.questionText,
  });

  final PublicTodayRecord record;
  final String questionDateKey;
  final String questionText;

  @override
  State<PublicRecordDetailOverlay> createState() =>
      _PublicRecordDetailOverlayState();
}

class _PublicRecordDetailOverlayState extends State<PublicRecordDetailOverlay> {
  static const String _hiddenRecordsPrefsKey =
      "today_records_hidden_record_ids";
  static const String _blockedAuthorsPrefsKey = "today_records_blocked_authors";

  final PublicRecordReportRepository _reportRepository =
      PublicRecordReportRepository();
  _PublicRecordMenuAction? _selectedAction;

  Future<void> _openActionListBottomSheet() async {
    final _PublicRecordMenuAction?
    action = await showModalBottomSheet<_PublicRecordMenuAction>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppPopupTokens.dimmed,
      elevation: 0,
      builder: (BuildContext sheetContext) {
        final double keyboardInset = MediaQuery.viewInsetsOf(
          sheetContext,
        ).bottom;
        final double bottomInset = MediaQuery.viewPaddingOf(
          sheetContext,
        ).bottom;
        final double safeBottomPadding =
            (bottomInset + AppSpacing.s24) < AppSpacing.s48
            ? AppSpacing.s48
            : (bottomInset + AppSpacing.s24);

        return DecoratedBox(
          decoration: const BoxDecoration(
            color: AppNeutralColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: AppPopupTokens.bottomSheetShadow,
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.s24,
              AppSpacing.s20,
              AppSpacing.s24,
              safeBottomPadding + keyboardInset,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppNeutralColors.grey300,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s16),
                Text(
                  "작업 선택",
                  style: AppTypography.headingXSmall.copyWith(
                    color: AppNeutralColors.grey900,
                  ),
                ),
                const SizedBox(height: AppSpacing.s12),
                AppBottomSheetListItem(
                  label: "신고",
                  selected: _selectedAction == _PublicRecordMenuAction.report,
                  onTap: () => Navigator.of(
                    sheetContext,
                  ).pop(_PublicRecordMenuAction.report),
                ),
                AppBottomSheetListItem(
                  label: "숨김",
                  selected: _selectedAction == _PublicRecordMenuAction.hide,
                  onTap: () => Navigator.of(
                    sheetContext,
                  ).pop(_PublicRecordMenuAction.hide),
                ),
                AppBottomSheetListItem(
                  label: "차단",
                  selected: _selectedAction == _PublicRecordMenuAction.block,
                  onTap: () => Navigator.of(
                    sheetContext,
                  ).pop(_PublicRecordMenuAction.block),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (action == null || !mounted) {
      return;
    }
    setState(() {
      _selectedAction = action;
    });
    if (action == _PublicRecordMenuAction.report) {
      await _openReportBottomSheet();
      return;
    }
    if (action == _PublicRecordMenuAction.hide) {
      await _openHideDialog();
      return;
    }
    await _openBlockDialog();
  }

  Future<void> _openHideDialog() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: AppPopupTokens.dimmed,
      builder: (BuildContext dialogContext) {
        final AppButtonMetrics buttonMetrics = AppButtonTokens.metrics(
          AppButtonSize.large,
        );
        final BrandScale brand = dialogContext.appBrandScale;

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            decoration: BoxDecoration(
              color: AppNeutralColors.white,
              borderRadius: BorderRadius.circular(AppSpacing.s16),
            ),
            padding: const EdgeInsets.all(AppSpacing.s24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  "이 답변을 숨기시겠어요?",
                  style: AppTypography.headingSmall.copyWith(
                    color: AppNeutralColors.grey900,
                  ),
                ),
                const SizedBox(height: AppSpacing.s8),
                Text(
                  "숨기면 내 기기에서만 보이지 않아요.",
                  style: AppTypography.bodyMediumRegular.copyWith(
                    color: AppNeutralColors.grey500,
                  ),
                ),
                const SizedBox(height: AppSpacing.s20),
                SizedBox(
                  height: 56,
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: FilledButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(false),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(56),
                            backgroundColor: AppNeutralColors.grey100,
                            foregroundColor: AppNeutralColors.grey600,
                            textStyle: buttonMetrics.textStyle,
                            overlayColor: Colors.transparent,
                            splashFactory: NoSplash.splashFactory,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.s8,
                              ),
                            ),
                          ),
                          child: const Text("취소"),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s8),
                      Expanded(
                        child: FilledButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(true),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(56),
                            backgroundColor: brand.c500,
                            foregroundColor: AppNeutralColors.white,
                            textStyle: buttonMetrics.textStyle,
                            overlayColor: Colors.transparent,
                            splashFactory: NoSplash.splashFactory,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.s8,
                              ),
                            ),
                          ),
                          child: const Text("숨기기"),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final Set<String> hiddenRecordIds =
        (prefs.getStringList(_hiddenRecordsPrefsKey) ?? const <String>[])
            .toSet();
    hiddenRecordIds.add(_recordTargetId(widget.record));
    await prefs.setStringList(
      _hiddenRecordsPrefsKey,
      hiddenRecordIds.toList(growable: false),
    );
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(PublicRecordDetailResult.hidden);
  }

  Future<void> _openBlockDialog() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: AppPopupTokens.dimmed,
      builder: (BuildContext dialogContext) {
        final AppButtonMetrics buttonMetrics = AppButtonTokens.metrics(
          AppButtonSize.large,
        );
        final BrandScale brand = dialogContext.appBrandScale;

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            decoration: BoxDecoration(
              color: AppNeutralColors.white,
              borderRadius: BorderRadius.circular(AppSpacing.s16),
            ),
            padding: const EdgeInsets.all(AppSpacing.s24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  "이 사용자를 차단하시겠어요?",
                  style: AppTypography.headingSmall.copyWith(
                    color: AppNeutralColors.grey900,
                  ),
                ),
                const SizedBox(height: AppSpacing.s8),
                Text(
                  "차단하면 내 기기에서만 이 사용자의 글이 보이지 않아요.",
                  style: AppTypography.bodyMediumRegular.copyWith(
                    color: AppNeutralColors.grey500,
                  ),
                ),
                const SizedBox(height: AppSpacing.s20),
                SizedBox(
                  height: 56,
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: FilledButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(false),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(56),
                            backgroundColor: AppNeutralColors.grey100,
                            foregroundColor: AppNeutralColors.grey600,
                            textStyle: buttonMetrics.textStyle,
                            overlayColor: Colors.transparent,
                            splashFactory: NoSplash.splashFactory,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.s8,
                              ),
                            ),
                          ),
                          child: const Text("취소"),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s8),
                      Expanded(
                        child: FilledButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(true),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(56),
                            backgroundColor: brand.c500,
                            foregroundColor: AppNeutralColors.white,
                            textStyle: buttonMetrics.textStyle,
                            overlayColor: Colors.transparent,
                            splashFactory: NoSplash.splashFactory,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.s8,
                              ),
                            ),
                          ),
                          child: const Text("차단하기"),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final Set<String> blockedAuthors =
        (prefs.getStringList(_blockedAuthorsPrefsKey) ?? const <String>[])
            .toSet();
    final String author = widget.record.author.trim();
    if (author.isNotEmpty) {
      blockedAuthors.add(author);
      await prefs.setStringList(
        _blockedAuthorsPrefsKey,
        blockedAuthors.toList(growable: false),
      );
    }
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(PublicRecordDetailResult.blocked);
  }

  Future<void> _openReportBottomSheet() async {
    final TextEditingController reasonController = TextEditingController();
    final FocusNode reasonFocusNode = FocusNode();
    final bool? submitted = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppPopupTokens.dimmed,
      elevation: 0,
      builder: (BuildContext sheetContext) {
        final AppButtonMetrics buttonMetrics = AppButtonTokens.metrics(
          AppButtonSize.large,
        );
        final double keyboardInset = MediaQuery.viewInsetsOf(
          sheetContext,
        ).bottom;
        final double bottomInset = MediaQuery.viewPaddingOf(
          sheetContext,
        ).bottom;
        final double safeBottomPadding =
            (bottomInset + AppSpacing.s24) < AppSpacing.s48
            ? AppSpacing.s48
            : (bottomInset + AppSpacing.s24);
        final BrandScale brand = sheetContext.appBrandScale;

        return DecoratedBox(
          decoration: const BoxDecoration(
            color: AppNeutralColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: AppPopupTokens.bottomSheetShadow,
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.s24,
              AppSpacing.s24,
              AppSpacing.s24,
              safeBottomPadding + keyboardInset,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Center(
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
                  "이 답변을 신고하시겠어요?",
                  style: AppTypography.headingSmall.copyWith(
                    color: AppNeutralColors.grey900,
                  ),
                ),
                const SizedBox(height: AppSpacing.s8),
                Text(
                  "아래 신고 사유를 간단하게 적어주세요.",
                  style: AppTypography.bodyMediumRegular.copyWith(
                    color: AppNeutralColors.grey500,
                  ),
                ),
                const SizedBox(height: AppSpacing.s20),
                AppEditableTextArea(
                  controller: reasonController,
                  focusNode: reasonFocusNode,
                  hintText: "신고사유",
                  height: 100,
                  backgroundColor: AppNeutralColors.grey50,
                  borderColor: Colors.transparent,
                  contentPadding: const EdgeInsets.all(10),
                  autocorrect: false,
                  enableSuggestions: false,
                ),
                const SizedBox(height: AppSpacing.s20),
                SizedBox(
                  height: 56,
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: FilledButton(
                          onPressed: () =>
                              Navigator.of(sheetContext).pop(false),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(56),
                            backgroundColor: AppNeutralColors.grey100,
                            foregroundColor: AppNeutralColors.grey600,
                            textStyle: buttonMetrics.textStyle,
                            overlayColor: Colors.transparent,
                            splashFactory: NoSplash.splashFactory,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.s8,
                              ),
                            ),
                          ),
                          child: const Text("취소"),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s8),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.of(sheetContext).pop(true),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(56),
                            backgroundColor: brand.c500,
                            foregroundColor: AppNeutralColors.white,
                            textStyle: buttonMetrics.textStyle,
                            overlayColor: Colors.transparent,
                            splashFactory: NoSplash.splashFactory,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.s8,
                              ),
                            ),
                          ),
                          child: const Text("보내기"),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted) {
      reasonFocusNode.dispose();
      reasonController.dispose();
      return;
    }

    if (submitted == true) {
      final String reason = reasonController.text.trim();
      if (reason.isEmpty) {
        _showToast("신고 사유를 입력해주세요.");
        reasonFocusNode.dispose();
        reasonController.dispose();
        return;
      }
      try {
        await _reportRepository.submit(
          reason: reason,
          targetId: _recordTargetId(widget.record),
          targetType: "public_answer",
          questionDateKey: widget.questionDateKey,
          authorName: widget.record.author,
          answerPreview: widget.record.body,
        );
        if (mounted) {
          _showToast("신고가 접수되었습니다. 빠르게 확인할게요.");
        }
      } on PublicRecordReportSubmitException catch (error) {
        if (mounted) {
          _showToast(error.userMessage);
        }
      } catch (_) {
        if (mounted) {
          _showToast("신고 접수에 실패했어요. 잠시 후 다시 시도해주세요.");
        }
      }
    }
    reasonFocusNode.dispose();
    reasonController.dispose();
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            message,
            style: AppTypography.captionMedium.copyWith(
              color: AppNeutralColors.white,
            ),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.sizeOf(context);
    final EdgeInsets safePadding = MediaQuery.paddingOf(context);
    final double cardWidth = math.min(screenSize.width - AppSpacing.s40, 350);
    final double horizontalInset = (screenSize.width - cardWidth) / 2;
    final double cardTop = math.max(
      safePadding.top + 180,
      math.min(screenSize.height * 0.42, 360),
    );
    final double closeTop = math.max(safePadding.top + 8, cardTop - 29);
    final double maxCardHeight = math.max(
      240,
      screenSize.height - cardTop - safePadding.bottom - AppSpacing.s40,
    );

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).maybePop(),
              child: const ColoredBox(color: Color(0x7A000000)),
            ),
          ),
          Positioned(
            left: horizontalInset,
            right: horizontalInset,
            top: closeTop,
            child: Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: () => Navigator.of(context).maybePop(),
                borderRadius: BorderRadius.circular(AppSpacing.s20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s8,
                    vertical: AppSpacing.s4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        "닫기",
                        style: AppTypography.buttonSmall.copyWith(
                          color: AppNeutralColors.white,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s4),
                      const Icon(
                        Icons.close,
                        size: 20,
                        color: AppNeutralColors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: horizontalInset,
            right: horizontalInset,
            top: cardTop,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxCardHeight),
              child: Container(
                width: cardWidth,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s32,
                  AppSpacing.s40,
                  AppSpacing.s32,
                  AppSpacing.s40,
                ),
                decoration: BoxDecoration(
                  color: AppNeutralColors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.s16),
                  boxShadow: AppElevation.level1,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    SizedBox(
                      width: double.infinity,
                      child: Text(
                        widget.questionText,
                        textAlign: TextAlign.left,
                        style: AppTypography.headingSmall.copyWith(
                          color: AppNeutralColors.grey900,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s24),
                    Flexible(
                      fit: FlexFit.loose,
                      child: SingleChildScrollView(
                        child: Text(
                          widget.record.body,
                          style: AppTypography.bodyMediumMedium.copyWith(
                            color: AppNeutralColors.grey900,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s24),
                    Row(
                      children: <Widget>[
                        Semantics(
                          button: true,
                          label: "더보기",
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTapDown: (_) => _openActionListBottomSheet(),
                            child: const SizedBox(
                              width: 24,
                              height: 24,
                              child: Icon(
                                Icons.more_horiz,
                                size: 24,
                                color: AppNeutralColors.grey200,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(
                              right: AppSpacing.s20,
                            ),
                            child: Text(
                              "${widget.record.author} 답변",
                              textAlign: TextAlign.center,
                              style: AppTypography.bodySmallSemiBold.copyWith(
                                color: context.appBrandScale.c500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _recordTargetId(PublicTodayRecord record) {
    return "${record.createdAt.millisecondsSinceEpoch}|"
        "${record.author}|${record.body}";
  }
}
