import "dart:async";

import "package:flutter/foundation.dart";
import "package:flutter_local_notifications/flutter_local_notifications.dart";
import "package:flutter_timezone/flutter_timezone.dart";
import "package:isar_community/isar.dart";
import "package:permission_handler/permission_handler.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:timezone/data/latest.dart" as tz_data;
import "package:timezone/timezone.dart" as tz;

import "../../core/kst_date_time.dart";
import "../../data/local_db/entities/bucket_item_entity.dart";
import "../../data/local_db/local_database.dart";
import "../home/home_bubble_messages.dart";
import "../home/home_character_selection_store.dart";
import "../more/notification_prefs_keys.dart";
import "../question/today_question_prompt_store.dart";
import "../question/today_question_store.dart";
import "daily_question_notification_plan.dart";
import "notification_schedule_calculator.dart";

// 예전 버전의 반복 알림 ID. 날짜별 예약으로 바뀌면서 지우기만 한다.
const int _dailyQuestionNotificationId = 10001;
const int _dailyQuestionCatchupNotificationId = 10002;
const int _weeklyReportNotificationId = 10003;
const int _bucketDdayNotificationBaseId = 200000;
const String _bucketDdayNotificationIdsKey = "bucket_dday_notification_ids";
const String _legacyPermissionOnboardingRequestedKey =
    "notification_permission_onboarding_requested";
const String _dailyQuestionCatchupSlotKey =
    "notification_daily_question_catchup_slot";

const AndroidNotificationDetails _androidNotificationDetails =
    AndroidNotificationDetails(
      "daily_question_channel_v4",
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
      presentBanner: true,
      presentList: true,
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
  await refreshDailyQuestionNotificationSchedulerState();
}

/// 오늘의 질문 알림 예약 세대. 새로 예약하거나 취소할 때마다 올라가고,
/// 진행 중이던 이전 예약은 세대가 바뀐 것을 보고 멈춘다.
/// (앱 복귀와 답변 저장이 겹쳐도 오래된 정보로 예약이 덮어써지지 않게 한다.)
int _dailyPlanGeneration = 0;

Future<void> refreshDailyQuestionNotificationSchedulerState() async {
  _logNotification("refresh scheduler state");
  await _ensureInitialized();
  await _resetNotificationSettingsIfNeeded();
  final bool hasNotificationPermission =
      await areNotificationsEnabledOnDevice();
  await _restoreSchedulesFromPrefs(
    hasNotificationPermission: hasNotificationPermission,
  );
  await _debugLogPendingNotifications("refresh scheduler state");
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

  if (defaultTargetPlatform == TargetPlatform.iOS) {
    final bool? enabled = await _areDarwinNotificationsEnabled();
    if (enabled != null) {
      return enabled;
    }
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
      if (granted != null) {
        return granted;
      }
    } catch (_) {}

    final bool? enabled = await _areDarwinNotificationsEnabled();
    if (enabled != null) {
      return enabled;
    }
    return false;
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

Future<bool> areDailyQuestionAlarmPermissionsGrantedOnDevice() async {
  if (kIsWeb) {
    return true;
  }

  final bool hasNotificationPermission =
      await areNotificationsEnabledOnDevice();
  if (!hasNotificationPermission) {
    return false;
  }

  if (defaultTargetPlatform == TargetPlatform.android) {
    final bool canScheduleExact = await canScheduleExactAlarmsOnDevice();
    if (!canScheduleExact) {
      _logNotification(
        "exact alarm permission not granted; inexact schedule fallback is available",
      );
    }

    final bool hasBatteryOptimizationExemption =
        await _isBatteryOptimizationDisabled();
    if (!hasBatteryOptimizationExemption) {
      _logNotification(
        "battery optimization not disabled; notifications may be delayed",
      );
    }
  }

  return true;
}

Future<bool> _isBatteryOptimizationDisabled() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
    return true;
  }
  try {
    final PermissionStatus status =
        await Permission.ignoreBatteryOptimizations.status;
    return status == PermissionStatus.granted;
  } catch (error) {
    _logNotification("failed to check battery optimization status: $error");
    return false;
  }
}

