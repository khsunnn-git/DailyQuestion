enum SplashRouteTarget { onboarding, login, characterSelect, nickname, home }

SplashRouteTarget resolveSplashRouteTarget({
  required bool hasSeenOnboarding,
  required bool hasInitialConsent,
  required bool hasNickname,
  bool hasCharacterSelection = true,
}) {
  if (!hasSeenOnboarding) {
    return SplashRouteTarget.onboarding;
  }
  if (!hasInitialConsent) {
    return SplashRouteTarget.login;
  }
  if (!hasNickname) {
    // 회원가입 중: 약관동의 → 캐릭터 선택 → 닉네임 설정
    return hasCharacterSelection
        ? SplashRouteTarget.nickname
        : SplashRouteTarget.characterSelect;
  }
  return SplashRouteTarget.home;
}
