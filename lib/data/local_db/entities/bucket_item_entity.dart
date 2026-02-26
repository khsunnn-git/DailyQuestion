import "package:isar/isar.dart";

part "bucket_item_entity.g.dart";

@collection
class BucketItemEntity {
  Id id = Isar.autoIncrement;

  late String title;
  late String category;
  late int categoryColorValue;
  late DateTime createdAt;
  DateTime? dueDate;
  late bool isCompleted;
  late DateTime updatedAt;
}
