import "dart:async";

import "package:flutter/material.dart";

import "../../design_system/design_system.dart";
import "today_question_store.dart";

class TodayQuestionAnswerScreen extends StatefulWidget {
  const TodayQuestionAnswerScreen({super.key});

  @override
  State<TodayQuestionAnswerScreen> createState() =>
      _TodayQuestionAnswerScreenState();
}

class _TodayQuestionAnswerScreenState extends State<TodayQuestionAnswerScreen> {
  bool _isPublic = false;
  int _polishUsedCount = 0;
  bool _showPolishLoading = false;
  final TextEditingController _answerController = TextEditingController();
  final FocusNode _answerFocusNode = FocusNode();

  bool get _hasInput => _answerController.text.trim().isNotEmpty;

  bool get _canPolish =>
      _effectiveCharCount(_answerController.text) >= 5 && _polishUsedCount < 3;

  @override
  void initState() {
    super.initState();
    _answerController.addListener(_handleAnswerChanged);
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
            return base
                .replaceAll("싶어요.", "싶습니다.")
                .replaceAll("거예요.", "것입니다.");
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

  Future<void> _openPolishBottomSheet(BuildContext context) async {
    if (!_canPolish) {
      return;
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

    final String? action = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      barrierColor: const Color(0xB8000000),
      backgroundColor: AppNeutralColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        final BrandScale brand = context.appBrandScale;
        final int displayCount = _polishUsedCount.clamp(1, 3);
        final bool canRetry = _polishUsedCount < 3;
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
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
      _openPolishBottomSheet(context);
      return;
    }

    if (action == "apply") {
      _answerController.text = polishedText;
      _answerController.selection = TextSelection.fromPosition(
        TextPosition(offset: _answerController.text.length),
      );
    }
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
    final DateTime now = DateTime.now();
    final double keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    final String currentDate =
        "${now.year.toString().padLeft(4, "0")}."
        "${now.month.toString().padLeft(2, "0")}."
        "${now.day.toString().padLeft(2, "0")}";
    return Scaffold(
      backgroundColor: brand.bg,
      body: SafeArea(
        child: Center(
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
                      110,
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
                              child: Text(
                                "오늘의 질문",
                                textAlign: TextAlign.center,
                                style: AppTypography.headingXSmall.copyWith(
                                  color: AppNeutralColors.grey900,
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
                                "올해 안에 꼭 해보고 싶은 일\n하나는 무엇인가요?",
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
                              side: WidgetStateProperty.resolveWith<BorderSide>(
                                (Set<WidgetState> states) {
                                  if (states.contains(WidgetState.disabled)) {
                                    return BorderSide.none;
                                  }
                                  return BorderSide(color: brand.c200);
                                },
                              ),
                              foregroundColor:
                                  WidgetStateProperty.resolveWith<Color>((
                                    Set<WidgetState> states,
                                  ) {
                                    if (states.contains(WidgetState.disabled)) {
                                      return brand.c300;
                                    }
                                    return brand.c500;
                                  }),
                              shape:
                                  const WidgetStatePropertyAll<OutlinedBorder>(
                                    StadiumBorder(),
                                  ),
                              textStyle:
                                  const WidgetStatePropertyAll<TextStyle>(
                                    AppTypography.buttonMedium,
                                  ),
                              elevation: const WidgetStatePropertyAll<double>(
                                0,
                              ),
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
                              bottom: BorderSide(
                                color: AppNeutralColors.grey100,
                              ),
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
                                  style: AppTypography.buttonSmall.copyWith(
                                    color: brand.c500,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.s4),
                                Icon(Icons.add, size: 16, color: brand.c500),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s16),
                        Container(
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
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      "전체공개",
                                      style: AppTypography.headingXSmall
                                          .copyWith(
                                            color: AppNeutralColors.grey900,
                                          ),
                                    ),
                                    const SizedBox(height: AppSpacing.s6),
                                    Text(
                                      "모든 사용자에게 익명으로 내 글을 공개합니다.",
                                      style: AppTypography.captionMedium
                                          .copyWith(
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
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: AppSpacing.s20,
                  right: AppSpacing.s20,
                  bottom: keyboardInset > 0 ? 12 : AppSpacing.s20,
                  child: SizedBox(
                    height: 60,
                    child: FilledButton(
                      onPressed: _hasInput
                          ? () {
                              TodayQuestionStore.instance.saveRecord(
                                answer: _answerController.text,
                                isPublic: _isPublic,
                                bucketTag: "제주도 한라산 가기",
                              );
                              if (!mounted) {
                                return;
                              }
                              Navigator.of(context).maybePop();
                            }
                          : null,
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.resolveWith<Color>(
                          (Set<WidgetState> states) {
                            if (states.contains(WidgetState.disabled)) {
                              return brand.c300;
                            }
                            if (states.contains(WidgetState.hovered)) {
                              return brand.c600;
                            }
                            return brand.c500;
                          },
                        ),
                        overlayColor: WidgetStatePropertyAll<Color>(
                          AppNeutralColors.white.withValues(alpha: 0.08),
                        ),
                        shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.s8),
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
        ),
      ),
    );
  }
}
