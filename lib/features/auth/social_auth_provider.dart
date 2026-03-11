enum SocialAuthProvider { kakao, naver, google }

extension SocialAuthProviderX on SocialAuthProvider {
  String get id {
    switch (this) {
      case SocialAuthProvider.kakao:
        return "kakao";
      case SocialAuthProvider.naver:
        return "naver";
      case SocialAuthProvider.google:
        return "google";
    }
  }

  String get label {
    switch (this) {
      case SocialAuthProvider.kakao:
        return "카카오";
      case SocialAuthProvider.naver:
        return "네이버";
      case SocialAuthProvider.google:
        return "구글";
    }
  }

  String get loginLabel => "$label로 로그인";

  String get startLabel => "$label로 시작하기";

  String get connectionLabel => "$label 연동";

  String get firebaseProviderId {
    switch (this) {
      case SocialAuthProvider.google:
        return "google.com";
      case SocialAuthProvider.kakao:
      case SocialAuthProvider.naver:
        return "";
    }
  }
}

SocialAuthProvider? socialAuthProviderFromId(String? raw) {
  switch (raw?.trim()) {
    case "kakao":
      return SocialAuthProvider.kakao;
    case "naver":
      return SocialAuthProvider.naver;
    case "google":
      return SocialAuthProvider.google;
    default:
      return null;
  }
}

SocialAuthProvider? socialAuthProviderFromFirebaseProviderId(String? raw) {
  switch (raw?.trim()) {
    case "google.com":
      return SocialAuthProvider.google;
    default:
      return null;
  }
}
