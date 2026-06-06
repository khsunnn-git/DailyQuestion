import "package:isar_community/isar.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../../data/local_db/entities/answer_record_entity.dart";
import "../../data/local_db/entities/bucket_category_entity.dart";
import "../../data/local_db/entities/bucket_item_entity.dart";
import "../../data/local_db/entities/daily_checkin_entity.dart";
import "../../data/local_db/entities/user_profile_entity.dart";
import "../../data/local_db/local_database.dart";
import "../auth/auth_service.dart";
import "../auth/social_login_store.dart";
import "../bucket/bucket_backup_service.dart";
import "../home/daily_checkin_backup_service.dart";
import "../home/daily_checkin_store.dart";
import "../notifications/daily_question_notification_scheduler.dart";
import "../question/public_answer_uploader.dart";
import "../question/today_question_store.dart";
import "../question/user_answer_backup_service.dart";
import "notification_prefs_keys.dart";

class DataManagementException implements Exception {
  const DataManagementException(this.message);

  final String message;
}

class DataManagementService {
  DataManagementService._();

  static final DataManagementService instance = DataManagementService._();

  static const String _bucketDdayNotificationIdsKey =
      "bucket_dday_notification_ids";
  static const String _dailyQuestionCatchupSlotKey =
      "notification_daily_question_catchup_slot";
  static const String _legacyNicknamePrefKey = "user_nickname";
  static const String _nicknamePrefKey = "nickname";
  static const String _myRecordsInstallMonthKey = "my_records_install_month";
  static const String _myRecordsInstallDateKey = "my_records_install_date";
  static const String _myRecordsInstallSchemaKey =
      "my_records_install_date_schema_version";
  static const String _legacyNotificationPermissionRequestedKey =
      "notification_permission_onboarding_requested";
  static const String _polishDraftsKey = "question_polish_drafts_v1";
  static const String _todayQuestionCachePrefix = "today_question_cache_";

  Future<void> deleteDeviceData() async {
    try {
      await _clearLocalData();
      await AuthService.instance.clearCurrentSession();
    } on AuthActionException catch (error) {
      throw DataManagementException(error.userMessage);
    } catch (_) {
      throw const DataManagementException(
        "이 기기 데이터를 삭제하지 못했어요. 잠시 후 다시 시도해주세요.",
      );
    }
  }

  Future<void> deleteAllData() async {
    final String? uid = AuthService.instance.currentUser?.uid;
    try {
      await deleteRemoteUserAnswerBackup(uid: uid);
      await deleteRemoteBucketBackup(uid: uid);
      await deleteRemoteDailyCheckinBackup(uid: uid);
      await PublicAnswerUploader.instance.deleteAllOwnedAnswers(uid: uid);
      await _clearLocalData();
      await AuthService.instance.clearCurrentSession();
    } on AuthActionException catch (error) {
      throw DataManagementException(error.userMessage);
    } catch (_) {
      throw const DataManagementException(
        "모든 데이터를 삭제하지 못했어요. 네트워크 상태를 확인한 뒤 다시 시도해주세요.",
      );
    }
  }

  Future<void> _clearLocalData() async {
    await cancelDailyQuestionNotificationSchedule();
    await syncBucketDdayNotificationSchedule(
      enabled: false,
      daysBefore: NotificationPrefsKeys.defaultBucketDdayDaysBefore,
    );

    final Isar isar = await LocalDatabase.instance.isar;
    await isar.writeTxn(() async {
      await isar.answerRecordEntitys.clear();
      await isar.bucketItemEntitys.clear();
      await isar.bucketCategoryEntitys.clear();
      await isar.dailyCheckinEntitys.clear();
      await isar.userProfileEntitys.clear();
    });

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> keys = prefs.getKeys().toList(growable: false);
    for (final String key in keys) {
      if (_shouldRemovePreference(key)) {
        await prefs.remove(key);
      }
    }

    await SocialLoginStore.instance.clearRecentProvider();
    await PublicAnswerUploader.instance.clearDeviceAnonId();
    await TodayQuestionStore.instance.reloadFromDatabase();
    await DailyCheckinStore.instance.reloadToday();
  }

  bool _shouldRemovePreference(String key) {
    if (key.startsWith(_todayQuestionCachePrefix)) {
      return true;
    }

    return key == NotificationPrefsKeys.todayQuestionEnabled ||
        key == NotificationPrefsKeys.settingsSchemaVersion ||
        key == NotificationPrefsKeys.todayQuestionHour ||
        key == NotificationPrefsKeys.todayQuestionMinute ||
        key == NotificationPrefsKeys.bucketDdayEnabled ||
        key == NotificationPrefsKeys.bucketDdayDaysBefore ||
        key == _legacyNotificationPermissionRequestedKey ||
        key == _bucketDdayNotificationIdsKey ||
        key == _dailyQuestionCatchupSlotKey ||
        key == "bucket_backup_has_synced" ||
        key == "daily_checkin_backup_has_synced" ||
        key == _legacyNicknamePrefKey ||
        key == _nicknamePrefKey ||
        key == _myRecordsInstallMonthKey ||
        key == _myRecordsInstallDateKey ||
        key == _myRecordsInstallSchemaKey ||
        key == _polishDraftsKey;
  }
}
