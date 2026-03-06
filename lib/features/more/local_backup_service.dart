import "dart:convert";
import "dart:io";

import "package:isar/isar.dart";
import "package:path_provider/path_provider.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../../data/local_db/entities/answer_record_entity.dart";
import "../../data/local_db/entities/bucket_category_entity.dart";
import "../../data/local_db/entities/bucket_item_entity.dart";
import "../../data/local_db/entities/daily_checkin_entity.dart";
import "../../data/local_db/entities/user_profile_entity.dart";
import "../../data/local_db/local_database.dart";

class LocalBackupException implements Exception {
  const LocalBackupException(this.message);

  final String message;

  @override
  String toString() => "LocalBackupException: $message";
}

class LocalBackupService {
  LocalBackupService._();

  static final LocalBackupService instance = LocalBackupService._();

  static const int _formatVersion = 1;

  Future<File> exportBackupFile() async {
    final Isar isar = await LocalDatabase.instance.isar;
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final List<AnswerRecordEntity> answers = await isar.answerRecordEntitys
        .where()
        .findAll();
    final List<BucketItemEntity> bucketItems = await isar.bucketItemEntitys
        .where()
        .findAll();
    final List<BucketCategoryEntity> bucketCategories = await isar
        .bucketCategoryEntitys
        .where()
        .findAll();
    final List<DailyCheckinEntity> dailyCheckins = await isar
        .dailyCheckinEntitys
        .where()
        .findAll();
    final List<UserProfileEntity> userProfiles = await isar.userProfileEntitys
        .where()
        .findAll();

    final Map<String, dynamic> payload = <String, dynamic>{
      "formatVersion": _formatVersion,
      "exportedAt": DateTime.now().toUtc().toIso8601String(),
      "answerRecords": answers.map(_answerToJson).toList(growable: false),
      "bucketItems": bucketItems.map(_bucketItemToJson).toList(growable: false),
      "bucketCategories": bucketCategories
          .map(_bucketCategoryToJson)
          .toList(growable: false),
      "dailyCheckins": dailyCheckins
          .map(_dailyCheckinToJson)
          .toList(growable: false),
      "userProfiles": userProfiles
          .map(_userProfileToJson)
          .toList(growable: false),
      "sharedPreferences": _collectPrefs(prefs),
    };

    final Directory tempDir = await getTemporaryDirectory();
    final DateTime now = DateTime.now();
    final String fileName =
        "dailyquestion_backup_${now.year.toString().padLeft(4, "0")}"
        "${now.month.toString().padLeft(2, "0")}"
        "${now.day.toString().padLeft(2, "0")}_"
        "${now.hour.toString().padLeft(2, "0")}"
        "${now.minute.toString().padLeft(2, "0")}"
        "${now.second.toString().padLeft(2, "0")}.json";
    final File output = File("${tempDir.path}/$fileName");
    await output.writeAsString(jsonEncode(payload));
    return output;
  }

  Future<void> restoreFromRawJson(String rawJson) async {
    final dynamic decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, dynamic>) {
      throw const LocalBackupException("백업 파일 형식이 올바르지 않아요.");
    }

    final int? formatVersion = _asInt(decoded["formatVersion"]);
    if (formatVersion != _formatVersion) {
      throw const LocalBackupException("지원하지 않는 백업 파일 버전이에요.");
    }

    final List<AnswerRecordEntity> answers = _parseAnswerRecords(
      decoded["answerRecords"],
    );
    final List<BucketItemEntity> bucketItems = _parseBucketItems(
      decoded["bucketItems"],
    );
    final List<BucketCategoryEntity> bucketCategories = _parseBucketCategories(
      decoded["bucketCategories"],
    );
    final List<DailyCheckinEntity> dailyCheckins = _parseDailyCheckins(
      decoded["dailyCheckins"],
    );
    final List<UserProfileEntity> userProfiles = _parseUserProfiles(
      decoded["userProfiles"],
    );
    final Map<String, dynamic> prefsMap = _parsePrefsMap(
      decoded["sharedPreferences"],
    );

