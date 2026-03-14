import "package:flutter_test/flutter_test.dart";

import "package:dailyquestion/features/splash/splash_route_resolver.dart";

void main() {
  group("resolveSplashRouteTarget", () {
    test("routes to login when consent is missing", () {
      expect(
        resolveSplashRouteTarget(
          hasInitialConsent: false,
          hasNickname: false,
        ),
        SplashRouteTarget.login,
      );
    });

    test("routes to nickname when consent exists but nickname is missing", () {
      expect(
        resolveSplashRouteTarget(
          hasInitialConsent: true,
          hasNickname: false,
        ),
        SplashRouteTarget.nickname,
      );
    });

    test("routes home when consent and nickname both exist", () {
      expect(
        resolveSplashRouteTarget(
          hasInitialConsent: true,
          hasNickname: true,
        ),
        SplashRouteTarget.home,
      );
    });
  });
}
