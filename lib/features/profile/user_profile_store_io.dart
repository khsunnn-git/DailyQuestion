import "package:isar_community/isar.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../../data/local_db/entities/user_profile_entity.dart";
import "../../data/local_db/local_database.dart";
import "user_profile_events.dart";

const String _nicknameKey = "nickname";
const String _legacyNicknamePrefKey = "user_nickname";
const String _initialConsentPrefKey = "initial_consent_accepted";
const String _onboardingSeenPrefKey = "onboarding_seen";
const Duration _isarNicknameAccessTimeout = Duration(seconds: 2);

Future<String?> loadNickname() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final Isar? isar = await _openIsarForNicknameOrNull();
  if (isar != null) {
    final UserProfileEntity? stored = await isar.userProfileEntitys.getByKey(
      _nicknameKey,
    );
    final String? dbNickname = stored?.value.trim();
    if (dbNickname != null && dbNickname.isNotEmpty) {
      await prefs.setString(_legacyNicknamePrefKey, dbNickname);
      return dbNickname;
    }
  }

  final String? legacyNickname = prefs
      .getString(_legacyNicknamePrefKey)
      ?.trim();
  if (legacyNickname == null || legacyNickname.isEmpty) {
    return null;
  }
  if (isar != null) {
    await _persistNicknameToIsar(isar, legacyNickname);
  }
  return legacyNickname;
}

Future<void> saveNickname(String nickname) async {
  final String normalized = nickname.trim();
  if (normalized.isEmpty) {
    return;
  }
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString(_legacyNicknamePrefKey, normalized);

  final Isar? isar = await _openIsarForNicknameOrNull();
  if (isar != null) {
    await _persistNicknameToIsar(isar, normalized);
  }
  UserProfileEvents.notifyNicknameChanged();
}

Future<bool> loadInitialConsentAccepted() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_initialConsentPrefKey) ?? false;
}

Future<void> saveInitialConsentAccepted(bool accepted) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_initialConsentPrefKey, accepted);
}

Future<bool> loadOnboardingSeen() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final bool? seen = prefs.getBool(_onboardingSeenPrefKey);
  if (seen != null) {
    return seen;
  }

  final String? legacyNickname = prefs
      .getString(_legacyNicknamePrefKey)
      ?.trim();
  final bool hasLegacyProfile =
      (prefs.getBool(_initialConsentPrefKey) ?? false) ||
      (legacyNickname?.isNotEmpty ?? false);
  return hasLegacyProfile;
}

Future<void> saveOnboardingSeen(bool seen) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_onboardingSeenPrefKey, seen);
}

Future<Isar?> _openIsarForNicknameOrNull() async {
  try {
    return await LocalDatabase.instance.isar.timeout(
      _isarNicknameAccessTimeout,
    );
  } catch (_) {
    return null;
  }
}

Future<void> _persistNicknameToIsar(Isar isar, String nickname) async {
  final UserProfileEntity entity = UserProfileEntity()
    ..key = _nicknameKey
    ..value = nickname;
  await isar.writeTxn(() async {
    await isar.userProfileEntitys.putByKey(entity);
  });
}
