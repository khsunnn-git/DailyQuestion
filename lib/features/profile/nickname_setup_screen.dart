import "dart:async";

import "package:flutter/material.dart";
import "package:flutter/services.dart";

import "../../design_system/design_system.dart";
import "nickname_complete_screen.dart";
import "nickname_firestore_service.dart";
import "user_profile_prefs.dart";

class NicknameSetupScreen extends StatefulWidget {
  const NicknameSetupScreen({
    super.key,
    this.onCompleted,
    this.isEditMode = false,
  });

  final VoidCallback? onCompleted;
  final bool isEditMode;

  @override
  State<NicknameSetupScreen> createState() => _NicknameSetupScreenState();
}

class _NicknameSetupScreenState extends State<NicknameSetupScreen> {
  static const int _minNicknameLength = 2;
  static const int _maxNicknameLength = 10;
  static const Color _main500 = Color(0xFF017AF7);
  static const Color _main600 = Color(0xFF0069D6);
  static const Color _main100 = Color(0xFFE9F6FF);
  static const Duration _checkDebounce = Duration(milliseconds: 120);

  final TextEditingController _nicknameController = TextEditingController();
  final FocusNode _nicknameFocusNode = FocusNode();

  Timer? _checkTimer;
  int _checkSerial = 0;
  bool _isSaving = false;
  _NicknameValidationState _validationState = _NicknameValidationState.idle;

  String get _trimmedNickname => _nicknameController.text.trim();
  int get _nicknameLength => _trimmedNickname.length;
  bool get _isKoreanOnly =>
      RegExp(r"^[ㄱ-ㅎㅏ-ㅣ가-힣]+$").hasMatch(_trimmedNickname);
  bool get _isLocallyValid =>
      _trimmedNickname.isNotEmpty &&
      _isKoreanOnly &&
      _nicknameLength >= _minNicknameLength &&
      _nicknameLength <= _maxNicknameLength;
  bool get _canSave =>
      _isLocallyValid &&
      !_isSaving &&
      _validationState != _NicknameValidationState.taken;

  String get _supportingMessage {
    return switch (_validationState) {
      _NicknameValidationState.idle => "한글만 사용할 수 있습니다.",
      _NicknameValidationState.invalidLength => "2자 이상 10자 이내로 작성해 주세요.",
      _NicknameValidationState.invalidCharacter => "한글만 사용할 수 있습니다.",
      _NicknameValidationState.checking => "사용 가능한 닉네임인지 확인 중입니다.",
      _NicknameValidationState.taken => "이미 사용 중인 닉네임입니다. 다른 이름을 입력해주세요.",
      _NicknameValidationState.available => "사용 가능한 닉네임입니다.",
      _NicknameValidationState.unavailable => "닉네임 확인이 원활하지 않습니다. 다시 시도해주세요.",
    };
  }

  Color get _supportingColor {
    return switch (_validationState) {
      _NicknameValidationState.available => _main500,
      _NicknameValidationState.checking => AppNeutralColors.grey500,
      _NicknameValidationState.invalidLength ||
      _NicknameValidationState.invalidCharacter ||
      _NicknameValidationState.taken ||
      _NicknameValidationState.unavailable => AppSemanticColors.error500,
      _NicknameValidationState.idle => AppNeutralColors.grey500,
    };
  }

  Color get _fieldBorderColor {
    if (_validationState == _NicknameValidationState.available ||
        (_nicknameFocusNode.hasFocus &&
            _validationState == _NicknameValidationState.idle) ||
        (_nicknameFocusNode.hasFocus &&
            _validationState == _NicknameValidationState.checking)) {
      return _main500;
    }
    if (_validationState == _NicknameValidationState.invalidLength ||
        _validationState == _NicknameValidationState.invalidCharacter ||
        _validationState == _NicknameValidationState.taken ||
        _validationState == _NicknameValidationState.unavailable) {
      return AppSemanticColors.error500;
    }
    return AppNeutralColors.grey300;
  }

  bool get _isErrorState {
    return _validationState == _NicknameValidationState.invalidLength ||
        _validationState == _NicknameValidationState.invalidCharacter ||
        _validationState == _NicknameValidationState.taken ||
        _validationState == _NicknameValidationState.unavailable;
  }

