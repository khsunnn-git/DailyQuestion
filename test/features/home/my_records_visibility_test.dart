import "package:flutter_test/flutter_test.dart";

import "package:dailyquestion/features/home/my_records_visibility.dart";
import "package:dailyquestion/features/question/today_question_store.dart";

void main() {
  group("resolveMyRecordsVisibleStartDate", () {
    test("uses the earliest restored record when it predates install date", () {
      final DateTime resolved = resolveMyRecordsVisibleStartDate(
        storedInstallDate: DateTime(2026, 3, 14),
        records: <TodayQuestionRecord>[
          TodayQuestionRecord(
            createdAt: DateTime(2026, 1, 8, 9),
            answer: "old record",
            author: "나의 기록",
            questionDateKey: "20260108",
          ),
        ],
      )!;

      expect(resolved, DateTime(2026, 1, 8));
    });

    test("keeps the stored install date when records are newer", () {
      final DateTime resolved = resolveMyRecordsVisibleStartDate(
        storedInstallDate: DateTime(2026, 3, 14),
        records: <TodayQuestionRecord>[
          TodayQuestionRecord(
            createdAt: DateTime(2026, 3, 15, 9),
            answer: "new record",
            author: "나의 기록",
            questionDateKey: "20260315",
          ),
        ],
      )!;

      expect(resolved, DateTime(2026, 3, 14));
    });
  });
}
