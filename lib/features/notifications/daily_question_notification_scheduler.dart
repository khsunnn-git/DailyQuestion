import "daily_question_notification_scheduler_io.dart"
    if (dart.library.js_interop) "daily_question_notification_scheduler_web.dart"
    as impl;

Future<void> initializeDailyQuestionNotificationScheduler() async {
  await impl.initializeDailyQuestionNotificationScheduler();
}

Future<void> refreshDailyQuestionNotificationSchedulerState({
  bool requestPermissionOnFirstRun = false,
}) async {
  await impl.refreshDailyQuestionNotificationSchedulerState(
    requestPermissionOnFirstRun: requestPermissionOnFirstRun,
  );
}

Future<void> updateDailyQuestionNotificationSchedule({
  required bool enabled,
  required int hour,
  required int minute,
}) async {
  await impl.updateDailyQuestionNotificationSchedule(
    enabled: enabled,
    hour: hour,
    minute: minute,
  );
}

Future<void> cancelDailyQuestionNotificationSchedule() async {
  await impl.cancelDailyQuestionNotificationSchedule();
}

Future<void> syncBucketDdayNotificationSchedule({
  required bool enabled,
  required int daysBefore,
}) async {
  await impl.syncBucketDdayNotificationSchedule(
    enabled: enabled,
    daysBefore: daysBefore,
  );
}

Future<void> syncWeeklyReportNotificationSchedule({
  required bool enabled,
}) async {
  await impl.syncWeeklyReportNotificationSchedule(enabled: enabled);
}

Future<bool> areNotificationsEnabledOnDevice() async {
  return impl.areNotificationsEnabledOnDevice();
}

Future<bool> requestNotificationPermissionOnDevice() async {
  return impl.requestNotificationPermissionOnDevice();
}

Future<bool> canScheduleExactAlarmsOnDevice() async {
  return impl.canScheduleExactAlarmsOnDevice();
}

Future<bool> requestExactAlarmPermissionOnDevice() async {
  return impl.requestExactAlarmPermissionOnDevice();
}
