import "package:shared_preferences/shared_preferences.dart";

const String _nicknameKey = "user_nickname";
const String _initialConsentKey = "initial_consent_accepted";

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
}

Future<bool> loadInitialConsentAccepted() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_initialConsentKey) ?? false;
}

Future<void> saveInitialConsentAccepted(bool accepted) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_initialConsentKey, accepted);
}
