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

  String get slotKey => kstDateKeyFromDateTime(slotAnchor);

  String get summaryTitle {
    final String startMonth = startDate.month.toString().padLeft(2, "0");
    final String startDay = startDate.day.toString().padLeft(2, "0");
    final String endMonth = endDate.month.toString().padLeft(2, "0");
    final String endDay = endDate.day.toString().padLeft(2, "0");
    return "$startMonth.$startDay - $endMonth.$endDay 요약";
  }
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
  final DateTime referenceDate = DateTime(
    slotAnchor.year,
    slotAnchor.month,
    slotAnchor.day,
  ).subtract(const Duration(days: 1));
  final DateTime startDate = referenceDate.subtract(const Duration(days: 6));
  return WeeklyReportWindow(
    slotAnchor: slotAnchor,
    referenceDate: referenceDate,
    startDate: startDate,
    endDate: referenceDate,
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