Future<bool> requestBatteryOptimizationExemption() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
    return true;
  }
  try {
    final PermissionStatus status = await Permission.ignoreBatteryOptimizations
        .request();
    final bool granted = status == PermissionStatus.granted;
    _logNotification("battery optimization exemption request result=$granted");
    return granted;
  } catch (error) {
    _logNotification(
      "failed to request battery optimization exemption: $error",
    );
    return false;
  }
}

Future<bool> requestDailyQuestionAlarmPermissionsOnDevice() async {
  if (kIsWeb) {
    return true;
  }

  bool hasNotificationPermission = await areNotificationsEnabledOnDevice();
  if (!hasNotificationPermission) {
    hasNotificationPermission = await requestNotificationPermissionOnDevice();
  }
  if (!hasNotificationPermission) {
    return false;
  }

  if (defaultTargetPlatform != TargetPlatform.android) {
    return true;
  }

  if (!await canScheduleExactAlarmsOnDevice()) {
    try {
      await requestExactAlarmPermissionOnDevice();
    } catch (error) {
      _logNotification("exact alarm permission request failed: $error");
    }
  }

  if (!await _isBatteryOptimizationDisabled()) {
    try {
      await requestBatteryOptimizationExemption();
    } catch (error) {
      _logNotification("battery optimization exemption request failed: $error");
    }
  }

  return true;
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
  await _cancelDailyQuestionPlan();
  if (!enabled) {
    _logNotification("daily schedule canceled because enabled=false");
    return;
  }
  // Exact alarms improve punctuality on Android, but reminders should still be
  // scheduled with an inexact fallback when that permission is unavailable.
  await _scheduleDaily(hour: hour, minute: minute);
}

Future<void> cancelDailyQuestionNotificationSchedule() async {
  _logNotification("cancel daily schedule");
  await _ensureInitialized();
  await _cancelDailyQuestionPlan();
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
  await _debugLogPendingNotifications("sync bucket dday");
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
    defaultPresentAlert: true,
    defaultPresentBadge: true,
    defaultPresentSound: true,
    defaultPresentBanner: true,
    defaultPresentList: true,
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

Future<void> _resetNotificationSettingsIfNeeded() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final int schemaVersion =
      prefs.getInt(NotificationPrefsKeys.settingsSchemaVersion) ?? 0;

  if (schemaVersion >= NotificationPrefsKeys.currentSettingsSchemaVersion) {
    await _ensureDefaultNotificationPreferences(prefs);
    return;
  }

  _logNotification(
    "reset notification settings schema=$schemaVersion -> ${NotificationPrefsKeys.currentSettingsSchemaVersion}",
  );
  await _notifications.cancelAll();
  await prefs.remove(_bucketDdayNotificationIdsKey);
  await prefs.remove(NotificationPrefsKeys.todayQuestionEnabled);
  await prefs.remove(NotificationPrefsKeys.todayQuestionHour);
  await prefs.remove(NotificationPrefsKeys.todayQuestionMinute);
  await prefs.remove(NotificationPrefsKeys.bucketDdayEnabled);
  await prefs.remove(NotificationPrefsKeys.bucketDdayDaysBefore);
  await prefs.remove(_legacyPermissionOnboardingRequestedKey);
  await _ensureDefaultNotificationPreferences(prefs);
  await prefs.setInt(
    NotificationPrefsKeys.settingsSchemaVersion,
    NotificationPrefsKeys.currentSettingsSchemaVersion,
  );
}

