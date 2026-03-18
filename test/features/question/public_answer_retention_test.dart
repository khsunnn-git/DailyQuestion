import "package:dailyquestion/features/question/public_answer_retention.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  test("keeps last 7 days inclusive when calculating cutoff", () {
    final String cutoff = publicAnswerRetentionCutoffDateKey(
      now: DateTime.utc(2026, 3, 15, 3),
    );

    expect(cutoff, "20260309");
    expect(
      shouldDeletePublicAnswerDateKey(
        "20260308",
        now: DateTime.utc(2026, 3, 15, 3),
      ),
      isTrue,
    );
    expect(
      shouldDeletePublicAnswerDateKey(
        "20260309",
        now: DateTime.utc(2026, 3, 15, 3),
      ),
      isFalse,
    );
  });

  test("recentPublicAnswerDateKeys returns latest 7 keys in descending order", () {
    final List<String> keys = recentPublicAnswerDateKeys(
      now: DateTime.utc(2026, 3, 15, 3),
    );

    expect(
      keys,
      <String>[
        "20260315",
        "20260314",
        "20260313",
        "20260312",
        "20260311",
        "20260310",
        "20260309",
      ],
    );
  });
}
