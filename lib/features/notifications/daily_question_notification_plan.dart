import "package:timezone/timezone.dart" as tz;

/// 오늘의 질문 알림과 저녁 리마인드를 날짜별로 계산한다.
///
/// 반복 알림 1개 대신 앞으로 [dailyQuestionPlanDays]일 치를 날짜별로 따로
/// 예약해서, 날마다 그날의 질문을 본문에 넣고 이미 답한 날은 건너뛴다.
/// 앱을 열거나 답변을 저장할 때마다 다시 계산해서 예약을 갈아 끼운다.

const int dailyQuestionPlanDays = 14;
const int dailyQuestionPlanBaseId = 11000;
const int eveningReminderPlanBaseId = 11100;

/// 저녁 리마인드 시각.
const int eveningReminderHour = 21;

/// 오늘의 질문 알림이 이 시각 이후로 설정돼 있으면 저녁 리마인드는 보내지 않는다.
const int eveningReminderLatestDailyHour = 20;

const String dailyQuestionDefaultTitle = "오늘의 질문이 도착했어요";
const String dailyQuestionFallbackBody = "내일의 나를 만날 수 있는 소중한 질문 시간!";
const String eveningReminderDefaultTitle = "오늘 질문, 아직 기다리고 있어요";
const String eveningReminderFallbackBody = "1분이면 충분해요. 오늘 하루를 남겨 보세요";

enum PlannedNotificationKind { daily, dailyCatchup, evening }

class PlannedNotification {
  const PlannedNotification({
    required this.id,
    required this.kind,
    required this.scheduledAt,
    required this.title,
    required this.body,
  });

  final int id;
  final PlannedNotificationKind kind;
  final tz.TZDateTime scheduledAt;
  final String title;
  final String body;

  @override
  String toString() =>
      "PlannedNotification(id=$id kind=${kind.name} at=$scheduledAt title=$title)";
}

/// 이 계획이 쓰는 모든 알림 ID. 다시 예약하기 전에 한꺼번에 지울 때 쓴다.
List<int> allDailyQuestionPlanIds() {
  return <int>[
    for (int i = 0; i < dailyQuestionPlanDays; i++) dailyQuestionPlanBaseId + i,
    for (int i = 0; i < dailyQuestionPlanDays; i++)
      eveningReminderPlanBaseId + i,
  ];
}

/// [questions]의 키는 오늘로부터 지난 일수(0 = 오늘)다. 없는 날은 기본 문구를 쓴다.
///
/// [activeStreakDays]는 어제 또는 오늘까지 이어진 연속 기록일(끊겼으면 0).
/// [nextAnswerHintTitle]은 다음 답변 하나로 캐릭터가 자랄 때의 제목
/// (예: "오늘 쓰면 물고기가 자라요!")이며, 다음 오늘의 질문 알림 1개에만 쓴다.
List<PlannedNotification> planDailyQuestionNotifications({
  required tz.TZDateTime now,
  required int hour,
  required int minute,
  required bool dailyEnabled,
  required bool eveningEnabled,
  required bool answeredToday,
  required int activeStreakDays,
  Map<int, String> questions = const <int, String>{},
  String? nextAnswerHintTitle,
}) {
  if (!dailyEnabled) {
    return const <PlannedNotification>[];
  }
  final List<PlannedNotification> planned = <PlannedNotification>[];
  final bool canSendEvening =
      eveningEnabled && hour < eveningReminderLatestDailyHour;
  final int firstOpenDay = answeredToday ? 1 : 0;
  bool hintUsed = false;

  for (int day = firstOpenDay; day < dailyQuestionPlanDays; day++) {
    final String? question = _cleanQuestion(questions[day]);

    final tz.TZDateTime dailyAt = tz.TZDateTime(
      now.location,
      now.year,
      now.month,
      now.day + day,
      hour,
      minute,
    );
    tz.TZDateTime? dailyScheduledAt;
    PlannedNotificationKind dailyKind = PlannedNotificationKind.daily;
    if (dailyAt.isAfter(now)) {
      dailyScheduledAt = dailyAt;
    } else if (day == 0 && now.hour == hour && now.minute == minute) {
      // 지금 이 분으로 시간을 맞춘 경우 오늘 알림을 놓치지 않게 바로 보낸다.
      dailyScheduledAt = now.add(const Duration(seconds: 5));
      dailyKind = PlannedNotificationKind.dailyCatchup;
    }
    if (dailyScheduledAt != null) {
      final bool useHint = !hintUsed && nextAnswerHintTitle != null;
      hintUsed = hintUsed || useHint;
      planned.add(
        PlannedNotification(
          id: dailyQuestionPlanBaseId + day,
          kind: dailyKind,
          scheduledAt: dailyScheduledAt,
          title: useHint ? nextAnswerHintTitle : dailyQuestionDefaultTitle,
          body: question ?? dailyQuestionFallbackBody,
        ),
      );
    }

    if (!canSendEvening) {
      continue;
    }
    final tz.TZDateTime eveningAt = tz.TZDateTime(
      now.location,
      now.year,
      now.month,
      now.day + day,
      eveningReminderHour,
    );
    if (!eveningAt.isAfter(now)) {
      continue;
    }
    final bool streakAtRisk = day == firstOpenDay && activeStreakDays >= 1;
    planned.add(
      PlannedNotification(
        id: eveningReminderPlanBaseId + day,
        kind: PlannedNotificationKind.evening,
        scheduledAt: eveningAt,
        title: streakAtRisk
            ? "연속 $activeStreakDays일 기록이 오늘 끊겨요"
            : eveningReminderDefaultTitle,
        body: streakAtRisk
            ? (question == null
                  ? eveningReminderFallbackBody
                  : "1분이면 충분해요. $question")
            : (question ?? eveningReminderFallbackBody),
      ),
    );
  }
  return planned;
}

String? _cleanQuestion(String? raw) {
  if (raw == null) {
    return null;
  }
  final String cleaned = raw.replaceAll(RegExp(r"\s+"), " ").trim();
  return cleaned.isEmpty ? null : cleaned;
}
