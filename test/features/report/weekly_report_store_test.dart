import "package:dailyquestion/features/report/report_aggregation_service.dart";
import "package:dailyquestion/features/report/report_api_client.dart";
import "package:dailyquestion/features/report/report_models.dart";
import "package:dailyquestion/features/report/weekly_report_schedule.dart";
import "package:dailyquestion/features/report/weekly_report_store.dart";
import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test("refreshes cached weekly report when snapshot data changes", () async {
    final _FakeReportAggregationService aggregationService =
        _FakeReportAggregationService(recordedDays: 0);
    final WeeklyReportStore store = WeeklyReportStore(
      aggregationService: aggregationService,
      apiClient: ReportApiClient(baseUrl: ""),
    );

    await store.prepareCurrentWeeklyReport(forceRefresh: true);
    expect(store.value.snapshot?.recordedDays, 0);

    aggregationService.recordedDays = 4;
    await store.prepareCurrentWeeklyReport();

    expect(store.value.snapshot?.recordedDays, 4);
    expect(store.value.report?.summary, "days 4");
  });
}

class _FakeReportAggregationService extends ReportAggregationService {
  _FakeReportAggregationService({required this.recordedDays});

  int recordedDays;

  @override
  Future<WeeklyAggregationSnapshot> buildWeeklySnapshot({
    DateTime? referenceDate,
  }) async {
    final WeeklyReportWindow window = currentWeeklyReportWindow();
    return WeeklyAggregationSnapshot(
      payload: ReportAnalyzePayload(
        period: "weekly",
        startDate: window.startDate.toIso8601String(),
        endDate: window.endDate.toIso8601String(),
        metrics: <String, Object?>{"recorded_days": recordedDays},
        days: List<Map<String, Object?>>.generate(
          7,
          (int index) => <String, Object?>{
            "date_key": "2026030${index + 1}",
            "answer": index < recordedDays ? "answer ${index + 1}" : null,
          },
          growable: false,
        ),
        entriesCompact: List<String>.generate(
          recordedDays,
          (int index) => "entry ${index + 1}",
          growable: false,
        ),
        topKeywords: const <String>[],
        representativeAnswers: List<String>.generate(
          recordedDays,
          (int index) => "answer ${index + 1}",
          growable: false,
        ),
      ),
      weeklyScore: recordedDays,
      averageMood: 0,
      averageEnergy: 0,
      averageStress: 0,
      recordedDays: recordedDays,
      targetDays: 7,
      topKeywords: const <String>[],
      trendDelta: 0,
    );
  }

  @override
  WeeklyAiReport buildCompactLocalFallbackReport(
    WeeklyAggregationSnapshot snapshot,
  ) {
    return _report(snapshot);
  }

  @override
  WeeklyAiReport buildLocalFallbackReport(WeeklyAggregationSnapshot snapshot) {
    return _report(snapshot);
  }

  WeeklyAiReport _report(WeeklyAggregationSnapshot snapshot) {
    return WeeklyAiReport(
      summary: "days ${snapshot.recordedDays}",
      insights: const <String>[],
      actions: const <String>[],
      weeklyScore: snapshot.weeklyScore,
      source: "test",
    );
  }
}
