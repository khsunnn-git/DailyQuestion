import "package:dailyquestion/features/report/report_aggregation_service.dart";
import "package:dailyquestion/features/report/report_models.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  const ReportAggregationService service = ReportAggregationService();

  test(
    "buildLocalFallbackReport uses concrete summary and grounded actions",
    () {
      final WeeklyAggregationSnapshot snapshot = _snapshot(
        recordedDays: 4,
        weeklyScore: 4,
        averageMood: 4.2,
        averageEnergy: 3.8,
        averageStress: 2.1,
        trendDelta: 0.4,
        topKeywords: const <String>["산책", "휴식", "친구"],
        days: const <Map<String, Object?>>[
          <String, Object?>{
            "date_key": "20260308",
            "mood_score": 4,
            "energy_score": 4,
            "stress_score": 2,
            "day_score": 4,
            "answer": "산책하고 나니 마음이 가벼웠다.",
          },
          <String, Object?>{
            "date_key": "20260309",
            "mood_score": 5,
            "energy_score": 4,
            "stress_score": 2,
            "day_score": 4,
            "answer": "친구와 대화하며 안심이 됐다.",
          },
          <String, Object?>{
            "date_key": "20260310",
            "mood_score": 2,
            "energy_score": 2,
            "stress_score": 5,
            "day_score": 2,
            "answer": "해야 할 일이 많아 부담이 컸다.",
          },
          <String, Object?>{
            "date_key": "20260311",
            "mood_score": 4,
            "energy_score": 5,
            "stress_score": 2,
            "day_score": 4,
            "answer": "휴식을 취하니 다시 의욕이 생겼다.",
          },
        ],
      );

      final WeeklyAiReport report = service.buildLocalFallbackReport(snapshot);

      expect(report.summary, isNot(contains("좋았던 순간과 힘들었던 순간")));
      expect(report.insights.join(" "), isNot(contains("긍정 신호")));
      expect(report.insights.join(" "), isNot(contains("부담 신호")));
      expect(
        report.insights.first,
        "기분 평균 4.2점, 에너지 평균 3.8점, 스트레스 평균 2.1점입니다.",
      );
      expect(report.insights, contains("이번 한 주 일요일에 컨디션이 좋았고, 산책을 자주 언급하셨어요."));
      expect(report.insights, contains("화요일은 상대적으로 컨디션이 저조했어요."));
      expect(report.insights, contains("최근 자주 나온 키워드는 산책, 휴식, 친구 입니다."));
      expect(report.actions.first, contains("산책"));
      expect(report.actions.join(" "), isNot(contains("독서")));
      expect(report.actions.join(" "), isNot(contains("날이 느껴지는 날")));
      expect(
        report.actions.every((String item) => !item.startsWith("다음 주 미션")),
        isTrue,
      );
      expect(report.actions.join(" "), isNot(contains("퇴근")));
    },
  );

  test(
    "buildCompactLocalFallbackReport still explains emotional direction",
    () {
      final WeeklyAggregationSnapshot snapshot = _snapshot(
        recordedDays: 2,
        weeklyScore: 3,
        averageMood: 3.0,
        averageEnergy: 2.5,
        averageStress: 3.5,
        trendDelta: -0.2,
        topKeywords: const <String>["일", "휴식"],
        days: const <Map<String, Object?>>[
          <String, Object?>{
            "date_key": "20260308",
            "mood_score": 3,
            "energy_score": 3,
            "stress_score": 3,
            "day_score": 3,
            "answer": "일이 많아서 쉬고 싶었다.",
          },
          <String, Object?>{
            "date_key": "20260309",
            "mood_score": 2,
            "energy_score": 2,
            "stress_score": 4,
            "day_score": 2,
            "answer": "몸이 조금 지쳐 있었다.",
          },
        ],
      );

      final WeeklyAiReport report = service.buildCompactLocalFallbackReport(
        snapshot,
      );

      expect(report.emotionSummary, contains("조금만 더 기록이 쌓이면"));
      expect(report.emotionSummary, isNotEmpty);
      expect(report.actions.first, contains("쉬"));
      expect(report.actions.first, isNot(contains("다음 주 미션")));
    },
  );

  test("buildLocalFallbackReport treats missing checkins as unscored data", () {
    final WeeklyAggregationSnapshot snapshot = _snapshot(
      recordedDays: 4,
      weeklyScore: 0,
      averageMood: 0,
      averageEnergy: 0,
      averageStress: 0,
      trendDelta: 0,
      topKeywords: const <String>["산책", "휴식"],
      days: const <Map<String, Object?>>[
        <String, Object?>{
          "date_key": "20260308",
          "day_score": null,
          "answer": "산책하고 나니 마음이 조금 가벼웠다.",
        },
        <String, Object?>{
          "date_key": "20260309",
          "day_score": null,
          "answer": "집에서 쉬니 한결 편안했다.",
        },
      ],
    );

    final WeeklyAiReport report = service.buildLocalFallbackReport(snapshot);

    expect(report.summary, isNot(contains("0/5점")));
    expect(report.summary, contains("체크인 데이터가 아직 부족"));
    expect(report.insights.first, contains("평균 점수는 집계되지 않았어요"));
    expect(report.insights, contains("이번 한 주에는 산책을 자주 언급하셨어요."));
    expect(report.insights, contains("최근 자주 나온 키워드는 산책, 휴식 입니다."));
  });

  test("buildLocalFallbackReport can include community recovery idea", () {
    final WeeklyAggregationSnapshot snapshot = _snapshot(
      recordedDays: 4,
      weeklyScore: 4,
      averageMood: 3.8,
      averageEnergy: 3.4,
      averageStress: 2.7,
      trendDelta: 0.2,
      topKeywords: const <String>["회사"],
      communityRecoveryIdeas: const <String>[
        "다음 주 미션: 최근 공개답변에서는 음악 듣기로 기분을 환기한 이야기도 보였어요. 마음이 답답한 날 한 번 가볍게 시도해보세요.",
      ],
      days: const <Map<String, Object?>>[
        <String, Object?>{
          "date_key": "20260308",
          "mood_score": 4,
          "energy_score": 4,
          "stress_score": 2,
          "day_score": 4,
          "answer": "회사 생각이 많았지만 금방 지나갔다.",
        },
      ],
    );

    final WeeklyAiReport report = service.buildLocalFallbackReport(snapshot);

    expect(
      report.actions.any((String item) => item.contains("최근 공개글")),
      isTrue,
    );
    expect(
      report.actions.every((String item) => !item.startsWith("다음 주 미션")),
      isTrue,
    );
  });

  test("stable week highlights bucket achievement and varied actions", () {
    final WeeklyAggregationSnapshot snapshot = _snapshot(
      recordedDays: 5,
      weeklyScore: 4,
      averageMood: 3.8,
      averageEnergy: 3.4,
      averageStress: 3.2,
      trendDelta: 0.0,
      topKeywords: const <String>["집", "파란색", "커피"],
      representativeAnswers: const <String>["집에서 파란색 컵으로 커피를 마시면 차분해진다."],
      dueBucketCount: 1,
      completedDueBucketCount: 1,
      days: const <Map<String, Object?>>[
        <String, Object?>{
          "date_key": "20260308",
          "mood_score": 4,
          "energy_score": 3,
          "stress_score": 3,
          "day_score": 4,
          "answer": "집에서 파란색 컵으로 커피를 마셨다.",
        },
      ],
    );

    final WeeklyAiReport report = service.buildLocalFallbackReport(snapshot);

    expect(report.summary, contains("완료 예정이었던 버킷리스트 1개도 잘 마무리했어요"));
    expect(report.summary, contains("작은 성취가 꾸준히 쌓이고 있어요"));
    expect(report.insights.first, contains("평균적으로 안정적인 흐름"));
    expect(report.insights.join(" "), contains("요즘 '집'을 자주 떠올리셨어요"));
    expect(report.actions, hasLength(3));
    expect(report.actions[0], contains("집에서 10분만"));
    expect(report.actions[1], contains("파란색 계열"));
    expect(report.actions[2], contains("좋아하는 음료"));
  });

  test("weekly report expands personal media and sports cues into actions", () {
    final WeeklyAggregationSnapshot snapshot = _snapshot(
      recordedDays: 5,
      weeklyScore: 3,
      averageMood: 2.6,
      averageEnergy: 2.4,
      averageStress: 4.0,
      trendDelta: -0.3,
      topKeywords: const <String>["드라마", "야구", "휴식"],
      representativeAnswers: const <String>[
        "피곤한 날에는 드라마를 한 편 보면 마음이 풀렸다.",
        "야구 보는 시간이 생각보다 큰 힘이 됐다.",
      ],
      days: const <Map<String, Object?>>[
        <String, Object?>{
          "date_key": "20260310",
          "mood_score": 2,
          "energy_score": 2,
          "stress_score": 5,
          "day_score": 2,
          "answer": "너무 지쳐서 드라마 한 편만 보고 쉬었다.",
        },
        <String, Object?>{
          "date_key": "20260311",
          "mood_score": 4,
          "energy_score": 3,
          "stress_score": 3,
          "day_score": 4,
          "answer": "야구 하이라이트를 보니 기분이 조금 나아졌다.",
        },
      ],
    );

    final WeeklyAiReport report = service.buildLocalFallbackReport(snapshot);
    final String joinedInsights = report.insights.join(" ");
    final String joinedActions = report.actions.join(" ");

    expect(joinedInsights, contains("드라마 한 편"));
    expect(joinedInsights, contains("다음 에피소드"));
    expect(joinedActions, contains("다음 에피소드"));
    expect(joinedActions, contains("야구"));
    expect(joinedActions, contains("경기 관람"));
    expect(joinedActions, isNot(contains("안부")));
  });

  test("tuneWeeklyReport keeps OpenAI insights and actions when present", () {
    final WeeklyAggregationSnapshot snapshot = _snapshot(
      recordedDays: 5,
      weeklyScore: 3,
      averageMood: 2.6,
      averageEnergy: 2.4,
      averageStress: 4.0,
      trendDelta: -0.3,
      topKeywords: const <String>["드라마"],
      days: const <Map<String, Object?>>[
        <String, Object?>{
          "date_key": "20260310",
          "mood_score": 2,
          "energy_score": 2,
          "stress_score": 5,
          "day_score": 2,
          "answer": "드라마를 보고 쉬었다.",
        },
      ],
    );
    const WeeklyAiReport aiReport = WeeklyAiReport(
      summary: "ai summary",
      emotionSummary: "ai emotion",
      insights: <String>["AI가 답변 속 드라마 패턴을 직접 해석한 인사이트"],
      actions: <String>["다음 에피소드를 정해두고 쉬는 시간을 만들어보세요."],
      weeklyScore: 3,
      source: "ai",
    );

    final WeeklyAiReport tuned = service.tuneWeeklyReport(
      report: aiReport,
      snapshot: snapshot,
    );

    expect(tuned.insights, aiReport.insights);
    expect(tuned.actions, aiReport.actions);
  });
}

