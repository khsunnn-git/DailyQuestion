import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_auth/firebase_auth.dart";

import "user_profile_store.dart";

const String _usersCollectionId = "users";
const String _answersCollectionId = "answers";

enum PostLoginDestination { termsConsent, home }

class UserProfileRemoteService {
  UserProfileRemoteService._({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  static final UserProfileRemoteService instance = UserProfileRemoteService._();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<PostLoginDestination> resolvePostLoginDestination() async {
    final User? user = _auth.currentUser;
    if (user == null || user.isAnonymous) {
      return PostLoginDestination.termsConsent;
    }

    final DocumentReference<Map<String, dynamic>> userDoc = _firestore
        .collection(_usersCollectionId)
        .doc(user.uid);
    final DocumentSnapshot<Map<String, dynamic>> snapshot = await userDoc.get();
    final Map<String, dynamic>? data = snapshot.data();
    final String? remoteNickname = _normalizedString(data?["nickname"]);
    final bool remoteConsentAccepted = data?["consentAccepted"] == true;
    final bool remoteOnboardingCompleted =
        data?["onboardingCompleted"] == true;
    final bool hasRemoteAnswers = await _hasRemoteAnswers(userDoc);
    final bool isReturningUser =
        remoteOnboardingCompleted ||
        remoteConsentAccepted ||
        remoteNickname != null ||
        hasRemoteAnswers;

    if (!isReturningUser) {
      return PostLoginDestination.termsConsent;
    }

    await saveInitialConsentAccepted(true);
    if (remoteNickname != null) {
      await saveNickname(remoteNickname);
    }
    return PostLoginDestination.home;
  }

  Future<void> syncCurrentUserProfile() async {
    final User? user = _auth.currentUser;
    if (user == null || user.isAnonymous) {
      return;
    }

    final bool consentAccepted = await loadInitialConsentAccepted();
    final String? nickname = _normalizedString(await loadNickname());
    final Map<String, dynamic> payload = <String, dynamic>{
      "updatedAt": FieldValue.serverTimestamp(),
    };

    if (consentAccepted) {
      payload["consentAccepted"] = true;
    }
    if (nickname != null) {
      payload["nickname"] = nickname;
    }
    if (consentAccepted && nickname != null) {
      payload["onboardingCompleted"] = true;
    }
    if (payload.length == 1) {
      return;
    }

    await _firestore
        .collection(_usersCollectionId)
        .doc(user.uid)
        .set(payload, SetOptions(merge: true));
  }

  Future<bool> _hasRemoteAnswers(
    DocumentReference<Map<String, dynamic>> userDoc,
  ) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await userDoc
        .collection(_answersCollectionId)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  String? _normalizedString(Object? value) {
    final String text = "$value".trim();
    if (text.isEmpty || text == "null") {
      return null;
    }
    return text;
  }
}
