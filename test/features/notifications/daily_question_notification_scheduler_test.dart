// ignore_for_file: depend_on_referenced_packages

import "package:flutter/services.dart";
import "package:flutter_local_notifications/flutter_local_notifications.dart";
import "package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart";
import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";

import "package:dailyquestion/features/more/notification_prefs_keys.dart";
import "package:dailyquestion/features/notifications/daily_question_notification_scheduler.dart";

const MethodChannel _notificationsChannel = MethodChannel(
  "dexterous.com/flutter/local_notifications",
);
const MethodChannel _timezoneChannel = MethodChannel("flutter_timezone");

bool _notificationsEnabled = true;
bool _canScheduleExactNotifications = true;
int _cancelAllCallCount = 0;
List<int> _scheduledNotificationIds = <int>[];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    _notificationsEnabled = true;
    _canScheduleExactNotifications = true;
    _cancelAllCallCount = 0;
    _scheduledNotificationIds = <int>[];
    FlutterLocalNotificationsPlatform.instance =
        AndroidFlutterLocalNotificationsPlugin();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_notificationsChannel, (
          MethodCall methodCall,
        ) async {
          switch (methodCall.method) {
            case "initialize":
              return true;
            case "cancel":
              return null;
            case "cancelAll":
              _cancelAllCallCount++;
              return null;
            case "zonedSchedule":
              final Object? rawArguments = methodCall.arguments;
              if (rawArguments is Map) {
                final Object? id = rawArguments["id"];
                if (id is int) {
                  _scheduledNotificationIds.add(id);
                }
              }
              return null;
            case "pendingNotificationRequests":
              return <Object?>[];
            case "areNotificationsEnabled":
              return _notificationsEnabled;
            case "canScheduleExactNotifications":
              return _canScheduleExactNotifications;
          }
          return null;
        });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_timezoneChannel, (
          MethodCall methodCall,
        ) async {
          return "Asia/Seoul";
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_notificationsChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_timezoneChannel, null);
  });

  test(
    "resets legacy notification preferences to the 3pm default once",
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        NotificationPrefsKeys.todayQuestionEnabled: false,
        NotificationPrefsKeys.todayQuestionHour: 9,
        NotificationPrefsKeys.todayQuestionMinute: 45,
        NotificationPrefsKeys.bucketDdayEnabled: true,
        NotificationPrefsKeys.bucketDdayDaysBefore: 3,
      });

      await initializeDailyQuestionNotificationScheduler();

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getInt(NotificationPrefsKeys.settingsSchemaVersion),
        NotificationPrefsKeys.currentSettingsSchemaVersion,
      );
      expect(prefs.getBool(NotificationPrefsKeys.todayQuestionEnabled), isTrue);
      expect(
        prefs.getInt(NotificationPrefsKeys.todayQuestionHour),
        NotificationPrefsKeys.defaultTodayQuestionHour,
      );
      expect(
        prefs.getInt(NotificationPrefsKeys.todayQuestionMinute),
        NotificationPrefsKeys.defaultTodayQuestionMinute,
      );
      expect(prefs.getBool(NotificationPrefsKeys.bucketDdayEnabled), isFalse);
      expect(
        prefs.getInt(NotificationPrefsKeys.bucketDdayDaysBefore),
        NotificationPrefsKeys.defaultBucketDdayDaysBefore,
      );
      expect(_cancelAllCallCount, 1);
      expect(_scheduledNotificationIds, contains(_dailyQuestionScheduleId));
      expect(_scheduledNotificationIds, contains(_weeklyReportScheduleId));
    },
  );

  test(
    "preserves a user-selected time after the reset migration completed",
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        NotificationPrefsKeys.settingsSchemaVersion:
            NotificationPrefsKeys.currentSettingsSchemaVersion,
        NotificationPrefsKeys.todayQuestionEnabled: true,
        NotificationPrefsKeys.todayQuestionHour: 21,
        NotificationPrefsKeys.todayQuestionMinute: 15,
        NotificationPrefsKeys.bucketDdayEnabled: false,
        NotificationPrefsKeys.bucketDdayDaysBefore:
            NotificationPrefsKeys.defaultBucketDdayDaysBefore,
      });

      await refreshDailyQuestionNotificationSchedulerState();

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(NotificationPrefsKeys.todayQuestionHour), 21);
      expect(prefs.getInt(NotificationPrefsKeys.todayQuestionMinute), 15);
      expect(_cancelAllCallCount, 0);
      expect(_scheduledNotificationIds, contains(_dailyQuestionScheduleId));
    },
  );

  test(
    "daily question notification still schedules without exact alarm permission",
    () async {
      _canScheduleExactNotifications = false;

      SharedPreferences.setMockInitialValues(<String, Object>{
        NotificationPrefsKeys.settingsSchemaVersion:
            NotificationPrefsKeys.currentSettingsSchemaVersion,
        NotificationPrefsKeys.todayQuestionEnabled: true,
        NotificationPrefsKeys.todayQuestionHour: 21,
        NotificationPrefsKeys.todayQuestionMinute: 15,
      });

      await refreshDailyQuestionNotificationSchedulerState();

      expect(_scheduledNotificationIds, contains(_dailyQuestionScheduleId));
    },
  );
}

const int _dailyQuestionScheduleId = 10001;
const int _weeklyReportScheduleId = 10003;
