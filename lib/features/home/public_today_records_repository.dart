import "dart:async";
import "dart:convert";

import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:http/http.dart" as http;

import "../auth/auth_service.dart";
import "../question/public_answer_retention.dart";
import "../moderation/public_record_moderation.dart";

class PublicTodayRecord {
  const PublicTodayRecord({
    required this.body,
    required this.author,
    required this.createdAt,
    required this.questionDateKey,
    required this.questionSlot,
    required this.answerDocId,
    this.likeCount = 0,
  });

  final String body;
  final String author;
  final DateTime createdAt;
  final String questionDateKey;
  final int questionSlot;
  final String answerDocId;
  final int likeCount;

  bool get canToggleLike => answerDocId.isNotEmpty && questionSlot >= 0;
}

class PublicRecordLikeResult {
  const PublicRecordLikeResult({required this.liked, required this.likeCount});

  final bool liked;
  final int likeCount;
}

class PublicRecordLikeException implements Exception {
  const PublicRecordLikeException(this.message);

  final String message;
}

class PublicTodayRecordsRepository {
  PublicTodayRecordsRepository._();

  static final PublicTodayRecordsRepository instance =
      PublicTodayRecordsRepository._();

  static const String _rootCollection = "public_answers";
  static final Uri _toggleLikeEndpoint = Uri.parse(
    "https://us-central1-dailyquestion-29840.cloudfunctions.net/togglePublicAnswerLikeApi",
  );

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
        final String? moderationStatus = (data["moderationStatus"] as String?)
            ?.trim();
        final double? sentimentScore = _parseSentimentScore(
          data["sentimentScore"],
        );
        if (PublicRecordModeration.shouldHideOnFeed(
          body: body,
          moderationStatus: moderationStatus,
          sentimentScore: sentimentScore,
        )) {
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
            questionDateKey: questionDateKey,
            questionSlot: _slotFromDocument(doc),
            answerDocId: doc.id,
            likeCount: _parseLikeCount(data["likeCount"]),
          ),
        );
      }
    }

    records.sort((PublicTodayRecord a, PublicTodayRecord b) {
      return b.createdAt.compareTo(a.createdAt);
    });
    return records;
  }

  Future<List<PublicTodayRecord>> fetchRecentDays({
    int days = publicAnswerRetentionDays,
    DateTime? now,
  }) async {
    final List<String> dateKeys = recentPublicAnswerDateKeys(
      now: now,
      days: days,
    );
    final List<List<PublicTodayRecord>> recordsByDate =
        await Future.wait<List<PublicTodayRecord>>(
          dateKeys.map(fetchByDateKey),
        );
    final List<PublicTodayRecord> records =
        recordsByDate
            .expand((List<PublicTodayRecord> items) => items)
            .toList(growable: false)
          ..sort((PublicTodayRecord a, PublicTodayRecord b) {
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
      final String? moderationStatus = (data["moderationStatus"] as String?)
          ?.trim();
      final double? sentimentScore = _parseSentimentScore(
        data["sentimentScore"],
      );
      if (PublicRecordModeration.shouldHideOnFeed(
        body: body,
        moderationStatus: moderationStatus,
        sentimentScore: sentimentScore,
      )) {
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
          questionDateKey:
              (data["questionDateKey"] as String?)?.trim().isNotEmpty == true
              ? (data["questionDateKey"] as String).trim()
              : _dateKeyFromDocument(doc),
          questionSlot: _slotFromDocument(doc),
          answerDocId: doc.id,
          likeCount: _parseLikeCount(data["likeCount"]),
        ),
      );
    }
    return records;
  }

  Future<PublicRecordLikeResult> toggleLike(PublicTodayRecord record) async {
    if (!record.canToggleLike) {
      return PublicRecordLikeResult(liked: false, likeCount: record.likeCount);
    }

    final User user = await AuthService.instance.ensureSignedInUser();
    final String? idToken = await user.getIdToken();
    if (idToken == null || idToken.trim().isEmpty) {
      return PublicRecordLikeResult(liked: false, likeCount: record.likeCount);
    }

    final http.Response response = await http.post(
      _toggleLikeEndpoint,
      headers: <String, String>{
        "Authorization": "Bearer ${idToken.trim()}",
        "Content-Type": "application/json",
      },
      body: jsonEncode(<String, Object?>{
        "questionDateKey": record.questionDateKey,
        "questionSlot": record.questionSlot,
        "answerDocId": record.answerDocId,
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PublicRecordLikeException(
        "togglePublicAnswerLikeApi failed (${response.statusCode})",
      );
    }

    final Object? data = jsonDecode(response.body);
    if (data is Map) {
      return PublicRecordLikeResult(
        liked: data["liked"] == true,
        likeCount: _parseLikeCount(data["likeCount"]),
      );
    }
    return PublicRecordLikeResult(liked: false, likeCount: record.likeCount);
  }

  double? _parseSentimentScore(Object? raw) {
    if (raw is num) {
      return raw.toDouble();
    }
    if (raw is String) {
      return double.tryParse(raw);
    }
    return null;
  }

  int _parseLikeCount(Object? raw) {
    if (raw is int) {
      return raw < 0 ? 0 : raw;
    }
    if (raw is num) {
      final int value = raw.toInt();
      return value < 0 ? 0 : value;
    }
    if (raw is String) {
      final int? value = int.tryParse(raw);
      if (value == null || value < 0) {
        return 0;
      }
      return value;
    }
    return 0;
  }

  int _slotFromDocument(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final String slotDocId = doc.reference.parent.parent?.id ?? "";
    if (!slotDocId.startsWith("slot_")) {
      return -1;
    }
    return int.tryParse(slotDocId.substring("slot_".length)) ?? -1;
  }

  String _dateKeyFromDocument(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    return doc.reference.parent.parent?.parent.parent?.id ?? "";
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
