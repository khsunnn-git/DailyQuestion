import "dart:async";

import "package:flutter/foundation.dart";
import "package:flutter_local_notifications/flutter_local_notifications.dart";
import "package:flutter_timezone/flutter_timezone.dart";
import "package:isar/isar.dart";
import "package:permission_handler/permission_handler.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:timezone/data/latest.dart" as tz_data;
import "package:timezone/timezone.dart" as tz;

import "../../data/local_db/entities/bucket_item_entity.dart";
import "../../data/local_db/local_database.dart";
import "../more/notification_prefs_keys.dart";

const int _dailyQuestionNotificationId = 10001;
const int _dailyQuestionCatchupNotificationId = 10002;
const int _weeklyReportNotificationId = 10003;
const int _bucketDdayNotificationBaseId = 200000;
const String _bucketDdayNotificationIdsKey = "bucket_dday_notification_ids";

const AndroidNotificationDetails _androidNotificationDetails =
    AndroidNotificationDetails(
      "daily_question_channel_v3",
      "오늘의 질문 알림",
      channelDescription: "오늘의 질문 알림을 매일 지정된 시간에 전송합니다.",
      // Android small icons need a solid alpha-only asset to render correctly.
      icon: "ic_noti_question_small",
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

const DarwinNotificationDetails _darwinNotificationDetails =
    DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

const NotificationDetails _notificationDetails = NotificationDetails(
  android: _androidNotificationDetails,
  iOS: _darwinNotificationDetails,
);

final FlutterLocalNotificationsPlugin _notifications =
    FlutterLocalNotificationsPlugin();

bool _initialized = false;

void _logNotification(String message) {
  if (kDebugMode) {
    debugPrint("[notifications] $message");
  }
}

Future<void> initializeDailyQuestionNotificationScheduler() async {
  _logNotification("initialize scheduler");
  await _ensureInitialized();
  final bool hasNotificationPermission =
      await _ensureNotificationPermissionOnFirstLaunch();
  await _restoreSchedulesFromPrefs(
    hasNotificationPermission: hasNotificationPermission,
  );
}

Future<bool> areNotificationsEnabledOnDevice() async {
  if (kIsWeb) {
    return false;
  }
  await _ensureInitialized();

  if (defaultTargetPlatform == TargetPlatform.android) {
    try {
      final bool? enabled = await _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.areNotificationsEnabled();
      if (enabled != null) {
        return enabled;
      }
    } catch (_) {}
  }

  try {
    final PermissionStatus status = await Permission.notification.status;
    return _isNotificationPermissionGranted(status);
  } catch (_) {
    return false;
  }
}

Future<bool> requestNotificationPermissionOnDevice() async {
  if (kIsWeb) {
    return false;
  }
  await _ensureInitialized();

  if (defaultTargetPlatform == TargetPlatform.iOS) {
    try {
      final bool? granted = await _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? false;
    } catch (_) {
      return false;
    }
  }

  if (defaultTargetPlatform == TargetPlatform.android) {
    try {
      final bool? granted = await _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      if (granted != null) {
        return granted;
      }
    } catch (_) {}
  }

  try {
    final PermissionStatus status = await Permission.notification.request();
    return _isNotificationPermissionGranted(status);
  } catch (_) {
    return false;
  }
}

Future<bool> canScheduleExactAlarmsOnDevice() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
    return true;
  }
  await _ensureInitialized();
  try {
    final bool? canSchedule = await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.canScheduleExactNotifications();
    return canSchedule ?? false;
  } catch (_) {
    return false;
  }
}

Future<bool> requestExactAlarmPermissionOnDevice() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
    return true;
  }
  await _ensureInitialized();
  try {
    final bool? granted = await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestExactAlarmsPermission();
    if (granted != null) {
      return granted;
    }
  } catch (_) {}
  return canScheduleExactAlarmsOnDevice();
}

