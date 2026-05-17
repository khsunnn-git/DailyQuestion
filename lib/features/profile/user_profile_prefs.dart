import "dart:async";

import "user_profile_remote_service.dart";
import "user_profile_store.dart";

class UserProfilePrefs {
  UserProfilePrefs._();

  static Future<String?> getNickname() async {
    return loadNickname();
  }

  static Future<void> setNickname(
    String nickname, {
    bool syncRemote = true,
  }) async {
    await saveNickname(nickname);
    if (syncRemote) {
      unawaited(UserProfileRemoteService.instance.syncCurrentUserProfile());
    }
  }

  static Future<bool> hasNickname() async {
    final String? nickname = await getNickname();
    return nickname != null;
  }

  static Future<bool> hasInitialConsentAccepted() async {
    return loadInitialConsentAccepted();
  }

  static Future<bool> hasSeenOnboarding() async {
    return loadOnboardingSeen();
  }

  static Future<void> setInitialConsentAccepted(
    bool accepted, {
    bool syncRemote = true,
  }) async {
    await saveInitialConsentAccepted(accepted);
    if (syncRemote) {
      unawaited(UserProfileRemoteService.instance.syncCurrentUserProfile());
    }
  }

  static Future<void> setOnboardingSeen(bool seen) async {
    await saveOnboardingSeen(seen);
  }

  static Future<void> syncCurrentUserProfileBestEffort({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    try {
      await UserProfileRemoteService.instance.syncCurrentUserProfile().timeout(
        timeout,
      );
    } catch (_) {
      // Keep onboarding moving even if profile sync is temporarily unavailable.
    }
  }
}
