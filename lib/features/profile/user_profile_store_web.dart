import "package:shared_preferences/shared_preferences.dart";

import "user_profile_events.dart";

const String _nicknameKey = "user_nickname";
const String _initialConsentKey = "initial_consent_accepted";
const String _onboardingSeenKey = "onboarding_seen";

Future<String?> loadNickname() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String? nickname = prefs.getString(_nicknameKey)?.trim();
  if (nickname == null || nickname.isEmpty) {
    return null;
  }
  return nickname;
}

Future<void> saveNickname(String nickname) async {
  final String normalized = nickname.trim();
  if (normalized.isEmpty) {
    return;
  }
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString(_nicknameKey, normalized);
  UserProfileEvents.notifyNicknameChanged();
}

Future<bool> loadInitialConsentAccepted() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_initialConsentKey) ?? false;
}

Future<void> saveInitialConsentAccepted(bool accepted) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_initialConsentKey, accepted);
}

Future<bool> loadOnboardingSeen() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final bool? seen = prefs.getBool(_onboardingSeenKey);
  if (seen != null) {
    return seen;
  }

  final String? nickname = prefs.getString(_nicknameKey)?.trim();
  final bool hasLegacyProfile =
      (prefs.getBool(_initialConsentKey) ?? false) ||
      (nickname?.isNotEmpty ?? false);
  return hasLegacyProfile;
}

Future<void> saveOnboardingSeen(bool seen) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_onboardingSeenKey, seen);
}
