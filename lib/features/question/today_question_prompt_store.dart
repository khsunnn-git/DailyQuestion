import "dart:convert";

import "package:cloud_firestore/cloud_firestore.dart";
import "package:flutter/foundation.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../../core/kst_date_time.dart";

const String _defaultFallbackQuestion = "올해 안에 꼭 해보고 싶은 일\n하나는 무엇인가요?";

int _dayOfYear(DateTime date) {
  return date.difference(DateTime(date.year, 1, 1)).inDays + 1;
}

class TodayQuestionPromptState {
  const TodayQuestionPromptState({
    required this.date,
    required this.dayOfYear,
    required this.isLoading,
    required this.hasLoaded,
    required this.baseQuestion,
    this.errorMessage,
  });

  factory TodayQuestionPromptState.initial() {
    final DateTime now = nowInKst();
    return TodayQuestionPromptState(
      date: DateTime(now.year, now.month, now.day),
      dayOfYear: _dayOfYear(now),
      isLoading: true,
      hasLoaded: false,
      baseQuestion: _defaultFallbackQuestion,
    );
  }

  final DateTime date;
  final int dayOfYear;
  final bool isLoading;
  final bool hasLoaded;
  final String baseQuestion;
  final String? errorMessage;

  String get currentQuestionText => baseQuestion;

  TodayQuestionPromptState copyWith({
    DateTime? date,
    int? dayOfYear,
    bool? isLoading,
    bool? hasLoaded,
    String? baseQuestion,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TodayQuestionPromptState(
      date: date ?? this.date,
      dayOfYear: dayOfYear ?? this.dayOfYear,
      isLoading: isLoading ?? this.isLoading,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      baseQuestion: baseQuestion ?? this.baseQuestion,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class TodayQuestionPromptStore extends ValueNotifier<TodayQuestionPromptState> {
  TodayQuestionPromptStore._() : super(TodayQuestionPromptState.initial());

  static final TodayQuestionPromptStore instance = TodayQuestionPromptStore._();
  static const String _questionCacheKeyPrefix = "today_question_cache_";

  SharedPreferences? _prefs;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      await reloadIfNeeded();
      return;
    }
    _initialized = true;
    _prefs = await SharedPreferences.getInstance();
    await _loadForDate(nowInKst());
  }

  Future<void> reloadIfNeeded() async {
    final DateTime now = nowInKst();
    final DateTime today = DateTime(now.year, now.month, now.day);
    if (!_isSameDate(today, value.date)) {
      await _loadForDate(today);
    }
  }

  Future<void> _loadForDate(DateTime date) async {
    value = value.copyWith(isLoading: true, clearError: true);
    final DateTime normalized = DateTime(date.year, date.month, date.day);
    final int day = _dayOfYear(normalized);

    try {
      final Map<String, dynamic>? docData = await _fetchTodayQuestionData(day);
      if (docData != null) {
        final String base =
            (docData["base"] as String?)?.trim().isNotEmpty == true
            ? (docData["base"] as String).trim()
            : _defaultFallbackQuestion;
        await _saveCachedQuestionData(normalized, base);
        _applyLoadedQuestion(date: normalized, day: day, base: base);
        return;
      }

      final _CachedQuestionData? cached = _readCachedQuestionData(normalized);
      if (cached != null) {
        _applyLoadedQuestion(
          date: normalized,
          day: day,
          base: cached.base,
          errorMessage: "네트워크 없이 로컬에 저장된 질문을 보여줘요.",
        );
        return;
      }

      value = value.copyWith(
        date: normalized,
        dayOfYear: day,
        isLoading: false,
        hasLoaded: true,
        baseQuestion: _defaultFallbackQuestion,
        errorMessage: "오늘 질문 데이터가 없어 기본 질문을 보여줘요.",
      );
    } catch (_) {
      final _CachedQuestionData? cached = _readCachedQuestionData(normalized);
      if (cached != null) {
        _applyLoadedQuestion(
          date: normalized,
          day: day,
          base: cached.base,
          errorMessage: "질문 서버 연결에 실패해 로컬 질문을 보여줘요.",
        );
        return;
      }
      value = value.copyWith(
        date: normalized,
        dayOfYear: day,
        isLoading: false,
        hasLoaded: true,
        baseQuestion: _defaultFallbackQuestion,
        errorMessage: "질문을 불러오지 못해 기본 질문을 보여줘요.",
      );
    }
  }

  void _applyLoadedQuestion({
    required DateTime date,
    required int day,
    required String base,
    String? errorMessage,
  }) {
    value = value.copyWith(
      date: date,
      dayOfYear: day,
      isLoading: false,
      hasLoaded: true,
      baseQuestion: base,
      errorMessage: errorMessage,
      clearError: errorMessage == null,
    );
  }

  Future<void> _saveCachedQuestionData(DateTime date, String base) async {
    final String encoded = jsonEncode(<String, dynamic>{"base": base});
    await _prefs?.setString(_questionCacheKeyForDate(date), encoded);
  }

  _CachedQuestionData? _readCachedQuestionData(DateTime date) {
    final String? raw = _prefs?.getString(_questionCacheKeyForDate(date));
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      final String base =
          (decoded["base"] as String?)?.trim().isNotEmpty == true
          ? (decoded["base"] as String).trim()
          : _defaultFallbackQuestion;
      return _CachedQuestionData(base: base);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _fetchTodayQuestionData(int dayOfYear) async {
    final CollectionReference<Map<String, dynamic>> ref = FirebaseFirestore
        .instance
        .collection("daily_questions");

    final List<String> docIds = <String>[
      "$dayOfYear",
      dayOfYear.toString().padLeft(3, "0"),
    ];
    for (final String id in docIds) {
      final DocumentSnapshot<Map<String, dynamic>> snapshot = await ref
          .doc(id)
          .get();
      if (snapshot.exists && snapshot.data() != null) {
        return snapshot.data();
      }
    }

    final QuerySnapshot<Map<String, dynamic>> query = await ref
        .where("dayOfYear", isEqualTo: dayOfYear)
        .limit(1)
        .get();
    if (query.docs.isEmpty) {
      return null;
    }
    return query.docs.first.data();
  }

  String _questionCacheKeyForDate(DateTime date) {
    final String mm = date.month.toString().padLeft(2, "0");
    final String dd = date.day.toString().padLeft(2, "0");
    return "$_questionCacheKeyPrefix${date.year}$mm$dd";
  }

  static bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _CachedQuestionData {
  const _CachedQuestionData({required this.base});

  final String base;
}