  bool get _isSuccessState {
    return _validationState == _NicknameValidationState.available;
  }

  @override
  void initState() {
    super.initState();
    _nicknameController.addListener(_onNicknameChanged);
    _nicknameFocusNode.addListener(_onNicknameFocusChanged);
    unawaited(NicknameFirestoreService.instance.warmUpAuth());
    if (widget.isEditMode) {
      unawaited(_loadInitialNickname());
    }
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    _nicknameController
      ..removeListener(_onNicknameChanged)
      ..dispose();
    _nicknameFocusNode
      ..removeListener(_onNicknameFocusChanged)
      ..dispose();
    super.dispose();
  }

  void _onNicknameFocusChanged() {
    if (!_nicknameFocusNode.hasFocus && _isLocallyValid) {
      _checkTimer?.cancel();
      _checkSerial += 1;
      final int serial = _checkSerial;
      _checkAvailabilityNow(serial, _trimmedNickname);
    }
    setState(() {});
  }

  void _onNicknameChanged() {
    _checkTimer?.cancel();
    _checkSerial += 1;
    _runLocalValidation();
    if (_isLocallyValid) {
      _scheduleRemoteCheck(_checkSerial);
    }
    setState(() {});
  }

  void _runLocalValidation() {
    if (_trimmedNickname.isEmpty) {
      _validationState = _NicknameValidationState.idle;
      return;
    }
    if (!_isKoreanOnly) {
      _validationState = _NicknameValidationState.invalidCharacter;
      return;
    }
    if (_nicknameLength < _minNicknameLength ||
        _nicknameLength > _maxNicknameLength) {
      _validationState = _NicknameValidationState.invalidLength;
      return;
    }
    _validationState = _NicknameValidationState.checking;
  }

  void _scheduleRemoteCheck(int serial) {
    final String requestedNickname = _trimmedNickname;
    _checkTimer = Timer(_checkDebounce, () async {
      _checkAvailabilityNow(serial, requestedNickname);
    });
  }

  Future<void> _checkAvailabilityNow(
    int serial,
    String requestedNickname,
  ) async {
    if (!mounted || !_isLocallyValid || requestedNickname != _trimmedNickname) {
      return;
    }
    final NicknameCheckResult result = await NicknameFirestoreService.instance
        .checkAvailability(requestedNickname);
    if (!mounted ||
        serial != _checkSerial ||
        requestedNickname != _trimmedNickname ||
        !_isLocallyValid) {
      return;
    }
    setState(() {
      _validationState = switch (result.state) {
        NicknameCheckState.available => _NicknameValidationState.available,
        NicknameCheckState.duplicate => _NicknameValidationState.taken,
        // 사전 중복확인 실패는 일시적인 네트워크 문제일 수 있어
        // 사용자에게 오류를 고정 노출하지 않고 저장 시점에서 재검증한다.
        NicknameCheckState.unavailable => _NicknameValidationState.idle,
      };
    });
  }

  Future<void> _saveNickname() async {
    if (!_canSave || _isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final NicknameReservationResult reservation = await NicknameFirestoreService
        .instance
        .reserveAndSave(_trimmedNickname);

    if (!mounted) {
      return;
    }

    if (reservation.isDuplicate) {
      setState(() {
        _isSaving = false;
        _validationState = _NicknameValidationState.taken;
      });
      return;
    }

    if (!reservation.success) {
      setState(() {
        _isSaving = false;
        _validationState = _NicknameValidationState.unavailable;
      });
      return;
    }

    await UserProfilePrefs.setNickname(_trimmedNickname);
    if (!mounted) {
      return;
    }

    if (widget.isEditMode) {
      Navigator.of(context).pop(true);
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => NicknameCompleteScreen(
          nickname: _trimmedNickname,
          onStart: widget.onCompleted,
        ),
      ),
    );
  }

