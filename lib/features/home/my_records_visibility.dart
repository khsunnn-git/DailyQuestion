import "../../core/kst_date_time.dart";
import "../question/today_question_store.dart";

DateTime myRecordsDisplayDate(TodayQuestionRecord record) {
  final String? key = record.questionDateKey?.trim();
  if (key != null && key.length == 8) {
    final int? year = int.tryParse(key.substring(0, 4));
    final int? month = int.tryParse(key.substring(4, 6));
    final int? day = int.tryParse(key.substring(6, 8));
    if (year != null && month != null && day != null) {
      return DateTime(year, month, day);
    }
  }
  final DateTime kst = toKst(record.createdAt);
  return DateTime(kst.year, kst.month, kst.day);
}

DateTime? resolveMyRecordsVisibleStartDate({
  required DateTime? storedInstallDate,
  required Iterable<TodayQuestionRecord> records,
}) {
  DateTime? earliestRecordDate;
  for (final TodayQuestionRecord record in records) {
    final DateTime displayDate = myRecordsDisplayDate(record);
    final DateTime normalized = DateTime(
      displayDate.year,
      displayDate.month,
      displayDate.day,
    );
    if (earliestRecordDate == null || normalized.isBefore(earliestRecordDate)) {
      earliestRecordDate = normalized;
    }
  }

  if (storedInstallDate == null) {
    return earliestRecordDate;
  }
  final DateTime normalizedInstallDate = DateTime(
    storedInstallDate.year,
    storedInstallDate.month,
    storedInstallDate.day,
  );
  if (earliestRecordDate == null ||
      !earliestRecordDate.isBefore(normalizedInstallDate)) {
    return normalizedInstallDate;
  }
  return earliestRecordDate;
}
