# DailyQuestion Release Guide

Version: `2.0.3+42`
Date: `2026-05-10`

## Android
```bash
flutter build appbundle
flutter build apk --release
```

- Play Console 업로드 파일: `build/app/outputs/bundle/release/app-release.aab`
- 테스트용 설치 파일: `build/app/outputs/flutter-apk/app-release.apk`

## iOS
```bash
flutter build ipa
```

- App Store Connect 업로드 파일: `build/ios/ipa/*.ipa`
- 업로드 전 확인: Xcode에서 배포용 Signing Team, Bundle Identifier, Provisioning Profile이 현재 계정과 맞아야 합니다.
- 아카이브가 `Unable to find a destination matching the provided destination specifier: { generic:1, platform:iOS }`로 실패하면 Xcode `Settings > Components`에서 최신 iOS 플랫폼을 먼저 설치해주세요.

## 체크 포인트
- 앱 버전 표기: `2.0.3+42`
- Android versionName: `2.0.3`
- Android versionCode: `42`
- iOS CFBundleShortVersionString: `2.0.3`
- iOS CFBundleVersion: `42`

## 이번 배포 주요 포인트
- 안드로이드 알림 예약 및 권한 흐름 안정화
- 알림 설정의 테스트 알림 기능 제거
- 그린 테마 전환 이후 테마 안내 팝업 미노출
- 의견 보내기 Firestore 접수 방식 적용
