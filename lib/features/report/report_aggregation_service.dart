import "dart:math";
// ignore_for_file: use_null_aware_elements

import "package:isar/isar.dart";

import "../../core/kst_date_time.dart";
import "../../data/local_db/entities/daily_checkin_entity.dart";
import "../../data/local_db/local_database.dart";
import "../home/public_today_records_repository.dart";
import "../question/public_answer_retention.dart";
import "../question/today_question_store.dart";
import "report_models.dart";

class ReportAggregationService {
  const ReportAggregationService({
    PublicTodayRecordsRepository? publicRecordsRepository,
  }) : _publicRecordsRepository = publicRecordsRepository;

  final PublicTodayRecordsRepository? _publicRecordsRepository;

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
    "새로",
    "가득",
    "이런",
    "그런",
    "저런",
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
    final int checkinRecordedDays = days
        .where(
          (Map<String, Object?> day) =>
              day["mood_score"] != null ||
              day["energy_score"] != null ||
              day["stress_score"] != null,
        )
        .length;
    final double trendDelta = _trendDelta(dayScores);
    final List<String> topKeywords = _extractKeywords(weeklyAnswers, topN: 5);
    final List<String> communityRecoveryIdeas =
        await _loadCommunityRecoveryIdeas(now: endDate);
    final _EmotionPattern emotionPattern = _emotionPattern(
      days: days,
      trendDelta: trendDelta,
    );

    final ReportAnalyzePayload payload = ReportAnalyzePayload(
      period: "weekly",
      startDate: _isoDate(startDate),
      endDate: _isoDate(endDate),
      metrics: <String, Object?>{
        "weekly_score": weeklyScore,
        "avg_mood": averageMood,
        "avg_energy": averageEnergy,
        "avg_stress": averageStress,
        "checkin_recorded_days": checkinRecordedDays,
        "recorded_days": activeDateKeys.length,
        "target_days": 7,
        "completion_rate": activeDateKeys.length / 7,
        "trend_delta": trendDelta,
        "positive_day_count": emotionPattern.positiveDays,
        "burden_day_count": emotionPattern.burdenDays,
        "stable_day_count": emotionPattern.stableDays,
        "emotion_balance": emotionPattern.balanceLabel,
      },
      days: days,
      entriesCompact: entriesCompact,
      topKeywords: topKeywords,
      representativeAnswers: representativeAnswers,
      communityRecoveryIdeas: communityRecoveryIdeas,
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
    final bool hasCheckinData = snapshot.hasCheckinData;
    final String trendText = snapshot.trendDelta > 0.2
        ? "주 후반으로 갈수록 컨디션이 좋아졌어요."
        : snapshot.trendDelta < -0.2
        ? "주 후반에 컨디션이 다소 낮아졌어요."
        : "주간 컨디션이 비교적 안정적이었어요.";
    final _DayScoreEvidence? bestDay = _pickDayByScore(
      snapshot.payload.days,
      pickMax: true,
    );
    final _DayScoreEvidence? hardestDay = _pickDayByScore(
      snapshot.payload.days,
      pickMax: false,
    );
    final List<String> actions = _buildNextWeekMissions(
      snapshot: snapshot,
      bestDay: bestDay,
      hardestDay: hardestDay,
    );
    final _EmotionPattern emotionPattern = _emotionPattern(
      days: snapshot.payload.days,
      trendDelta: snapshot.trendDelta,
    );
    final String emotionKeywordText = snapshot.topKeywords.isEmpty
        ? ""
        : "반복된 키워드로는 ${snapshot.topKeywords.take(3).join(", ")}가 보여요.";
    final List<String> insights = _buildWeeklyInsights(
      snapshot: snapshot,
      bestDay: bestDay,
      hardestDay: hardestDay,
    );

    return WeeklyAiReport(
      summary: hasCheckinData
          ? "이번 주 평균 점수는 ${snapshot.weeklyScore}/5점, 기록률은 $completionRate%예요. "
                "$trendText"
          : "이번 주 기록률은 $completionRate%예요. "
                "감정 체크인 데이터가 아직 부족해서 평균 점수는 집계되지 않았어요.",
      emotionSummary:
          "${emotionPattern.balanceSentence} "
          "${emotionPattern.flowSentence}"
          "${emotionKeywordText.isEmpty ? "" : " $emotionKeywordText"}",
      insights: insights,
      actions: actions.take(3).toList(growable: false),
      weeklyScore: snapshot.weeklyScore,
      monthlyScore: null,
      source: "local-fallback",
    );
  }

