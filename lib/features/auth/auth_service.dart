import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/foundation.dart";
import "package:google_sign_in/google_sign_in.dart";

import "social_auth_provider.dart";

class AuthActionException implements Exception {
  const AuthActionException(this.userMessage);

  final String userMessage;
}

class AuthService {
  AuthService._({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth;
  bool _googleInitialized = false;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User> ensureSignedInUser() async {
    final User? user = currentUser;
    if (user != null) {
      return user;
    }
    final UserCredential credential = await _auth.signInAnonymously();
    final User? signedInUser = credential.user;
    if (signedInUser == null) {
      throw const AuthActionException("사용자 정보를 준비하지 못했어요. 다시 시도해주세요.");
    }
    return signedInUser;
  }

  SocialAuthProvider? get currentProvider {
    final User? user = currentUser;
    if (user == null || user.isAnonymous) {
      return null;
    }
    for (final UserInfo info in user.providerData) {
      final SocialAuthProvider? provider =
          socialAuthProviderFromFirebaseProviderId(info.providerId);
      if (provider != null) {
        return provider;
      }
    }
    return null;
  }

  bool get hasConnectedProvider {
    final User? user = currentUser;
    return user != null && !user.isAnonymous;
  }

  String get currentProviderLabel {
    final SocialAuthProvider? provider = currentProvider;
    if (provider != null) {
      return provider.label;
    }
    final User? user = currentUser;
    if (user == null || user.isAnonymous) {
      return "연결 안 됨";
    }
    if ((user.email ?? "").trim().isNotEmpty) {
      return "이메일";
    }
    return "연결됨";
  }

  String? get currentProviderConnectionLabel {
    final SocialAuthProvider? provider = currentProvider;
    if (provider != null) {
      return provider.connectionLabel;
    }
    final User? user = currentUser;
    if (user == null || user.isAnonymous) {
      return null;
    }
    if ((user.email ?? "").trim().isNotEmpty) {
      return "이메일 연동";
    }
    return "연동됨";
  }

  Future<UserCredential> signInWithProvider(SocialAuthProvider provider) async {
    switch (provider) {
      case SocialAuthProvider.google:
        return _signInWithGoogle();
      case SocialAuthProvider.kakao:
      case SocialAuthProvider.naver:
        throw AuthActionException("${provider.label} 로그인은 다음 단계에서 연결할 예정이에요.");
    }
  }

  Future<void> disconnectConnectedProvider() async {
    final SocialAuthProvider? provider = currentProvider;
    await _auth.signOut();
    if (provider == SocialAuthProvider.google) {
      try {
        await _ensureGoogleInitialized();
        await GoogleSignIn.instance.disconnect();
      } catch (_) {
        try {
          await GoogleSignIn.instance.signOut();
        } catch (_) {
          // Keep Firebase sign-out as the source of truth even if plugin cleanup fails.
        }
      }
    }
  }

  Future<void> clearCurrentSession() async {
    if (hasConnectedProvider) {
      await disconnectConnectedProvider();
      return;
    }
    if (currentUser != null) {
      await _auth.signOut();
    }
  }

  Future<UserCredential> _signInWithGoogle() async {
    if (kIsWeb) {
      final GoogleAuthProvider provider = GoogleAuthProvider();
      try {
        final UserCredential credential = await _linkOrSignInWithPopup(
          provider,
        );
        return credential;
      } on FirebaseAuthException catch (error) {
        throw _mapFirebaseAuthError(error);
      }
    }

    await _ensureGoogleInitialized();
    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw const AuthActionException("이 기기에서는 구글 로그인을 사용할 수 없어요.");
    }

    try {
      final GoogleSignInAccount googleUser = await GoogleSignIn.instance
          .authenticate();
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final String? idToken = googleAuth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const AuthActionException("구글 인증 정보를 가져오지 못했어요.");
      }

      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: idToken,
      );
      final UserCredential userCredential = await _linkOrSignInWithCredential(
        credential,
      );
      return userCredential;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthActionException("로그인이 취소되었어요.");
      }
      throw const AuthActionException("구글 로그인에 실패했어요. 잠시 후 다시 시도해주세요.");
    } on FirebaseAuthException catch (error) {
      throw _mapFirebaseAuthError(error);
    }
  }

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) {
      return;
    }
    await GoogleSignIn.instance.initialize();
    _googleInitialized = true;
  }

  Future<UserCredential> _linkOrSignInWithCredential(
    AuthCredential credential,
  ) async {
    final User? current = currentUser;
    if (current != null && current.isAnonymous) {
      try {
        return await current.linkWithCredential(credential);
      } on FirebaseAuthException catch (error) {
        if (error.code == "credential-already-in-use" ||
            error.code == "provider-already-linked") {
          return _auth.signInWithCredential(credential);
        }
        rethrow;
      }
    }
    return _auth.signInWithCredential(credential);
  }

  Future<UserCredential> _linkOrSignInWithPopup(
    GoogleAuthProvider provider,
  ) async {
    final User? current = currentUser;
    if (current != null && current.isAnonymous) {
      try {
        return await current.linkWithProvider(provider);
      } on FirebaseAuthException catch (error) {
        if (error.code == "credential-already-in-use" ||
            error.code == "provider-already-linked") {
          return _auth.signInWithPopup(provider);
        }
        rethrow;
      }
    }
    return _auth.signInWithPopup(provider);
  }

  AuthActionException _mapFirebaseAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case "account-exists-with-different-credential":
        return const AuthActionException("이미 다른 로그인 방식으로 연결된 계정이에요.");
      case "network-request-failed":
        return const AuthActionException("네트워크 연결을 확인한 뒤 다시 시도해주세요.");
      case "invalid-credential":
        return const AuthActionException("로그인 정보를 확인하지 못했어요. 다시 시도해주세요.");
      case "popup-closed-by-user":
        return const AuthActionException("로그인이 취소되었어요.");
      default:
        return const AuthActionException("로그인에 실패했어요. 잠시 후 다시 시도해주세요.");
    }
  }
}
