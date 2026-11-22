import "package:dailyquestion/features/notifications/daily_question_notification_plan.dart";
import "package:flutter_test/flutter_test.dart";
import "package:timezone/data/latest.dart" as tz_data;
import "package:timezone/timezone.dart" as tz;

void main() {
  late tz.Location seoul;

  setUpAll(() {
    tz_data.initializeTimeZones();
    seoul = tz.getLocation("Asia/Seoul");
  });

  tz.TZDateTime at(int day, int hour, [int minute = 0]) {
    return tz.TZDateTime(seoul, 2026, 11, day, hour, minute);
  }

  List<PlannedNotification> plan({
    required tz.TZDateTime now,
    int hour = 9,
    int minute = 0,
    bool dailyEnabled = true,
    bool eveningEnabled = true,
    bool answeredToday = false,
    int activeStreakDays = 0,
    Map<int, String> questions = const <int, String>{},
    String? hint,
  }) {
    return planDailyQuestionNotifications(
      now: now,
      hour: hour,
      minute: minute,
      dailyEnabled: dailyEnabled,
      eveningEnabled: eveningEnabled,
      answeredToday: answeredToday,
      activeStreakDays: activeStreakDays,
      questions: questions,
      nextAnswerHintTitle: hint,
    );
  }

  Iterable<PlannedNotification> ofKind(
    List<PlannedNotification> items,
    PlannedNotificationKind kind,
  ) {
    return items.where((PlannedNotification item) => item.kind == kind);
  }

  test("returns nothing when the daily notification is off", () {
    expect(plan(now: at(7, 8), dailyEnabled: false), isEmpty);
  });

  test("schedules one daily notification per day with that day's question", () {
    final List<PlannedNotification> items = plan(
      now: at(7, 8),
      questions: <int, String>{0: "나에게 가장 중요한 루틴은?", 1: "요즘 자주 듣는 노래는?"},
    );
    final List<PlannedNotification> daily = ofKind(
      items,
      PlannedNotificationKind.daily,
    ).toList();

    expect(daily, hasLength(dailyQuestionPlanDays));
    expect(daily.first.scheduledAt, at(7, 9));
    expect(daily.first.id, dailyQuestionPlanBaseId);
    expect(daily.first.title, dailyQuestionDefaultTitle);
    expect(daily.first.body, "나에게 가장 중요한 루틴은?");
    expect(daily[1].body, "요즘 자주 듣는 노래는?");
    expect(daily[2].body, dailyQuestionFallbackBody);
  });

  test("flattens line breaks in questions", () {
    final List<PlannedNotification> items = plan(
      now: at(7, 8),
      questions: <int, String>{0: "올해 안에 꼭 해보고 싶은 일\n하나는 무엇인가요?"},
    );
    expect(items.first.body, "올해 안에 꼭 해보고 싶은 일 하나는 무엇인가요?");
  });

  test("skips today's notifications once the user answered", () {
    final List<PlannedNotification> items = plan(
      now: at(7, 8),
      answeredToday: true,
    );
    expect(
      items.any(
        (PlannedNotification item) =>
            item.id == dailyQuestionPlanBaseId ||
            item.id == eveningReminderPlanBaseId,
      ),
      isFalse,
    );
    expect(items.first.scheduledAt, at(8, 9));
  });

  test("skips today's daily notification when its time already passed", () {
    final List<PlannedNotification> items = plan(now: at(7, 10));
    final PlannedNotification firstDaily = ofKind(
      items,
      PlannedNotificationKind.daily,
    ).first;
    expect(firstDaily.scheduledAt, at(8, 9));
  });

  test("sends a catch-up when the time was set to the current minute", () {
    final List<PlannedNotification> items = plan(
      now: at(7, 9, 0).add(const Duration(seconds: 20)),
    );
    final List<PlannedNotification> catchups = ofKind(
      items,
      PlannedNotificationKind.dailyCatchup,
    ).toList();
    expect(catchups, hasLength(1));
    expect(catchups.single.id, dailyQuestionPlanBaseId);
  });

  test("puts the growth hint only on the next daily notification", () {
    final List<PlannedNotification> daily = ofKind(
      plan(now: at(7, 10), hint: "오늘 쓰면 물고기가 자라요!"),
      PlannedNotificationKind.daily,
    ).toList();
    expect(daily.first.title, "오늘 쓰면 물고기가 자라요!");
    expect(
      daily
          .skip(1)
          .every(
            (PlannedNotification item) =>
                item.title == dailyQuestionDefaultTitle,
          ),
      isTrue,
    );
  });

  group("evening reminder", () {
    test("is scheduled at 9pm for each open day", () {
      final List<PlannedNotification> evening = ofKind(
        plan(now: at(7, 8)),
        PlannedNotificationKind.evening,
      ).toList();
      expect(evening, hasLength(dailyQuestionPlanDays));
      expect(evening.first.scheduledAt, at(7, eveningReminderHour));
      expect(evening.first.id, eveningReminderPlanBaseId);
    });

    test("warns about a streak on the next unanswered day only", () {
      final List<PlannedNotification> evening = ofKind(
        plan(
          now: at(7, 8),
          activeStreakDays: 4,
          questions: <int, String>{0: "나에게 가장 중요한 루틴은?"},
        ),
        PlannedNotificationKind.evening,
      ).toList();
      expect(evening.first.title, "연속 4일 기록이 오늘 끊겨요");
      expect(evening.first.body, "1분이면 충분해요. 나에게 가장 중요한 루틴은?");
      expect(evening[1].title, eveningReminderDefaultTitle);
    });

    test("moves the streak warning to tomorrow after answering today", () {
      final List<PlannedNotification> evening = ofKind(
        plan(now: at(7, 22), answeredToday: true, activeStreakDays: 5),
        PlannedNotificationKind.evening,
      ).toList();
      expect(evening.first.scheduledAt, at(8, eveningReminderHour));
      expect(evening.first.title, "연속 5일 기록이 오늘 끊겨요");
    });

    test("uses the generic copy without a streak", () {
      final PlannedNotification first = ofKind(
        plan(now: at(7, 8)),
        PlannedNotificationKind.evening,
      ).first;
      expect(first.title, eveningReminderDefaultTitle);
      expect(first.body, eveningReminderFallbackBody);
    });

    test("is skipped when turned off", () {
      expect(
        ofKind(
          plan(now: at(7, 8), eveningEnabled: false),
          PlannedNotificationKind.evening,
        ),
        isEmpty,
      );
    });

    test("is skipped when the daily time is already in the evening", () {
      expect(
        ofKind(
          plan(now: at(7, 8), hour: eveningReminderLatestDailyHour),
          PlannedNotificationKind.evening,
        ),
        isEmpty,
      );
    });
  });

  test("uses unique ids within the known id range", () {
    final List<PlannedNotification> items = plan(now: at(7, 8));
    final Set<int> ids = items
        .map((PlannedNotification item) => item.id)
        .toSet();
    expect(ids, hasLength(items.length));
    expect(allDailyQuestionPlanIds().toSet().containsAll(ids), isTrue);
  });
}
