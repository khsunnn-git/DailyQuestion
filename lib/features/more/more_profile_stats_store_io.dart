import "../../data/local_db/entities/bucket_item_entity.dart";
import "../../data/local_db/local_database.dart";
import "../../core/kst_date_time.dart";
import "../question/today_question_store.dart";
import "more_profile_stats_store.dart";

Future<MoreProfileStats> loadMoreProfileStats() async {
  final isar = await LocalDatabase.instance.isar;
  final int bucketCount = await isar.bucketItemEntitys.count();

  await TodayQuestionStore.instance.initialize();
  final Set<String> answeredDateKeys = <String>{};
  for (final record in TodayQuestionStore.instance.value) {
    final String key = (record.questionDateKey?.trim().isNotEmpty ?? false)
        ? record.questionDateKey!.trim()
        : kstDateKeyFromDateTime(record.createdAt);
    answeredDateKeys.add(key);
  }
  final int answeredDays = answeredDateKeys.length;

  return MoreProfileStats(
    questionStreakDays: answeredDays > 0 ? answeredDays : null,
    bucketCount: bucketCount,
  );
}
