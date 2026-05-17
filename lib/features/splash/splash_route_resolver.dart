enum SplashRouteTarget { onboarding, login, nickname, home }

SplashRouteTarget resolveSplashRouteTarget({
  required bool hasSeenOnboarding,
  required bool hasInitialConsent,
  required bool hasNickname,
}) {
  if (!hasSeenOnboarding) {
    return SplashRouteTarget.onboarding;
  }
  if (!hasInitialConsent) {
    return SplashRouteTarget.login;
  }
  if (!hasNickname) {
    return SplashRouteTarget.nickname;
  }
  return SplashRouteTarget.home;
}
