import "package:flutter/material.dart";
import "dart:math" as math;

import "../../design_system/design_system.dart";
import "../auth/auth_service.dart";
import "feedback_repository.dart";
import "feedback_submission_draft.dart";

class FeedbackSendScreen extends StatefulWidget {
  const FeedbackSendScreen({super.key});

  @override
  State<FeedbackSendScreen> createState() => _FeedbackSendScreenState();
}

class _FeedbackSendScreenState extends State<FeedbackSendScreen> {
  static const double _screenWidth = 390;
  static const List<String> _categoryOptions = <String>[
    "기타",
    "버그 문제",
    "기능 제안",
    "이용 문의",
  ];

  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FeedbackRepository _feedbackRepository = FeedbackRepository();

  String _selectedCategory = _categoryOptions.first;
  bool _isSubmitting = false;
  bool _emailDirty = false;

  bool get _canSubmit =>
      !_isSubmitting && _messageController.text.trim().isNotEmpty;
  bool get _hasEmail => _emailController.text.trim().isNotEmpty;

  bool get _isEmailValid {
    final String value = _emailController.text.trim();
    if (value.isEmpty) {
      return true;
    }
    final RegExp emailPattern = RegExp(r"^[^\s@]+@[^\s@]+\.[^\s@]+$");
    return emailPattern.hasMatch(value);
  }

