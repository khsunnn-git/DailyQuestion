abstract final class NotificationPrefsKeys {
  static const String todayQuestionEnabled =
      "notification_today_question_enabled";
  static const String bucketDdayEnabled = "notification_bucket_dday_enabled";
  static const String todayQuestionHour = "notification_today_question_hour";
  static const String todayQuestionMinute =
      "notification_today_question_minute";
  static const String bucketDdayDaysBefore =
      "notification_bucket_dday_days_before";

  static const int defaultTodayQuestionHour = 15;
  static const int defaultTodayQuestionMinute = 0;
  static const int defaultBucketDdayDaysBefore = 7;
}
