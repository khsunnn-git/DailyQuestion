import "package:isar/isar.dart";

part "user_profile_entity.g.dart";

@collection
class UserProfileEntity {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String key;

  late String value;
}
