import "package:dailyquestion/features/report/ai_report_timeline.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  test(
    "monthly timeline starts from first recorded month and disables future months",
    () {
      final options = buildMonthlyAiReportTimelineOptions(
        year: 2026,
        firstRecordDate: DateTime(2026, 3, 10),
        now: DateTime(2026, 4, 30, 9),
      );

      expect(options.first.label, "3월");
      expect(options.first.enabled, isTrue);
      expect(options[1].label, "4월");
      expect(options[1].enabled, isTrue);
      expect(options[2].label, "5월");
      expect(options[2].enabled, isFalse);
    },
  );

  test(
    "monthly timeline keeps the current month disabled before 8am close",
    () {
      final options = buildMonthlyAiReportTimelineOptions(
        year: 2026,
        firstRecordDate: DateTime(2026, 3, 10),
        now: DateTime.utc(2026, 4, 29, 22, 59),
      );

      expect(options[0].label, "3월");
      expect(options[0].enabled, isTrue);
      expect(options[1].label, "4월");
      expect(options[1].enabled, isFalse);
    },
  );

  test(
    "quarterly timeline enables only closed quarters with recorded range",
    () {
      final options = buildQuarterlyAiReportTimelineOptions(
        year: 2026,
        firstRecordDate: DateTime(2026, 3, 10),
        now: DateTime(2026, 4, 30, 9),
      );

      expect(options[0].label, "1분기");
      expect(options[0].enabled, isTrue);
      expect(options[1].label, "2분기");
      expect(options[1].enabled, isFalse);
    },
  );

  test("yearly timeline is enabled only after the year closes", () {
    final beforeYearClose = buildYearlyAiReportTimelineOption(
      year: 2026,
      now: DateTime(2026, 12, 30, 9),
    );
    final afterYearClose = buildYearlyAiReportTimelineOption(
      year: 2026,
      now: DateTime(2026, 12, 31, 9),
    );

    expect(beforeYearClose.enabled, isFalse);
    expect(afterYearClose.enabled, isTrue);
  });

  test("weekly timeline builds up to five slots in a month", () {
    final options = buildWeeklyAiReportTimelineOptions(
      year: 2026,
      month: 3,
      now: DateTime(2026, 3, 21, 12),
    );

    expect(options.length, 5);
    expect(options.first.label, "1주");
    expect(options.last.label, "5주");
  });

  test("weekly timeline keeps early and late overlapping weeks for april", () {
    final options = buildWeeklyAiReportTimelineOptions(
      year: 2026,
      month: 4,
      now: DateTime(2026, 4, 15, 12),
    );

    expect(options.length, 5);
    expect(options.first.startDate, DateTime(2026, 3, 29));
    expect(options.first.endDate, DateTime(2026, 4, 4));
    expect(options.last.startDate, DateTime(2026, 4, 26));
    expect(options.last.endDate, DateTime(2026, 5, 2));
  });
}
