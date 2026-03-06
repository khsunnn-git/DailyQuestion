import "dart:async";

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
const int _bucketDdayNotificationBaseId = 200000;
const String _bucketDdayNotificationIdsKey = "bucket_dday_notification_ids";

const AndroidNotificationDetails _androidNotificationDetails =
    AndroidNotificationDetails(
      "daily_question_channel_v2",
      "오늘의 질문 알림",
      channelDescription: "오늘의 질문 알림을 매일 지정된 시간에 전송합니다.",
      icon: "ic_noti_question",
      importance: Importance.high,
      priority: Priority.high,
      playSound: false,
      enableVibration: false,
    );

const DarwinNotificationDetails _darwinNotificationDetails =
    DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: false,
    );

const NotificationDetails _notificationDetails = NotificationDetails(
  android: _androidNotificationDetails,
  iOS: _darwinNotificationDetails,
);

final FlutterLocalNotificationsPlugin _notifications =
    FlutterLocalNotificationsPlugin();

bool _initialized = false;

Future<void> initializeDailyQuestionNotificationScheduler() async {
  await _ensureInitialized();
  await _restoreSchedulesFromPrefs();
}

Future<void> updateDailyQuestionNotificationSchedule({
  required bool enabled,
  required int hour,
  required int minute,
}) async {
  await _ensureInitialized();
  await _notifications.cancel(_dailyQuestionNotificationId);
  await _notifications.cancel(_dailyQuestionCatchupNotificationId);
  if (!enabled) {
    return;
  }
  await _scheduleDaily(hour: hour, minute: minute);
}

Future<void> cancelDailyQuestionNotificationSchedule() async {
  await _ensureInitialized();
  await _notifications.cancel(_dailyQuestionNotificationId);
  await _notifications.cancel(_dailyQuestionCatchupNotificationId);
}

Future<void> syncBucketDdayNotificationSchedule({
  required bool enabled,
  required int daysBefore,
}) async {
  await _ensureInitialized();
  final PermissionStatus permissionStatus =
      await Permission.notification.status;
  final bool hasPermission =
      permissionStatus == PermissionStatus.granted ||
      permissionStatus == PermissionStatus.provisional;
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

  unawaited(
    _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission(),
  );
  unawaited(
    _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: false),
  );

  _initialized = true;
}

Future<void> _configureLocalTimeZone() async {
  try {
    final String timezoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezoneName));
  } catch (_) {
    try {
      tz.setLocalLocation(tz.getLocation("Asia/Seoul"));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation("UTC"));
    }
  }
}

Future<void> _restoreSchedulesFromPrefs() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final bool todayQuestionEnabled =
      prefs.getBool(NotificationPrefsKeys.todayQuestionEnabled) ?? false;
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

  if (!todayQuestionEnabled) {
    await _notifications.cancel(_dailyQuestionNotificationId);
    await _notifications.cancel(_dailyQuestionCatchupNotificationId);
  } else {
    await _scheduleDaily(hour: hour, minute: minute);
  }
  await _resyncBucketDdayNotifications(
    enabled: bucketDdayEnabled,
    daysBefore: bucketDdayDaysBefore,
  );
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
  final bool isSameMinuteSelection =
      now.hour == hour && now.minute == minute;
  final tz.TZDateTime repeatingSchedule = todayAtSelectedTime.isAfter(now)
      ? todayAtSelectedTime
      : todayAtSelectedTime.add(const Duration(days: 1));

  await _notifications.zonedSchedule(
    _dailyQuestionNotificationId,
    "오늘의 질문이 도착했어요!",
    "내일의 나를 만날 수 있는 소중한 질문 시간!",
    repeatingSchedule,
    _notificationDetails,
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
    matchDateTimeComponents: DateTimeComponents.time,
  );

  // If the user saved the exact current minute, send a one-time catch-up
  // notification shortly after save so today's alert is not skipped.
  if (isSameMinuteSelection && !todayAtSelectedTime.isAfter(now)) {
    final tz.TZDateTime catchupTime = now.add(const Duration(seconds: 5));
    await _notifications.zonedSchedule(
      _dailyQuestionCatchupNotificationId,
      "오늘의 질문이 도착했어요!",
      "내일의 나를 만날 수 있는 소중한 질문 시간!",
      catchupTime,
      _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
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

  if (!enabled || daysBefore <= 0) {
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
    await _notifications.zonedSchedule(
      notificationId,
      "${item.title} 완료 D-$daysBefore일 전이에요!",
      "실천하기 위한 계획을 세워볼까요?",
      scheduled,
      _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
    nextIdsRaw.add(notificationId.toString());
  }

  if (nextIdsRaw.isNotEmpty) {
    await prefs.setStringList(_bucketDdayNotificationIdsKey, nextIdsRaw);
  }
}
