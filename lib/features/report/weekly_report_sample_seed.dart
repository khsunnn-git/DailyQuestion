import "package:isar/isar.dart";

import "../../core/kst_date_time.dart";
import "../../data/local_db/entities/daily_checkin_entity.dart";
import "../../data/local_db/local_database.dart";
import "../question/today_question_store.dart";

class WeeklyReportSampleSeed {
  const WeeklyReportSampleSeed();

  Future<void> apply() async {
    await TodayQuestionStore.instance.initialize();
    final Isar isar = await LocalDatabase.instance.isar;
    final DateTime today = DateTime.now();
    final DateTime end = DateTime(today.year, today.month, today.day, 21);

    const List<String> questions = <String>[
      "오늘 가장 기분 좋았던 순간은?",
      "요즘 나를 조금 지치게 하는 건?",
      "최근 감사했던 일은?",
      "지금 가장 필요한 변화는?",
      "오늘 나를 웃게 만든 건?",
      "요즘 자주 떠오르는 생각은?",
      "지금의 나에게 해주고 싶은 말은?",
    ];
    const List<String> answers = <String>[
      "점심시간에 산책하면서 봄 냄새가 나서 기분이 좋아졌어요.",
      "일정이 겹쳐서 집중이 자꾸 끊기는 게 조금 지쳐요.",
      "동료가 먼저 도와줘서 일을 빨리 마칠 수 있었어요.",
      "아침 루틴을 조금 더 규칙적으로 바꾸고 싶어요.",
      "친구가 보낸 짧은 농담 메시지에 크게 웃었어요.",
      "이번 달 목표를 너무 많이 잡았나 계속 점검하게 돼요.",
      "조급해하지 말고 하나씩 해도 충분히 잘하고 있어.",
    ];
    // score: 5 (high) -> 1 (low)
    const List<int> moodScores = <int>[4, 3, 4, 3, 5, 4, 4];
    const List<int> energyScores = <int>[3, 2, 4, 3, 4, 3, 4];
    const List<int> stressScores = <int>[3, 2, 3, 2, 4, 3, 4];

    for (int i = 0; i < 7; i++) {
      final DateTime day = end.subtract(Duration(days: 6 - i));
      final String dateKey = kstDateKeyFromDateTime(day);
      final int slot = (day.difference(DateTime(day.year, 1, 1)).inDays + 1);

      await TodayQuestionStore.instance.saveRecord(
        answer: answers[i],
        isPublic: false,
        createdAt: day,
        questionText: questions[i],
        questionSlot: 0,
        questionDayOfYear: slot,
      );

      final DailyCheckinEntity entity = DailyCheckinEntity()
        ..dateKey = dateKey
        ..createdAt = day
        ..updatedAt = day
        ..moodIndex = 5 - moodScores[i]
        ..energyIndex = 5 - energyScores[i]
        ..stressIndex = 5 - stressScores[i];

      await isar.writeTxn(() async {
        await isar.dailyCheckinEntitys.putByDateKey(entity);
      });
    }
  }
}
