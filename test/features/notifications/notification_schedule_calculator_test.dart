import "package:flutter_test/flutter_test.dart";
import "package:timezone/data/latest.dart" as tz_data;
import "package:timezone/timezone.dart" as tz;

import "package:dailyquestion/features/notifications/notification_schedule_calculator.dart";

void main() {
  setUpAll(() {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation("Asia/Seoul"));
  });

  group("nextDailyNotificationTime", () {
    test("keeps a future time on the same day with zero seconds", () {
      final tz.TZDateTime now = tz.TZDateTime(
        tz.local,
        2026,
        3,
        20,
        14,
        12,
        47,
      );

      final tz.TZDateTime scheduled = nextDailyNotificationTime(
        now: now,
        hour: 15,
        minute: 30,
      );

      expect(scheduled, tz.TZDateTime(tz.local, 2026, 3, 20, 15, 30));
      expect(scheduled.second, 0);
    });

    test("moves to the next day when the selected minute already passed", () {
      final tz.TZDateTime now = tz.TZDateTime(tz.local, 2026, 3, 20, 15, 30, 1);

      final tz.TZDateTime scheduled = nextDailyNotificationTime(
        now: now,
        hour: 15,
        minute: 30,
      );

      expect(scheduled, tz.TZDateTime(tz.local, 2026, 3, 21, 15, 30));
      expect(scheduled.second, 0);
    });
  });

  group("bucketDdayNotificationTime", () {
    test("normalizes reminders to noon on the D-day offset date", () {
      final tz.TZDateTime scheduled = bucketDdayNotificationTime(
        location: tz.local,
        dueDate: DateTime(2026, 3, 23, 18, 45, 59),
        daysBefore: 3,
      );

      expect(scheduled, tz.TZDateTime(tz.local, 2026, 3, 20, 12));
      expect(scheduled.hour, 12);
      expect(scheduled.minute, 0);
      expect(scheduled.second, 0);
    });
  });

  group("bucketDueDateNotificationTime", () {
    test("normalizes the due date reminder to noon", () {
      final tz.TZDateTime scheduled = bucketDueDateNotificationTime(
        location: tz.local,
        dueDate: DateTime(2026, 3, 23, 18, 45, 59),
      );

      expect(scheduled, tz.TZDateTime(tz.local, 2026, 3, 23, 12));
      expect(scheduled.hour, 12);
      expect(scheduled.minute, 0);
      expect(scheduled.second, 0);
    });
  });

  group("nextBucketNotificationTime", () {
    test("keeps the D-day offset reminder when it is still in the future", () {
      final tz.TZDateTime? scheduled = nextBucketNotificationTime(
        location: tz.local,
        dueDate: DateTime(2026, 3, 23, 18, 45, 59),
        daysBefore: 3,
        now: tz.TZDateTime(tz.local, 2026, 3, 20, 11, 59, 59),
      );

      expect(scheduled, tz.TZDateTime(tz.local, 2026, 3, 20, 12));
    });

    test(
      "falls back to the due date noon when the D-day reminder was missed",
      () {
        final tz.TZDateTime? scheduled = nextBucketNotificationTime(
          location: tz.local,
          dueDate: DateTime(2026, 3, 23, 18, 45, 59),
          daysBefore: 3,
          now: tz.TZDateTime(tz.local, 2026, 3, 20, 12, 0, 1),
        );

        expect(scheduled, tz.TZDateTime(tz.local, 2026, 3, 23, 12));
      },
    );

    test("returns null when both reminder times have already passed", () {
      final tz.TZDateTime? scheduled = nextBucketNotificationTime(
        location: tz.local,
        dueDate: DateTime(2026, 3, 23, 18, 45, 59),
        daysBefore: 3,
        now: tz.TZDateTime(tz.local, 2026, 3, 23, 12, 0, 1),
      );

      expect(scheduled, isNull);
    });
  });
}