  WeeklyAiReport buildCompactLocalFallbackReport(
    WeeklyAggregationSnapshot snapshot,
  ) {
    final int completionRate =
        ((snapshot.recordedDays / snapshot.targetDays) * 100).round();
    final String keywordText = snapshot.topKeywords.isEmpty
        ? "이번 주에는 아직 뚜렷한 키워드가 많이 쌓이지 않았어요."
        : "지금까지 자주 나온 키워드는 ${snapshot.topKeywords.take(2).join(", ")} 입니다.";
    final _EmotionPattern emotionPattern = _emotionPattern(
      days: snapshot.payload.days,
      trendDelta: snapshot.trendDelta,
    );

    return WeeklyAiReport(
      summary:
          "이번 주는 ${snapshot.recordedDays}일 기록했어요. "
          "아직 데이터가 많지 않아 간단한 리포트로 정리했어요. "
          "$keywordText",
      emotionSummary:
          "${emotionPattern.balanceSentence} "
          "조금만 더 기록이 쌓이면 긍정 흐름과 부담 흐름을 더 자세하게 읽어드릴 수 있어요.",
      insights: <String>[
        "기록률은 $completionRate%이고, 조금만 더 쌓이면 더 정확한 주간 리포트를 볼 수 있어요.",
      ],
      actions: <String>[_buildCompactAction(snapshot)],
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
        weekdayLabel: _weekdayLabelFromKey(dateKey),
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
      for (final MapEntry<String, int> entry in perRecord.entries) {
        _addScore(counter, entry.key, entry.value);
      }
    }
    final List<MapEntry<String, int>> sorted =
        _removeSubTokens(
            counter,
          ).entries.where((MapEntry<String, int> e) => e.value > 0).toList()
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
    final List<MapEntry<String, int>> repeated = sorted
        .where((MapEntry<String, int> e) => e.value >= 2)
        .toList();
    final List<MapEntry<String, int>> effective = repeated.isNotEmpty
        ? repeated
        : sorted;
    return effective
        .take(topN)
        .map((MapEntry<String, int> e) => e.key)
        .toList();
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

    final List<MapEntry<String, int>> sorted =
        _removeSubTokens(
            counter,
          ).entries.where((MapEntry<String, int> e) => e.value > 0).toList()
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
    if (amount == 0) {
      return;
    }
    counter[token] = (counter[token] ?? 0) + amount;
  }

