import "package:dailyquestion/features/report/ai_report_cache_store.dart";
import "package:dailyquestion/features/report/report_models.dart";
import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test("persists and restores cached ai reports", () async {
    const AiReportCacheStore store = AiReportCacheStore();
    final CachedAiReportEntry entry = CachedAiReportEntry(
      cacheKey: "weekly-20260322",
      periodKey: "weekly",
      generatedAt: DateTime(2026, 3, 22, 8),
      startDate: DateTime(2026, 3, 15),
      endDate: DateTime(2026, 3, 21),
      payload: const ReportAnalyzePayload(
        period: "weekly",
        startDate: "2026-03-15",
        endDate: "2026-03-21",
        metrics: <String, Object?>{"recorded_days": 4},
        days: <Map<String, Object?>>[],
        entriesCompact: <String>[],
        topKeywords: <String>["산책"],
        representativeAnswers: <String>[],
      ),
      report: const WeeklyAiReport(
        summary: "주간 요약",
        insights: <String>["인사이트"],
        actions: <String>["액션"],
        weeklyScore: 4,
        source: "ai",
      ),
    );

    await store.upsert(entry);

    final Map<String, CachedAiReportEntry> restored = await store.readAll();
    final CachedAiReportEntry? cached = restored["weekly-20260322"];

    expect(cached, isNotNull);
    expect(cached!.periodKey, "weekly");
    expect(cached.payload.period, "weekly");
    expect(cached.report.summary, "주간 요약");
    expect(cached.report.isFromOpenAi, isTrue);
  });

  test("ignores cached reports that are not from OpenAI", () async {
    const AiReportCacheStore store = AiReportCacheStore();
    final CachedAiReportEntry entry = CachedAiReportEntry(
      cacheKey: "weekly-20260329",
      periodKey: "weekly",
      generatedAt: DateTime(2026, 3, 29, 8),
      startDate: DateTime(2026, 3, 22),
      endDate: DateTime(2026, 3, 28),
      payload: const ReportAnalyzePayload(
        period: "weekly",
        startDate: "2026-03-22",
        endDate: "2026-03-28",
        metrics: <String, Object?>{"recorded_days": 4},
        days: <Map<String, Object?>>[],
        entriesCompact: <String>[],
        topKeywords: <String>["휴식"],
        representativeAnswers: <String>[],
      ),
      report: const WeeklyAiReport(
        summary: "fallback",
        insights: <String>["인사이트"],
        actions: <String>["액션"],
        weeklyScore: 3,
        source: "server-fallback",
      ),
    );

    await store.upsert(entry);

    final Map<String, CachedAiReportEntry> restored = await store.readAll();
    expect(restored, isEmpty);
  });
}