Future<void> syncWeeklyReportNotificationSchedule({
  required bool enabled,
}) async {
  await _ensureInitialized();
  await _notifications.cancel(_weeklyReportNotificationId);
  if (!enabled) {
    _logNotification("weekly report schedule canceled because enabled=false");
    return;
  }
  await _scheduleWeeklyReportNotification();
}

Future<void> updateDailyQuestionNotificationSchedule({
  required bool enabled,
  required int hour,
  required int minute,
}) async {
  _logNotification(
    "update daily schedule enabled=$enabled time=${hour.toString().padLeft(2, "0")}:${minute.toString().padLeft(2, "0")}",
  );
  await _ensureInitialized();
  await _notifications.cancel(_dailyQuestionNotificationId);
  await _notifications.cancel(_dailyQuestionCatchupNotificationId);
  if (!enabled) {
    _logNotification("daily schedule canceled because enabled=false");
    return;
  }
  await _scheduleDaily(hour: hour, minute: minute);
}

Future<void> cancelDailyQuestionNotificationSchedule() async {
  _logNotification("cancel daily schedule");
  await _ensureInitialized();
  await _notifications.cancel(_dailyQuestionNotificationId);
  await _notifications.cancel(_dailyQuestionCatchupNotificationId);
}

Future<void> syncBucketDdayNotificationSchedule({
  required bool enabled,
  required int daysBefore,
}) async {
  await _ensureInitialized();
  final bool hasPermission = await areNotificationsEnabledOnDevice();
  _logNotification(
    "sync bucket dday enabled=$enabled daysBefore=$daysBefore notificationsEnabled=$hasPermission effective=${enabled && hasPermission}",
  );
  await _resyncBucketDdayNotifications(
    enabled: enabled && hasPermission,
    daysBefore: daysBefore,
  );
}

Future<void> _ensureInitialized() async {
  if (_initialized) {
    return;
  }

  tz_data.initializeTimeZones();
  await _configureLocalTimeZone();

  const AndroidInitializationSettings androidInit =
      AndroidInitializationSettings("@mipmap/ic_launcher");
  const DarwinInitializationSettings darwinInit = DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
  );
  const InitializationSettings initializationSettings = InitializationSettings(
    android: androidInit,
    iOS: darwinInit,
  );

  await _notifications.initialize(initializationSettings);

  _initialized = true;
  _logNotification("plugin initialized");
}

Future<void> _configureLocalTimeZone() async {
  try {
    final String timezoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezoneName));
    _logNotification("timezone set to $timezoneName");
  } catch (_) {
    try {
      tz.setLocalLocation(tz.getLocation("Asia/Seoul"));
      _logNotification("timezone fallback to Asia/Seoul");
    } catch (_) {
      tz.setLocalLocation(tz.getLocation("UTC"));
      _logNotification("timezone fallback to UTC");
    }
  }
}

Future<bool> _ensureNotificationPermissionOnFirstLaunch() async {
  if (kIsWeb) {
    return false;
  }

  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final bool onboardingRequested =
      prefs.getBool(NotificationPrefsKeys.permissionOnboardingRequested) ??
      false;
  final bool alreadyGranted = await areNotificationsEnabledOnDevice();
  if (alreadyGranted) {
    if (!onboardingRequested) {
      await prefs.setBool(
        NotificationPrefsKeys.permissionOnboardingRequested,
        true,
      );
    }
    _logNotification("permission already granted before onboarding request");
    return true;
  }

  if (onboardingRequested) {
    _logNotification("permission onboarding already requested once");
    return false;
  }

  final bool granted = await requestNotificationPermissionOnDevice();
  await prefs.setBool(
    NotificationPrefsKeys.permissionOnboardingRequested,
    true,
  );
  _logNotification("permission onboarding requested granted=$granted");
  return granted;
}

