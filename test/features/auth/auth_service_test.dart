import "package:dailyquestion/features/auth/auth_service.dart";
import "package:dailyquestion/features/auth/social_auth_provider.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  test("returns the current user immediately when already restored", () async {
    int recentProviderReads = 0;

    final String? restored = await restoreUserFromRecentProvider<String>(
      currentUser: "current-user",
      readRecentProvider: () async {
        recentProviderReads += 1;
        return SocialAuthProvider.google;
      },
      waitForRestoredAuthState: (_) async => "restored-user",
      attemptRestoreGoogleIdToken: () async => "google-token",
      signInWithGoogleIdToken: (String token) async => "signed-in:$token",
    );

    expect(restored, "current-user");
    expect(recentProviderReads, 0);
  });

  test("prefers Firebase restored user before provider fallback", () async {
    int googleRestoreAttempts = 0;

    final String? restored = await restoreUserFromRecentProvider<String>(
      currentUser: null,
      readRecentProvider: () async => SocialAuthProvider.google,
      waitForRestoredAuthState: (_) async => "firebase-user",
      attemptRestoreGoogleIdToken: () async {
        googleRestoreAttempts += 1;
        return "google-token";
      },
      signInWithGoogleIdToken: (String token) async => "signed-in:$token",
    );

    expect(restored, "firebase-user");
    expect(googleRestoreAttempts, 0);
  });

  test(
    "restores a Google session when Firebase user is not recovered",
    () async {
      int signInAttempts = 0;

      final String? restored = await restoreUserFromRecentProvider<String>(
        currentUser: null,
        readRecentProvider: () async => SocialAuthProvider.google,
        waitForRestoredAuthState: (_) async => null,
        attemptRestoreGoogleIdToken: () async => "google-token",
        signInWithGoogleIdToken: (String token) async {
          signInAttempts += 1;
          return "signed-in:$token";
        },
      );

      expect(restored, "signed-in:google-token");
      expect(signInAttempts, 1);
    },
  );

  test(
    "does not attempt Google restore for non-Google recent providers",
    () async {
      int googleRestoreAttempts = 0;

      final String? restored = await restoreUserFromRecentProvider<String>(
        currentUser: null,
        readRecentProvider: () async => SocialAuthProvider.kakao,
        waitForRestoredAuthState: (_) async => null,
        attemptRestoreGoogleIdToken: () async {
          googleRestoreAttempts += 1;
          return "google-token";
        },
        signInWithGoogleIdToken: (String token) async => "signed-in:$token",
      );

      expect(restored, isNull);
      expect(googleRestoreAttempts, 0);
    },
  );
}