  Future<void> _loadInitialNickname() async {
    final String? saved = await UserProfilePrefs.getNickname();
    if (!mounted) {
      return;
    }
    final String initial = saved?.trim() ?? "";
    if (initial.isEmpty) {
      return;
    }
    _nicknameController.text = initial;
    _nicknameController.selection = TextSelection.collapsed(
      offset: initial.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color disabledButtonColor = Color.alphaBlend(
      const Color(0xA3FFFFFF),
      _main600,
    );

    return Scaffold(
      backgroundColor: AppNeutralColors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            AppHeader(
              title: "닉네임 설정",
              trailing: null,
              onLeadingPressed: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s20),
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.s8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        widget.isEditMode
                            ? "나를 표현할 새로운\n닉네임을 적어주세요!"
                            : "나를 표현할\n닉네임을 적어주세요!",
                        style: TextStyle(
                          fontFamily: AppFontFamily.suit,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          height: 1.4,
                          color: AppNeutralColors.grey900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s24),
                  ClipOval(
                    child: SizedBox(
                      width: 100,
                      height: 100,
                      child: Image.asset(
                        "assets/images/signup/signup_nickname_profile_fish.png",
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  SizedBox(
                    width: 350,
                    child: Column(
                      children: <Widget>[
                        SizedBox(
                          height: 58,
                          child: TextField(
                            controller: _nicknameController,
                            focusNode: _nicknameFocusNode,
                            autofocus: true,
                            keyboardType: TextInputType.name,
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.allow(
                                RegExp(r"[ㄱ-ㅎㅏ-ㅣ가-힣]"),
                              ),
                              LengthLimitingTextInputFormatter(
                                _maxNicknameLength,
                              ),
                            ],
                            style: AppInputTokens.mdTextStyle.copyWith(
                              color: AppNeutralColors.grey900,
                            ),
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _saveNickname(),
                            decoration: InputDecoration(
                              hintText: "닉네임을 입력해주세요.",
                              hintStyle: AppInputTokens.mdTextStyle.copyWith(
                                color: AppNeutralColors.grey400,
                              ),
                              counterText: "",
                              suffixIcon: _isErrorState || _isSuccessState
                                  ? Padding(
                                      padding: const EdgeInsets.only(right: 12),
                                      child: Icon(
                                        _isErrorState
                                            ? Icons.error_outline
                                            : Icons.check,
                                        size: 24,
                                        color: _isErrorState
                                            ? AppSemanticColors.error500
                                            : _main500,
                                      ),
                                    )
                                  : null,
                              suffixIconConstraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 24,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.s16,
                                vertical: AppSpacing.s16,
                              ),
                              filled: true,
                              fillColor: AppNeutralColors.white,
                              border: OutlineInputBorder(
                                borderRadius: AppInputTokens.radius,
                                borderSide: BorderSide(
                                  color: _fieldBorderColor,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: AppInputTokens.radius,
                                borderSide: BorderSide(
                                  color: _fieldBorderColor,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: AppInputTokens.radius,
                                borderSide: BorderSide(
                                  color: _fieldBorderColor,
                                  width: 1.4,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s6),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.s12,
                          ),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: Row(
                                  children: <Widget>[
                                    if (_isErrorState || _isSuccessState)
                                      Padding(
                                        padding: EdgeInsets.only(
                                          right: AppInputTokens.supportingGap,
                                        ),
                                        child: Icon(
                                          _isErrorState
                                              ? Icons.error_outline
                                              : Icons.check,
                                          size: 20,
                                          color: _isErrorState
                                              ? AppSemanticColors.error500
                                              : _main500,
                                        ),
                                      ),
                                    Expanded(
                                      child: Text(
                                        _supportingMessage,
                                        style: AppInputTokens.supportingMdStyle
                                            .copyWith(color: _supportingColor),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                "($_nicknameLength/$_maxNicknameLength)",
                                style: AppInputTokens.supportingMdStyle
                                    .copyWith(color: _supportingColor),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: SizedBox(
                  width: 350,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _canSave ? _saveNickname : null,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      backgroundColor: _main500,
                      disabledBackgroundColor: disabledButtonColor,
                      foregroundColor: AppNeutralColors.white,
                      disabledForegroundColor: _main100,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppInputTokens.radius,
                      ),
                      textStyle: AppTypography.buttonLarge,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppNeutralColors.white,
                            ),
                          )
                        : Text(widget.isEditMode ? "완료" : "다음"),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _NicknameValidationState {
  idle,
  invalidLength,
  invalidCharacter,
  checking,
  taken,
  available,
  unavailable,
}
