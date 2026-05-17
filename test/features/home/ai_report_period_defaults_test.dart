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

  test("month stays weekly until the last day 8am", () {
    expect(
      isAiReportMonthClosed(
        year: 2026,
        month: 3,
        now: DateTime(2026, 3, 31, 7, 59),
      ),
      isFalse,
    );
    expect(
      shouldDefaultAiReportToMonthly(
        year: 2026,
        month: 3,
        now: DateTime(2026, 3, 31, 7, 59),
      ),
      isFalse,
    );
  });

  test("month defaults to monthly from the last day 8am", () {
    expect(
      isAiReportMonthClosed(
        year: 2026,
        month: 3,
        now: DateTime(2026, 3, 31, 8),
      ),
      isTrue,
    );
    expect(
      shouldDefaultAiReportToMonthly(
        year: 2026,
        month: 3,
        now: DateTime(2026, 3, 31, 8),
      ),
      isTrue,
    );
  });
}
