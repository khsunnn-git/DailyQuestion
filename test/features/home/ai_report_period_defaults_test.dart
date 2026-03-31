import "package:flutter_test/flutter_test.dart";

import "package:dailyquestion/features/home/ai_report_period_defaults.dart";

void main() {
  test("month is not closed before the last day", () {
    expect(
      isAiReportMonthClosed(
        year: 2026,
        month: 3,
        now: DateTime(2026, 3, 30, 23, 59),
      ),
      isFalse,
    );
    expect(
      shouldDefaultAiReportToMonthly(
        year: 2026,
        month: 3,
        now: DateTime(2026, 3, 30, 23, 59),
      ),
      isFalse,
    );
  });

  test("month defaults to monthly on the last day", () {
    expect(
      isAiReportMonthClosed(
        year: 2026,
        month: 3,
        now: DateTime(2026, 3, 31, 0, 0),
      ),
      isTrue,
    );
    expect(
      shouldDefaultAiReportToMonthly(
        year: 2026,
        month: 3,
        now: DateTime(2026, 3, 31, 0, 0),
      ),
      isTrue,
    );
  });
}
