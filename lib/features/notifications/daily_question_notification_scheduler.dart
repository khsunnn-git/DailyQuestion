import "daily_question_notification_scheduler_io.dart"
    if (dart.library.js_interop) "daily_question_notification_scheduler_web.dart"
    as impl;

Future<void> initializeDailyQuestionNotificationScheduler() async {
  await impl.initializeDailyQuestionNotificationScheduler();
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