  bool get _showEmailError => _emailDirty && _hasEmail && !_isEmailValid;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onChanged);
    _emailController.addListener(_onChanged);
  }

  @override
  void dispose() {
    _messageController.removeListener(_onChanged);
    _emailController.removeListener(_onChanged);
    _messageController.dispose();
    _emailController.dispose();
    _messageFocusNode.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _openCategorySheet() async {
    final String? selected = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      barrierColor: AppPopupTokens.dimmed,
      builder: (BuildContext sheetContext) {
        final double bottomInset = MediaQuery.viewPaddingOf(
          sheetContext,
        ).bottom;
        final double bottomPadding = bottomInset + AppSpacing.s20;
        final double safeBottomPadding = bottomPadding < AppSpacing.s48
            ? AppSpacing.s48
            : bottomPadding;

        return DecoratedBox(
          decoration: const BoxDecoration(
            color: AppNeutralColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: AppPopupTokens.bottomSheetShadow,
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.s20,
                AppSpacing.s16,
                AppSpacing.s20,
                safeBottomPadding,
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
                  ..._categoryOptions.map((String option) {
                    return AppBottomSheetListItem(
                      label: option,
                      selected: option == _selectedCategory,
                      onTap: () => Navigator.of(sheetContext).pop(option),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (!mounted || selected == null || selected == _selectedCategory) {
      return;
    }
    setState(() {
      _selectedCategory = selected;
    });
  }

  Future<void> _submitFeedback() async {
    if (!_canSubmit) {
      return;
    }
    if (!_isEmailValid) {
      setState(() {
        _emailDirty = true;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("이메일 형식을 확인해 주세요.")));
      return;
    }
    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = await AuthService.instance.ensureSignedInUser();
      final FeedbackSubmissionDraft draft =
          await FeedbackSubmissionDraft.fromForm(
            category: _selectedCategory,
            message: _messageController.text.trim(),
            replyEmail: _emailController.text.trim(),
            signedInEmail: user.email,
            userId: user.uid,
          );
      await _feedbackRepository.submit(
        draft: draft,
        category: _selectedCategory,
        message: _messageController.text.trim(),
        replyEmail: _emailController.text.trim(),
        senderUid: user.uid,
        senderEmail: user.email,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("의견을 보냈어요.")));
      Navigator.of(context).pop();
    } on FeedbackSubmitException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.userMessage)));
    } on AuthActionException catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("사용자 정보를 준비하지 못했어요. 다시 시도해주세요.")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    final double rawWidth = MediaQuery.sizeOf(context).width;
    final double frameWidth = rawWidth <= 0
        ? _screenWidth
        : math.min(_screenWidth, rawWidth);
    return Scaffold(
      backgroundColor: brand.bg,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: frameWidth,
            child: Column(
              children: <Widget>[
                const SizedBox(height: AppHeaderTokens.topInset),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.s20),
                  child: Row(
                    children: <Widget>[
                      SizedBox(
                        width: AppSpacing.s24,
                        height: AppSpacing.s24,
                        child: IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints.tightFor(
                            width: AppSpacing.s24,
                            height: AppSpacing.s24,
                          ),
                          icon: const Icon(
                            Icons.arrow_back,
                            size: AppSpacing.s24,
                            color: AppNeutralColors.grey900,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          "의견 보내기",
                          textAlign: TextAlign.center,
                          style: AppTypography.headingXSmall.copyWith(
                            color: AppNeutralColors.grey900,
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: AppSpacing.s24,
                        height: AppSpacing.s24,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.s12),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.s20,
                      AppSpacing.s0,
                      AppSpacing.s20,
                      180,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        InkWell(
                          onTap: _openCategorySheet,
                          borderRadius: BorderRadius.circular(AppSpacing.s8),
                          child: Container(
                            width: double.infinity,
                            height: AppSpacing.s56,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.s20,
                            ),
                            decoration: BoxDecoration(
                              color: AppNeutralColors.white,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.s8,
                              ),
                              border: Border.all(color: brand.c300),
                            ),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    _selectedCategory,
                                    style: AppTypography.bodyMediumMedium
                                        .copyWith(
                                          color: AppNeutralColors.grey900,
                                        ),
                                  ),
                                ),
                                const Icon(
                                  Icons.keyboard_arrow_up,
                                  size: AppSpacing.s24,
                                  color: AppNeutralColors.grey900,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s8),
                        AppEditableTextArea(
                          controller: _messageController,
                          focusNode: _messageFocusNode,
                          height: AppInputTokens.textAreaBottomSheetHeight,
                          hintText: "불편한 점이 있다면 무엇이든 말해주세요",
                          backgroundColor: AppNeutralColors.white,
                          borderColor: brand.c300,
                        ),
                        const SizedBox(height: AppSpacing.s24),
                        Text(
                          "이메일(선택)",
                          style: AppTypography.captionMedium.copyWith(
                            color: AppNeutralColors.grey900,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s6),
                        Container(
                          width: double.infinity,
                          height: AppSpacing.s48,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.s16,
                          ),
                          decoration: BoxDecoration(
                            color: AppNeutralColors.white,
                            borderRadius: BorderRadius.circular(AppSpacing.s8),
                            border: Border.all(
                              color: _showEmailError
                                  ? AppSemanticColors.error500
                                  : brand.c300,
                            ),
                          ),
                          alignment: Alignment.centerLeft,
                          child: TextField(
                            controller: _emailController,
                            focusNode: _emailFocusNode,
                            textAlignVertical: TextAlignVertical.center,
                            onTap: () {
                              if (!_emailDirty) {
                                setState(() {
                                  _emailDirty = true;
                                });
                              }
                            },
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.done,
                            cursorColor: AppNeutralColors.grey900,
                            style: AppTypography.bodySmallMedium.copyWith(
                              color: AppNeutralColors.grey900,
                              decoration: TextDecoration.none,
                              decorationColor: Colors.transparent,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              isCollapsed: true,
                              contentPadding: EdgeInsets.zero,
                              hintText: "daily@question.com",
                              hintStyle: AppTypography.bodySmallMedium.copyWith(
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
                        const SizedBox(height: AppSpacing.s4),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.s12,
                          ),
                          child: Row(
                            children: <Widget>[
                              Icon(
                                Icons.error_outline,
                                size: AppSpacing.s20,
                                color: _showEmailError
                                    ? AppSemanticColors.error500
                                    : AppNeutralColors.grey300,
                              ),
                              const SizedBox(width: AppSpacing.s4),
                              Text(
                                _showEmailError
                                    ? "이메일 형식이 올바르지 않아요"
                                    : "답변이 필요하시면 입력해 주세요",
                                style: AppTypography.captionSmall.copyWith(
                                  color: _showEmailError
                                      ? AppSemanticColors.error500
                                      : AppNeutralColors.grey300,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  minimum: const EdgeInsets.fromLTRB(
                    AppSpacing.s20,
                    0,
                    AppSpacing.s20,
                    AppSpacing.s20,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: AppSpacing.s56,
                    child: FilledButton(
                      onPressed: _canSubmit && _isEmailValid
                          ? _submitFeedback
                          : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: _canSubmit ? brand.c500 : brand.c300,
                        foregroundColor: _canSubmit
                            ? AppNeutralColors.white
                            : brand.c100,
                        disabledBackgroundColor: brand.c300,
                        disabledForegroundColor: brand.c100,
                        surfaceTintColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.s8),
                        ),
                        textStyle: AppTypography.buttonLarge,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: AppSpacing.s20,
                              height: AppSpacing.s20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppNeutralColors.white,
                              ),
                            )
                          : Text(
                              "의견 보내기",
                              style: AppTypography.buttonLarge.copyWith(
                                color: _canSubmit
                                    ? AppNeutralColors.white
                                    : brand.c100,
                                decoration: TextDecoration.none,
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
