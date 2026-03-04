import "user_profile_store_io.dart"
    if (dart.library.js_interop) "user_profile_store_web.dart"
    as store;

Future<String?> loadNickname() => store.loadNickname();
Future<void> saveNickname(String nickname) => store.saveNickname(nickname);
Future<bool> loadInitialConsentAccepted() => store.loadInitialConsentAccepted();
Future<void> saveInitialConsentAccepted(bool accepted) =>
    store.saveInitialConsentAccepted(accepted);
