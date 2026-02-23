import "package:flutter/material.dart";

import "../../design_system/design_system.dart";

class TodayQuestionAnswerScreen extends StatefulWidget {
  const TodayQuestionAnswerScreen({super.key});

  @override
  State<TodayQuestionAnswerScreen> createState() =>
      _TodayQuestionAnswerScreenState();
}

class _TodayQuestionAnswerScreenState extends State<TodayQuestionAnswerScreen> {
  bool _isPublic = false;
  final TextEditingController _answerController = TextEditingController();
  final FocusNode _answerFocusNode = FocusNode();

  bool get _hasInput => _answerController.text.trim().isNotEmpty;

  bool get _canPolish => _effectiveCharCount(_answerController.text) >= 5;

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
    return normalized
        .replaceAll("  ", " ")
        .replaceAll("..", ".")
        .replaceAll("\n\n\n", "\n\n");
  }

  Future<void> _openPolishBottomSheet(BuildContext context) async {
    if (!_canPolish) {
      return;
    }
    final String originalText = _answerController.text;
    final String polishedText = _buildPolishedText(originalText);

    final String? action = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppNeutralColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        final BrandScale brand = context.appBrandScale;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                "문장을 이렇게 다듬어봤어요",
                style: AppTypography.headingXSmall.copyWith(
                  color: AppNeutralColors.grey900,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: brand.c50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: brand.c200),
                ),
                child: Text(
                  polishedText,
                  style: AppTypography.bodyMediumMedium.copyWith(
                    color: AppNeutralColors.grey900,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop("keep"),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        side: BorderSide(color: brand.c200),
                      ),
                      child: Text(
                        "원문 유지",
                        style: AppTypography.buttonMedium.copyWith(
                          color: AppNeutralColors.grey900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop("apply"),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: brand.c500,
                      ),
                      child: Text(
                        "적용하기",
                        style: AppTypography.buttonMedium.copyWith(
                          color: AppNeutralColors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (!mounted) {
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
    final AppButtonMetrics mediumButtonMetrics = AppButtonTokens.metrics(
      AppButtonSize.medium,
    );
    final Color polishDisabledBackground = Color.alphaBlend(
      AppTransparentColors.light64,
      brand.c200,
    );
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
                          height: 370,
                        ),
                        const SizedBox(height: AppSpacing.s24),
                        SizedBox(
                          height: mediumButtonMetrics.height,
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
                                      return polishDisabledBackground;
                                    }
                                    return brand.c100;
                                  }),
                              side: WidgetStateProperty.resolveWith<BorderSide>(
                                (Set<WidgetState> states) {
                                  if (states.contains(WidgetState.disabled)) {
                                    return BorderSide(color: brand.c200);
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
                              textStyle: WidgetStatePropertyAll<TextStyle>(
                                mediumButtonMetrics.textStyle,
                              ),
                              elevation:
                                  WidgetStateProperty.resolveWith<double>((
                                Set<WidgetState> states,
                              ) {
                                if (states.contains(WidgetState.hovered)) {
                                  return 2;
                                }
                                return 0;
                              }),
                              shadowColor:
                                  const WidgetStatePropertyAll<Color>(
                                Color(0x14000000),
                              ),
                            ),
                            child: const Text("✨ 문장을 매끄럽게 다듬어줄까요?"),
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
                      onPressed: _hasInput ? () {} : null,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
