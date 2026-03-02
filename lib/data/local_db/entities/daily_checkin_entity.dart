import "package:isar/isar.dart";

part "daily_checkin_entity.g.dart";

@collection
class DailyCheckinEntity {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String dateKey;

  late DateTime createdAt;
  late DateTime updatedAt;

  int? moodIndex;
  int? energyIndex;
  int? stressIndex;
}
