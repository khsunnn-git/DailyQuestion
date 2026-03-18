import "package:dailyquestion/core/kst_date_time.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  group("durationUntilNextKstDateChange", () {
    test("returns the remaining time until the next KST midnight", () {
      final Duration remaining = durationUntilNextKstDateChange(
        from: DateTime.utc(2026, 3, 18, 14, 59, 30),
      );

      expect(remaining, const Duration(seconds: 30));
    });

    test("returns 24 hours exactly at KST midnight", () {
      final Duration remaining = durationUntilNextKstDateChange(
        from: DateTime.utc(2026, 3, 18, 15),
      );

      expect(remaining, const Duration(hours: 24));
    });

    test("handles the year-end boundary in KST", () {
      final Duration remaining = durationUntilNextKstDateChange(
        from: DateTime.utc(2026, 12, 31, 14, 59, 59),
      );

      expect(remaining, const Duration(seconds: 1));
    });
  });
}