Future<void> _restoreSchedulesFromPrefs({
  required bool hasNotificationPermission,
}) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final bool todayQuestionEnabled =
      prefs.getBool(NotificationPrefsKeys.todayQuestionEnabled) ??
      NotificationPrefsKeys.defaultTodayQuestionEnabled;
  final int hour =
      prefs.getInt(NotificationPrefsKeys.todayQuestionHour) ??
      NotificationPrefsKeys.defaultTodayQuestionHour;
  final int minute =
      prefs.getInt(NotificationPrefsKeys.todayQuestionMinute) ??
      NotificationPrefsKeys.defaultTodayQuestionMinute;
  final bool bucketDdayEnabled =
      prefs.getBool(NotificationPrefsKeys.bucketDdayEnabled) ?? false;
  final int bucketDdayDaysBefore =
      prefs.getInt(NotificationPrefsKeys.bucketDdayDaysBefore) ??
      NotificationPrefsKeys.defaultBucketDdayDaysBefore;
  _logNotification(
    "restore prefs todayEnabled=$todayQuestionEnabled time=${hour.toString().padLeft(2, "0")}:${minute.toString().padLeft(2, "0")} bucketEnabled=$bucketDdayEnabled bucketDaysBefore=$bucketDdayDaysBefore hasPermission=$hasNotificationPermission",
  );

  if (!todayQuestionEnabled || !hasNotificationPermission) {
    await _notifications.cancel(_dailyQuestionNotificationId);
    await _notifications.cancel(_dailyQuestionCatchupNotificationId);
    _logNotification(
      "daily schedule not restored because todayEnabled=$todayQuestionEnabled hasPermission=$hasNotificationPermission",
    );
  } else {
    await _scheduleDaily(hour: hour, minute: minute);
  }
  if (!hasNotificationPermission) {
    await _notifications.cancel(_weeklyReportNotificationId);
    _logNotification(
      "weekly report schedule not restored because hasPermission=$hasNotificationPermission",
    );
  } else {
    await _scheduleWeeklyReportNotification();
  }
  await _resyncBucketDdayNotifications(
    enabled: bucketDdayEnabled && hasNotificationPermission,
    daysBefore: bucketDdayDaysBefore,
  );
}

bool _isNotificationPermissionGranted(PermissionStatus status) {
  return status == PermissionStatus.granted ||
      status == PermissionStatus.provisional;
}

Future<AndroidScheduleMode> _resolveAndroidScheduleMode() async {
  final bool canScheduleExact = await canScheduleExactAlarmsOnDevice();
  final AndroidScheduleMode mode = canScheduleExact
      ? AndroidScheduleMode.exactAllowWhileIdle
      : AndroidScheduleMode.inexactAllowWhileIdle;
  _logNotification("android schedule mode=$mode exact=$canScheduleExact");
  return mode;
}

Future<void> _zonedScheduleBestEffort({
  required int id,
  required String title,
  required String body,
  required tz.TZDateTime scheduledDate,
  DateTimeComponents? matchDateTimeComponents,
}) async {
  final AndroidScheduleMode preferredMode = await _resolveAndroidScheduleMode();

  Future<void> scheduleWithMode(AndroidScheduleMode mode) {
    return _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      _notificationDetails,
      androidScheduleMode: mode,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: matchDateTimeComponents,
    );
  }

  try {
    await scheduleWithMode(preferredMode);
  } catch (error) {
    if (preferredMode != AndroidScheduleMode.exactAllowWhileIdle) {
      rethrow;
    }
    _logNotification(
      "exact scheduling failed for id=$id, retry with inexactAllowWhileIdle error=$error",
    );
    await scheduleWithMode(AndroidScheduleMode.inexactAllowWhileIdle);
  }
}

