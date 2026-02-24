import "dart:math";

import "package:flutter/foundation.dart";

class TodayQuestionRecord {
  const TodayQuestionRecord({
    required this.createdAt,
    required this.answer,
    required this.author,
    this.bucketTag,
    this.isPublic = false,
  });

  final DateTime createdAt;
  final String answer;
  final String author;
  final String? bucketTag;
  final bool isPublic;
}

class TodayQuestionStore extends ValueNotifier<List<TodayQuestionRecord>> {
  TodayQuestionStore._() : super(const <TodayQuestionRecord>[]);

  static final TodayQuestionStore instance = TodayQuestionStore._();
  final Random _random = Random();
  static const List<String> _nickAnimals = <String>[
    "호랑이",
    "고양이",
    "여우",
    "펭귄",
    "수달",
    "토끼",
    "고슴도치",
    "참새",
  ];
  static const List<String> _nickTraits = <String>[
    "익명의",
    "웃는",
    "반짝이는",
    "차분한",
    "용감한",
    "느긋한",
    "기분좋은",
  ];

  TodayQuestionRecord? get latestRecord => value.isEmpty ? null : value.first;

  int get consecutiveRecordDays {
    if (value.isEmpty) {
      return 0;
    }
    final Set<DateTime> uniqueDays = value
        .map((TodayQuestionRecord item) => _dateOnly(item.createdAt))
        .toSet();
    final List<DateTime> sorted = uniqueDays.toList()
      ..sort((a, b) => b.compareTo(a));
    if (sorted.isEmpty) {
      return 0;
    }
    int streak = 1;
    DateTime cursor = sorted.first;
    for (int i = 1; i < sorted.length; i++) {
      final DateTime expectedPrev = cursor.subtract(const Duration(days: 1));
      if (_dateOnly(sorted[i]) == _dateOnly(expectedPrev)) {
        streak += 1;
        cursor = sorted[i];
      } else {
        break;
      }
    }
    return streak;
  }

  void saveRecord({
    required String answer,
    required bool isPublic,
    String? bucketTag,
  }) {
    final String normalized = answer.trim();
    if (normalized.isEmpty) {
      return;
    }

    final TodayQuestionRecord next = TodayQuestionRecord(
      createdAt: DateTime.now(),
      answer: normalized,
      author: isPublic ? _buildRandomNickname() : "나의 기록",
      bucketTag: bucketTag,
      isPublic: isPublic,
    );
    value = <TodayQuestionRecord>[next, ...value];
  }

  String _buildRandomNickname() {
    final String trait = _nickTraits[_random.nextInt(_nickTraits.length)];
    final String animal = _nickAnimals[_random.nextInt(_nickAnimals.length)];
    return "$trait $animal님";
  }

  DateTime _dateOnly(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }
}
