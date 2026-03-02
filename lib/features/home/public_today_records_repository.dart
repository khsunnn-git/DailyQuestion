import "dart:async";

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

  Stream<List<PublicTodayRecord>> watchByDateKey(String questionDateKey) {
    final FirebaseFirestore db = FirebaseFirestore.instance;
    final StreamController<List<PublicTodayRecord>> controller =
        StreamController<List<PublicTodayRecord>>();

    List<QueryDocumentSnapshot<Map<String, dynamic>>> slot0Docs =
        const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    List<QueryDocumentSnapshot<Map<String, dynamic>>> slot1Docs =
        const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    List<QueryDocumentSnapshot<Map<String, dynamic>>> slot2Docs =
        const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    bool hasSlot0 = false;
    bool hasSlot1 = false;
    bool hasSlot2 = false;

    void emitIfReady() {
      if (!(hasSlot0 && hasSlot1 && hasSlot2)) {
        return;
      }
      final List<PublicTodayRecord> records = <PublicTodayRecord>[
        ..._toRecords(slot0Docs),
        ..._toRecords(slot1Docs),
        ..._toRecords(slot2Docs),
      ];
      records.sort((PublicTodayRecord a, PublicTodayRecord b) {
        return b.createdAt.compareTo(a.createdAt);
      });
      if (!controller.isClosed) {
        controller.add(records);
      }
    }

    final List<StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
    subscriptions = <StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>[
      _slotQuery(db, questionDateKey, 0).snapshots().listen((
        QuerySnapshot<Map<String, dynamic>> snap,
      ) {
        slot0Docs = snap.docs;
        hasSlot0 = true;
        emitIfReady();
      }, onError: controller.addError),
      _slotQuery(db, questionDateKey, 1).snapshots().listen((
        QuerySnapshot<Map<String, dynamic>> snap,
      ) {
        slot1Docs = snap.docs;
        hasSlot1 = true;
        emitIfReady();
      }, onError: controller.addError),
      _slotQuery(db, questionDateKey, 2).snapshots().listen((
        QuerySnapshot<Map<String, dynamic>> snap,
      ) {
        slot2Docs = snap.docs;
        hasSlot2 = true;
        emitIfReady();
      }, onError: controller.addError),
    ];

    controller.onCancel = () async {
      for (final StreamSubscription<QuerySnapshot<Map<String, dynamic>>> sub
          in subscriptions) {
        await sub.cancel();
      }
    };

    return controller.stream;
  }

  List<PublicTodayRecord> _toRecords(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final List<PublicTodayRecord> records = <PublicTodayRecord>[];
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in docs) {
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
