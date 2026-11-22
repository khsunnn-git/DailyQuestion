import "dart:math";
// ignore_for_file: use_null_aware_elements

import "package:isar_community/isar.dart";

import "../../core/kst_date_time.dart";
import "../../data/local_db/entities/bucket_item_entity.dart";
import "../../data/local_db/entities/daily_checkin_entity.dart";
import "../../data/local_db/local_database.dart";
import "../question/today_question_store.dart";
import "report_models.dart";

enum ReportPeriod { monthly, quarterly, yearly }

({DateTime startDate, DateTime endDate, String periodKey})
resolveSelectedPeriodReportWindow({
  required ReportPeriod period,
  required int year,
  required int month,
}) {
  switch (period) {
    case ReportPeriod.monthly:
      return (
        startDate: DateTime(year, month, 1),
        endDate: DateTime(year, month + 1, 0),
        periodKey: "monthly",
      );
    case ReportPeriod.quarterly:
      final int quarterStartMonth = ((month - 1) ~/ 3) * 3 + 1;
      return (
        startDate: DateTime(year, quarterStartMonth, 1),
        endDate: DateTime(year, quarterStartMonth + 3, 0),
        periodKey: "quarterly",
      );
    case ReportPeriod.yearly:
      return (
        startDate: DateTime(year, 1, 1),
        endDate: DateTime(year + 1, 1, 0),
        periodKey: "yearly",
      );
  }
}

class PeriodReportAggregationService {
  const PeriodReportAggregationService();

  Future<ReportAnalyzePayload> buildPayloadFor(ReportPeriod period) async {
    final DateTime now = nowInKst();
    final DateTime endDate = DateTime(now.year, now.month, now.day);
    final int windowDays = switch (period) {
      ReportPeriod.monthly => 30,
      ReportPeriod.quarterly => 90,
      ReportPeriod.yearly => 365,
    };
    final String periodKey = switch (period) {
      ReportPeriod.monthly => "monthly",
      ReportPeriod.quarterly => "quarterly",
      ReportPeriod.yearly => "yearly",
    };
    final DateTime startDate = endDate.subtract(Duration(days: windowDays - 1));

    return _buildPayload(
      startDate: startDate,
      endDate: endDate,
      periodKey: periodKey,
    );
  }

  Future<ReportAnalyzePayload> buildPayloadForSelection({
    required ReportPeriod period,
    required int year,
    required int month,
  }) async {
    final ({DateTime startDate, DateTime endDate, String periodKey})
    periodWindow = resolveSelectedPeriodReportWindow(
      period: period,
      year: year,
      month: month,
    );

    return _buildPayload(
      startDate: periodWindow.startDate,
      endDate: periodWindow.endDate,
      periodKey: periodWindow.periodKey,
    );
  }

  WeeklyAiReport buildLocalFallbackReport({
    required ReportAnalyzePayload payload,
    required ReportPeriod period,
    required int year,
    required int month,
  }) {
    final int recordedDays = _metricInt(
      payload.metrics["recorded_days"],
      fallback: payload.days.length,
    );
    final int targetDays = _metricInt(
      payload.metrics["target_days"],
      fallback: max(1, payload.days.length),
    );
    final int overallScore = _metricInt(payload.metrics["overall_score"]);
    final double avgMood = _metricDouble(payload.metrics["avg_mood"]);
    final double avgEnergy = _metricDouble(payload.metrics["avg_energy"]);
    final double avgStress = _metricDouble(payload.metrics["avg_stress"]);
    final String focusLabel = _selectedPeriodLabel(
      period: period,
      year: year,
      month: month,
    );
    final String nextLabel = _nextPeriodLabel(period);
    final _PeriodScoreEvidence? bestDay = _pickPeriodDay(
      payload.days,
      pickMax: true,
    );
    final _PeriodScoreEvidence? hardestDay = _pickPeriodDay(
      payload.days,
      pickMax: false,
    );

    return WeeklyAiReport(
      summary: _buildPeriodSummary(
        focusLabel: focusLabel,
        recordedDays: recordedDays,
        targetDays: targetDays,
        avgMood: avgMood,
        avgEnergy: avgEnergy,
        avgStress: avgStress,
      ),
      insights: _buildPeriodInsights(
        focusLabel: focusLabel,
        payload: payload,
        avgMood: avgMood,
        avgEnergy: avgEnergy,
        avgStress: avgStress,
        bestDay: bestDay,
        hardestDay: hardestDay,
      ),
      actions: _buildPeriodActions(
        nextLabel: nextLabel,
        payload: payload,
        avgEnergy: avgEnergy,
        avgStress: avgStress,
        recordedDays: recordedDays,
        targetDays: targetDays,
      ),
      weeklyScore: overallScore,
      monthlyScore: null,
      source: "local-fallback",
    );
  }

