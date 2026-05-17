import "package:dailyquestion/features/report/period_report_aggregation_service.dart";
import "package:dailyquestion/features/report/report_models.dart";
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

  test("builds local fallback report for monthly period payload", () {
    const PeriodReportAggregationService service =
        PeriodReportAggregationService();
    final WeeklyAiReport report = service.buildLocalFallbackReport(
      payload: const ReportAnalyzePayload(
        period: "monthly",
        startDate: "2026-03-01",
        endDate: "2026-03-31",
        metrics: <String, Object?>{
          "overall_score": 4,
          "avg_mood": 3.8,
          "avg_energy": 3.2,
          "avg_stress": 2.4,
          "recorded_days": 18,
          "target_days": 31,
        },
        days: <Map<String, Object?>>[
          <String, Object?>{
            "date_key": "20260305",
            "day_score": 4,
            "answer": "산책을 하니 조금 안정됐다",
            "keywords": <String>["산책", "휴식"],
          },
          <String, Object?>{
            "date_key": "20260312",
            "day_score": 2,
            "answer": "업무가 몰려서 피곤했다",
            "keywords": <String>["업무", "피로"],
          },
        ],
        entriesCompact: <String>[],
        topKeywords: <String>["산책", "휴식", "업무"],
        representativeAnswers: <String>["산책을 하니 조금 안정됐다"],
      ),
      period: ReportPeriod.monthly,
      year: 2026,
      month: 3,
    );

    expect(report.source, "local-fallback");
    expect(report.summary, contains("3월"));
    expect(report.insights, hasLength(3));
    expect(report.actions, isNotEmpty);
  });

  test("builds local fallback report even when payload is sparse", () {
    const PeriodReportAggregationService service =
        PeriodReportAggregationService();
    final WeeklyAiReport report = service.buildLocalFallbackReport(
      payload: const ReportAnalyzePayload(
        period: "yearly",
        startDate: "2026-01-01",
        endDate: "2026-12-31",
        metrics: <String, Object?>{
          "overall_score": 0,
          "recorded_days": 0,
          "target_days": 365,
        },
        days: <Map<String, Object?>>[],
        entriesCompact: <String>[],
        topKeywords: <String>[],
        representativeAnswers: <String>[],
      ),
      period: ReportPeriod.yearly,
      year: 2026,
      month: 12,
    );

    expect(report.source, "local-fallback");
    expect(report.summary, contains("2026년"));
    expect(report.insights, isNotEmpty);
    expect(report.actions, isNotEmpty);
  });
}
