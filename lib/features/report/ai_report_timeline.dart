import "../../core/kst_date_time.dart";
import "../home/ai_report_period_defaults.dart";
import "weekly_report_schedule.dart";

class AiReportTimelineOption {
  const AiReportTimelineOption({
    required this.id,
    required this.label,
    required this.startDate,
    required this.endDate,
    required this.generatedAt,
    required this.enabled,
  });

  final String id;
  final String label;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime generatedAt;
  final bool enabled;
}

List<AiReportTimelineOption> buildWeeklyAiReportTimelineOptions({
  required int year,
  required int month,
  required DateTime now,
}) {
  final DateTime normalizedNow = toKst(now);
  final List<WeeklyReportWindow> windows = weeklyReportWindowsForMonth(
    year: year,
    month: month,
  );

  return List<AiReportTimelineOption>.generate(windows.length, (int index) {
    final WeeklyReportWindow window = windows[index];
    return AiReportTimelineOption(
      id: "weekly-${window.slotKey}",
      label: "${index + 1}주",
      startDate: window.startDate,
      endDate: window.endDate,
      generatedAt: window.slotAnchor,
      enabled: !normalizedNow.isBefore(window.slotAnchor),
    );
  });
}

List<AiReportTimelineOption> buildMonthlyAiReportTimelineOptions({
  required int year,
  required DateTime? firstRecordDate,
  required DateTime now,
}) {
  final int startMonth = _startMonthForYear(
    year: year,
    firstRecordDate: firstRecordDate,
  );
  if (startMonth > 12) {
    return const <AiReportTimelineOption>[];
  }

  final int latestClosedMonth = latestClosedAiReportMonthForYear(
    year: year,
    now: now,
  );

  return List<AiReportTimelineOption>.generate(13 - startMonth, (int index) {
    final int month = startMonth + index;
    return AiReportTimelineOption(
      id: "monthly-$year-$month",
      label: "$month월",
      startDate: DateTime(year, month, 1),
      endDate: DateTime(year, month + 1, 0),
      generatedAt: DateTime(year, month + 1, 0, 8),
      enabled: month <= latestClosedMonth,
    );
  });
}

List<AiReportTimelineOption> buildQuarterlyAiReportTimelineOptions({
  required int year,
  required DateTime? firstRecordDate,
  required DateTime now,
}) {
  final int latestClosedMonth = latestClosedAiReportMonthForYear(
    year: year,
    now: now,
  );

  return List<AiReportTimelineOption>.generate(4, (int index) {
    final int quarter = index + 1;
    final int startMonth = (quarter - 1) * 3 + 1;
    final int endMonth = startMonth + 2;
    final bool intersectsRecordedYear =
        firstRecordDate == null ||
        year > firstRecordDate.year ||
        (year == firstRecordDate.year && endMonth >= firstRecordDate.month);

    return AiReportTimelineOption(
      id: "quarterly-$year-q$quarter",
      label: "$quarter분기",
      startDate: DateTime(year, startMonth, 1),
      endDate: DateTime(year, endMonth + 1, 0),
      generatedAt: DateTime(year, endMonth + 1, 0, 8),
      enabled: intersectsRecordedYear && endMonth <= latestClosedMonth,
    );
  });
}

AiReportTimelineOption buildYearlyAiReportTimelineOption({
  required int year,
  required DateTime now,
}) {
  return AiReportTimelineOption(
    id: "yearly-$year",
    label: "$year년",
    startDate: DateTime(year, 1, 1),
    endDate: DateTime(year + 1, 1, 0),
    generatedAt: DateTime(year, 12, 31, 8),
    enabled: isYearlyAiReportClosed(year: year, now: now),
  );
}

int latestClosedAiReportMonthForYear({
  required int year,
  required DateTime now,
}) {
  final DateTime normalizedNow = toKst(now);
  if (year < normalizedNow.year) {
    return 12;
  }
  if (year > normalizedNow.year) {
    return 0;
  }

  int latestClosedMonth = 0;
  for (int month = 1; month <= 12; month++) {
    if (isAiReportMonthClosed(year: year, month: month, now: normalizedNow)) {
      latestClosedMonth = month;
    }
  }
  return latestClosedMonth;
}

bool isYearlyAiReportClosed({required int year, required DateTime now}) {
  return latestClosedAiReportMonthForYear(year: year, now: now) >= 12;
}

int _startMonthForYear({
  required int year,
  required DateTime? firstRecordDate,
}) {
  if (firstRecordDate == null) {
    return 1;
  }
  if (year < firstRecordDate.year) {
    return 13;
  }
  if (year == firstRecordDate.year) {
    return firstRecordDate.month;
  }
  return 1;
}
