import "dart:math";
// ignore_for_file: use_null_aware_elements

import "package:isar/isar.dart";

import "../../core/kst_date_time.dart";
import "../../data/local_db/entities/daily_checkin_entity.dart";
import "../../data/local_db/local_database.dart";
import "../question/today_question_store.dart";
import "report_models.dart";

class ReportAggregationService {
  const ReportAggregationService();

  static const Set<String> _stopWords = <String>{
    "오늘",
    "요즘",
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
    "돼요",
    "되요",
    "되고",
    "그냥",
    "정말",
    "너무",
    "그리고",
    "대한",
    "에서",
    "으로",
    "한다",
    "했다",
    "하는",
    "있다",
    "없다",
    "나는",
    "내가",
    "우리",
    "저는",
  };
  static const Set<String> _lowInfoWords = <String>{
    "사람",
    "하루",
    "기분",
    "마음",
    "생각",
    "시간",
    "요즘",
    "오늘",
    "이번",
    "상태",
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
    "거나",
    "하게",
    "하며",
    "했던",
    "하고",
    "같다",
    "같은",
    "좋다",
    "좋은",
    "나쁜",
    "싶다",
    "싶은",
    "하기",
    "가기",
    "보기",
    "먹기",
    "듣기",
    "고",
    "어",
    "나",
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

  Future<WeeklyAggregationSnapshot> buildWeeklySnapshot({
    DateTime? referenceDate,
  }) async {
    await TodayQuestionStore.instance.initialize();
    final DateTime now = referenceDate ?? nowInKst();
    final DateTime endDate = DateTime(now.year, now.month, now.day);
    final DateTime startDate = endDate.subtract(const Duration(days: 6));

    final List<DailyCheckinEntity> checkins = await _loadCheckinsInRange(
      startDate: startDate,
      endDate: endDate,
    );
    final Map<String, DailyCheckinEntity> byDateKey =
        <String, DailyCheckinEntity>{
          for (final DailyCheckinEntity item in checkins) item.dateKey: item,
        };
    final List<TodayQuestionRecord> weeklyAnswers = TodayQuestionStore
        .instance
        .value
        .where((TodayQuestionRecord item) {
          final DateTime day = _kstDateOnlyFromRecord(item);
          return !day.isBefore(startDate) && !day.isAfter(endDate);
        })
        .toList(growable: false);

    final Set<String> activeDateKeys = <String>{};
    final List<int> moodScores = <int>[];
    final List<int> energyScores = <int>[];
    final List<int> stressScores = <int>[];
    final List<int> dayScores = <int>[];
    final List<Map<String, Object?>> days = <Map<String, Object?>>[];
    final List<String> entriesCompact = <String>[];
    final List<String> representativeAnswers = <String>[];

    for (int i = 0; i < 7; i++) {
      final DateTime date = startDate.add(Duration(days: i));
      final String dateKey = _yyyymmdd(date);
      final DailyCheckinEntity? checkin = byDateKey[dateKey];
      final TodayQuestionRecord? answer = _latestRecordByDateKey(
        weeklyAnswers,
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
        dayScores.add(dayScore);
      }

      if (checkin != null || answer != null) {
        activeDateKeys.add(dateKey);
      }

      final String? answerText = answer?.answer.trim();
      final int dayOfYear = _resolveDayOfYear(answer, date);
      final List<String> entryKeywords = _keywordsFromRecord(answer, topN: 2);
      final int? satisfaction10 = _score10From5(mood);
      final int? energy10 = _score10From5(energy);
      final int? stress10 = _score10From5(stress);

      if (answerText != null && answerText.isNotEmpty) {
        if (representativeAnswers.length < 5) {
          representativeAnswers.add(answerText);
        }
        entriesCompact.add(
          _compactEntryLine(
            dayOfYear: dayOfYear,
            answer: answerText,
            satisfaction10: satisfaction10,
            energy10: energy10,
            stress10: stress10,
            keywords: entryKeywords,
          ),
        );
      }

      days.add(<String, Object?>{
        "date_key": dateKey,
        "day_of_year": dayOfYear,
        "mood_score": mood,
        "energy_score": energy,
        "stress_score": stress,
        "satisfaction_10": satisfaction10,
        "energy_10": energy10,
        "stress_10": stress10,
        "day_score": dayScore,
        "question": answer?.questionText,
        "answer": answerText,
        "keywords": entryKeywords,
        "compact_line": answerText == null
            ? null
            : _compactEntryLine(
                dayOfYear: dayOfYear,
                answer: answerText,
                satisfaction10: satisfaction10,
                energy10: energy10,
                stress10: stress10,
                keywords: entryKeywords,
              ),
      });
    }

    final double averageMood = _averageIntList(moodScores);
    final double averageEnergy = _averageIntList(energyScores);
    final double averageStress = _averageIntList(stressScores);
    final int weeklyScore = dayScores.isEmpty
        ? 0
        : (dayScores.reduce((int a, int b) => a + b) / dayScores.length)
              .round();
    final double trendDelta = _trendDelta(dayScores);
    final List<String> topKeywords = _extractKeywords(weeklyAnswers, topN: 5);

    final ReportAnalyzePayload payload = ReportAnalyzePayload(
      period: "weekly",
      startDate: _isoDate(startDate),
      endDate: _isoDate(endDate),
      metrics: <String, Object?>{
        "weekly_score": weeklyScore,
        "avg_mood": averageMood,
        "avg_energy": averageEnergy,
        "avg_stress": averageStress,
        "recorded_days": activeDateKeys.length,
        "target_days": 7,
        "completion_rate": activeDateKeys.length / 7,
        "trend_delta": trendDelta,
      },
      days: days,
      entriesCompact: entriesCompact,
      topKeywords: topKeywords,
      representativeAnswers: representativeAnswers,
    );

    return WeeklyAggregationSnapshot(
      payload: payload,
      weeklyScore: weeklyScore,
      averageMood: averageMood,
      averageEnergy: averageEnergy,
      averageStress: averageStress,
      recordedDays: activeDateKeys.length,
      targetDays: 7,
      topKeywords: topKeywords,
      trendDelta: trendDelta,
    );
  }

  WeeklyAiReport buildLocalFallbackReport(WeeklyAggregationSnapshot snapshot) {
    final int completionRate =
        ((snapshot.recordedDays / snapshot.targetDays) * 100).round();
    final String trendText = snapshot.trendDelta > 0.2
        ? "주 후반으로 갈수록 컨디션이 좋아졌어요."
        : snapshot.trendDelta < -0.2
        ? "주 후반에 컨디션이 다소 낮아졌어요."
        : "주간 컨디션이 비교적 안정적이었어요.";
    final String keywordText = snapshot.topKeywords.isEmpty
        ? "아직 추출된 핵심 키워드가 부족해요."
        : "자주 나온 키워드는 ${snapshot.topKeywords.take(3).join(", ")} 입니다.";
    final _DayScoreEvidence? bestDay = _pickDayByScore(
      snapshot.payload.days,
      pickMax: true,
    );
    final _DayScoreEvidence? hardestDay = _pickDayByScore(
      snapshot.payload.days,
      pickMax: false,
    );
    final String bestDayText = bestDay == null
        ? "이번 주 최고 컨디션 데이터를 아직 찾지 못했어요."
        : "${bestDay.dateLabel}에 컨디션이 가장 좋았고(평균 ${bestDay.score}점), \"${bestDay.answerSnippet}\"";
    final String hardestDayText = hardestDay == null
        ? "이번 주 저점 데이터는 아직 충분하지 않아요."
        : "${hardestDay.dateLabel}에는 상대적으로 힘들었어요(평균 ${hardestDay.score}점).";
    final List<String> actions = _buildNextWeekMissions(
      snapshot: snapshot,
      bestDay: bestDay,
      hardestDay: hardestDay,
    );

    return WeeklyAiReport(
      summary:
          "이번 주 평균 점수는 ${snapshot.weeklyScore}/5점, 기록률은 $completionRate%예요. "
          "$trendText "
          "좋았던 순간과 힘들었던 순간이 분명하게 구분되는 한 주였습니다.",
      insights: <String>[
        "기분 평균 ${snapshot.averageMood.toStringAsFixed(1)}점, 에너지 평균 ${snapshot.averageEnergy.toStringAsFixed(1)}점, 스트레스 평균 ${snapshot.averageStress.toStringAsFixed(1)}점입니다.",
        bestDayText,
        hardestDayText,
        keywordText,
        "총 ${snapshot.recordedDays}일 기록했어요. 기록이 누적될수록 리포트가 더 정확해집니다.",
      ],
      actions: actions.take(3).toList(growable: false),
      weeklyScore: snapshot.weeklyScore,
      monthlyScore: null,
      source: "local-fallback",
    );
  }

  _DayScoreEvidence? _pickDayByScore(
    List<Map<String, Object?>> days, {
    required bool pickMax,
  }) {
    _DayScoreEvidence? selected;
    for (final Map<String, Object?> day in days) {
      final int? score = day["day_score"] as int?;
      if (score == null) {
        continue;
      }
      final String dateKey = (day["date_key"] as String?) ?? "";
      final String answer = (day["answer"] as String?)?.trim() ?? "";
      final _DayScoreEvidence evidence = _DayScoreEvidence(
        score: score,
        dateLabel: _dateLabelFromKey(dateKey),
        answerSnippet: _snippet(answer),
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

  TodayQuestionRecord? _latestRecordByDateKey(
    List<TodayQuestionRecord> records,
    String dateKey,
  ) {
    TodayQuestionRecord? result;
    for (final TodayQuestionRecord item in records) {
      final String key = _yyyymmdd(_kstDateOnlyFromRecord(item));
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
      for (final _CompoundToken compound in _buildCompoundNouns(answerNouns)) {
        int score = compound.size >= 3 ? 3 : 2;
        if (_domainBoostWords.contains(compound.text)) {
          score += 1;
        }
        _addScore(counter, compound.text, score);
      }

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
        for (final _CompoundToken compound in _buildCompoundNouns(tagNouns)) {
          int score = compound.size >= 3 ? 4 : 3;
          if (_domainBoostWords.contains(compound.text)) {
            score += 1;
          }
          _addScore(counter, compound.text, score);
        }
      }
    }
    final List<MapEntry<String, int>> sorted = _removeSubTokens(counter).entries
        .where((MapEntry<String, int> e) => e.value > 0)
        .toList()
      ..sort((MapEntry<String, int> a, MapEntry<String, int> b) {
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
    return sorted.take(topN).map((MapEntry<String, int> e) => e.key).toList();
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
      for (final _CompoundToken compound in _buildCompoundNouns(tagNouns)) {
        int score = compound.size >= 3 ? 4 : 3;
        if (_domainBoostWords.contains(compound.text)) {
          score += 1;
        }
        _addScore(counter, compound.text, score);
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
    for (final _CompoundToken compound in _buildCompoundNouns(answerNouns)) {
      int score = compound.size >= 3 ? 3 : 2;
      if (_domainBoostWords.contains(compound.text)) {
        score += 1;
      }
      _addScore(counter, compound.text, score);
    }

    final List<MapEntry<String, int>> sorted = _removeSubTokens(counter).entries
        .where((MapEntry<String, int> e) => e.value > 0)
        .toList()
      ..sort((MapEntry<String, int> a, MapEntry<String, int> b) {
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
    return sorted.take(topN).map((MapEntry<String, int> e) => e.key).toList();
  }

  List<String> _extractNouns(String text) {
    final List<String> result = <String>[];
    final Iterable<String> tokens = RegExp(
      r"[가-힣A-Za-z0-9]{2,}",
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

  List<_CompoundToken> _buildCompoundNouns(List<String> nouns) {
    if (nouns.length < 2) {
      return const <_CompoundToken>[];
    }
    final Set<String> dedupe = <String>{};
    final List<_CompoundToken> result = <_CompoundToken>[];
    for (int size = 2; size <= 3; size++) {
      if (nouns.length < size) {
        break;
      }
      for (int i = 0; i <= nouns.length - size; i++) {
        final String text = nouns.sublist(i, i + size).join(" ");
        if (dedupe.add(text)) {
          result.add(_CompoundToken(text: text, size: size));
        }
      }
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
        final bool stronger = other.value >= item.value && _wordCount(other.key) > 1;
        return contained && stronger;
      });
      if (!remove) {
        result[item.key] = item.value;
      }
    }
    return result;
  }

  int _wordCount(String text) => text.split(" ").where((String w) => w.isNotEmpty).length;

  void _addScore(Map<String, int> counter, String token, int amount) {
    if (amount == 0) {
      return;
    }
    counter[token] = (counter[token] ?? 0) + amount;
  }

  DateTime _kstDateOnlyFromRecord(TodayQuestionRecord record) {
    return kstDateOnly(record.createdAt);
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

  String _dateLabelFromKey(String dateKey) {
    if (dateKey.length != 8) {
      return dateKey;
    }
    final String mm = dateKey.substring(4, 6);
    final String dd = dateKey.substring(6, 8);
    return "$mm월 $dd일";
  }

  String _snippet(String text) {
    if (text.isEmpty) {
      return "답변이 기록되지 않았어요.";
    }
    if (text.length <= 30) {
      return text;
    }
    return "${text.substring(0, 30)}...";
  }

  int _resolveDayOfYear(TodayQuestionRecord? record, DateTime date) {
    if (record?.questionDayOfYear != null && record!.questionDayOfYear! > 0) {
      return record.questionDayOfYear!;
    }
    return date.difference(DateTime(date.year, 1, 1)).inDays + 1;
  }

  int? _score10From5(int? score5) {
    if (score5 == null) {
      return null;
    }
    return score5 * 2;
  }

  String _compactEntryLine({
    required int dayOfYear,
    required String answer,
    required int? satisfaction10,
    required int? energy10,
    required int? stress10,
    required List<String> keywords,
  }) {
    final String scoreText =
        "${satisfaction10 ?? "-"}/${energy10 ?? "-"}/${stress10 ?? "-"}";
    final String keywordText = keywords.isEmpty ? "없음" : keywords.join(",");
    return "$dayOfYear) \"${_snippet(answer)}\" | $scoreText | $keywordText";
  }

  List<String> _buildNextWeekMissions({
    required WeeklyAggregationSnapshot snapshot,
    required _DayScoreEvidence? bestDay,
    required _DayScoreEvidence? hardestDay,
  }) {
    final List<String> missions = <String>[];
    final String bestCue = bestDay?.answerSnippet ?? "";
    final String hardCue = hardestDay?.answerSnippet ?? "";

    if (bestCue.contains("산책")) {
      missions.add("다음 주 미션: 점심시간 10분 산책을 주 3회 해보세요.");
    } else if (bestCue.contains("음악")) {
      missions.add("다음 주 미션: 집중 시작 전에 1곡(3~5분) 고정 음악을 들어보세요.");
    } else if (bestCue.contains("혼자")) {
      missions.add("다음 주 미션: 하루 15분 혼자 쉬는 시간을 캘린더에 먼저 예약해보세요.");
    } else if (bestCue.isNotEmpty) {
      missions.add("다음 주 미션: 컨디션이 좋았던 날의 행동 1가지를 골라 주 3회 반복해보세요.");
    }

    if (hardCue.contains("일정") ||
        hardCue.contains("집중") ||
        hardCue.contains("미룸")) {
      missions.add("다음 주 미션: 큰 일을 25분 단위로 나누고 첫 블록만 바로 시작해보세요.");
    } else if (hardCue.contains("피곤") || hardCue.contains("수면")) {
      missions.add("다음 주 미션: 취침 시작 시각을 30분만 고정해 에너지 저점을 줄여보세요.");
    } else if (hardCue.contains("스트레스") || hardCue.contains("예민")) {
      missions.add("다음 주 미션: 스트레스가 오른 순간을 하루 1줄로 기록해 트리거를 찾으세요.");
    } else if (hardCue.isNotEmpty) {
      missions.add("다음 주 미션: 힘들었던 순간의 원인 1가지를 줄이고 대안 행동 1개를 정해보세요.");
    }

    if (snapshot.averageStress <= 3.0) {
      missions.add("다음 주 미션: 퇴근 후 30분은 알림을 끄고 회복 루틴(산책/샤워/스트레칭)만 해보세요.");
    } else if (snapshot.averageEnergy <= 3.0) {
      missions.add("다음 주 미션: 오전에 가장 중요한 일 1개를 먼저 처리해 에너지를 아껴보세요.");
    } else {
      missions.add("다음 주 미션: 이번 주 핵심 키워드 1개를 실행 목표로 정하고 완료 체크를 남겨보세요.");
    }

    while (missions.length < 3) {
      missions.add("다음 주 미션: 하루를 마치며 '좋았던 순간 1개'를 짧게 기록해보세요.");
    }
    return missions.take(3).toList(growable: false);
  }

  bool _isLikelyNoun(String token) {
    if (token.isEmpty || token.length < 2) {
      return false;
    }
    for (final String suffix in _nonNounSuffixes) {
      if (token.endsWith(suffix)) {
        return false;
      }
    }
    // Adverb-like endings are often noisy for keyword cards.
    if (token.endsWith("히") || token.endsWith("게")) {
      return false;
    }
    return true;
  }

  String? _normalizeNounToken(String token) {
    String value = token.trim().toLowerCase();
    if (value.length < 2) {
      return null;
    }
    if (value.startsWith("같")) {
      return null;
    }
    for (final String suffix in _josaSuffixes) {
      if (value.length > suffix.length + 1 && value.endsWith(suffix)) {
        value = value.substring(0, value.length - suffix.length);
        break;
      }
    }
    if (!_isLikelyNoun(value)) {
      return null;
    }
    for (final String noise in <String>["계속", "많이", "말고", "돼요", "되요", "되고"]) {
      if (value.contains(noise)) {
        return null;
      }
    }
    return value;
  }

  int? _scoreFromIndex(int? index) {
    if (index == null || index < 0 || index > 4) {
      return null;
    }
    return 5 - index;
  }

  double _averageIntList(List<int> values) {
    if (values.isEmpty) {
      return 0;
    }
    final int total = values.reduce((int a, int b) => a + b);
    return total / values.length;
  }

  double _trendDelta(List<int> dayScores) {
    if (dayScores.length < 4) {
      return 0;
    }
    final int split = max(1, dayScores.length ~/ 2);
    final List<int> head = dayScores.take(split).toList(growable: false);
    final List<int> tail = dayScores.skip(split).toList(growable: false);
    if (head.isEmpty || tail.isEmpty) {
      return 0;
    }
    return _averageIntList(tail) - _averageIntList(head);
  }
}

class _DayScoreEvidence {
  const _DayScoreEvidence({
    required this.score,
    required this.dateLabel,
    required this.answerSnippet,
  });

  final int score;
  final String dateLabel;
  final String answerSnippet;
}

class _CompoundToken {
  const _CompoundToken({required this.text, required this.size});

  final String text;
  final int size;
}
