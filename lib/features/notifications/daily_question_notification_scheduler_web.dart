Future<void> initializeDailyQuestionNotificationScheduler() async {}

Future<void> updateDailyQuestionNotificationSchedule({
  required bool enabled,
  required int hour,
  required int minute,
}) async {}

Future<void> cancelDailyQuestionNotificationSchedule() async {}

Future<void> syncBucketDdayNotificationSchedule({
  required bool enabled,
  required int daysBefore,
}) async {}

Future<void> syncWeeklyReportNotificationSchedule({
  required bool enabled,
}) async {}

Future<bool> areNotificationsEnabledOnDevice() async => false;

Future<bool> requestNotificationPermissionOnDevice() async => false;

Future<bool> canScheduleExactAlarmsOnDevice() async => true;

Future<bool> requestExactAlarmPermissionOnDevice() async => true;
