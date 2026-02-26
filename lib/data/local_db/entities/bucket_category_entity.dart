import "package:isar/isar.dart";

part "bucket_category_entity.g.dart";

@collection
class BucketCategoryEntity {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String name;

  late int colorValue;
}
