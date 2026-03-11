import "package:dailyquestion/features/profile/nickname_rules.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  group("nickname input formatters", () {
    test("allow Chunjiin composing dot during the first syllable", () {
      final TextInputFormatter formatter = nicknameInputFormatters(
        maxLength: 10,
      ).first;

      const TextEditingValue oldValue = TextEditingValue(text: "ㄱ");
      const TextEditingValue newValue = TextEditingValue(text: "ㄱㆍ");

      final TextEditingValue result = formatter.formatEditUpdate(
        oldValue,
        newValue,
      );

      expect(result.text, "ㄱㆍ");
    });

    test("continue to block non-Korean characters", () {
      final TextInputFormatter formatter = nicknameInputFormatters(
        maxLength: 10,
      ).first;

      const TextEditingValue oldValue = TextEditingValue.empty;
      const TextEditingValue newValue = TextEditingValue(text: "겨a");

      final TextEditingValue result = formatter.formatEditUpdate(
        oldValue,
        newValue,
      );

      expect(result.text, "겨");
    });
  });

  group("nickname validation", () {
    test("accept complete Hangul nicknames", () {
      expect(nicknameValidationRegExp.hasMatch("겨울밤바다"), isTrue);
    });

    test("reject unfinished Chunjiin composing text", () {
      expect(nicknameValidationRegExp.hasMatch("ㄱㆍ"), isFalse);
    });
  });
}
