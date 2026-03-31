import "package:dailyquestion/features/report/period_report_aggregation_service.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  test("monthly period uses the full selected month", () {
    final ({DateTime startDate, DateTime endDate, String periodKey}) window =
        resolveSelectedPeriodReportWindow(
          period: ReportPeriod.monthly,
          year: 2026,
          month: 3,
        );

    expect(window.periodKey, "monthly");
    expect(window.startDate, DateTime(2026, 3, 1));
    expect(window.endDate, DateTime(2026, 3, 31));
  });

  test("quarterly period uses the selected quarter boundary", () {
    final ({DateTime startDate, DateTime endDate, String periodKey}) window =
        resolveSelectedPeriodReportWindow(
          period: ReportPeriod.quarterly,
          year: 2026,
          month: 5,
        );

    expect(window.periodKey, "quarterly");
    expect(window.startDate, DateTime(2026, 4, 1));
    expect(window.endDate, DateTime(2026, 6, 30));
  });

  test("yearly period uses the full selected year", () {
    final ({DateTime startDate, DateTime endDate, String periodKey}) window =
        resolveSelectedPeriodReportWindow(
          period: ReportPeriod.yearly,
          year: 2026,
          month: 12,
        );

    expect(window.periodKey, "yearly");
    expect(window.startDate, DateTime(2026, 1, 1));
    expect(window.endDate, DateTime(2026, 12, 31));
  });
}
