import "package:cloud_firestore/cloud_firestore.dart";

class PublicTodayRecord {
  const PublicTodayRecord({
    required this.body,
    required this.author,
    required this.createdAt,
  });

  final String body;
  final String author;
  final DateTime createdAt;
}

class PublicTodayRecordsRepository {
  PublicTodayRecordsRepository._();

  static final PublicTodayRecordsRepository instance =
      PublicTodayRecordsRepository._();

  static const String _rootCollection = "public_answers";

  Future<List<PublicTodayRecord>> fetchByDateKey(String questionDateKey) async {
    final FirebaseFirestore db = FirebaseFirestore.instance;
    final List<QuerySnapshot<Map<String, dynamic>>> snapshots =
        await Future.wait(<Future<QuerySnapshot<Map<String, dynamic>>>>[
          _slotQuery(db, questionDateKey, 0).get(),
          _slotQuery(db, questionDateKey, 1).get(),
          _slotQuery(db, questionDateKey, 2).get(),
        ]);

    final List<PublicTodayRecord> records = <PublicTodayRecord>[];
    for (final QuerySnapshot<Map<String, dynamic>> snap in snapshots) {
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snap.docs) {
        final Map<String, dynamic> data = doc.data();
        final String body = (data["answerText"] as String? ?? "").trim();
        if (body.isEmpty) {
          continue;
        }
        final String author = (data["anonymousName"] as String? ?? "익명의 사용자님")
            .trim();
        final Timestamp? ts = data["createdAt"] as Timestamp?;
        records.add(
          PublicTodayRecord(
            body: body,
            author: author.isEmpty ? "익명의 사용자님" : author,
            createdAt: ts?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0),
          ),
        );
      }
    }

    records.sort((PublicTodayRecord a, PublicTodayRecord b) {
      return b.createdAt.compareTo(a.createdAt);
    });
    return records;
  }

  Query<Map<String, dynamic>> _slotQuery(
    FirebaseFirestore db,
    String questionDateKey,
    int slot,
  ) {
    return db
        .collection(_rootCollection)
        .doc(questionDateKey)
        .collection("slots")
        .doc("slot_$slot")
        .collection("answers")
        .orderBy("createdAt", descending: true)
        .limit(50);
  }
}
