import "../../data/local_db/entities/bucket_item_entity.dart";
import "../../data/local_db/local_database.dart";
import "../question/today_question_store.dart";
import "more_profile_stats_store.dart";

Future<MoreProfileStats> loadMoreProfileStats() async {
  final isar = await LocalDatabase.instance.isar;
  final int bucketCount = await isar.bucketItemEntitys.count();

  await TodayQuestionStore.instance.initialize();
  final int streakDays = TodayQuestionStore.instance.consecutiveRecordDays;

  return MoreProfileStats(
    questionStreakDays: streakDays > 0 ? streakDays : null,
    bucketCount: bucketCount,
  );
}
