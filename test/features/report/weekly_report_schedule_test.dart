import "package:dailyquestion/features/report/weekly_report_schedule.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  group("currentWeeklyReportWindow", () {
    test("keeps previous slot before Sunday 8am KST", () {
      final WeeklyReportWindow window = currentWeeklyReportWindow(
        now: DateTime.utc(2026, 3, 14, 22, 59),
      );

      expect(window.slotAnchor, DateTime(2026, 3, 8, 8));
      expect(window.startDate, DateTime(2026, 3, 1));
      expect(window.endDate, DateTime(2026, 3, 7));
      expect(window.summaryTitle, "03.01 - 03.07 요약");
    });

    test("switches to new slot from Sunday 8am KST", () {
      final WeeklyReportWindow window = currentWeeklyReportWindow(
        now: DateTime.utc(2026, 3, 14, 23, 1),
      );

      expect(window.slotAnchor, DateTime(2026, 3, 15, 8));
      expect(window.startDate, DateTime(2026, 3, 8));
      expect(window.endDate, DateTime(2026, 3, 14));
      expect(window.summaryTitle, "03.08 - 03.14 요약");
    });
  });

  test("resolves a weekly window from an arbitrary recorded date", () {
    final WeeklyReportWindow window = weeklyReportWindowForDate(
      DateTime(2026, 4, 22),
    );

    expect(window.slotAnchor, DateTime(2026, 4, 26, 8));
    expect(window.startDate, DateTime(2026, 4, 19));
    expect(window.endDate, DateTime(2026, 4, 25));
  });

  test("limits monthly weekly windows to five slots", () {
    final List<WeeklyReportWindow> windows = weeklyReportWindowsForMonth(
      year: 2021,
      month: 5,
    );

    expect(windows.length, 5);
    expect(windows.first.startDate, DateTime(2021, 4, 25));
    expect(windows.last.startDate, DateTime(2021, 5, 23));
    expect(windows.last.endDate, DateTime(2021, 5, 29));
  });
}
