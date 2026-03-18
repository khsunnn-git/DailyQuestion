import "../../core/kst_date_time.dart";

const int publicAnswerRetentionDays = 7;

String publicAnswerRetentionCutoffDateKey({
  DateTime? now,
  int retentionDays = publicAnswerRetentionDays,
}) {
  assert(retentionDays > 0);
  final DateTime baseDate = kstDateOnly(now ?? DateTime.now());
  final DateTime cutoffDate = baseDate.subtract(
    Duration(days: retentionDays - 1),
  );
  return kstDateKeyFromDateTime(cutoffDate);
}

bool shouldDeletePublicAnswerDateKey(
  String questionDateKey, {
  DateTime? now,
  int retentionDays = publicAnswerRetentionDays,
}) {
  final String normalizedKey = questionDateKey.trim();
  if (normalizedKey.isEmpty) {
    return false;
  }
  final String cutoffKey = publicAnswerRetentionCutoffDateKey(
    now: now,
    retentionDays: retentionDays,
  );
  return normalizedKey.compareTo(cutoffKey) < 0;
}

List<String> recentPublicAnswerDateKeys({
  DateTime? now,
  int days = publicAnswerRetentionDays,
}) {
  assert(days > 0);
  final DateTime baseDate = kstDateOnly(now ?? DateTime.now());
  return List<String>.generate(days, (int index) {
    final DateTime date = baseDate.subtract(Duration(days: index));
    return kstDateKeyFromDateTime(date);
  }, growable: false);
}
