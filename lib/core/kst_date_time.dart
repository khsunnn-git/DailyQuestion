const Duration _kstOffset = Duration(hours: 9);

DateTime nowInKst() {
  return toKst(DateTime.now());
}

DateTime toKst(DateTime dateTime) {
  return dateTime.toUtc().add(_kstOffset);
}

DateTime kstDateOnly(DateTime dateTime) {
  final DateTime kst = toKst(dateTime);
  return DateTime(kst.year, kst.month, kst.day);
}

String kstDateKeyFromDateTime(DateTime dateTime) {
  final DateTime kst = toKst(dateTime);
  final String mm = kst.month.toString().padLeft(2, "0");
  final String dd = kst.day.toString().padLeft(2, "0");
  return "${kst.year}$mm$dd";
}

String kstDateKeyNow() {
  return kstDateKeyFromDateTime(DateTime.now());
}

bool isSameKstDate(DateTime a, DateTime b) {
  final DateTime aKst = toKst(a);
  final DateTime bKst = toKst(b);
  return aKst.year == bKst.year &&
      aKst.month == bKst.month &&
      aKst.day == bKst.day;
}

Duration durationUntilNextKstDateChange({DateTime? from}) {
  final DateTime reference = from ?? DateTime.now();
  final DateTime kst = toKst(reference);
  final DateTime nextKstDate = DateTime.utc(kst.year, kst.month, kst.day + 1);
  final Duration remaining = nextKstDate.difference(kst);
  return remaining.isNegative ? Duration.zero : remaining;
}
