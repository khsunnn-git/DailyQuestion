import "dart:math";
// ignore_for_file: use_null_aware_elements

import "package:isar_community/isar.dart";

import "../../core/keyword_semantics.dart";
import "../../core/kst_date_time.dart";
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

  static const Set<String> _stopWords = <String>{
    "오늘",
    "요즘",
    "오랜만",
    "대충",
    "계속",
    "많이",
    "말고",
    "진짜",
    "조금",
    "약간",
    "아직",
    "이미",
    "먼저",
    "다시",
    "또",
    "더",
    "덜",
    "자꾸",
    "바로",
    "새로",
    "가득",
    "이런",
    "그런",
    "저런",
    "돼요",
    "되요",
    "되고",
    "그리고",
    "정말",
    "너무",
    "그냥",
    "나는",
    "내가",
    "우리",
    "에서",
    "으로",
    "하다",
    "했다",
    "하는",
    "있다",
    "없다",
  };
  static const Set<String> _lowInfoWords = <String>{
    "사람",
    "하루",
    "기분",
    "마음",
    "생각",
    "시간",
    "생활",
    "정상",
    "요즘",
    "오늘",
    "이번",
    "상태",
  };
  static const Set<String> _blockedKeywordWords = <String>{
    "이야기",
    "얘기",
    "오랜만",
    "대충",
    "정주행중인",
    "추억돋는다",
    "다녀오기",
    "돌아오기",
    "보기",
    "가기",
    "오기",
    "하기",
    "해보기",
    "보내기",
    "지내기",
    "나가기",
    "들어가기",
  };
  static const Set<String> _domainBoostWords = <String>{
    "행복",
    "기쁨",
    "설렘",
    "불안",
    "우울",
    "외로움",
    "스트레스",
    "안정",
    "가족",
    "친구",
    "연인",
    "엄마",
    "아빠",
    "동생",
    "고양이",
    "강아지",
    "운동",
    "공부",
    "산책",
    "여행",
    "취업",
    "이직",
    "퇴사",
    "건강",
    "독서",
    "기록",
    "집",
    "회사",
    "학교",
    "카페",
    "병원",
  };

  static const Set<String> _nonNounSuffixes = <String>{
    "하다",
    "했다",
    "해요",
    "합니다",
    "되는",
    "되다",
    "됐다",
    "이다",
    "예요",
    "어요",
    "아요",
    "네요",
    "하게",
    "하며",
    "같다",
    "같은",
    "좋다",
    "좋은",
    "싶다",
    "싶은",
    "하기",
    "가기",
    "보기",
    "먹기",
    "듣기",
    "한다",
    "된다",
    "했다가",
    "하려",
    "하려고",
    "하도록",
    "되도록",
    "시키다",
    "시킨다",
    "시키는",
    "시키고",
    "하기로",
    "되기로",
    "하려면",
    "된다면",
    "되게",
    "할수록",
    "될수록",
    "해보자",
    "해보기",
    "아서",
    "어서",
    "여서",
    "워서",
    "고서",
    "면서",
    "고",
    "어",
    "나",
  };

  static const List<String> _verbLikeFragments = <String>[
    "하도록",
    "되도록",
    "하려고",
    "하려",
    "한다",
    "된다",
    "했다",
    "되고",
    "되는",
    "되게",
    "하기로",
    "되기로",
    "하려면",
    "한다면",
    "된다면",
    "할수록",
    "될수록",
    "해보자",
    "해보기",
    "하며",
    "하면",
    "가서",
    "와서",
    "해서",
    "이사가서",
    "했으면",
    "겠다",
    "으면",
    "들으면",
    "아서",
    "어서",
    "여서",
    "워서",
    "고서",
    "면서",
  ];

  static const Set<String> _singleCharAllowedNouns = <String>{
    "비",
    "밥",
    "술",
    "잠",
    "집",
    "일",
    "물",
    "눈",
    "돈",
    "말",
    "밤",
    "낮",
    "길",
    "차",
    "책",
    "꽃",
    "몸",
    "힘",
    "맛",
    "꿈",
    "옷",
    "손",
    "발",
    "산",
    "달",
    "별",
    "빵",
  };

  static const List<String> _inlineJosaSuffixes = <String>[
    "이라서",
    "라서",
    "에서",
    "에게",
    "으로",
    "이며",
    "이고",
    "은",
    "는",
    "이",
    "가",
    "을",
    "를",
    "에",
    "도",
    "와",
    "과",
    "랑",
    "야",
  ];

  static const List<String> _clauseTailEndings = <String>[
    "라면",
    "다면",
    "으면",
    "면서",
    "려고",
    "려면",
    "해야",
    "해요",
    "네요",
    "아요",
    "어요",
    "했어",
    "하면",
    "한다",
    "된다",
    "하다",
    "되다",
    "가요",
    "와요",
    "오면",
    "가면",
    "면",
    "다",
    "고",
    "서",
    "요",
    "자",
    "네",
    "까",
    "게",
    "지",
    "며",
  ];

  static const List<String> _predicateTailStarters = <String>[
    "하",
    "되",
    "가",
    "오",
    "보",
    "먹",
    "듣",
    "읽",
    "쓰",
    "누",
    "마시",
    "걷",
    "놀",
    "쉬",
    "좋",
    "싫",
    "있",
    "없",
    "많",
    "적",
    "크",
    "작",
    "같",
    "남",
    "살",
    "웃",
    "울",
    "떠",
    "타",
    "입",
  ];
  static const List<String> _keywordTailReplacements = <String>["이야기", "다녀오기"];
  static const List<String> _compoundActionSuffixes = <String>[
    "보기",
    "가기",
    "오기",
    "먹기",
    "듣기",
    "읽기",
    "쓰기",
    "마시기",
    "타기",
  ];
  static const Set<String> _blockedCompoundActionPrefixes = <String>{
    "다녀",
    "돌아",
    "보내",
    "지내",
    "들어",
    "나가",
    "해",
    "해보",
    "챙기",
    "챙겨",
    "놀러",
  };

  static const List<String> _josaSuffixes = <String>[
    "으로부터",
    "에게서",
    "이라서",
    "라서",
    "에서",
    "에게",
    "으로",
    "처럼",
    "보다",
    "까지",
    "부터",
    "하고",
    "이며",
    "이고",
    "이나",
    "거나",
    "라도",
    "만의",
    "의",
    "은",
    "는",
    "이",
    "가",
    "을",
    "를",
    "에",
    "도",
    "만",
    "와",
    "과",
    "랑",
    "야",
  ];

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
    final List<String> keywords = payload.topKeywords
        .take(3)
        .where((String keyword) => keyword.trim().isNotEmpty)
        .toList(growable: false);
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
        keywords: keywords,
      ),
      insights: _buildPeriodInsights(
        focusLabel: focusLabel,
        payload: payload,
        avgMood: avgMood,
        avgEnergy: avgEnergy,
        avgStress: avgStress,
        keywords: keywords,
        bestDay: bestDay,
        hardestDay: hardestDay,
      ),
      actions: _buildPeriodActions(
        nextLabel: nextLabel,
        keywords: keywords,
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
      final List<String> keywords = _keywordsFromRecord(answer, topN: 2);
      final int? sat10 = _score10From5(mood);
      final int? ene10 = _score10From5(energy);
      final int? str10 = _score10From5(stress);

      if (answerText != null && answerText.isNotEmpty) {
        if (representativeAnswers.length < 8) {
          representativeAnswers.add(answerText);
        }
        entriesCompact.add(
          "$dayOfYear) \"${_snippet(answerText)}\" | ${sat10 ?? "-"}/${ene10 ?? "-"}/${str10 ?? "-"} | "
          "${keywords.isEmpty ? "없음" : keywords.join(",")}",
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
        "keywords": keywords,
      });
    }

    final double avgMood = _averageIntList(moodScores);
    final double avgEnergy = _averageIntList(energyScores);
    final double avgStress = _averageIntList(stressScores);
    final int overallScore = overallScores.isEmpty
        ? 0
        : (overallScores.reduce((int a, int b) => a + b) / overallScores.length)
              .round();
    final List<String> topKeywords = _extractKeywords(rangeAnswers, topN: 5);

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

  String _buildPeriodSummary({
    required String focusLabel,
    required int recordedDays,
    required int targetDays,
    required double avgMood,
    required double avgEnergy,
    required double avgStress,
    required List<String> keywords,
  }) {
    if (recordedDays <= 0) {
      return "$focusLabel에는 아직 분석할 기록이 충분하지 않아 간단한 리포트로 정리했어요. "
          "기록이 조금 더 쌓이면 흐름을 더 정확하게 읽어드릴 수 있어요.";
    }

    final bool hasCheckinData = avgMood > 0 || avgEnergy > 0 || avgStress > 0;
    final String completionText = "$recordedDays/$targetDays일 기록이 쌓였어요.";
    final String scoreText = hasCheckinData
        ? "${_moodTone(avgMood)} ${_energyTone(avgEnergy)} ${_stressTone(avgStress)}"
        : "체크인 데이터는 아직 많지 않지만 기록 흐름은 이어지고 있어요.";
    final String keywordText = keywords.isEmpty
        ? ""
        : " 자주 떠오른 키워드는 ${keywords.join(", ")}였어요.";

    return "$focusLabel에는 $completionText $scoreText$keywordText"
        .replaceAll(RegExp(r"\s+"), " ")
        .trim();
  }

  List<String> _buildPeriodInsights({
    required String focusLabel,
    required ReportAnalyzePayload payload,
    required double avgMood,
    required double avgEnergy,
    required double avgStress,
    required List<String> keywords,
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

    if (keywords.isNotEmpty) {
      insights.add("$focusLabel에 자주 나온 키워드는 ${keywords.join(", ")} 입니다.");
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
    required List<String> keywords,
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

    final String? keywordAction = _keywordBasedAction(
      nextLabel: nextLabel,
      keywords: keywords,
    );
    if (keywordAction != null) {
      addAction(keywordAction);
    }

    addAction("$nextLabel에는 괜찮았던 날의 루틴 1가지를 다시 재현해보세요.");
    addAction("$nextLabel에는 나를 가장 잘 회복시킨 순간을 먼저 일정에 넣어보세요.");

    return actions.take(3).toList(growable: false);
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

  String? _keywordBasedAction({
    required String nextLabel,
    required List<String> keywords,
  }) {
    if (keywords.isEmpty) {
      return null;
    }

    final String primaryKeyword = keywords.first;
    const Set<String> recoveryKeywords = <String>{
      "산책",
      "운동",
      "휴식",
      "음악",
      "독서",
      "여행",
    };
    const Set<String> relationKeywords = <String>{
      "가족",
      "친구",
      "연인",
      "엄마",
      "아빠",
      "동생",
    };

    if (recoveryKeywords.contains(primaryKeyword)) {
      return "$nextLabel에도 $primaryKeyword처럼 도움이 됐던 루틴을 짧게라도 이어가보세요.";
    }
    if (relationKeywords.contains(primaryKeyword)) {
      return "$nextLabel에는 $primaryKeyword와 연결되는 시간을 먼저 일정에 넣어보세요.";
    }
    return "$nextLabel에는 $primaryKeyword 관련 순간을 다시 만들 수 있는 시간을 미리 확보해보세요.";
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
      final List<String> keywords = _stringList(
        day["keywords"],
      ).take(2).toList();
      final _PeriodScoreEvidence evidence = _PeriodScoreEvidence(
        score: score,
        dateLabel: _dateLabelFromKey((day["date_key"] as String?) ?? ""),
        keywords: keywords,
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
    if (evidence.keywords.isNotEmpty) {
      final String keywordText = evidence.keywords.join(", ");
      return positive
          ? "$keywordText 같은 키워드가 눈에 띄었어요."
          : "$keywordText 같은 키워드가 함께 보였어요.";
    }
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

  List<String> _stringList(Object? value) {
    if (value is! List<dynamic>) {
      return const <String>[];
    }
    return value
        .map((dynamic item) => "$item".trim())
        .where((String item) => item.isNotEmpty)
        .toList(growable: false);
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

  List<String> _extractKeywords(
    List<TodayQuestionRecord> records, {
    int topN = 5,
  }) {
    final Map<String, int> counter = <String, int>{};
    for (final TodayQuestionRecord record in records) {
      final Map<String, int> perRecord = <String, int>{};
      for (final String tag in record.bucketTags) {
        final List<String> tagNouns = _extractNouns(tag);
        for (final String noun in tagNouns) {
          int score = 2;
          if (_domainBoostWords.contains(noun)) {
            score += 1;
          }
          if (_lowInfoWords.contains(noun)) {
            score -= 1;
          }
          _setMaxScore(perRecord, noun, score);
        }
      }
      final List<String> answerNouns = _extractNouns(record.answer);
      for (final String noun in answerNouns) {
        int score = 1;
        if (_domainBoostWords.contains(noun)) {
          score += 1;
        }
        if (_lowInfoWords.contains(noun)) {
          score -= 1;
        }
        _setMaxScore(perRecord, noun, score);
      }
      _applySemanticKeywords(perRecord, record.answer, score: 3);
      for (final MapEntry<String, int> entry in perRecord.entries) {
        _addScore(counter, entry.key, entry.value);
      }
    }
    final List<MapEntry<String, int>> sorted =
        _removeSubTokens(
            counter,
          ).entries.where((MapEntry<String, int> e) => e.value > 0).toList()
          ..sort((a, b) {
            if (b.value != a.value) {
              return b.value.compareTo(a.value);
            }
            final int aWordCount = _wordCount(a.key);
            final int bWordCount = _wordCount(b.key);
            if (bWordCount != aWordCount) {
              return bWordCount.compareTo(aWordCount);
            }
            return a.key.compareTo(b.key);
          });
    final List<MapEntry<String, int>> repeated = sorted
        .where((MapEntry<String, int> e) => e.value >= 2)
        .toList();
    final List<MapEntry<String, int>> effective = repeated.isNotEmpty
        ? repeated
        : sorted;
    return effective.take(topN).map((e) => e.key).toList(growable: false);
  }

  List<String> _keywordsFromRecord(
    TodayQuestionRecord? record, {
    int topN = 2,
  }) {
    if (record == null) {
      return const <String>[];
    }
    final Map<String, int> counter = <String, int>{};
    for (final String tag in record.bucketTags) {
      final List<String> tagNouns = _extractNouns(tag);
      for (final String noun in tagNouns) {
        int score = 2;
        if (_domainBoostWords.contains(noun)) {
          score += 1;
        }
        if (_lowInfoWords.contains(noun)) {
          score -= 1;
        }
        _addScore(counter, noun, score);
      }
    }

    final List<String> answerNouns = _extractNouns(record.answer);
    for (final String noun in answerNouns) {
      int score = 1;
      if (_domainBoostWords.contains(noun)) {
        score += 1;
      }
      if (_lowInfoWords.contains(noun)) {
        score -= 1;
      }
      _addScore(counter, noun, score);
    }
    _applySemanticKeywords(counter, record.answer, score: 3);

    final List<MapEntry<String, int>> sorted =
        _removeSubTokens(
            counter,
          ).entries.where((MapEntry<String, int> e) => e.value > 0).toList()
          ..sort((a, b) {
            if (b.value != a.value) {
              return b.value.compareTo(a.value);
            }
            final int aWordCount = _wordCount(a.key);
            final int bWordCount = _wordCount(b.key);
            if (bWordCount != aWordCount) {
              return bWordCount.compareTo(aWordCount);
            }
            return a.key.compareTo(b.key);
          });
    return sorted.take(topN).map((e) => e.key).toList(growable: false);
  }

  List<String> _extractNouns(String text) {
    final List<String> result = <String>[];
    final Iterable<String> tokens = RegExp(
      r"[가-힣A-Za-z0-9]{1,}",
    ).allMatches(text).map((Match m) => m.group(0) ?? "");
    for (final String token in tokens) {
      final String? noun = _normalizeNounToken(token);
      if (noun == null || _stopWords.contains(noun)) {
        continue;
      }
      result.add(noun);
    }
    return result;
  }

  Map<String, int> _removeSubTokens(Map<String, int> source) {
    final List<MapEntry<String, int>> all = source.entries.toList();
    final Map<String, int> result = <String, int>{};
    for (final MapEntry<String, int> item in all) {
      final bool remove = all.any((MapEntry<String, int> other) {
        if (identical(item, other) || item.key == other.key) {
          return false;
        }
        final bool contained =
            other.key.length > item.key.length && other.key.contains(item.key);
        final bool stronger =
            other.value >= item.value && _wordCount(other.key) > 1;
        return contained && stronger;
      });
      if (!remove) {
        result[item.key] = item.value;
      }
    }
    return result;
  }

  int _wordCount(String text) =>
      text.split(" ").where((String w) => w.isNotEmpty).length;

  void _addScore(Map<String, int> counter, String token, int amount) {
    if (amount == 0) return;
    counter[token] = (counter[token] ?? 0) + amount;
  }

  void _setMaxScore(Map<String, int> counter, String token, int amount) {
    if (amount == 0) return;
    final int existing = counter[token] ?? 0;
    if (amount > existing) {
      counter[token] = amount;
    }
  }

  void _applySemanticKeywords(
    Map<String, int> counter,
    String text, {
    required int score,
  }) {
    for (final String keyword in semanticKeywordsFromText(text)) {
      _setMaxScore(counter, keyword, score);
    }
    for (final String artifact in artifactKeywordsForText(text)) {
      counter.remove(artifact);
    }
  }

  bool _isLikelyNoun(String token) {
    if (token.isEmpty) return false;
    if (token.length < 2) return _singleCharAllowedNouns.contains(token);
    for (final String suffix in _nonNounSuffixes) {
      if (token.endsWith(suffix)) return false;
    }
    if (token.endsWith("히") || token.endsWith("게")) return false;
    return true;
  }

  String? _normalizeNounToken(String token) {
    final String rawValue = token.trim().toLowerCase();
    String value = rawValue;
    if (value.isEmpty) {
      return null;
    }
    final String? semanticAlias = semanticKeywordAliasForToken(rawValue);
    if (semanticAlias != null) {
      return semanticAlias;
    }
    value = _extractLeadingNounCandidate(value);
    if (value.startsWith("이사가")) {
      value = "이사";
    }
    if (value.startsWith("같")) {
      return null;
    }
    for (final String suffix in _josaSuffixes) {
      if (value.length > suffix.length && value.endsWith(suffix)) {
        value = value.substring(0, value.length - suffix.length);
        break;
      }
    }
    value = _normalizeKeywordTail(value);
    if (!_isLikelyNoun(value)) {
      final String? compoundAction = _normalizeCompoundActionNoun(value);
      if (compoundAction == null) {
        return null;
      }
      return compoundAction;
    }
    for (final String fragment in _verbLikeFragments) {
      if (value == fragment ||
          value.endsWith(fragment) ||
          value.contains(fragment)) {
        return null;
      }
    }
    if (_blockedKeywordWords.contains(value)) {
      return null;
    }
    for (final String noise in <String>["계속", "많이", "말고", "돼요", "되요", "되고"]) {
      if (value.contains(noise)) {
        return null;
      }
    }
    return value;
  }

  String _normalizeKeywordTail(String value) {
    if (_blockedKeywordWords.contains(value)) {
      return value;
    }
    for (final String suffix in _keywordTailReplacements) {
      if (value.length <= suffix.length + 1 || !value.endsWith(suffix)) {
        continue;
      }
      final String prefix = value.substring(0, value.length - suffix.length);
      if (_isMeaningfulKeywordStem(prefix)) {
        return prefix;
      }
    }
    return value;
  }

  String? _normalizeCompoundActionNoun(String value) {
    if (_blockedKeywordWords.contains(value)) {
      return null;
    }
    for (final String suffix in _compoundActionSuffixes) {
      if (value.length <= suffix.length + 1 || !value.endsWith(suffix)) {
        continue;
      }
      final String prefix = value.substring(0, value.length - suffix.length);
      if (!_isMeaningfulKeywordStem(prefix)) {
        continue;
      }
      final bool blocked = _blockedCompoundActionPrefixes.any(prefix.endsWith);
      if (blocked) {
        continue;
      }
      return value;
    }
    return null;
  }

  bool _isMeaningfulKeywordStem(String value) {
    if (value.isEmpty ||
        _stopWords.contains(value) ||
        _lowInfoWords.contains(value) ||
        _blockedKeywordWords.contains(value)) {
      return false;
    }
    if (!_isLikelyNoun(value)) {
      return false;
    }
    for (final String fragment in _verbLikeFragments) {
      if (value == fragment ||
          value.endsWith(fragment) ||
          value.contains(fragment)) {
        return false;
      }
    }
    return true;
  }

  String _extractLeadingNounCandidate(String value) {
    for (final String suffix in _inlineJosaSuffixes) {
      final int index = value.indexOf(suffix, 1);
      if (index <= 0) {
        continue;
      }
      final String noun = value.substring(0, index);
      final String tail = value.substring(index + suffix.length);
      if (noun.isEmpty || tail.isEmpty) {
        continue;
      }
      if (_looksLikeClauseTail(tail)) {
        return noun;
      }
    }
    return value;
  }

  bool _looksLikeClauseTail(String tail) {
    if (tail.isEmpty) {
      return false;
    }
    for (final String ending in _clauseTailEndings) {
      if (tail.length > ending.length && tail.endsWith(ending)) {
        return true;
      }
    }
    for (final String fragment in _verbLikeFragments) {
      if (tail == fragment ||
          tail.endsWith(fragment) ||
          tail.contains(fragment)) {
        return true;
      }
    }
    for (final String starter in _predicateTailStarters) {
      if (tail.startsWith(starter)) {
        return true;
      }
    }
    return false;
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
    required this.keywords,
    required this.answerSnippet,
  });

  final int score;
  final String dateLabel;
  final List<String> keywords;
  final String answerSnippet;
}
