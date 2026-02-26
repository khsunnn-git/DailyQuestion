import "package:cloud_firestore/cloud_firestore.dart";
import "package:flutter/foundation.dart";
import "package:shared_preferences/shared_preferences.dart";

const String _defaultFallbackQuestion = "올해 안에 꼭 해보고 싶은 일\n하나는 무엇인가요?";

int _dayOfYear(DateTime date) {
  return date.difference(DateTime(date.year, 1, 1)).inDays + 1;
}

class TodayQuestionPromptState {
  const TodayQuestionPromptState({
    required this.date,
    required this.dayOfYear,
    required this.isLoading,
    required this.refreshIndex,
    required this.baseQuestion,
    required this.reserveQuestions,
    this.errorMessage,
  });

  factory TodayQuestionPromptState.initial() {
    final DateTime now = DateTime.now();
    return TodayQuestionPromptState(
      date: DateTime(now.year, now.month, now.day),
      dayOfYear: _dayOfYear(now),
      isLoading: false,
      refreshIndex: 0,
      baseQuestion: _defaultFallbackQuestion,
      reserveQuestions: const <String>[],
    );
  }

  final DateTime date;
  final int dayOfYear;
  final bool isLoading;
  final int refreshIndex;
  final String baseQuestion;
  final List<String> reserveQuestions;
  final String? errorMessage;

  String get currentQuestionText {
    if (refreshIndex == 0) {
      return baseQuestion;
    }
    if (refreshIndex == 1 && reserveQuestions.isNotEmpty) {
      return reserveQuestions.first;
    }
    if (refreshIndex == 2 && reserveQuestions.length >= 2) {
      return reserveQuestions[1];
    }
    return baseQuestion;
  }

  bool get canAdvance {
    if (refreshIndex == 0) {
      return reserveQuestions.isNotEmpty;
    }
    if (refreshIndex == 1) {
      return reserveQuestions.length >= 2;
    }
    return false;
  }

  TodayQuestionPromptState copyWith({
    DateTime? date,
    int? dayOfYear,
    bool? isLoading,
    int? refreshIndex,
    String? baseQuestion,
    List<String>? reserveQuestions,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TodayQuestionPromptState(
      date: date ?? this.date,
      dayOfYear: dayOfYear ?? this.dayOfYear,
      isLoading: isLoading ?? this.isLoading,
      refreshIndex: refreshIndex ?? this.refreshIndex,
      baseQuestion: baseQuestion ?? this.baseQuestion,
      reserveQuestions: reserveQuestions ?? this.reserveQuestions,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class TodayQuestionPromptStore extends ValueNotifier<TodayQuestionPromptState> {
  TodayQuestionPromptStore._() : super(TodayQuestionPromptState.initial());

  static final TodayQuestionPromptStore instance = TodayQuestionPromptStore._();
  static const String _refreshKeyPrefix = "today_question_refresh_index_";

  SharedPreferences? _prefs;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      await reloadIfNeeded();
      return;
    }
    _initialized = true;
    _prefs = await SharedPreferences.getInstance();
    await _loadForDate(DateTime.now());
  }

  Future<void> reloadIfNeeded() async {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    if (!_isSameDate(today, value.date)) {
      await _loadForDate(today);
    }
  }

  Future<bool> advanceToNextQuestion() async {
    await initialize();
    await reloadIfNeeded();
    if (!value.canAdvance) {
      return false;
    }
    final int nextIndex = (value.refreshIndex + 1).clamp(0, 2);
    await _prefs!.setInt(_refreshKeyForDate(value.date), nextIndex);
    value = value.copyWith(refreshIndex: nextIndex, clearError: true);
    return true;
  }

  Future<void> _loadForDate(DateTime date) async {
    value = value.copyWith(isLoading: true, clearError: true);
    final DateTime normalized = DateTime(date.year, date.month, date.day);
    final int day = _dayOfYear(normalized);
    final int? saved = _prefs?.getInt(_refreshKeyForDate(normalized));
    final int savedIndex = (saved ?? 0).clamp(0, 2);

    try {
      final Map<String, dynamic>? docData = await _fetchTodayQuestionData(day);
      if (docData == null) {
        value = value.copyWith(
          date: normalized,
          dayOfYear: day,
          isLoading: false,
          refreshIndex: 0,
          baseQuestion: _defaultFallbackQuestion,
          reserveQuestions: const <String>[],
          errorMessage: "오늘 질문 데이터가 없어 기본 질문을 보여줘요.",
        );
        return;
      }

      final String base =
          (docData["base"] as String?)?.trim().isNotEmpty == true
          ? (docData["base"] as String).trim()
          : _defaultFallbackQuestion;
      final List<String> reserves = _parseReserveQuestions(docData["reserve"]);
      final int maxAllowedIndex = reserves.length >= 2
          ? 2
          : reserves.isNotEmpty
          ? 1
          : 0;
      final int normalizedIndex = savedIndex > maxAllowedIndex
          ? maxAllowedIndex
          : savedIndex;
      if (normalizedIndex != savedIndex) {
        await _prefs?.setInt(_refreshKeyForDate(normalized), normalizedIndex);
      }

      value = value.copyWith(
        date: normalized,
        dayOfYear: day,
        isLoading: false,
        refreshIndex: normalizedIndex,
        baseQuestion: base,
        reserveQuestions: reserves,
        clearError: true,
      );
    } catch (_) {
      value = value.copyWith(
        date: normalized,
        dayOfYear: day,
        isLoading: false,
        refreshIndex: 0,
        baseQuestion: _defaultFallbackQuestion,
        reserveQuestions: const <String>[],
        errorMessage: "질문을 불러오지 못해 기본 질문을 보여줘요.",
      );
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

  List<String> _parseReserveQuestions(dynamic raw) {
    if (raw is! List<dynamic>) {
      return const <String>[];
    }
    return raw
        .map((dynamic item) => item.toString().trim())
        .where((String item) => item.isNotEmpty)
        .take(2)
        .toList(growable: false);
  }

  String _refreshKeyForDate(DateTime date) {
    final String mm = date.month.toString().padLeft(2, "0");
    final String dd = date.day.toString().padLeft(2, "0");
    return "$_refreshKeyPrefix${date.year}$mm$dd";
  }

  static bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
