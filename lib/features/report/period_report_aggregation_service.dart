import "dart:math";
// ignore_for_file: use_null_aware_elements

import "package:isar/isar.dart";

import "../../core/kst_date_time.dart";
import "../../data/local_db/entities/daily_checkin_entity.dart";
import "../../data/local_db/local_database.dart";
import "../question/today_question_store.dart";
import "report_models.dart";

enum ReportPeriod { monthly, quarterly, yearly }

class PeriodReportAggregationService {
  const PeriodReportAggregationService();

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

  Future<ReportAnalyzePayload> buildPayloadFor(ReportPeriod period) async {
    await TodayQuestionStore.instance.initialize();
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
      ..sort((a, b) {
        if (b.value != a.value) return b.value.compareTo(a.value);
        final int aWordCount = _wordCount(a.key);
        final int bWordCount = _wordCount(b.key);
        if (bWordCount != aWordCount) return bWordCount.compareTo(aWordCount);
        return a.key.compareTo(b.key);
      });
    return sorted.take(topN).map((e) => e.key).toList(growable: false);
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
      ..sort((a, b) {
        if (b.value != a.value) return b.value.compareTo(a.value);
        final int aWordCount = _wordCount(a.key);
        final int bWordCount = _wordCount(b.key);
        if (bWordCount != aWordCount) return bWordCount.compareTo(aWordCount);
        return a.key.compareTo(b.key);
      });
    return sorted.take(topN).map((e) => e.key).toList(growable: false);
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
    if (amount == 0) return;
    counter[token] = (counter[token] ?? 0) + amount;
  }

  bool _isLikelyNoun(String token) {
    if (token.length < 2) return false;
    for (final String suffix in _nonNounSuffixes) {
      if (token.endsWith(suffix)) return false;
    }
    if (token.endsWith("히") || token.endsWith("게")) return false;
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

class _CompoundToken {
  const _CompoundToken({required this.text, required this.size});

  final String text;
  final int size;
}
