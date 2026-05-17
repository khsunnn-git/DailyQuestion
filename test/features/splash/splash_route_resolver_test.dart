import "package:flutter_test/flutter_test.dart";

import "package:dailyquestion/features/splash/splash_route_resolver.dart";

void main() {
  group("resolveSplashRouteTarget", () {
    test("routes to onboarding when onboarding has not been seen", () {
      expect(
        resolveSplashRouteTarget(
          hasSeenOnboarding: false,
          hasInitialConsent: false,
          hasNickname: false,
        ),
        SplashRouteTarget.onboarding,
      );
    });

    test("routes to login when consent is missing", () {
      expect(
        resolveSplashRouteTarget(
          hasSeenOnboarding: true,
          hasInitialConsent: false,
          hasNickname: false,
        ),
        SplashRouteTarget.login,
      );
    });

    test("routes to nickname when consent exists but nickname is missing", () {
      expect(
        resolveSplashRouteTarget(
          hasSeenOnboarding: true,
          hasInitialConsent: true,
          hasNickname: false,
        ),
        SplashRouteTarget.nickname,
      );
    });

    test("routes home when consent and nickname both exist", () {
      expect(
        resolveSplashRouteTarget(
          hasSeenOnboarding: true,
          hasInitialConsent: true,
          hasNickname: true,
        ),
        SplashRouteTarget.home,
      );
    });
  });
}
