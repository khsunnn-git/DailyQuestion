import "package:isar/isar.dart";

part "answer_record_entity.g.dart";

@collection
class AnswerRecordEntity {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late int createdAtMillis;

  late DateTime createdAt;
  late String answer;
  late String author;
  String? bucketTag;
  List<String> bucketTags = <String>[];
  late bool isPublic;
  late int questionSlot;
  late String questionDateKey;
  String? questionText;
  late DateTime updatedAt;
}
