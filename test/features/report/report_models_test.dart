import "package:dailyquestion/features/report/report_models.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  test("isOpenAiReportSource only returns true for real ai source", () {
    expect(isOpenAiReportSource("ai"), isTrue);
    expect(isOpenAiReportSource(" AI "), isTrue);
    expect(isOpenAiReportSource("server-fallback"), isFalse);
    expect(isOpenAiReportSource("local-fallback"), isFalse);
    expect(isOpenAiReportSource("test"), isFalse);
    expect(isOpenAiReportSource(null), isFalse);
    expect(isOpenAiReportSource(""), isFalse);
  });

  test("WeeklyAiReport.isFromOpenAi follows normalized source", () {
    expect(
      const WeeklyAiReport(
        summary: "summary",
        insights: <String>[],
        actions: <String>[],
        weeklyScore: 4,
        source: "ai",
      ).isFromOpenAi,
      isTrue,
    );
    expect(
      const WeeklyAiReport(
        summary: "summary",
        insights: <String>[],
        actions: <String>[],
        weeklyScore: 4,
        source: "server-fallback",
      ).isFromOpenAi,
      isFalse,
    );
  });

  test("WeeklyAggregationSnapshot.fromJson reads legacy score keys", () {
    final WeeklyAggregationSnapshot snapshot =
        WeeklyAggregationSnapshot.fromJson(<String, dynamic>{
          "payload": <String, dynamic>{
            "period": "weekly",
            "start_date": "2026-03-08",
            "end_date": "2026-03-14",
            "metrics": <String, Object?>{
              "overall_score": 4,
              "avg_mood": 4.2,
              "avg_energy": 3.6,
              "avg_stress": 2.4,
              "recorded_days": 4,
              "target_days": 7,
              "trend_delta": 0.3,
            },
            "days": const <Map<String, Object?>>[
              <String, Object?>{
                "date_key": "20260308",
                "mood_score": 4,
                "energy_score": 4,
                "stress_score": 2,
              },
            ],
            "entries_compact": const <String>[],
            "top_keywords": const <String>["산책"],
            "representative_answers": const <String>[],
          },
        });

    expect(snapshot.weeklyScore, 4);
    expect(snapshot.averageMood, 4.2);
    expect(snapshot.averageEnergy, 3.6);
    expect(snapshot.averageStress, 2.4);
    expect(snapshot.recordedDays, 4);
    expect(snapshot.targetDays, 7);
    expect(snapshot.trendDelta, 0.3);
    expect(snapshot.topKeywords, const <String>["산책"]);
    expect(snapshot.hasCheckinData, isTrue);
  });
}
