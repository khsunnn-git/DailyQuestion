enum SplashRouteTarget { login, nickname, home }

SplashRouteTarget resolveSplashRouteTarget({
  required bool hasInitialConsent,
  required bool hasNickname,
}) {
  if (!hasInitialConsent) {
    return SplashRouteTarget.login;
  }
  if (!hasNickname) {
    return SplashRouteTarget.nickname;
  }
  return SplashRouteTarget.home;
}