  void _setMaxScore(Map<String, int> counter, String token, int amount) {
    if (amount == 0) {
      return;
    }
    final int existing = counter[token] ?? 0;
    if (amount > existing) {
      counter[token] = amount;
    }
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

  String _weekdayLabelFromKey(String dateKey) {
    if (dateKey.length != 8) {
      return "해당 요일";
    }
    final int? year = int.tryParse(dateKey.substring(0, 4));
    final int? month = int.tryParse(dateKey.substring(4, 6));
    final int? day = int.tryParse(dateKey.substring(6, 8));
    if (year == null || month == null || day == null) {
      return "해당 요일";
    }
    const List<String> weekdays = <String>[
      "월요일",
      "화요일",
      "수요일",
      "목요일",
      "금요일",
      "토요일",
      "일요일",
    ];
    return weekdays[DateTime(year, month, day).weekday - 1];
  }

  String _withObjectParticle(String word) {
    final String value = word.trim();
    if (value.isEmpty) {
      return value;
    }
    final int codeUnit = value.runes.last;
    final bool hasBatchim =
        codeUnit >= 0xAC00 &&
        codeUnit <= 0xD7A3 &&
        (codeUnit - 0xAC00) % 28 != 0;
    return "$value${hasBatchim ? "을" : "를"}";
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
    final Set<String> seen = <String>{};
    final List<_RecoveryActionCue> preferredCues = _preferredRecoveryCues(
      snapshot,
      prioritizedText: bestDay?.answerSnippet ?? "",
    );
    final String hardTheme = _hardMoodTheme(snapshot, hardestDay);

    void addMission(String text) {
      final String normalized = text
          .trim()
          .replaceFirst(
            RegExp(r"^(다음\s*주\s*미션|다음\s*주\s*액션|다음\s*액션)\s*[:：-]?\s*"),
            "",
          )
          .trim();
      if (normalized.isEmpty || !seen.add(normalized)) {
        return;
      }
      missions.add(normalized);
    }

    if (preferredCues.isNotEmpty) {
      final _RecoveryActionCue cue = preferredCues.first;
      addMission(
        "이번 주 기록에서는 ${cue.subject} 기분을 환기하는 데 도움이 된 흔적이 보여요. "
        "다음에 마음이 가라앉는 날엔 ${cue.recommendation}",
      );
    }

    if (snapshot.payload.communityRecoveryIdeas.isNotEmpty) {
      addMission(snapshot.payload.communityRecoveryIdeas.first);
    }

    if (preferredCues.length > 1) {
      final _RecoveryActionCue cue = preferredCues[1];
      addMission(
        "${hardTheme.isNotEmpty ? _hardThemeLead(hardTheme) : ""}"
        "${cue.shortLabel} 같은 작은 회복 행동부터 먼저 해보세요.",
      );
    } else if (preferredCues.isNotEmpty) {
      final _RecoveryActionCue cue = preferredCues.first;
      addMission(
        "${hardTheme.isNotEmpty ? _hardThemeLead(hardTheme) : ""}"
        "버티기보다 ${cue.shortLabel} 같은 작은 회복 행동부터 먼저 해보세요.",
      );
    }

    if (snapshot.topKeywords.isNotEmpty) {
      final String keyword = snapshot.topKeywords.first;
      addMission(
        "이번 주 자주 보인 키워드는 $keyword예요. "
        "기분이 흔들리는 날엔 $keyword와 연결된 작은 행동 하나를 다시 꺼내 해보세요.",
      );
    }

    while (missions.length < 3) {
      addMission("기분이 좋지 않은 날에는 이번 주 조금 편안했던 행동 1가지를 가장 먼저 다시 해보세요.");
      addMission("마음이 복잡한 날엔 해결부터 하려 하기보다 지금 할 수 있는 가장 작은 행동 1개만 시작해보세요.");
      addMission("하루를 마치며 나를 조금 편하게 만든 순간 1개만 짧게 적어보세요.");
    }
    return missions.take(3).toList(growable: false);
  }

  String _buildCompactAction(WeeklyAggregationSnapshot snapshot) {
    final _DayScoreEvidence? bestDay = _pickDayByScore(
      snapshot.payload.days,
      pickMax: true,
    );
    final List<_RecoveryActionCue> preferredCues = _preferredRecoveryCues(
      snapshot,
      prioritizedText: bestDay?.answerSnippet ?? "",
    );
    if (preferredCues.isNotEmpty) {
      final _RecoveryActionCue cue = preferredCues.first;
      return "이번 주 기록에서는 ${cue.subject} 도움이 된 흔적이 보여요. "
          "다음에 기분이 가라앉는 날엔 ${cue.recommendation}";
    }
    return "다음에 기분이 좋지 않은 날엔 이번 주 조금 괜찮았던 행동 1가지를 먼저 다시 해보세요.";
  }

  String _averageScoreInsight(WeeklyAggregationSnapshot snapshot) {
    final List<String> parts = <String>[
      if (snapshot.averageMood > 0)
        "기분 평균 ${snapshot.averageMood.toStringAsFixed(1)}점",
      if (snapshot.averageEnergy > 0)
        "에너지 평균 ${snapshot.averageEnergy.toStringAsFixed(1)}점",
      if (snapshot.averageStress > 0)
        "스트레스 평균 ${snapshot.averageStress.toStringAsFixed(1)}점",
    ];
    if (parts.isEmpty) {
      return "기분/에너지/스트레스 체크인 기록이 아직 없어서 평균 점수는 집계되지 않았어요.";
    }
    return "${parts.join(", ")}입니다.";
  }

  List<String> _buildWeeklyInsights({
    required WeeklyAggregationSnapshot snapshot,
    required _DayScoreEvidence? bestDay,
    required _DayScoreEvidence? hardestDay,
  }) {
    final List<String> insights = <String>[_averageScoreInsight(snapshot)];
    final String? leadKeyword = snapshot.topKeywords.isEmpty
        ? null
        : snapshot.topKeywords.first;

    if (snapshot.hasCheckinData && bestDay != null) {
      if (leadKeyword != null) {
        insights.add(
          "이번 한 주 ${bestDay.weekdayLabel}에 컨디션이 좋았고, "
          "${_withObjectParticle(leadKeyword)} 자주 언급하셨어요.",
        );
      } else {
        insights.add("이번 한 주 ${bestDay.weekdayLabel}에 컨디션이 좋았어요.");
      }
    } else if (leadKeyword != null) {
      insights.add("이번 한 주에는 ${_withObjectParticle(leadKeyword)} 자주 언급하셨어요.");
    }

    if (snapshot.hasCheckinData) {
      if (hardestDay != null &&
          (bestDay == null || hardestDay.dateLabel != bestDay.dateLabel)) {
        insights.add("${hardestDay.weekdayLabel}은 상대적으로 컨디션이 저조했어요.");
      } else if (bestDay != null) {
        insights.add("요일별 컨디션 차이는 비교적 고르게 유지됐어요.");
      }
    }

    if (snapshot.topKeywords.isEmpty) {
      insights.add("최근 자주 나온 키워드는 아직 더 모이면 선명해질 거예요.");
    } else {
      insights.add(
        "최근 자주 나온 키워드는 ${snapshot.topKeywords.take(3).join(", ")} 입니다.",
      );
    }
    return insights;
  }

  List<_RecoveryActionCue> _preferredRecoveryCues(
    WeeklyAggregationSnapshot snapshot, {
    String prioritizedText = "",
  }) {
    final List<String> texts = <String>[
      ...snapshot.payload.representativeAnswers,
      ...snapshot.payload.days
          .map(
            (Map<String, Object?> day) =>
                (day["answer"] as String?)?.trim() ?? "",
          )
          .where((String answer) => answer.isNotEmpty),
      ...snapshot.topKeywords,
    ];
    final Map<_RecoveryActionCue, int> scores = <_RecoveryActionCue, int>{};

    for (final _RecoveryActionCue cue in _recoveryActionCues) {
      int score = 0;
      for (final String text in texts) {
        for (final String pattern in cue.patterns) {
          if (!_matchesCuePattern(text: text, pattern: pattern)) {
            continue;
          }
          score += snapshot.topKeywords.contains(pattern) ? 2 : 1;
        }
      }
      for (final String pattern in cue.patterns) {
        if (_matchesCuePattern(text: prioritizedText, pattern: pattern)) {
          score += 3;
        }
      }
      if (score > 0) {
        scores[cue] = score;
      }
    }

    final List<MapEntry<_RecoveryActionCue, int>> sorted =
        scores.entries.toList()..sort((
          MapEntry<_RecoveryActionCue, int> a,
          MapEntry<_RecoveryActionCue, int> b,
        ) {
          if (b.value != a.value) {
            return b.value.compareTo(a.value);
          }
          return a.key.shortLabel.compareTo(b.key.shortLabel);
        });
    return sorted
        .map((MapEntry<_RecoveryActionCue, int> entry) => entry.key)
        .take(3)
        .toList(growable: false);
  }

  String _hardMoodTheme(
    WeeklyAggregationSnapshot snapshot,
    _DayScoreEvidence? hardestDay,
  ) {
    final String text = hardestDay?.answerSnippet ?? "";
    if (text.contains("불안") ||
        text.contains("걱정") ||
        text.contains("스트레스") ||
        text.contains("예민")) {
      return "걱정이나 긴장감";
    }
    if (text.contains("피곤") ||
        text.contains("지쳐") ||
        text.contains("수면") ||
        text.contains("잠")) {
      return "유난히 기운이 빠지는 느낌";
    }
    if (text.contains("외롭") || text.contains("혼자") || text.contains("관계")) {
      return "마음이 허전한 느낌";
    }
    if (text.contains("일정") ||
        text.contains("집중") ||
        text.contains("미룸") ||
        text.contains("해야")) {
      return "해야 할 일이 몰려 답답한 느낌";
    }
    if (snapshot.averageStress >= 4) {
      return "부담이 크게 올라오는 날";
    }
    if (snapshot.averageEnergy <= 2.5) {
      return "에너지가 뚝 떨어지는 날";
    }
    return "마음이 가라앉는 날";
  }

  String _hardThemeLead(String hardTheme) {
    final String normalized = hardTheme.trim();
    if (normalized.isEmpty) {
      return "";
    }
    if (normalized.endsWith("날")) {
      return "$normalized에는 ";
    }
    if (normalized.endsWith("느낌") || normalized.endsWith("긴장감")) {
      return "$normalized이 들 때는 ";
    }
    return "$normalized이 올라올 때는 ";
  }

  Future<List<String>> _loadCommunityRecoveryIdeas({
    required DateTime now,
  }) async {
    try {
      final List<PublicTodayRecord> records =
          await (_publicRecordsRepository ??
                  PublicTodayRecordsRepository.instance)
              .fetchRecentDays(now: now, days: publicAnswerRetentionDays);
      return _communityRecoveryIdeasFromRecords(records);
    } catch (_) {
      return const <String>[];
    }
  }

  List<String> _communityRecoveryIdeasFromRecords(
    List<PublicTodayRecord> records,
  ) {
    final Map<_RecoveryActionCue, int> scores = <_RecoveryActionCue, int>{};

    for (final PublicTodayRecord record in records) {
      final String text = record.body.trim();
      if (text.isEmpty) {
        continue;
      }
      for (final _RecoveryActionCue cue in _recoveryActionCues) {
        for (final String pattern in cue.patterns) {
          if (!_matchesCuePattern(text: text, pattern: pattern)) {
            continue;
          }
          scores[cue] = (scores[cue] ?? 0) + 1;
        }
      }
    }

    final List<MapEntry<_RecoveryActionCue, int>> sorted =
        scores.entries.toList()..sort((
          MapEntry<_RecoveryActionCue, int> a,
          MapEntry<_RecoveryActionCue, int> b,
        ) {
          if (b.value != a.value) {
            return b.value.compareTo(a.value);
          }
          return a.key.shortLabel.compareTo(b.key.shortLabel);
        });

    return sorted
        .take(2)
        .map((MapEntry<_RecoveryActionCue, int> entry) {
          return "최근 공개답변에서는 ${entry.key.shortLabel}로 기분을 환기한 이야기도 보였어요. "
              "마음이 답답한 날 한 번 가볍게 시도해보세요.";
        })
        .toList(growable: false);
  }

  bool _matchesCuePattern({required String text, required String pattern}) {
    final String normalizedText = text.trim().toLowerCase();
    final String normalizedPattern = pattern.trim().toLowerCase();
    if (normalizedText.isEmpty || normalizedPattern.isEmpty) {
      return false;
    }
    if (normalizedText == normalizedPattern) {
      return true;
    }
    if (_extractNouns(normalizedText).contains(normalizedPattern)) {
      return true;
    }
    if (normalizedPattern.length < 2) {
      return false;
    }
    return normalizedText.contains(normalizedPattern);
  }

  bool _isLikelyNoun(String token) {
    if (token.isEmpty) {
      return false;
    }
    if (token.length < 2) {
      return _singleCharAllowedNouns.contains(token);
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
    if (value.isEmpty) {
      return null;
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

  _EmotionPattern _emotionPattern({
    required List<Map<String, Object?>> days,
    required double trendDelta,
  }) {
    int positiveDays = 0;
    int burdenDays = 0;
    int stableDays = 0;

    for (final Map<String, Object?> day in days) {
      final int? mood = day["mood_score"] as int?;
      final int? energy = day["energy_score"] as int?;
      final int? stress = day["stress_score"] as int?;
      final int? dayScore = day["day_score"] as int?;
      final bool hasSignal =
          mood != null || energy != null || stress != null || dayScore != null;
      if (!hasSignal) {
        continue;
      }

      final bool positiveSignal =
          (mood != null && mood >= 4) ||
          (energy != null && energy >= 4 && (stress == null || stress <= 3)) ||
          (dayScore != null &&
              dayScore >= 4 &&
              (stress == null || stress <= 3));
      final bool burdenSignal =
          (stress != null && stress >= 4) ||
          (mood != null && mood <= 2) ||
          (dayScore != null && dayScore <= 2);

      if (positiveSignal && !burdenSignal) {
        positiveDays += 1;
      } else if (burdenSignal && !positiveSignal) {
        burdenDays += 1;
      } else {
        stableDays += 1;
      }
    }

    final String balanceLabel;
    final String balanceSentence;
    if (positiveDays == 0 && burdenDays == 0 && stableDays == 0) {
      balanceLabel = "데이터 부족";
      balanceSentence = "아직 감정 흐름을 읽을 만큼 체크인 데이터가 충분하지 않아요.";
    } else if (positiveDays >= burdenDays + 2) {
      balanceLabel = "긍정 우세";
      balanceSentence = "이번 주에는 전반적으로 긍정적인 생각과 안도감이 더 자주 보였어요.";
    } else if (burdenDays >= positiveDays + 2) {
      balanceLabel = "부담 우세";
      balanceSentence = "이번 주에는 해야 할 일이나 긴장감처럼 부담 신호가 조금 더 크게 드러났어요.";
    } else if (positiveDays > burdenDays) {
      balanceLabel = "완만한 긍정";
      balanceSentence = "부담도 있었지만 전체 톤은 조금 더 밝고 긍정적인 편이었어요.";
    } else if (burdenDays > positiveDays) {
      balanceLabel = "완만한 부담";
      balanceSentence = "긍정적인 순간도 있었지만 전체적으로는 부담감이 조금 더 앞섰어요.";
    } else {
      balanceLabel = "균형";
      balanceSentence = "이번 주에는 긍정과 부담이 함께 섞여 있었고 한쪽으로 크게 기울지는 않았어요.";
    }

    final String flowSentence;
    if (trendDelta > 0.45) {
      flowSentence = "주 초보다 주 후반에 마음이 한결 가벼워진 흐름이 보여요.";
    } else if (trendDelta > 0.15) {
      flowSentence = "주 후반으로 갈수록 조금 더 편안해졌어요.";
    } else if (trendDelta < -0.45) {
      flowSentence = "주 후반으로 갈수록 피로와 부담이 눈에 띄게 커졌어요.";
    } else if (trendDelta < -0.15) {
      flowSentence = "주 후반에는 초반보다 에너지나 기분이 살짝 내려갔어요.";
    } else {
      flowSentence = "한 주 전체의 감정 톤은 비교적 안정적으로 유지됐어요.";
    }

    return _EmotionPattern(
      positiveDays: positiveDays,
      burdenDays: burdenDays,
      stableDays: stableDays,
      balanceLabel: balanceLabel,
      balanceSentence: balanceSentence,
      flowSentence: flowSentence,
    );
  }
}

class _DayScoreEvidence {
  const _DayScoreEvidence({
    required this.score,
    required this.dateLabel,
    required this.weekdayLabel,
    required this.answerSnippet,
  });

  final int score;
  final String dateLabel;
  final String weekdayLabel;
  final String answerSnippet;
}

class _EmotionPattern {
  const _EmotionPattern({
    required this.positiveDays,
    required this.burdenDays,
    required this.stableDays,
    required this.balanceLabel,
    required this.balanceSentence,
    required this.flowSentence,
  });

  final int positiveDays;
  final int burdenDays;
  final int stableDays;
  final String balanceLabel;
  final String balanceSentence;
  final String flowSentence;
}

const List<_RecoveryActionCue> _recoveryActionCues = <_RecoveryActionCue>[
  _RecoveryActionCue(
    patterns: <String>["산책", "걷기", "걷다"],
    subject: "산책이",
    shortLabel: "산책",
    recommendation: "짧게라도 산책해보세요.",
  ),
  _RecoveryActionCue(
    patterns: <String>["음악", "노래", "플레이리스트"],
    subject: "음악을 듣는 시간이",
    shortLabel: "음악 듣기",
    recommendation: "좋아하는 음악 1~2곡을 들어보세요.",
  ),
  _RecoveryActionCue(
    patterns: <String>["친구", "대화", "통화", "가족", "엄마", "아빠", "동생", "연인"],
    subject: "가까운 사람과 나누는 대화가",
    shortLabel: "가까운 사람과 대화하기",
    recommendation: "믿는 사람 한 명에게 짧게라도 먼저 연락해보세요.",
  ),
  _RecoveryActionCue(
    patterns: <String>["휴식", "쉬기", "쉼", "멍", "혼자"],
    subject: "혼자 조용히 쉬는 시간이",
    shortLabel: "잠깐 쉬기",
    recommendation: "잠깐이라도 혼자 편하게 쉬는 시간을 만들어보세요.",
  ),
  _RecoveryActionCue(
    patterns: <String>["샤워", "목욕", "반신욕"],
    subject: "따뜻한 샤워 같은 몸을 풀어주는 시간이",
    shortLabel: "따뜻한 샤워",
    recommendation: "따뜻한 샤워로 몸의 긴장을 먼저 풀어보세요.",
  ),
  _RecoveryActionCue(
    patterns: <String>["스트레칭", "운동", "러닝", "헬스", "요가"],
    subject: "가볍게 몸을 움직이는 시간이",
    shortLabel: "가벼운 움직임",
    recommendation: "스트레칭이나 가벼운 움직임으로 몸부터 깨워보세요.",
  ),
  _RecoveryActionCue(
    patterns: <String>["독서", "책 읽", "책읽"],
    subject: "짧게 책을 읽는 시간이",
    shortLabel: "짧은 독서",
    recommendation: "몇 페이지라도 책을 읽으며 호흡을 고르세요.",
  ),
  _RecoveryActionCue(
    patterns: <String>["기록", "일기", "메모", "글"],
    subject: "생각을 적어보는 시간이",
    shortLabel: "짧게 기록하기",
    recommendation: "지금 드는 생각을 3줄만 적어보세요.",
  ),
  _RecoveryActionCue(
    patterns: <String>["카페", "커피"],
    subject: "잠깐 장소를 바꾸는 것이",
    shortLabel: "장소 바꾸기",
    recommendation: "잠깐 자리나 장소를 바꿔 분위기를 환기해보세요.",
  ),
  _RecoveryActionCue(
    patterns: <String>["잠", "수면", "낮잠"],
    subject: "몸을 쉬게 하는 시간이",
    shortLabel: "충분히 쉬기",
    recommendation: "조금 일찍 쉬며 몸을 먼저 회복해보세요.",
  ),
];

class _RecoveryActionCue {
  const _RecoveryActionCue({
    required this.patterns,
    required this.subject,
    required this.shortLabel,
    required this.recommendation,
  });

  final List<String> patterns;
  final String subject;
  final String shortLabel;
  final String recommendation;
}