Future<void> _scheduleDaily({required int hour, required int minute}) async {
  final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
  final tz.TZDateTime todayAtSelectedTime = tz.TZDateTime(
    tz.local,
    now.year,
    now.month,
    now.day,
    hour,
    minute,
  );
  final bool isSameMinuteSelection = now.hour == hour && now.minute == minute;
  final tz.TZDateTime repeatingSchedule = todayAtSelectedTime.isAfter(now)
      ? todayAtSelectedTime
      : todayAtSelectedTime.add(const Duration(days: 1));
  _logNotification(
    "schedule daily now=$now selected=$todayAtSelectedTime next=$repeatingSchedule sameMinute=$isSameMinuteSelection",
  );

  await _zonedScheduleBestEffort(
    id: _dailyQuestionNotificationId,
    title: "오늘의 질문이 도착했어요!",
    body: "내일의 나를 만날 수 있는 소중한 질문 시간!",
    scheduledDate: repeatingSchedule,
    matchDateTimeComponents: DateTimeComponents.time,
  );

  // If the user saved the exact current minute, send a one-time catch-up
  // notification shortly after save so today's alert is not skipped.
  if (isSameMinuteSelection && !todayAtSelectedTime.isAfter(now)) {
    final tz.TZDateTime catchupTime = now.add(const Duration(seconds: 5));
    _logNotification("schedule catch-up notification for $catchupTime");
    await _zonedScheduleBestEffort(
      id: _dailyQuestionCatchupNotificationId,
      title: "오늘의 질문이 도착했어요!",
      body: "내일의 나를 만날 수 있는 소중한 질문 시간!",
      scheduledDate: catchupTime,
    );
  }
}

Future<void> _scheduleWeeklyReportNotification() async {
  final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
  final int daysUntilSunday = (DateTime.sunday - now.weekday) % 7;
  tz.TZDateTime scheduled = tz.TZDateTime(
    tz.local,
    now.year,
    now.month,
    now.day,
    8,
  ).add(Duration(days: daysUntilSunday));
  if (!scheduled.isAfter(now)) {
    scheduled = scheduled.add(const Duration(days: 7));
  }
  _logNotification("schedule weekly report notification for $scheduled");
  await _zonedScheduleBestEffort(
    id: _weeklyReportNotificationId,
    title: "주간 리포트가 나왔어요",
    body: "지난 7일 기록을 돌아보러 와보세요.",
    scheduledDate: scheduled,
    matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
  );
}

Future<void> _resyncBucketDdayNotifications({
  required bool enabled,
  required int daysBefore,
}) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final List<String> previousIdsRaw =
      prefs.getStringList(_bucketDdayNotificationIdsKey) ?? <String>[];
  for (final String raw in previousIdsRaw) {
    final int? id = int.tryParse(raw);
    if (id != null) {
      await _notifications.cancel(id);
    }
  }
  await prefs.remove(_bucketDdayNotificationIdsKey);
  _logNotification(
    "resync bucket notifications enabled=$enabled daysBefore=$daysBefore cleared=${previousIdsRaw.length}",
  );

  if (!enabled || daysBefore <= 0) {
    _logNotification(
      "skip bucket resync because enabled=$enabled daysBefore=$daysBefore",
    );
    return;
  }

  final Isar isar = await LocalDatabase.instance.isar;
  final List<BucketItemEntity> items = await isar.bucketItemEntitys
      .where()
      .findAll();
  final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
  final List<String> nextIdsRaw = <String>[];

  for (final BucketItemEntity item in items) {
    final DateTime? dueDate = item.dueDate;
    if (dueDate == null || item.isCompleted) {
      continue;
    }

    tz.TZDateTime scheduled = tz.TZDateTime(
      tz.local,
      dueDate.year,
      dueDate.month,
      dueDate.day,
      9,
      0,
    ).subtract(Duration(days: daysBefore));
    if (!scheduled.isAfter(now)) {
      continue;
    }

    final int notificationId =
        _bucketDdayNotificationBaseId + (item.id % 100000000).toInt();
    _logNotification(
      "schedule bucket notification id=$notificationId title=${item.title} at=$scheduled",
    );
    await _zonedScheduleBestEffort(
      id: notificationId,
      title: "${item.title} 완료 D-$daysBefore일 전이에요!",
      body: "실천하기 위한 계획을 세워볼까요?",
      scheduledDate: scheduled,
    );
    nextIdsRaw.add(notificationId.toString());
  }

  if (nextIdsRaw.isNotEmpty) {
    await prefs.setStringList(_bucketDdayNotificationIdsKey, nextIdsRaw);
  }
  _logNotification("bucket resync completed scheduled=${nextIdsRaw.length}");
}
