import "package:timezone/timezone.dart" as tz;

tz.TZDateTime nextDailyNotificationTime({
  required tz.TZDateTime now,
  required int hour,
  required int minute,
}) {
  final tz.TZDateTime candidate = tz.TZDateTime(
    now.location,
    now.year,
    now.month,
    now.day,
    hour,
    minute,
  );
  if (candidate.isAfter(now)) {
    return candidate;
  }
  return tz.TZDateTime(
    now.location,
    now.year,
    now.month,
    now.day + 1,
    hour,
    minute,
  );
}

tz.TZDateTime bucketDdayNotificationTime({
  required tz.Location location,
  required DateTime dueDate,
  required int daysBefore,
}) {
  return tz.TZDateTime(
    location,
    dueDate.year,
    dueDate.month,
    dueDate.day,
    12,
  ).subtract(Duration(days: daysBefore));
}

tz.TZDateTime bucketDueDateNotificationTime({
  required tz.Location location,
  required DateTime dueDate,
}) {
  return tz.TZDateTime(location, dueDate.year, dueDate.month, dueDate.day, 12);
}

tz.TZDateTime? nextBucketNotificationTime({
  required tz.Location location,
  required DateTime dueDate,
  required int daysBefore,
  required tz.TZDateTime now,
}) {
  final tz.TZDateTime ddayReminder = bucketDdayNotificationTime(
    location: location,
    dueDate: dueDate,
    daysBefore: daysBefore,
  );
  if (ddayReminder.isAfter(now)) {
    return ddayReminder;
  }

  final tz.TZDateTime dueDateReminder = bucketDueDateNotificationTime(
    location: location,
    dueDate: dueDate,
  );
  if (dueDateReminder.isAfter(now)) {
    return dueDateReminder;
  }

  return null;
}
