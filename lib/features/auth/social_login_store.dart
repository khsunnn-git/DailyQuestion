import "package:shared_preferences/shared_preferences.dart";

import "social_auth_provider.dart";

class SocialLoginStore {
  SocialLoginStore._();

  static final SocialLoginStore instance = SocialLoginStore._();

  static const String _recentProviderKey = "recent_social_login_provider_v1";

  Future<void> saveRecentProvider(SocialAuthProvider provider) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_recentProviderKey, provider.id);
  }

  Future<SocialAuthProvider?> readRecentProvider() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return socialAuthProviderFromId(prefs.getString(_recentProviderKey));
  }
}
