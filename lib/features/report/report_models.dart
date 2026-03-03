class ReportAnalyzePayload {
  const ReportAnalyzePayload({
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.metrics,
    required this.days,
    required this.entriesCompact,
    required this.topKeywords,
    required this.representativeAnswers,
  });

  final String period;
  final String startDate;
  final String endDate;
  final Map<String, Object?> metrics;
  final List<Map<String, Object?>> days;
  final List<String> entriesCompact;
  final List<String> topKeywords;
  final List<String> representativeAnswers;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      "period": period,
      "start_date": startDate,
      "end_date": endDate,
      "metrics": metrics,
      "days": days,
      "entries_compact": entriesCompact,
      "top_keywords": topKeywords,
      "representative_answers": representativeAnswers,
    };
  }
}

class WeeklyAiReport {
  const WeeklyAiReport({
    required this.summary,
    required this.insights,
    required this.actions,
    required this.weeklyScore,
    this.monthlyScore,
    this.source = "ai",
  });

  final String summary;
  final List<String> insights;
  final List<String> actions;
  final int weeklyScore;
  final int? monthlyScore;
  final String source;

  factory WeeklyAiReport.fromJson(Map<String, dynamic> json) {
    return WeeklyAiReport(
      summary: (json["summary"] as String?)?.trim().isNotEmpty == true
          ? (json["summary"] as String).trim()
          : "이번 주 기록을 바탕으로 리포트를 생성했어요.",
      insights: _stringListOf(json["insights"]),
      actions: _stringListOf(json["actions"]),
      weeklyScore: _asInt(json["weekly_score"]) ?? 0,
      monthlyScore: _asInt(json["monthly_score"]),
      source: (json["source"] as String?)?.trim().isNotEmpty == true
          ? (json["source"] as String).trim()
          : "ai",
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      "summary": summary,
      "insights": insights,
      "actions": actions,
      "weekly_score": weeklyScore,
      "monthly_score": monthlyScore,
      "source": source,
    };
  }

  static List<String> _stringListOf(Object? value) {
    if (value is! List<dynamic>) {
      return const <String>[];
    }
    return value
        .whereType<String>()
        .map((String item) => item.trim())
        .where((String item) => item.isNotEmpty)
        .toList(growable: false);
  }

  static int? _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.round();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }
}

class WeeklyAggregationSnapshot {
  const WeeklyAggregationSnapshot({
    required this.payload,
    required this.weeklyScore,
    required this.averageMood,
    required this.averageEnergy,
    required this.averageStress,
    required this.recordedDays,
    required this.targetDays,
    required this.topKeywords,
    required this.trendDelta,
  });

  final ReportAnalyzePayload payload;
  final int weeklyScore;
  final double averageMood;
  final double averageEnergy;
  final double averageStress;
  final int recordedDays;
  final int targetDays;
  final List<String> topKeywords;
  final double trendDelta;
}
