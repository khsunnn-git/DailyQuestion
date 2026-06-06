import "data/local_db/local_database.dart";
import "features/bucket/bucket_backup_service.dart";
import "features/home/daily_checkin_backup_service.dart";
import "features/home/daily_checkin_store.dart";
import "features/question/today_question_store.dart";
import "features/question/user_answer_backup_service.dart";
import "features/report/ai_report_regeneration_service.dart";

Future<void> initializeAppDependencies() async {
  await LocalDatabase.instance.initialize();
  await TodayQuestionStore.instance.initialize();
  await DailyCheckinStore.instance.initialize();
  await startUserAnswerBackupService();
  await startDailyCheckinBackupService();
  await startBucketBackupService();
  await startAiReportRegenerationService();
}