    final Isar isar = await LocalDatabase.instance.isar;
    await isar.writeTxn(() async {
      await isar.answerRecordEntitys.clear();
      if (answers.isNotEmpty) {
        await isar.answerRecordEntitys.putAll(answers);
      }

      await isar.bucketItemEntitys.clear();
      if (bucketItems.isNotEmpty) {
        await isar.bucketItemEntitys.putAll(bucketItems);
      }

      await isar.bucketCategoryEntitys.clear();
      if (bucketCategories.isNotEmpty) {
        await isar.bucketCategoryEntitys.putAll(bucketCategories);
      }

      await isar.dailyCheckinEntitys.clear();
      if (dailyCheckins.isNotEmpty) {
        await isar.dailyCheckinEntitys.putAll(dailyCheckins);
      }

      await isar.userProfileEntitys.clear();
      if (userProfiles.isNotEmpty) {
        await isar.userProfileEntitys.putAll(userProfiles);
      }
    });

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    for (final MapEntry<String, dynamic> entry in prefsMap.entries) {
      final dynamic value = entry.value;
      if (value is bool) {
        await prefs.setBool(entry.key, value);
      } else if (value is int) {
        await prefs.setInt(entry.key, value);
      } else if (value is double) {
        await prefs.setDouble(entry.key, value);
      } else if (value is String) {
        await prefs.setString(entry.key, value);
      } else if (value is List<String>) {
        await prefs.setStringList(entry.key, value);
      }
    }
  }

  Future<void> restoreFromFilePath(String path) async {
    final File file = File(path);
    if (!await file.exists()) {
      throw const LocalBackupException("선택한 백업 파일을 찾을 수 없어요.");
    }
    final String raw = await file.readAsString();
    await restoreFromRawJson(raw);
  }

  Map<String, dynamic> _collectPrefs(SharedPreferences prefs) {
    final Map<String, dynamic> map = <String, dynamic>{};
    for (final String key in prefs.getKeys()) {
      final Object? value = prefs.get(key);
      if (value is bool ||
          value is int ||
          value is double ||
          value is String ||
          value is List<String>) {
        map[key] = value;
      }
    }
    return map;
  }

  Map<String, dynamic> _answerToJson(AnswerRecordEntity item) {
    return <String, dynamic>{
      "id": item.id,
      "createdAtMillis": item.createdAtMillis,
      "createdAt": item.createdAt.toUtc().toIso8601String(),
      "answer": item.answer,
      "author": item.author,
      "bucketTag": item.bucketTag,
      "bucketTags": item.bucketTags,
      "isPublic": item.isPublic,
      "questionSlot": item.questionSlot,
      "questionDayOfYear": item.questionDayOfYear,
      "questionDateKey": item.questionDateKey,
      "questionText": item.questionText,
      "moodScore5": item.moodScore5,
      "energyScore5": item.energyScore5,
      "stressScore5": item.stressScore5,
      "updatedAt": item.updatedAt.toUtc().toIso8601String(),
    };
  }

  Map<String, dynamic> _bucketItemToJson(BucketItemEntity item) {
    return <String, dynamic>{
      "id": item.id,
      "title": item.title,
      "category": item.category,
      "categoryColorValue": item.categoryColorValue,
      "createdAt": item.createdAt.toUtc().toIso8601String(),
      "dueDate": item.dueDate?.toUtc().toIso8601String(),
      "isCompleted": item.isCompleted,
      "updatedAt": item.updatedAt.toUtc().toIso8601String(),
    };
  }

  Map<String, dynamic> _bucketCategoryToJson(BucketCategoryEntity item) {
    return <String, dynamic>{
      "id": item.id,
      "name": item.name,
      "colorValue": item.colorValue,
    };
  }

  Map<String, dynamic> _dailyCheckinToJson(DailyCheckinEntity item) {
    return <String, dynamic>{
      "id": item.id,
      "dateKey": item.dateKey,
      "createdAt": item.createdAt.toUtc().toIso8601String(),
      "updatedAt": item.updatedAt.toUtc().toIso8601String(),
      "moodIndex": item.moodIndex,
      "energyIndex": item.energyIndex,
      "stressIndex": item.stressIndex,
    };
  }

  Map<String, dynamic> _userProfileToJson(UserProfileEntity item) {
    return <String, dynamic>{
      "id": item.id,
      "key": item.key,
      "value": item.value,
    };
  }

  List<AnswerRecordEntity> _parseAnswerRecords(dynamic raw) {
    if (raw is! List) {
      return <AnswerRecordEntity>[];
    }
    return raw
        .whereType<Map<String, dynamic>>()
        .map((Map<String, dynamic> json) {
          final AnswerRecordEntity item = AnswerRecordEntity();
          item.id = _asInt(json["id"]) ?? Isar.autoIncrement;
          item.createdAtMillis =
              _asInt(json["createdAtMillis"]) ??
              (_parseDateTime(json["createdAt"])?.millisecondsSinceEpoch ??
                  DateTime.now().millisecondsSinceEpoch);
          item.createdAt = _parseDateTime(json["createdAt"]) ?? DateTime.now();
          item.answer = "${json["answer"] ?? ""}";
          item.author = "${json["author"] ?? ""}";
          item.bucketTag = json["bucketTag"] as String?;
          item.bucketTags = (json["bucketTags"] is List)
              ? (json["bucketTags"] as List)
                    .map((dynamic e) => "$e")
                    .toList(growable: false)
              : <String>[];
          item.isPublic = json["isPublic"] == true;
          item.questionSlot = _asInt(json["questionSlot"]) ?? 0;
          item.questionDayOfYear = _asInt(json["questionDayOfYear"]);
          item.questionDateKey = "${json["questionDateKey"] ?? ""}";
          item.questionText = json["questionText"] as String?;
          item.moodScore5 = _asInt(json["moodScore5"]);
          item.energyScore5 = _asInt(json["energyScore5"]);
          item.stressScore5 = _asInt(json["stressScore5"]);
          item.updatedAt = _parseDateTime(json["updatedAt"]) ?? item.createdAt;
          return item;
        })
        .toList(growable: false);
  }

  List<BucketItemEntity> _parseBucketItems(dynamic raw) {
    if (raw is! List) {
      return <BucketItemEntity>[];
    }
    return raw
        .whereType<Map<String, dynamic>>()
        .map((Map<String, dynamic> json) {
          final BucketItemEntity item = BucketItemEntity();
          item.id = _asInt(json["id"]) ?? Isar.autoIncrement;
          item.title = "${json["title"] ?? ""}";
          item.category = "${json["category"] ?? ""}";
          item.categoryColorValue = _asInt(json["categoryColorValue"]) ?? 0;
          item.createdAt = _parseDateTime(json["createdAt"]) ?? DateTime.now();
          item.dueDate = _parseDateTime(json["dueDate"]);
          item.isCompleted = json["isCompleted"] == true;
          item.updatedAt = _parseDateTime(json["updatedAt"]) ?? item.createdAt;
          return item;
        })
        .toList(growable: false);
  }

  List<BucketCategoryEntity> _parseBucketCategories(dynamic raw) {
    if (raw is! List) {
      return <BucketCategoryEntity>[];
    }
    return raw
        .whereType<Map<String, dynamic>>()
        .map((Map<String, dynamic> json) {
          final BucketCategoryEntity item = BucketCategoryEntity();
          item.id = _asInt(json["id"]) ?? Isar.autoIncrement;
          item.name = "${json["name"] ?? ""}";
          item.colorValue = _asInt(json["colorValue"]) ?? 0;
          return item;
        })
        .toList(growable: false);
  }

  List<DailyCheckinEntity> _parseDailyCheckins(dynamic raw) {
    if (raw is! List) {
      return <DailyCheckinEntity>[];
    }
    return raw
        .whereType<Map<String, dynamic>>()
        .map((Map<String, dynamic> json) {
          final DailyCheckinEntity item = DailyCheckinEntity();
          item.id = _asInt(json["id"]) ?? Isar.autoIncrement;
          item.dateKey = "${json["dateKey"] ?? ""}";
          item.createdAt = _parseDateTime(json["createdAt"]) ?? DateTime.now();
          item.updatedAt = _parseDateTime(json["updatedAt"]) ?? item.createdAt;
          item.moodIndex = _asInt(json["moodIndex"]);
          item.energyIndex = _asInt(json["energyIndex"]);
          item.stressIndex = _asInt(json["stressIndex"]);
          return item;
        })
        .toList(growable: false);
  }

  List<UserProfileEntity> _parseUserProfiles(dynamic raw) {
    if (raw is! List) {
      return <UserProfileEntity>[];
    }
    return raw
        .whereType<Map<String, dynamic>>()
        .map((Map<String, dynamic> json) {
          final UserProfileEntity item = UserProfileEntity();
          item.id = _asInt(json["id"]) ?? Isar.autoIncrement;
          item.key = "${json["key"] ?? ""}";
          item.value = "${json["value"] ?? ""}";
          return item;
        })
        .toList(growable: false);
  }

  Map<String, dynamic> _parsePrefsMap(dynamic raw) {
    if (raw is! Map) {
      return <String, dynamic>{};
    }
    final Map<String, dynamic> map = <String, dynamic>{};
    raw.forEach((dynamic key, dynamic value) {
      final String normalizedKey = "$key";
      if (value is bool || value is int || value is double || value is String) {
        map[normalizedKey] = value;
      } else if (value is List) {
        map[normalizedKey] = value.map((dynamic e) => "$e").toList();
      }
    });
    return map;
  }

  int? _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value)?.toLocal();
    }
    return null;
  }
}
