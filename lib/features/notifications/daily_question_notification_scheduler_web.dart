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