Future<void> _ensureDefaultNotificationPreferences(
  SharedPreferences prefs,
) async {
  if (!prefs.containsKey(NotificationPrefsKeys.todayQuestionEnabled)) {
    await prefs.setBool(
      NotificationPrefsKeys.todayQuestionEnabled,
      NotificationPrefsKeys.defaultTodayQuestionEnabled,
    );
  }
  if (!prefs.containsKey(NotificationPrefsKeys.todayQuestionHour)) {
    await prefs.setInt(
      NotificationPrefsKeys.todayQuestionHour,
      NotificationPrefsKeys.defaultTodayQuestionHour,
    );
  }
  if (!prefs.containsKey(NotificationPrefsKeys.todayQuestionMinute)) {
    await prefs.setInt(
      NotificationPrefsKeys.todayQuestionMinute,
      NotificationPrefsKeys.defaultTodayQuestionMinute,
    );
  }
  if (!prefs.containsKey(NotificationPrefsKeys.bucketDdayEnabled)) {
    await prefs.setBool(NotificationPrefsKeys.bucketDdayEnabled, false);
  }
  if (!prefs.containsKey(NotificationPrefsKeys.bucketDdayDaysBefore)) {
    await prefs.setInt(
      NotificationPrefsKeys.bucketDdayDaysBefore,
      NotificationPrefsKeys.defaultBucketDdayDaysBefore,
    );
  }
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

  final bool canScheduleDailyQuestion =
      todayQuestionEnabled && hasNotificationPermission;

  if (!canScheduleDailyQuestion) {
    await _cancelDailyQuestionPlan();
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
  await _debugLogPendingNotifications("restore schedules");
}

bool _isNotificationPermissionGranted(PermissionStatus status) {
  return status == PermissionStatus.granted ||
      status == PermissionStatus.provisional;
}

Future<bool?> _areDarwinNotificationsEnabled() async {
  try {
    final NotificationsEnabledOptions? permissions = await _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.checkPermissions();
    if (permissions == null) {
      return null;
    }
    return permissions.isEnabled ||
        permissions.isAlertEnabled ||
        permissions.isProvisionalEnabled;
  } catch (error) {
    _logNotification("failed to read iOS notification permissions: $error");
    return null;
  }
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

Future<void> _debugLogPendingNotifications(String context) async {
  if (!kDebugMode) {
    return;
  }
  try {
    final List<PendingNotificationRequest> pending = await _notifications
        .pendingNotificationRequests();
    _logNotification(
      "$context pending=${pending.length} ids=${pending.map((PendingNotificationRequest item) => item.id).join(",")}",
    );
  } catch (error) {
    _logNotification("$context failed to read pending notifications: $error");
  }
}

Future<void> _cancelDailyQuestionPlan() async {
  _dailyPlanGeneration++;
  await _notifications.cancel(_dailyQuestionNotificationId);
  await _notifications.cancel(_dailyQuestionCatchupNotificationId);
  for (final int id in allDailyQuestionPlanIds()) {
    await _notifications.cancel(id);
  }
}

/// 어제 또는 오늘까지 이어진 연속 기록일. 이미 끊겼으면 0.
int _activeStreakDays(TodayQuestionStore store) {
  final DateTime? latest = store.latestRecordDate;
  if (latest == null) {
    return 0;
  }
  final DateTime today = kstDateOnly(DateTime.now());
  final int daysSince = DateTime.utc(
    today.year,
    today.month,
    today.day,
  ).difference(DateTime.utc(latest.year, latest.month, latest.day)).inDays;
  return daysSince <= 1 ? store.consecutiveRecordDays : 0;
}

Future<void> _scheduleDaily({required int hour, required int minute}) async {
  final int generation = ++_dailyPlanGeneration;
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final bool eveningEnabled =
      prefs.getBool(NotificationPrefsKeys.eveningReminderEnabled) ??
      NotificationPrefsKeys.defaultEveningReminderEnabled;
  final TodayQuestionStore store = TodayQuestionStore.instance;
  final bool recordsLoaded = store.isInitialized;
  final int totalRecordCount = store.value.length;
  final Map<int, String> questions = await TodayQuestionPromptStore.instance
      .fetchUpcomingQuestions(days: dailyQuestionPlanDays);
  if (generation != _dailyPlanGeneration) {
    _logNotification("skip stale daily plan generation=$generation");
    return;
  }
  await _cancelDailyQuestionPlan();
  final int activeGeneration = _dailyPlanGeneration;
  final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

  List<PlannedNotification> planned = planDailyQuestionNotifications(
    now: now,
    hour: hour,
    minute: minute,
    dailyEnabled: true,
    eveningEnabled: eveningEnabled,
    answeredToday: store.hasRecordForTodayKst,
    activeStreakDays: _activeStreakDays(store),
    questions: questions,
    nextAnswerHintTitle: homeNextAnswerHint(
      characterType: HomeCharacterSelectionStore.instance
          .resolve(totalRecordCount)
          .characterType,
      totalRecordCount: totalRecordCount,
    ),
  );
  if (!recordsLoaded) {
    // 기록을 아직 못 불러왔으면 오늘 답했는지 모르므로 오늘 저녁 리마인드는 보류한다.
    // 기록을 불러온 뒤 다시 예약할 때 채워진다.
    planned = planned
        .where(
          (PlannedNotification item) => item.id != eveningReminderPlanBaseId,
        )
        .toList(growable: false);
  }
  _logNotification(
    "schedule daily plan now=$now time=$hour:$minute evening=$eveningEnabled "
    "loaded=$recordsLoaded answeredToday=${store.hasRecordForTodayKst} "
    "questions=${questions.length} planned=${planned.length}",
  );

  for (final PlannedNotification item in planned) {
    if (activeGeneration != _dailyPlanGeneration) {
      _logNotification("stop stale daily plan generation=$activeGeneration");
      return;
    }
    if (item.kind == PlannedNotificationKind.dailyCatchup) {
      final String catchupSlot =
          "${now.year}-${now.month.toString().padLeft(2, "0")}-"
          "${now.day.toString().padLeft(2, "0")}-"
          "${hour.toString().padLeft(2, "0")}:"
          "${minute.toString().padLeft(2, "0")}";
      if (prefs.getString(_dailyQuestionCatchupSlotKey) == catchupSlot) {
        _logNotification(
          "skip duplicate catch-up notification for slot=$catchupSlot",
        );
        continue;
      }
      await prefs.setString(_dailyQuestionCatchupSlotKey, catchupSlot);
    }
    await _zonedScheduleBestEffort(
      id: item.id,
      title: item.title,
      body: item.body,
      scheduledDate: item.scheduledAt,
    );
  }
  await _debugLogPendingNotifications("schedule daily");
}

Future<void> _scheduleWeeklyReportNotification() async {
  await _notifications.cancel(_weeklyReportNotificationId);
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
  await _debugLogPendingNotifications("schedule weekly report");
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

    final tz.TZDateTime? scheduled = nextBucketNotificationTime(
      location: tz.local,
      dueDate: dueDate,
      daysBefore: daysBefore,
      now: now,
    );
    if (scheduled == null) {
      continue;
    }
    final tz.TZDateTime dueDateReminder = bucketDueDateNotificationTime(
      location: tz.local,
      dueDate: dueDate,
    );
    final bool isDueDateFallback = scheduled.isAtSameMomentAs(dueDateReminder);

    final int notificationId =
        _bucketDdayNotificationBaseId + (item.id % 100000000).toInt();
    _logNotification(
      "schedule bucket notification id=$notificationId title=${item.title} at=$scheduled fallback=$isDueDateFallback",
    );
    await _zonedScheduleBestEffort(
      id: notificationId,
      title: isDueDateFallback
          ? "${item.title} 완료 예정일이에요!"
          : "${item.title} 완료 D-$daysBefore일 전이에요!",
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
