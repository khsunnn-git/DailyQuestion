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

  factory ReportAnalyzePayload.fromJson(Map<String, dynamic> json) {
    return ReportAnalyzePayload(
      period: (json["period"] as String?)?.trim() ?? "",
      startDate: (json["start_date"] as String?)?.trim() ?? "",
      endDate: (json["end_date"] as String?)?.trim() ?? "",
      metrics: _mapOfObject(json["metrics"]),
      days: _listOfObjectMaps(json["days"]),
      entriesCompact: _stringListOf(json["entries_compact"]),
      topKeywords: _stringListOf(json["top_keywords"]),
      representativeAnswers: _stringListOf(json["representative_answers"]),
    );
  }

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

  static Map<String, Object?> _mapOfObject(Object? value) {
    if (value is! Map) {
      return const <String, Object?>{};
    }
    return value.map<String, Object?>(
      (Object? key, Object? item) => MapEntry("$key", item),
    );
  }

  static List<Map<String, Object?>> _listOfObjectMaps(Object? value) {
    if (value is! List<dynamic>) {
      return const <Map<String, Object?>>[];
    }
    return value
        .whereType<Map<dynamic, dynamic>>()
        .map(
          (Map<dynamic, dynamic> item) => item.map<String, Object?>(
            (dynamic key, dynamic data) => MapEntry("$key", data),
          ),
        )
        .toList(growable: false);
  }

  static List<String> _stringListOf(Object? value) {
    if (value is! List<dynamic>) {
      return const <String>[];
    }
    return value
        .map((dynamic item) => "$item".trim())
        .where((String item) => item.isNotEmpty)
        .toList(growable: false);
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

  factory WeeklyAggregationSnapshot.fromJson(Map<String, dynamic> json) {
    return WeeklyAggregationSnapshot(
      payload: ReportAnalyzePayload.fromJson(
        (json["payload"] as Map<String, dynamic>?) ?? const <String, dynamic>{},
      ),
      weeklyScore: _asInt(json["weekly_score"]) ?? 0,
      averageMood: _asDouble(json["average_mood"]),
      averageEnergy: _asDouble(json["average_energy"]),
      averageStress: _asDouble(json["average_stress"]),
      recordedDays: _asInt(json["recorded_days"]) ?? 0,
      targetDays: _asInt(json["target_days"]) ?? 7,
      topKeywords: ReportAnalyzePayload._stringListOf(json["top_keywords"]),
      trendDelta: _asDouble(json["trend_delta"]),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      "payload": payload.toJson(),
      "weekly_score": weeklyScore,
      "average_mood": averageMood,
      "average_energy": averageEnergy,
      "average_stress": averageStress,
      "recorded_days": recordedDays,
      "target_days": targetDays,
      "top_keywords": topKeywords,
      "trend_delta": trendDelta,
    };
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

  static double _asDouble(Object? value) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
  }
}
