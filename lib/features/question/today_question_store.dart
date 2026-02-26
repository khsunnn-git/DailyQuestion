import "dart:math";

import "package:flutter/foundation.dart";
import "package:isar/isar.dart";

import "../../data/local_db/entities/answer_record_entity.dart";
import "../../data/local_db/local_database.dart";
import "public_answer_uploader.dart";

class TodayQuestionRecord {
  const TodayQuestionRecord({
    required this.createdAt,
    required this.answer,
    required this.author,
    this.bucketTag,
    this.bucketTags = const <String>[],
    this.isPublic = false,
    this.questionSlot = 0,
    this.questionDateKey,
    this.questionText,
  });

  final DateTime createdAt;
  final String answer;
  final String author;
  final String? bucketTag;
  final List<String> bucketTags;
  final bool isPublic;
  final int questionSlot;
  final String? questionDateKey;
  final String? questionText;
}

class TodayQuestionStore extends ValueNotifier<List<TodayQuestionRecord>> {
  TodayQuestionStore._() : super(const <TodayQuestionRecord>[]);

  static final TodayQuestionStore instance = TodayQuestionStore._();
  final Random _random = Random();
  bool _initialized = false;
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

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    final isar = await LocalDatabase.instance.isar;
    final List<AnswerRecordEntity> entities = await isar.answerRecordEntitys
        .where()
        .findAll();
    final List<TodayQuestionRecord> loaded =
        entities.map(_toRecord).toList(growable: false)
          ..sort((TodayQuestionRecord a, TodayQuestionRecord b) {
            return b.createdAt.compareTo(a.createdAt);
          });
    value = loaded;
    _initialized = true;
  }

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

  List<bool> weeklyCompletion({DateTime? referenceDate}) {
    final DateTime reference = referenceDate ?? DateTime.now();
    final DateTime monday = _dateOnly(
      reference.subtract(Duration(days: reference.weekday - 1)),
    );
    final Set<DateTime> recordedDays = value
        .map((TodayQuestionRecord item) => _dateOnly(item.createdAt))
        .toSet();
    return List<bool>.generate(7, (int index) {
      final DateTime day = monday.add(Duration(days: index));
      return recordedDays.contains(day);
    }, growable: false);
  }

  Future<TodayQuestionRecord> saveRecord({
    required String answer,
    required bool isPublic,
    String? bucketTag,
    List<String> bucketTags = const <String>[],
    DateTime? createdAt,
    int? questionSlot,
    String? questionDateKey,
    String? questionText,
  }) async {
    await initialize();
    final String normalized = answer.trim();
    if (normalized.isEmpty) {
      throw ArgumentError("answer must not be empty");
    }
    final List<String> normalizedTags = bucketTags
        .map((String item) => item.trim())
        .where((String item) => item.isNotEmpty)
        .toList(growable: false);
    final String? resolvedBucketTag = normalizedTags.isNotEmpty
        ? normalizedTags.last
        : bucketTag?.trim();
    final DateTime resolvedCreatedAt = createdAt ?? DateTime.now();
    final int resolvedQuestionSlot = _normalizeSlot(questionSlot ?? 0);
    final String resolvedQuestionDateKey =
        questionDateKey ?? _dateKey(resolvedCreatedAt);

    if (createdAt != null) {
      final int existingIndex = value.indexWhere(
        (TodayQuestionRecord item) =>
            _dateOnly(item.createdAt) == _dateOnly(resolvedCreatedAt),
      );
      if (existingIndex >= 0) {
        final TodayQuestionRecord existing = value[existingIndex];
        final TodayQuestionRecord updated = TodayQuestionRecord(
          createdAt: existing.createdAt,
          answer: normalized,
          author: isPublic
              ? (existing.isPublic ? existing.author : _buildRandomNickname())
              : "나의 기록",
          bucketTag: resolvedBucketTag,
          bucketTags: normalizedTags,
          isPublic: isPublic,
          questionSlot: questionSlot == null
              ? existing.questionSlot
              : resolvedQuestionSlot,
          questionDateKey: questionDateKey ?? existing.questionDateKey,
          questionText: questionText ?? existing.questionText,
        );
        final List<TodayQuestionRecord> next = List<TodayQuestionRecord>.from(
          value,
        );
        next[existingIndex] = updated;
        value = next;
        await _upsertRecord(updated);
        await _syncPublicAnswer(updated);
        return updated;
      }
    }

    final TodayQuestionRecord next = TodayQuestionRecord(
      createdAt: resolvedCreatedAt,
      answer: normalized,
      author: isPublic ? _buildRandomNickname() : "나의 기록",
      bucketTag: resolvedBucketTag,
      bucketTags: normalizedTags,
      isPublic: isPublic,
      questionSlot: resolvedQuestionSlot,
      questionDateKey: resolvedQuestionDateKey,
      questionText: questionText,
    );
    final List<TodayQuestionRecord> merged =
        <TodayQuestionRecord>[next, ...value]
          ..sort((TodayQuestionRecord a, TodayQuestionRecord b) {
            return b.createdAt.compareTo(a.createdAt);
          });
    value = merged;
    await _upsertRecord(next);
    await _syncPublicAnswer(next);
    return next;
  }

  Future<TodayQuestionRecord?> updateRecord({
    required DateTime createdAt,
    required String answer,
    required bool isPublic,
    List<String> bucketTags = const <String>[],
  }) async {
    await initialize();
    final String normalizedAnswer = answer.trim();
    if (normalizedAnswer.isEmpty) {
      return null;
    }
    final List<String> normalizedTags = bucketTags
        .map((String item) => item.trim())
        .where((String item) => item.isNotEmpty)
        .toList(growable: false);

    TodayQuestionRecord? updatedRecord;
    final List<TodayQuestionRecord> next = value
        .map((TodayQuestionRecord item) {
          if (updatedRecord != null || item.createdAt != createdAt) {
            return item;
          }
          final TodayQuestionRecord updated = TodayQuestionRecord(
            createdAt: item.createdAt,
            answer: normalizedAnswer,
            author: isPublic
                ? (item.isPublic ? item.author : _buildRandomNickname())
                : "나의 기록",
            bucketTag: normalizedTags.isEmpty ? null : normalizedTags.last,
            bucketTags: normalizedTags,
            isPublic: isPublic,
            questionSlot: item.questionSlot,
            questionDateKey: item.questionDateKey,
            questionText: item.questionText,
          );
          updatedRecord = updated;
          return updated;
        })
        .toList(growable: false);

    if (updatedRecord != null) {
      value = next;
      await _upsertRecord(updatedRecord!);
      await _syncPublicAnswer(updatedRecord!);
    }
    return updatedRecord;
  }

  Future<bool> deleteRecord({required DateTime createdAt}) async {
    await initialize();
    TodayQuestionRecord? target;
    for (final TodayQuestionRecord item in value) {
      if (item.createdAt == createdAt) {
        target = item;
        break;
      }
    }
    final int beforeCount = value.length;
    value = value
        .where((TodayQuestionRecord item) => item.createdAt != createdAt)
        .toList(growable: false);
    final bool removed = value.length != beforeCount;
    if (removed) {
      await _deleteRecordByCreatedAt(createdAt);
      if (target != null) {
        final String questionDateKey =
            target.questionDateKey ?? _dateKey(target.createdAt);
        await PublicAnswerUploader.instance.delete(
          createdAt: target.createdAt,
          questionDateKey: questionDateKey,
          questionSlot: _normalizeSlot(target.questionSlot),
        );
      }
    }
    return removed;
  }

  Future<void> updateRecordBucketTags({
    required DateTime createdAt,
    required List<String> bucketTags,
  }) async {
    await initialize();
    final List<String> normalizedTags = bucketTags
        .map((String item) => item.trim())
        .where((String item) => item.isNotEmpty)
        .toList(growable: false);

    bool updated = false;
    TodayQuestionRecord? updatedRecord;
    final List<TodayQuestionRecord> next = value
        .map((TodayQuestionRecord item) {
          if (updated || item.createdAt != createdAt) {
            return item;
          }
          updated = true;
          updatedRecord = TodayQuestionRecord(
            createdAt: item.createdAt,
            answer: item.answer,
            author: item.author,
            bucketTag: normalizedTags.isEmpty ? null : normalizedTags.last,
            bucketTags: normalizedTags,
            isPublic: item.isPublic,
            questionSlot: item.questionSlot,
            questionDateKey: item.questionDateKey,
            questionText: item.questionText,
          );
          return updatedRecord!;
        })
        .toList(growable: false);

    if (updated) {
      value = next;
      await _upsertRecord(updatedRecord!);
      await _syncPublicAnswer(updatedRecord!);
    }
  }

  Future<void> _syncPublicAnswer(TodayQuestionRecord record) async {
    try {
      await PublicAnswerUploader.instance.sync(
        PublicAnswerPayload(
          createdAt: record.createdAt,
          questionDateKey: record.questionDateKey ?? _dateKey(record.createdAt),
          questionSlot: _normalizeSlot(record.questionSlot),
          answer: record.answer,
          author: record.author,
          questionText: record.questionText,
          bucketTags: List<String>.from(record.bucketTags),
          isPublic: record.isPublic,
        ),
      );
    } catch (_) {
      // Keep local save successful even when public sync fails.
    }
  }

  Future<void> _upsertRecord(TodayQuestionRecord record) async {
    final isar = await LocalDatabase.instance.isar;
    await isar.writeTxn(() async {
      final AnswerRecordEntity? existing = await isar.answerRecordEntitys
          .filter()
          .createdAtMillisEqualTo(record.createdAt.millisecondsSinceEpoch)
          .findFirst();
      final AnswerRecordEntity entity = existing ?? AnswerRecordEntity();
      if (existing != null) {
        entity.id = existing.id;
      }
      entity.createdAtMillis = record.createdAt.millisecondsSinceEpoch;
      entity.createdAt = record.createdAt;
      entity.answer = record.answer;
      entity.author = record.author;
      entity.bucketTag = record.bucketTag;
      entity.bucketTags = List<String>.from(record.bucketTags);
      entity.isPublic = record.isPublic;
      entity.questionSlot = _normalizeSlot(record.questionSlot);
      entity.questionDateKey =
          record.questionDateKey ?? _dateKey(record.createdAt);
      entity.questionText = record.questionText;
      entity.updatedAt = DateTime.now();
      await isar.answerRecordEntitys.put(entity);
    });
  }

  Future<void> _deleteRecordByCreatedAt(DateTime createdAt) async {
    final isar = await LocalDatabase.instance.isar;
    await isar.writeTxn(() async {
      final AnswerRecordEntity? entity = await isar.answerRecordEntitys
          .filter()
          .createdAtMillisEqualTo(createdAt.millisecondsSinceEpoch)
          .findFirst();
      if (entity == null) {
        return;
      }
      await isar.answerRecordEntitys.delete(entity.id);
    });
  }

  TodayQuestionRecord _toRecord(AnswerRecordEntity entity) {
    return TodayQuestionRecord(
      createdAt: entity.createdAt,
      answer: entity.answer,
      author: entity.author,
      bucketTag: entity.bucketTag,
      bucketTags: List<String>.from(entity.bucketTags),
      isPublic: entity.isPublic,
      questionSlot: _normalizeSlot(entity.questionSlot),
      questionDateKey: entity.questionDateKey,
      questionText: entity.questionText,
    );
  }

  String _buildRandomNickname() {
    final String trait = _nickTraits[_random.nextInt(_nickTraits.length)];
    final String animal = _nickAnimals[_random.nextInt(_nickAnimals.length)];
    return "$trait $animal님";
  }

  DateTime _dateOnly(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }

  int _normalizeSlot(int slot) {
    return slot.clamp(0, 2);
  }

  String _dateKey(DateTime dateTime) {
    final String mm = dateTime.month.toString().padLeft(2, "0");
    final String dd = dateTime.day.toString().padLeft(2, "0");
    return "${dateTime.year}$mm$dd";
  }
}
