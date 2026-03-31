bool isAiReportMonthClosed({
  required int year,
  required int month,
  required DateTime now,
}) {
  final DateTime today = DateTime(now.year, now.month, now.day);
  final DateTime lastDayOfMonth = DateTime(year, month + 1, 0);
  return !today.isBefore(lastDayOfMonth);
}

bool shouldDefaultAiReportToMonthly({
  required int year,
  required int month,
  required DateTime now,
}) {
  return isAiReportMonthClosed(year: year, month: month, now: now);
}