  Future<ReportAnalyzePayload> _buildPayload({
    required DateTime startDate,
    required DateTime endDate,
    required String periodKey,
  }) async {
    await TodayQuestionStore.instance.initialize();
    final int windowDays = endDate.difference(startDate).inDays + 1;

    final List<DailyCheckinEntity> checkins = await _loadCheckinsInRange(
      startDate: startDate,
      endDate: endDate,
    );
    final Map<String, DailyCheckinEntity> byDateKey =
        <String, DailyCheckinEntity>{
          for (final DailyCheckinEntity item in checkins) item.dateKey: item,
        };

    final List<TodayQuestionRecord> rangeAnswers = TodayQuestionStore
        .instance
        .value
        .where((TodayQuestionRecord item) {
          final DateTime day = kstDateOnly(item.createdAt);
          return !day.isBefore(startDate) && !day.isAfter(endDate);
        })
        .toList(growable: false);

    final List<int> moodScores = <int>[];
    final List<int> energyScores = <int>[];
    final List<int> stressScores = <int>[];
    final List<int> overallScores = <int>[];
    final Set<String> activeDateKeys = <String>{};
    final List<Map<String, Object?>> days = <Map<String, Object?>>[];
    final List<String> entriesCompact = <String>[];
    final List<String> representativeAnswers = <String>[];

    for (int i = 0; i < windowDays; i++) {
      final DateTime date = startDate.add(Duration(days: i));
      final String dateKey = _yyyymmdd(date);
      final DailyCheckinEntity? checkin = byDateKey[dateKey];
      final TodayQuestionRecord? answer = _latestRecordByDateKey(
        rangeAnswers,
        dateKey,
      );

      final int? mood = _scoreFromIndex(checkin?.moodIndex);
      final int? energy = _scoreFromIndex(checkin?.energyIndex);
      final int? stress = _scoreFromIndex(checkin?.stressIndex);
      if (mood != null) {
        moodScores.add(mood);
      }
      if (energy != null) {
        energyScores.add(energy);
      }
      if (stress != null) {
        stressScores.add(stress);
      }

      final List<int> parts = <int>[
        if (mood != null) mood,
        if (energy != null) energy,
        if (stress != null) stress,
      ];
      final int? dayScore = parts.isEmpty
          ? null
          : (parts.reduce((int a, int b) => a + b) / parts.length).round();
      if (dayScore != null) {
        overallScores.add(dayScore);
      }

      if (checkin != null || answer != null) {
        activeDateKeys.add(dateKey);
      }

      final String? answerText = answer?.answer.trim();
      final int dayOfYear = _resolveDayOfYear(answer, date);
      final int? sat10 = _score10From5(mood);
      final int? ene10 = _score10From5(energy);
      final int? str10 = _score10From5(stress);

      if (answerText != null && answerText.isNotEmpty) {
        if (representativeAnswers.length < 8) {
          representativeAnswers.add(answerText);
        }
        entriesCompact.add(
          "$dayOfYear) \"${_snippet(answerText)}\" | ${sat10 ?? "-"}/${ene10 ?? "-"}/${str10 ?? "-"}",
        );
      }

      days.add(<String, Object?>{
        "date_key": dateKey,
        "day_of_year": dayOfYear,
        "mood_score": mood,
        "energy_score": energy,
        "stress_score": stress,
        "satisfaction_10": sat10,
        "energy_10": ene10,
        "stress_10": str10,
        "day_score": dayScore,
        "question": answer?.questionText,
        "answer": answerText,
      });
    }

    final double avgMood = _averageIntList(moodScores);
    final double avgEnergy = _averageIntList(energyScores);
    final double avgStress = _averageIntList(stressScores);
    final int overallScore = overallScores.isEmpty
        ? 0
        : (overallScores.reduce((int a, int b) => a + b) / overallScores.length)
              .round();
    // 키워드 추출은 정확도가 낮아 리포트에서 쓰지 않는다 (2026-11).
    const List<String> topKeywords = <String>[];
    final List<String> bucketSuggestions = await _loadOpenBucketSuggestions();

    return ReportAnalyzePayload(
      period: periodKey,
      startDate: _isoDate(startDate),
      endDate: _isoDate(endDate),
      metrics: <String, Object?>{
        "overall_score": overallScore,
        "avg_mood": avgMood,
        "avg_energy": avgEnergy,
        "avg_stress": avgStress,
        "recorded_days": activeDateKeys.length,
        "target_days": windowDays,
        "completion_rate": activeDateKeys.length / max(1, windowDays),
      },
      days: days,
      entriesCompact: entriesCompact,
      topKeywords: topKeywords,
      representativeAnswers: representativeAnswers,
      communityRecoveryIdeas: bucketSuggestions,
    );
  }

