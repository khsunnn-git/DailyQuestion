import "package:cloud_firestore/cloud_firestore.dart";
import "package:flutter/foundation.dart";
import "package:firebase_auth/firebase_auth.dart";

enum NicknameCheckState { available, duplicate, unavailable }

class NicknameCheckResult {
  const NicknameCheckResult({required this.state});

  final NicknameCheckState state;
}

class NicknameReservationResult {
  const NicknameReservationResult({
    required this.success,
    this.isDuplicate = false,
  });

  final bool success;
  final bool isDuplicate;
}

class NicknameFirestoreService {
  NicknameFirestoreService._();

  static final NicknameFirestoreService instance = NicknameFirestoreService._();
  static const String _nicknameIndexCollection = "nickname_index";
  static const String _usersCollection = "users";
  String? _cachedUid;

  Future<void> warmUpAuth() async {
    await _ensureUid();
  }

  Future<NicknameCheckResult> checkAvailability(String nickname) async {
    try {
      final String uid = await _ensureUid();
      final String normalized = _normalize(nickname);
      final DocumentReference<Map<String, dynamic>> ref = FirebaseFirestore
          .instance
          .collection(_nicknameIndexCollection)
          .doc(normalized);
      final DocumentSnapshot<Map<String, dynamic>> snap = await ref.get();
      if (!snap.exists) {
        return const NicknameCheckResult(state: NicknameCheckState.available);
      }
      final Map<String, dynamic>? data = snap.data();
      final String? reservedByUid = data?["reservedByUid"] as String?;
      if (reservedByUid == null || reservedByUid == uid) {
        return const NicknameCheckResult(state: NicknameCheckState.available);
      }
      return const NicknameCheckResult(state: NicknameCheckState.duplicate);
    } on FirebaseException catch (e, st) {
      _logFirebaseException(
        scope: "checkAvailability",
        error: e,
        stackTrace: st,
      );
      return const NicknameCheckResult(state: NicknameCheckState.unavailable);
    } catch (e, st) {
      _logUnknownException(
        scope: "checkAvailability",
        error: e,
        stackTrace: st,
      );
      return const NicknameCheckResult(state: NicknameCheckState.unavailable);
    }
  }

  Future<NicknameReservationResult> reserveAndSave(String nickname) async {
    try {
      final String uid = await _ensureUid();
      final String trimmed = nickname.trim();
      final String normalized = _normalize(trimmed);
      final FirebaseFirestore db = FirebaseFirestore.instance;
      final DocumentReference<Map<String, dynamic>> indexRef = db
          .collection(_nicknameIndexCollection)
          .doc(normalized);
      final DocumentReference<Map<String, dynamic>> userRef = db
          .collection(_usersCollection)
          .doc(uid);

      bool duplicate = false;
      await db.runTransaction((Transaction tx) async {
        final DocumentSnapshot<Map<String, dynamic>> userSnap = await tx.get(
          userRef,
        );
        final DocumentSnapshot<Map<String, dynamic>> indexSnap = await tx.get(
          indexRef,
        );
        if (indexSnap.exists) {
          final String? reservedByUid =
              indexSnap.data()?["reservedByUid"] as String?;
          if (reservedByUid != null && reservedByUid != uid) {
            duplicate = true;
            return;
          }
        }
        final Timestamp now = Timestamp.now();
        final String? previousNormalized =
            (userSnap.data()?["nicknameNormalized"] as String?)?.trim();
        if (previousNormalized != null &&
            previousNormalized.isNotEmpty &&
            previousNormalized != normalized) {
          final DocumentReference<Map<String, dynamic>> previousIndexRef = db
              .collection(_nicknameIndexCollection)
              .doc(previousNormalized);
          final DocumentSnapshot<Map<String, dynamic>> previousIndexSnap =
              await tx.get(previousIndexRef);
          final String? previousReservedByUid =
              previousIndexSnap.data()?["reservedByUid"] as String?;
          if (previousIndexSnap.exists && previousReservedByUid == uid) {
            tx.delete(previousIndexRef);
          }
        }
        tx.set(indexRef, <String, dynamic>{
          "nickname": trimmed,
          "nicknameNormalized": normalized,
          "reservedByUid": uid,
          "updatedAt": now,
          "createdAt": indexSnap.exists
              ? (indexSnap.data()?["createdAt"] ?? now)
              : now,
        }, SetOptions(merge: true));
        tx.set(userRef, <String, dynamic>{
          "nickname": trimmed,
          "nicknameNormalized": normalized,
          "updatedAt": now,
          "createdAt": userSnap.exists
              ? (userSnap.data()?["createdAt"] ?? now)
              : now,
        }, SetOptions(merge: true));
      });

      if (duplicate) {
        return const NicknameReservationResult(
          success: false,
          isDuplicate: true,
        );
      }
      return const NicknameReservationResult(success: true);
    } on FirebaseException catch (e, st) {
      _logFirebaseException(scope: "reserveAndSave", error: e, stackTrace: st);
      return const NicknameReservationResult(success: false);
    } catch (e, st) {
      _logUnknownException(scope: "reserveAndSave", error: e, stackTrace: st);
      return const NicknameReservationResult(success: false);
    }
  }

  Future<String> _ensureUid() async {
    if (_cachedUid != null && _cachedUid!.isNotEmpty) {
      return _cachedUid!;
    }
    final FirebaseAuth auth = FirebaseAuth.instance;
    final User? current = auth.currentUser;
    if (current != null) {
      _cachedUid = current.uid;
      return current.uid;
    }
    late final UserCredential credential;
    try {
      credential = await auth.signInAnonymously();
    } on FirebaseException catch (e, st) {
      _logFirebaseException(scope: "_ensureUid", error: e, stackTrace: st);
      rethrow;
    } catch (e, st) {
      _logUnknownException(scope: "_ensureUid", error: e, stackTrace: st);
      rethrow;
    }
    _cachedUid = credential.user!.uid;
    return _cachedUid!;
  }

  String _normalize(String nickname) {
    return nickname.trim().toLowerCase();
  }

  void _logFirebaseException({
    required String scope,
    required FirebaseException error,
    required StackTrace stackTrace,
  }) {
    if (!kDebugMode) {
      return;
    }
    debugPrint(
      "[NicknameFirestoreService][$scope] FirebaseException "
      "code=${error.code} message=${error.message}",
    );
    debugPrintStack(stackTrace: stackTrace);
  }

  void _logUnknownException({
    required String scope,
    required Object error,
    required StackTrace stackTrace,
  }) {
    if (!kDebugMode) {
      return;
    }
    debugPrint("[NicknameFirestoreService][$scope] Exception: $error");
    debugPrintStack(stackTrace: stackTrace);
  }
}
