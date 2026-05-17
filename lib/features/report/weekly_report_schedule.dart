import "../../core/kst_date_time.dart";

class WeeklyReportWindow {
  const WeeklyReportWindow({
    required this.slotAnchor,
    required this.referenceDate,
    required this.startDate,
    required this.endDate,
  });

  final DateTime slotAnchor;
  final DateTime referenceDate;
  final DateTime startDate;
  final DateTime endDate;

  DateTime get currentProgressStartDate =>
      DateTime(slotAnchor.year, slotAnchor.month, slotAnchor.day);

  DateTime get nextGenerationDateTime =>
      slotAnchor.add(const Duration(days: 7));

  String get slotKey => kstDateKeyFromDateTime(slotAnchor);

  String get summaryTitle {
    final String startMonth = startDate.month.toString().padLeft(2, "0");
    final String startDay = startDate.day.toString().padLeft(2, "0");
    final String endMonth = endDate.month.toString().padLeft(2, "0");
    final String endDay = endDate.day.toString().padLeft(2, "0");
    return "$startMonth.$startDay - $endMonth.$endDay 요약";
  }
}

WeeklyReportWindow weeklyReportWindowForSlotAnchor(DateTime slotAnchor) {
  final DateTime normalizedSlotAnchor = DateTime(
    slotAnchor.year,
    slotAnchor.month,
    slotAnchor.day,
    slotAnchor.hour == 0 ? 8 : slotAnchor.hour,
    slotAnchor.minute,
    slotAnchor.second,
    slotAnchor.millisecond,
    slotAnchor.microsecond,
  );
  final DateTime referenceDate = DateTime(
    normalizedSlotAnchor.year,
    normalizedSlotAnchor.month,
    normalizedSlotAnchor.day,
  ).subtract(const Duration(days: 1));
  final DateTime startDate = referenceDate.subtract(const Duration(days: 6));
  return WeeklyReportWindow(
    slotAnchor: normalizedSlotAnchor,
    referenceDate: referenceDate,
    startDate: startDate,
    endDate: referenceDate,
  );
}

WeeklyReportWindow weeklyReportWindowForDate(DateTime date) {
  final DateTime normalizedDate = DateTime(date.year, date.month, date.day);
  final DateTime weekStart = normalizedDate.subtract(
    Duration(days: normalizedDate.weekday % DateTime.daysPerWeek),
  );
  return weeklyReportWindowForSlotAnchor(
    DateTime(weekStart.year, weekStart.month, weekStart.day + 7, 8),
  );
}

List<WeeklyReportWindow> weeklyReportWindowsForMonth({
  required int year,
  required int month,
}) {
  final List<WeeklyReportWindow> windows = <WeeklyReportWindow>[];
  final DateTime monthStart = DateTime(year, month, 1);
  final DateTime monthEnd = DateTime(year, month + 1, 0);
  DateTime weekStart = monthStart.subtract(
    Duration(days: monthStart.weekday % DateTime.daysPerWeek),
  );

  while (!weekStart.isAfter(monthEnd) && windows.length < 5) {
    final DateTime slotAnchor = DateTime(
      weekStart.year,
      weekStart.month,
      weekStart.day + 7,
      8,
    );
    windows.add(weeklyReportWindowForSlotAnchor(slotAnchor));
    weekStart = weekStart.add(const Duration(days: 7));
  }
  return windows;
}

WeeklyReportWindow currentWeeklyReportWindow({DateTime? now}) {
  final DateTime kstNow = _asKstClock(now ?? DateTime.now());
  final DateTime todayAtEight = DateTime(
    kstNow.year,
    kstNow.month,
    kstNow.day,
    8,
  );
  final int daysSinceSunday = kstNow.weekday % DateTime.daysPerWeek;
  DateTime slotAnchor = todayAtEight.subtract(Duration(days: daysSinceSunday));
  if (kstNow.isBefore(slotAnchor)) {
    slotAnchor = slotAnchor.subtract(const Duration(days: 7));
  }
  return weeklyReportWindowForSlotAnchor(
    DateTime(
      slotAnchor.year,
      slotAnchor.month,
      slotAnchor.day,
      slotAnchor.hour,
      slotAnchor.minute,
    ),
  );
}

DateTime _asKstClock(DateTime dateTime) {
  final DateTime kst = toKst(dateTime);
  return DateTime(
    kst.year,
    kst.month,
    kst.day,
    kst.hour,
    kst.minute,
    kst.second,
    kst.millisecond,
    kst.microsecond,
  );
}