  Future<List<DailyCheckinEntity>> _loadCheckinsInRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final Isar isar = await LocalDatabase.instance.isar;
    final List<DailyCheckinEntity> all = await isar.dailyCheckinEntitys
        .where()
        .anyId()
        .findAll();
    final String startKey = _yyyymmdd(startDate);
    final String endKey = _yyyymmdd(endDate);
    return all
        .where(
          (DailyCheckinEntity item) =>
              item.dateKey.compareTo(startKey) >= 0 &&
              item.dateKey.compareTo(endKey) <= 0,
        )
        .toList(growable: false);
  }

  Future<List<String>> _loadOpenBucketSuggestions() async {
    final Isar isar = await LocalDatabase.instance.isar;
    final List<BucketItemEntity> items = await isar.bucketItemEntitys
        .where()
        .findAll();
    items.sort((BucketItemEntity a, BucketItemEntity b) {
      final DateTime aDate = a.dueDate ?? a.createdAt;
      final DateTime bDate = b.dueDate ?? b.createdAt;
      return aDate.compareTo(bDate);
    });
    return items
        .where((BucketItemEntity item) => !item.isCompleted)
        .map((BucketItemEntity item) {
          final String category = item.category.trim();
          final String title = item.title.trim();
          if (title.isEmpty) {
            return "";
          }
          return "$category|$title";
        })
        .where((String item) => item.trim().isNotEmpty)
        .take(5)
        .toList(growable: false);
  }

  String _buildPeriodSummary({
    required String focusLabel,
    required int recordedDays,
    required int targetDays,
    required double avgMood,
    required double avgEnergy,
    required double avgStress,
  }) {
    if (recordedDays <= 0) {
      return "$focusLabel에는 아직 분석할 기록이 충분하지 않아 간단한 리포트로 정리했어요. "
          "기록이 조금 더 쌓이면 흐름을 더 정확하게 읽어드릴 수 있어요.";
    }

    final bool hasCheckinData = avgMood > 0 || avgEnergy > 0 || avgStress > 0;
    final String completionText = "$targetDays일중에 $recordedDays일동안 기록을 완료했어요.";
    final String scoreText = hasCheckinData
        ? "${_moodTone(avgMood)} ${_energyTone(avgEnergy)} ${_stressTone(avgStress)}"
        : "";
    return "$focusLabel에는 $completionText $scoreText"
        .replaceAll(RegExp(r"\s+"), " ")
        .trim();
  }

  List<String> _buildPeriodInsights({
    required String focusLabel,
    required ReportAnalyzePayload payload,
    required double avgMood,
    required double avgEnergy,
    required double avgStress,
    required _PeriodScoreEvidence? bestDay,
    required _PeriodScoreEvidence? hardestDay,
  }) {
    final List<String> insights = <String>[];
    final bool hasCheckinData = avgMood > 0 || avgEnergy > 0 || avgStress > 0;

    if (hasCheckinData) {
      insights.add(
        "기록일 기준 평균 만족도는 ${_formatScore10(avgMood)}점, "
        "에너지는 ${_formatScore10(avgEnergy)}점, "
        "스트레스는 ${_formatScore10(avgStress)}점이었어요.",
      );
    } else {
      insights.add("체크인 데이터가 적어 감정 점수 흐름은 제한적으로 집계됐어요.");
    }

    if (bestDay != null &&
        hardestDay != null &&
        bestDay.dateLabel != hardestDay.dateLabel) {
      insights.add(
        "${bestDay.dateLabel}에는 ${_periodDayEvidenceText(bestDay, positive: true)} "
        "${hardestDay.dateLabel}에는 ${_periodDayEvidenceText(hardestDay, positive: false)}",
      );
    } else if (bestDay != null) {
      insights.add(
        "${bestDay.dateLabel}에는 ${_periodDayEvidenceText(bestDay, positive: true)}",
      );
    } else if (payload.representativeAnswers.isNotEmpty) {
      insights.add(
        "남겨둔 기록에서는 \"${_snippet(payload.representativeAnswers.first)}\" 같은 문장이 눈에 띄었어요.",
      );
    }

    if (insights.length < 3) {
      final int recordedDays = _metricInt(
        payload.metrics["recorded_days"],
        fallback: payload.days.length,
      );
      final int targetDays = _metricInt(
        payload.metrics["target_days"],
        fallback: max(1, payload.days.length),
      );
      insights.add(
        "이번 기간 기록률은 ${((recordedDays / max(1, targetDays)) * 100).round()}%예요. "
        "기록이 조금 더 이어지면 패턴을 더 선명하게 읽을 수 있어요.",
      );
    }

    return insights.take(3).toList(growable: false);
  }

  List<String> _buildPeriodActions({
    required String nextLabel,
    required ReportAnalyzePayload payload,
    required double avgEnergy,
    required double avgStress,
    required int recordedDays,
    required int targetDays,
  }) {
    final List<String> actions = <String>[];

    void addAction(String value) {
      final String normalized = value.trim();
      if (normalized.isEmpty || actions.contains(normalized)) {
        return;
      }
      actions.add(normalized);
    }

    if (recordedDays < max(3, (targetDays * 0.4).round())) {
      addAction("$nextLabel에는 하루 한 줄이라도 기록을 남겨 리포트 정확도를 높여보세요.");
    }
    if (avgStress >= 3.5) {
      addAction("$nextLabel에는 스트레스가 높았던 날의 공통 상황을 1줄로 적어보세요.");
    }
    if (avgEnergy > 0 && avgEnergy <= 2.8) {
      addAction("$nextLabel에는 에너지가 떨어지는 시간대에 10분 회복 루틴을 하나 고정해보세요.");
    }

    final String? positiveAnswerAction = _positiveAnswerAction(
      nextLabel: nextLabel,
      payload: payload,
    );
    if (positiveAnswerAction != null) {
      addAction(positiveAnswerAction);
    }

    final String? bucketAction = _bucketAction(
      nextLabel: nextLabel,
      payload: payload,
    );
    if (bucketAction != null) {
      addAction(bucketAction);
    }

    addAction("$nextLabel에는 나를 가장 잘 회복시킨 순간을 먼저 일정에 넣어보세요.");

    return actions.take(3).toList(growable: false);
  }

  String? _positiveAnswerAction({
    required String nextLabel,
    required ReportAnalyzePayload payload,
  }) {
    Map<String, Object?>? selected;
    int selectedScore = -1;
    for (final Map<String, Object?> day in payload.days) {
      final String answer = ((day["answer"] as String?) ?? "").trim();
      if (answer.isEmpty) {
        continue;
      }
      final String question = ((day["question"] as String?) ?? "").trim();
      final int score = _tryInt(day["day_score"]) ?? 0;
      final bool isGoodMoodQuestion =
          question.contains("기분") ||
          question.contains("좋") ||
          question.contains("행동") ||
          question.contains("루틴");
      if (score >= selectedScore && (score >= 4 || isGoodMoodQuestion)) {
        selected = day;
        selectedScore = score;
      }
    }
    final String answer = ((selected?["answer"] as String?) ?? "").trim();
    if (answer.isEmpty) {
      return null;
    }
    return "$nextLabel에는 기분이 좋았던 날 남긴 \"${_snippet(answer)}\"를 다시 할 수 있는 작은 일정으로 잡아보세요.";
  }

  String? _bucketAction({
    required String nextLabel,
    required ReportAnalyzePayload payload,
  }) {
    if (payload.communityRecoveryIdeas.isEmpty) {
      return null;
    }
    final List<String> parts = payload.communityRecoveryIdeas.first.split("|");
    if (parts.length < 2) {
      return null;
    }
    final String category = parts.first.trim().isEmpty
        ? "버킷리스트"
        : parts.first.trim();
    final String title = parts.sublist(1).join("|").trim();
    if (title.isEmpty) {
      return null;
    }
    final String verb = _bucketCategoryVerb(category);
    return "아직 버킷리스트의 \"$title\"를 실행해보지 않았으니, $nextLabel에는 $category 카테고리에서 작게 $verb 볼까요?";
  }

  String _bucketCategoryVerb(String category) {
    if (category.contains("여행")) {
      return "여행 계획부터 시작해";
    }
    if (category.contains("관람") || category.contains("문화")) {
      return "관람 일정을 찾아";
    }
    if (category.contains("도전") || category.contains("성장")) {
      return "도전해";
    }
    if (category.contains("운동") || category.contains("건강")) {
      return "몸을 움직여";
    }
    return "실행해";
  }

  String _moodTone(double score) {
    if (score >= 4.0) {
      return "만족감은 비교적 안정적이었고";
    }
    if (score >= 3.0) {
      return "만족감은 무난한 편이었고";
    }
    return "만족감은 다소 흔들리는 편이었고";
  }

  String _energyTone(double score) {
    if (score >= 4.0) {
      return "에너지도 전반적으로 유지됐어요.";
    }
    if (score >= 3.0) {
      return "에너지는 중간 정도를 유지했어요.";
    }
    return "에너지는 쉽게 떨어지는 날이 있었어요.";
  }

  String _stressTone(double score) {
    if (score >= 4.0) {
      return "스트레스 부담은 비교적 큰 편이었어요.";
    }
    if (score >= 3.0) {
      return "스트레스는 중간 정도였어요.";
    }
    return "스트레스 부담은 비교적 낮았어요.";
  }

  String _formatScore10(double score5) {
    return (score5 * 2).toStringAsFixed(1);
  }

  String _selectedPeriodLabel({
    required ReportPeriod period,
    required int year,
    required int month,
  }) {
    return switch (period) {
      ReportPeriod.monthly => "$month월",
      ReportPeriod.quarterly => "${((month - 1) ~/ 3) + 1}분기",
      ReportPeriod.yearly => "$year년",
    };
  }

  String _nextPeriodLabel(ReportPeriod period) {
    return switch (period) {
      ReportPeriod.monthly => "다음 달",
      ReportPeriod.quarterly => "다음 분기",
      ReportPeriod.yearly => "다음 해",
    };
  }

  _PeriodScoreEvidence? _pickPeriodDay(
    List<Map<String, Object?>> days, {
    required bool pickMax,
  }) {
    _PeriodScoreEvidence? selected;
    for (final Map<String, Object?> day in days) {
      final int? score = _tryInt(day["day_score"]);
      if (score == null) {
        continue;
      }
      final _PeriodScoreEvidence evidence = _PeriodScoreEvidence(
        score: score,
        dateLabel: _dateLabelFromKey((day["date_key"] as String?) ?? ""),
        answerSnippet: ((day["answer"] as String?) ?? "").trim(),
      );
      if (selected == null) {
        selected = evidence;
        continue;
      }
      final bool shouldReplace = pickMax
          ? evidence.score > selected.score
          : evidence.score < selected.score;
      if (shouldReplace) {
        selected = evidence;
      }
    }
    return selected;
  }

  String _periodDayEvidenceText(
    _PeriodScoreEvidence evidence, {
    required bool positive,
  }) {
    if (evidence.answerSnippet.isNotEmpty) {
      return "\"${_snippet(evidence.answerSnippet)}\" 같은 기록이 남아 있었어요.";
    }
    return positive ? "비교적 안정적인 흐름이 보였어요." : "조금 더 돌봄이 필요한 흐름이 보였어요.";
  }

  String _dateLabelFromKey(String dateKey) {
    if (dateKey.length != 8) {
      return "기록이 남은 날";
    }
    final int? month = int.tryParse(dateKey.substring(4, 6));
    final int? day = int.tryParse(dateKey.substring(6, 8));
    if (month == null || day == null) {
      return "기록이 남은 날";
    }
    return "$month월 $day일";
  }

  int _metricInt(Object? value, {int fallback = 0}) {
    return _tryInt(value) ?? fallback;
  }

  int? _tryInt(Object? value) {
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

  double _metricDouble(Object? value) {
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

  TodayQuestionRecord? _latestRecordByDateKey(
    List<TodayQuestionRecord> records,
    String dateKey,
  ) {
    TodayQuestionRecord? result;
    for (final TodayQuestionRecord item in records) {
      final String key = _yyyymmdd(kstDateOnly(item.createdAt));
      if (key != dateKey) {
        continue;
      }
      if (result == null || item.createdAt.isAfter(result.createdAt)) {
        result = item;
      }
    }
    return result;
  }

  int _resolveDayOfYear(TodayQuestionRecord? record, DateTime date) {
    if (record?.questionDayOfYear != null && record!.questionDayOfYear! > 0) {
      return record.questionDayOfYear!;
    }
    return date.difference(DateTime(date.year, 1, 1)).inDays + 1;
  }

  int? _scoreFromIndex(int? index) {
    if (index == null || index < 0 || index > 4) return null;
    return 5 - index;
  }

  int? _score10From5(int? score5) => score5 == null ? null : score5 * 2;

  double _averageIntList(List<int> values) {
    if (values.isEmpty) return 0;
    final int total = values.reduce((a, b) => a + b);
    return total / values.length;
  }

  String _snippet(String text) {
    if (text.length <= 32) return text;
    return "${text.substring(0, 32)}...";
  }

  String _isoDate(DateTime dateTime) {
    final String mm = dateTime.month.toString().padLeft(2, "0");
    final String dd = dateTime.day.toString().padLeft(2, "0");
    return "${dateTime.year}-$mm-$dd";
  }

  String _yyyymmdd(DateTime dateTime) {
    final String mm = dateTime.month.toString().padLeft(2, "0");
    final String dd = dateTime.day.toString().padLeft(2, "0");
    return "${dateTime.year}$mm$dd";
  }
}

class _PeriodScoreEvidence {
  const _PeriodScoreEvidence({
    required this.score,
    required this.dateLabel,
    required this.answerSnippet,
  });

  final int score;
  final String dateLabel;
  final String answerSnippet;
}
