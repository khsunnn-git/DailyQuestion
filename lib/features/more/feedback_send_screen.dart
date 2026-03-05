import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import "dart:math" as math;

import "../../design_system/design_system.dart";

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
  final _FeedbackRepository _feedbackRepository = _FeedbackRepository();

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
      await _feedbackRepository.submit(
        category: _selectedCategory,
        message: _messageController.text.trim(),
        email: _emailController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      final bool confirmed = await _showCompletedDialog();
      if (mounted && confirmed) {
        Navigator.of(context).pop();
      }
    } on _FeedbackSubmitException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.userMessage)));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<bool> _showCompletedDialog() async {
    final BrandScale brand = context.appBrandScale;
    final bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: AppPopupTokens.dimmed,
      builder: (BuildContext dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.s20),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s20,
                AppSpacing.s32,
                AppSpacing.s20,
                AppSpacing.s20,
              ),
              decoration: BoxDecoration(
                color: AppNeutralColors.white,
                borderRadius: BorderRadius.circular(AppSpacing.s24),
                boxShadow: AppPopupTokens.shadow,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s16,
                      ),
                      child: Text(
                        "의견 보내기가\n완료되었습니다.",
                        style: AppTypography.headingSmall.copyWith(
                          color: AppNeutralColors.grey900,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s28),
                    SizedBox(
                      height: AppSpacing.s56,
                      child: FilledButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        style: FilledButton.styleFrom(
                          backgroundColor: brand.c500,
                          foregroundColor: AppNeutralColors.white,
                          disabledBackgroundColor: brand.c300,
                          disabledForegroundColor: brand.c100,
                          surfaceTintColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.s8),
                          ),
                          textStyle: AppTypography.buttonLarge,
                        ),
                        child: Text(
                          "확인",
                          style: AppTypography.buttonLarge.copyWith(
                            color: AppNeutralColors.white,
                            decoration: TextDecoration.none,
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
      },
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    final double rawWidth = MediaQuery.sizeOf(context).width;
    final double frameWidth = rawWidth <= 0 ? _screenWidth : math.min(_screenWidth, rawWidth);
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
                      const SizedBox(width: AppSpacing.s24, height: AppSpacing.s24),
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
                              borderRadius: BorderRadius.circular(AppSpacing.s8),
                              border: Border.all(color: brand.c300),
                            ),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    _selectedCategory,
                                    style: AppTypography.bodyMediumMedium.copyWith(
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
                          hintText: "무엇이든 가볍게 적어보세요",
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
                              hintText: "Daily@question.com",
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
                      onPressed: _canSubmit && _isEmailValid ? _submitFeedback : null,
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

class _FeedbackRepository {
  _FeedbackRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<void> submit({
    required String category,
    required String message,
    required String email,
  }) async {
    try {
      final User user = await _ensureSignedInUser();
      await _firestore.collection("reports").add(<String, dynamic>{
        "reason": message,
        "targetId": "app_feedback",
        "targetType": "customer_feedback",
        "reporterUid": user.uid,
        "category": category,
        "email": email,
        "status": "open",
        "source": "feedback_form",
        "reportedAt": FieldValue.serverTimestamp(),
        "reportedAtClient": Timestamp.now(),
        "createdAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (error) {
      if (error.code == "permission-denied") {
        throw const _FeedbackSubmitException(
          userMessage: "의견 전송 권한이 없어요. 로그인 상태를 확인 후 다시 시도해주세요.",
        );
      }
      throw const _FeedbackSubmitException(
        userMessage: "의견 전송에 실패했어요. 네트워크를 확인하고 다시 시도해주세요.",
      );
    }
  }

  Future<User> _ensureSignedInUser() async {
    final User? current = _auth.currentUser;
    if (current != null) {
      return current;
    }
    try {
      final UserCredential credential = await _auth.signInAnonymously();
      final User? created = credential.user;
      if (created != null) {
        return created;
      }
    } on FirebaseAuthException catch (_) {
      throw const _FeedbackSubmitException(
        userMessage: "로그인이 필요해서 의견을 보내지 못했어요. 다시 시도해주세요.",
      );
    }
    throw const _FeedbackSubmitException(
      userMessage: "의견 정보를 준비하지 못했어요. 잠시 후 다시 시도해주세요.",
    );
  }
}

class _FeedbackSubmitException implements Exception {
  const _FeedbackSubmitException({required this.userMessage});

  final String userMessage;
}
