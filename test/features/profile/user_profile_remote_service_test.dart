import "package:dailyquestion/features/profile/user_profile_remote_service.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  group("resolvePostLoginDestinationForState", () {
    test("returns terms for a brand new user", () {
      expect(
        resolvePostLoginDestinationForState(
          remoteNickname: null,
          localNickname: null,
          remoteConsentAccepted: false,
          remoteOnboardingCompleted: false,
          hasRemoteAnswers: false,
        ),
        PostLoginDestination.termsConsent,
      );
    });

    test("returns home when remote nickname exists", () {
      expect(
        resolvePostLoginDestinationForState(
          remoteNickname: "혜선",
          localNickname: null,
          remoteConsentAccepted: true,
          remoteOnboardingCompleted: true,
          hasRemoteAnswers: true,
        ),
        PostLoginDestination.home,
      );
    });

    test("returns home when only local nickname exists", () {
      expect(
        resolvePostLoginDestinationForState(
          remoteNickname: null,
          localNickname: "혜선",
          remoteConsentAccepted: true,
          remoteOnboardingCompleted: false,
          hasRemoteAnswers: true,
        ),
        PostLoginDestination.home,
      );
    });

    test("returns nickname setup for legacy returning users missing nickname", () {
      expect(
        resolvePostLoginDestinationForState(
          remoteNickname: null,
          localNickname: null,
          remoteConsentAccepted: true,
          remoteOnboardingCompleted: false,
          hasRemoteAnswers: true,
        ),
        PostLoginDestination.nicknameSetup,
      );
    });
  });
}
