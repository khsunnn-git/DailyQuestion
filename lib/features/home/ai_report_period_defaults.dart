bool isAiReportMonthClosed({
  required int year,
  required int month,
  required DateTime now,
}) {
  final DateTime kstClock = DateTime(
    now.year,
    now.month,
    now.day,
    now.hour,
    now.minute,
    now.second,
    now.millisecond,
    now.microsecond,
  );
  final DateTime generationDateTime = DateTime(year, month + 1, 0, 8);
  return !kstClock.isBefore(generationDateTime);
}

bool shouldDefaultAiReportToMonthly({
  required int year,
  required int month,
  required DateTime now,
}) {
  return isAiReportMonthClosed(year: year, month: month, now: now);
}
