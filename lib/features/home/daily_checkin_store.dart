import "package:flutter/foundation.dart";
import "package:isar/isar.dart";

import "../../core/kst_date_time.dart";
import "../../data/local_db/entities/daily_checkin_entity.dart";
import "../../data/local_db/local_database.dart";

class DailyCheckinRecord {
  const DailyCheckinRecord({
    required this.dateKey,
    required this.createdAt,
    required this.updatedAt,
    this.moodIndex,
    this.energyIndex,
    this.stressIndex,
  });

  final String dateKey;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? moodIndex;
  final int? energyIndex;
  final int? stressIndex;

  int? get moodScore => DailyCheckinStore.scoreFromIndex(moodIndex);
  int? get energyScore => DailyCheckinStore.scoreFromIndex(energyIndex);
  int? get stressScore => DailyCheckinStore.scoreFromIndex(stressIndex);

  DailyCheckinRecord copyWith({
    DateTime? createdAt,
    DateTime? updatedAt,
    int? moodIndex,
    int? energyIndex,
    int? stressIndex,
    bool clearMood = false,
    bool clearEnergy = false,
    bool clearStress = false,
  }) {
    return DailyCheckinRecord(
      dateKey: dateKey,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      moodIndex: clearMood ? null : (moodIndex ?? this.moodIndex),
      energyIndex: clearEnergy ? null : (energyIndex ?? this.energyIndex),
      stressIndex: clearStress ? null : (stressIndex ?? this.stressIndex),
    );
  }
}

enum DailyCheckinMetric { mood, energy, stress }

class DailyCheckinStore extends ValueNotifier<DailyCheckinRecord?> {
  DailyCheckinStore._() : super(null);

  static final DailyCheckinStore instance = DailyCheckinStore._();
  bool _initialized = false;

  static int? scoreFromIndex(int? index) {
    if (index == null) {
      return null;
    }
    if (index < 0 || index > 4) {
      return null;
    }
    return 5 - index;
  }

  static int? indexFromScore(int? score) {
    if (score == null) {
      return null;
    }
    if (score < 1 || score > 5) {
      return null;
    }
    return 5 - score;
  }

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    value = await _loadTodayRecord();
    _initialized = true;
  }

  Future<void> reloadToday() async {
    await initialize();
    value = await _loadTodayRecord();
  }

  int? selectedIndexOf(DailyCheckinMetric metric) {
    final DailyCheckinRecord? record = value;
    if (record == null) {
      return null;
    }
    return switch (metric) {
      DailyCheckinMetric.mood => record.moodIndex,
      DailyCheckinMetric.energy => record.energyIndex,
      DailyCheckinMetric.stress => record.stressIndex,
    };
  }

  int? selectedScoreOf(DailyCheckinMetric metric) {
    return scoreFromIndex(selectedIndexOf(metric));
  }

  Future<DailyCheckinRecord> saveSelection({
    required DailyCheckinMetric metric,
    required int selectedIndex,
  }) async {
    await initialize();
    if (selectedIndex < 0 || selectedIndex > 4) {
      throw ArgumentError("selectedIndex must be between 0 and 4");
    }

    final DateTime now = DateTime.now();
    final String todayKey = kstDateKeyNow();
    final DailyCheckinRecord current =
        (value != null && value!.dateKey == todayKey)
        ? value!
        : DailyCheckinRecord(dateKey: todayKey, createdAt: now, updatedAt: now);
    final DailyCheckinRecord next = switch (metric) {
      DailyCheckinMetric.mood => current.copyWith(
        moodIndex: selectedIndex,
        updatedAt: now,
      ),
      DailyCheckinMetric.energy => current.copyWith(
        energyIndex: selectedIndex,
        updatedAt: now,
      ),
      DailyCheckinMetric.stress => current.copyWith(
        stressIndex: selectedIndex,
        updatedAt: now,
      ),
    };

    value = next;
    await _upsert(next);
    return next;
  }

  Future<DailyCheckinRecord?> _loadTodayRecord() async {
    final isar = await LocalDatabase.instance.isar;
    final String todayKey = kstDateKeyNow();
    final DailyCheckinEntity? entity = await isar.dailyCheckinEntitys
        .where()
        .dateKeyEqualTo(todayKey)
        .findFirst();
    if (entity != null) {
      return _toRecord(entity);
    }
    // Backward compatibility for previously double-shifted keys.
    final String legacyKey = kstDateKeyFromDateTime(nowInKst());
    if (legacyKey == todayKey) {
      return null;
    }
    final DailyCheckinEntity? legacyEntity = await isar.dailyCheckinEntitys
        .where()
        .dateKeyEqualTo(legacyKey)
        .findFirst();
    if (legacyEntity == null) {
      return null;
    }
    return DailyCheckinRecord(
      dateKey: todayKey,
      createdAt: legacyEntity.createdAt,
      updatedAt: legacyEntity.updatedAt,
      moodIndex: legacyEntity.moodIndex,
      energyIndex: legacyEntity.energyIndex,
      stressIndex: legacyEntity.stressIndex,
    );
  }

  DailyCheckinRecord _toRecord(DailyCheckinEntity entity) {
    return DailyCheckinRecord(
      dateKey: entity.dateKey,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      moodIndex: entity.moodIndex,
      energyIndex: entity.energyIndex,
      stressIndex: entity.stressIndex,
    );
  }

  Future<void> _upsert(DailyCheckinRecord record) async {
    final isar = await LocalDatabase.instance.isar;
    final DailyCheckinEntity entity = DailyCheckinEntity()
      ..dateKey = record.dateKey
      ..createdAt = record.createdAt
      ..updatedAt = record.updatedAt
      ..moodIndex = record.moodIndex
      ..energyIndex = record.energyIndex
      ..stressIndex = record.stressIndex;
    await isar.writeTxn(() async {
      await isar.dailyCheckinEntitys.put(entity);
    });
  }
}