WeeklyAggregationSnapshot _snapshot({
  required int recordedDays,
  required int weeklyScore,
  required double averageMood,
  required double averageEnergy,
  required double averageStress,
  required double trendDelta,
  required List<String> topKeywords,
  required List<Map<String, Object?>> days,
  List<String> communityRecoveryIdeas = const <String>[],
  List<String> representativeAnswers = const <String>[],
  int dueBucketCount = 0,
  int completedDueBucketCount = 0,
}) {
  return WeeklyAggregationSnapshot(
    payload: ReportAnalyzePayload(
      period: "weekly",
      startDate: "2026-03-08",
      endDate: "2026-03-14",
      metrics: <String, Object?>{"recorded_days": recordedDays},
      days: days,
      entriesCompact: const <String>[],
      topKeywords: topKeywords,
      representativeAnswers: representativeAnswers,
      communityRecoveryIdeas: communityRecoveryIdeas,
    ),
    weeklyScore: weeklyScore,
    averageMood: averageMood,
    averageEnergy: averageEnergy,
    averageStress: averageStress,
    recordedDays: recordedDays,
    targetDays: 7,
    topKeywords: topKeywords,
    trendDelta: trendDelta,
    dueBucketCount: dueBucketCount,
    completedDueBucketCount: completedDueBucketCount,
  );
}
