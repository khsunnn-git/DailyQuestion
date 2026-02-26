import "package:isar/isar.dart";
import "package:path_provider/path_provider.dart";

import "entities/answer_record_entity.dart";
import "entities/bucket_category_entity.dart";
import "entities/bucket_item_entity.dart";

class LocalDatabase {
  LocalDatabase._();

  static final LocalDatabase instance = LocalDatabase._();

  late Isar _isar;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    final directory = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      <CollectionSchema<dynamic>>[
        AnswerRecordEntitySchema,
        BucketItemEntitySchema,
        BucketCategoryEntitySchema,
      ],
      directory: directory.path,
      name: "dailyquestion_db",
    );
    _initialized = true;
  }

  Future<Isar> get isar async {
    await initialize();
    return _isar;
  }
}
