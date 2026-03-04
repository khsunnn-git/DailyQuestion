import "package:shared_preferences/shared_preferences.dart";

import "../../data/local_db/entities/user_profile_entity.dart";
import "../../data/local_db/local_database.dart";

const String _nicknameKey = "nickname";
const String _legacyNicknamePrefKey = "user_nickname";
const String _initialConsentPrefKey = "initial_consent_accepted";

Future<String?> loadNickname() async {
  final isar = await LocalDatabase.instance.isar;
  final UserProfileEntity? stored = await isar.userProfileEntitys.getByKey(
    _nicknameKey,
  );

  final String? dbNickname = stored?.value.trim();
  if (dbNickname != null && dbNickname.isNotEmpty) {
    return dbNickname;
  }

  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String? legacyNickname = prefs
      .getString(_legacyNicknamePrefKey)
      ?.trim();
  if (legacyNickname == null || legacyNickname.isEmpty) {
    return null;
  }
  await saveNickname(legacyNickname);
  await prefs.remove(_legacyNicknamePrefKey);
  return legacyNickname;
}

Future<void> saveNickname(String nickname) async {
  final String normalized = nickname.trim();
  if (normalized.isEmpty) {
    return;
  }
  final isar = await LocalDatabase.instance.isar;
  final UserProfileEntity entity = UserProfileEntity()
    ..key = _nicknameKey
    ..value = normalized;
  await isar.writeTxn(() async {
    await isar.userProfileEntitys.putByKey(entity);
  });
}

Future<bool> loadInitialConsentAccepted() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_initialConsentPrefKey) ?? false;
}

Future<void> saveInitialConsentAccepted(bool accepted) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_initialConsentPrefKey, accepted);
}
