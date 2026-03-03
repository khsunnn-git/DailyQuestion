import "data/local_db/local_database.dart";
import "features/home/daily_checkin_store.dart";
import "features/question/today_question_store.dart";

Future<void> initializeAppDependencies() async {
  await LocalDatabase.instance.initialize();
  await TodayQuestionStore.instance.initialize();
  await DailyCheckinStore.instance.initialize();
}
