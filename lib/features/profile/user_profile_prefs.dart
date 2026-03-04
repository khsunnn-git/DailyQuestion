import "user_profile_store.dart";

class UserProfilePrefs {
  UserProfilePrefs._();

  static Future<String?> getNickname() async {
    return loadNickname();
  }

  static Future<void> setNickname(String nickname) async {
    await saveNickname(nickname);
  }

  static Future<bool> hasNickname() async {
    final String? nickname = await getNickname();
    return nickname != null;
  }

  static Future<bool> hasInitialConsentAccepted() async {
    return loadInitialConsentAccepted();
  }

  static Future<void> setInitialConsentAccepted(bool accepted) async {
    await saveInitialConsentAccepted(accepted);
  }
}
