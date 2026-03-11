import "package:flutter/services.dart";

final RegExp nicknameValidationRegExp = RegExp(r"^[ㄱ-ㅎㅏ-ㅣ가-힣]+$");

final RegExp _nicknameInputAllowedRegExp = RegExp(r"[ㄱ-ㅎㅏ-ㅣ가-힣ㆍᆢ]");

List<TextInputFormatter> nicknameInputFormatters({required int maxLength}) {
  return <TextInputFormatter>[
    // Allow Chunjiin's composing dots so the first syllable can be assembled.
    FilteringTextInputFormatter.allow(_nicknameInputAllowedRegExp),
    LengthLimitingTextInputFormatter(maxLength),
  ];
}
