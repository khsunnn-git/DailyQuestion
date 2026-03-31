bool isOpenAiReportSource(String? source) {
  return source?.trim().toLowerCase() == "ai";
}

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
    this.communityRecoveryIdeas = const <String>[],
  });

  final String period;
  final String startDate;
  final String endDate;
  final Map<String, Object?> metrics;
  final List<Map<String, Object?>> days;
  final List<String> entriesCompact;
  final List<String> topKeywords;
  final List<String> representativeAnswers;
  final List<String> communityRecoveryIdeas;

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
      communityRecoveryIdeas: _stringListOf(json["community_recovery_ideas"]),
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
      "community_recovery_ideas": communityRecoveryIdeas,
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
    this.emotionSummary = "",
    required this.insights,
    required this.actions,
    required this.weeklyScore,
    this.monthlyScore,
    this.source = "ai",
  });

  final String summary;
  final String emotionSummary;
  final List<String> insights;
  final List<String> actions;
  final int weeklyScore;
  final int? monthlyScore;
  final String source;

  bool get isFromOpenAi => isOpenAiReportSource(source);

  factory WeeklyAiReport.fromJson(Map<String, dynamic> json) {
    final String normalizedSummary = _normalizeSummaryText(
      (json["summary"] as String?)?.trim() ?? "",
    );
    return WeeklyAiReport(
      summary: normalizedSummary.isNotEmpty
          ? normalizedSummary
          : "이번 주 기록을 바탕으로 리포트를 생성했어요.",
      emotionSummary: (json["emotion_summary"] as String?)?.trim() ?? "",
      insights: _normalizedInsights(json["insights"]),
      actions: _normalizedActions(json["actions"]),
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
      "emotion_summary": emotionSummary,
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

  static List<String> _normalizedInsights(Object? value) {
    return _stringListOf(
      value,
    ).map(_normalizeInsightText).whereType<String>().toList(growable: false);
  }

  static List<String> _normalizedActions(Object? value) {
    return _stringListOf(
      value,
    ).map(_normalizeActionText).whereType<String>().toList(growable: false);
  }

  static String _normalizeSummaryText(String value) {
    String normalized = value.trim();
    if (normalized.isEmpty) {
      return normalized;
    }
    normalized = normalized.replaceAll(
      "좋았던 순간과 힘들었던 순간이 분명하게 구분되는 한 주였습니다.",
      "",
    );
    normalized = normalized.replaceAll(RegExp(r"\s+"), " ").trim();
    return normalized;
  }

  static String? _normalizeInsightText(String value) {
    final String normalized = value.trim();
    if (normalized.isEmpty) {
      return null;
    }
    const List<String> blockedFragments = <String>[
      "긍정 신호",
      "부담 신호",
      "최고 컨디션 데이터",
      "저점 데이터",
    ];
    for (final String fragment in blockedFragments) {
      if (normalized.contains(fragment)) {
        return null;
      }
    }
    return normalized;
  }

  static String? _normalizeActionText(String value) {
    String normalized = value.trim();
    if (normalized.isEmpty) {
      return null;
    }
    normalized = normalized.replaceFirst(
      RegExp(r"^(다음\s*주\s*미션|다음\s*주\s*액션|다음\s*액션)\s*[:：-]?\s*"),
      "",
    );
    normalized = normalized.trim();
    return normalized.isEmpty ? null : normalized;
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
    this.dueBucketCount = 0,
    this.completedDueBucketCount = 0,
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
  final int dueBucketCount;
  final int completedDueBucketCount;

  bool get hasCheckinData =>
      averageMood > 0 ||
      averageEnergy > 0 ||
      averageStress > 0 ||
      payload.days.any(
        (Map<String, Object?> day) =>
            day["mood_score"] != null ||
            day["energy_score"] != null ||
            day["stress_score"] != null,
      );

  factory WeeklyAggregationSnapshot.fromJson(Map<String, dynamic> json) {
    final ReportAnalyzePayload payload = ReportAnalyzePayload.fromJson(
      (json["payload"] as Map<String, dynamic>?) ?? const <String, dynamic>{},
    );
    Object? pickFirst(List<Object?> values) {
      for (final Object? value in values) {
        if (value != null) {
          return value;
        }
      }
      return null;
    }

    final List<String> decodedTopKeywords = ReportAnalyzePayload._stringListOf(
      json["top_keywords"],
    );
    return WeeklyAggregationSnapshot(
      payload: payload,
      weeklyScore:
          _asInt(
            pickFirst(<Object?>[
              json["weekly_score"],
              json["overall_score"],
              payload.metrics["weekly_score"],
              payload.metrics["overall_score"],
            ]),
          ) ??
          0,
      averageMood: _asDouble(
        pickFirst(<Object?>[
          json["average_mood"],
          json["avg_mood"],
          payload.metrics["average_mood"],
          payload.metrics["avg_mood"],
        ]),
      ),
      averageEnergy: _asDouble(
        pickFirst(<Object?>[
          json["average_energy"],
          json["avg_energy"],
          payload.metrics["average_energy"],
          payload.metrics["avg_energy"],
        ]),
      ),
      averageStress: _asDouble(
        pickFirst(<Object?>[
          json["average_stress"],
          json["avg_stress"],
          payload.metrics["average_stress"],
          payload.metrics["avg_stress"],
        ]),
      ),
      recordedDays:
          _asInt(
            pickFirst(<Object?>[
              json["recorded_days"],
              payload.metrics["recorded_days"],
            ]),
          ) ??
          0,
      targetDays:
          _asInt(
            pickFirst(<Object?>[
              json["target_days"],
              payload.metrics["target_days"],
            ]),
          ) ??
          7,
      topKeywords: decodedTopKeywords.isNotEmpty
          ? decodedTopKeywords
          : payload.topKeywords,
      trendDelta: _asDouble(
        pickFirst(<Object?>[
          json["trend_delta"],
          payload.metrics["trend_delta"],
        ]),
      ),
      dueBucketCount:
          _asInt(
            pickFirst(<Object?>[
              json["due_bucket_count"],
              payload.metrics["due_bucket_count"],
            ]),
          ) ??
          0,
      completedDueBucketCount:
          _asInt(
            pickFirst(<Object?>[
              json["completed_due_bucket_count"],
              payload.metrics["completed_due_bucket_count"],
            ]),
          ) ??
          0,
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
      "due_bucket_count": dueBucketCount,
      "completed_due_bucket_count": completedDueBucketCount,
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
