import "dart:async";

import "user_profile_remote_service.dart";
import "user_profile_store.dart";

class UserProfilePrefs {
  UserProfilePrefs._();

  static Future<String?> getNickname() async {
    return loadNickname();
  }

  static Future<void> setNickname(String nickname) async {
    await saveNickname(nickname);
    unawaited(UserProfileRemoteService.instance.syncCurrentUserProfile());
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
    unawaited(UserProfileRemoteService.instance.syncCurrentUserProfile());
  }
}
