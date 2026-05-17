# DailyQuestion Release Guide

Version: `2.0.2+41`
Date: `2026-05-08`

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
- 앱 버전 표기: `2.0.2+41`
- Android versionName: `2.0.2`
- Android versionCode: `41`
- iOS CFBundleShortVersionString: `2.0.2`
- iOS CFBundleVersion: `41`

## 이번 배포 주요 포인트
- 홈 그린 테마 사전 안내 팝업 추가
- 설정 버전 표기 자동 동기화
- 사용자 의견 메일 전송 연결
- 안드로이드 알림 진단용 테스트 알림 추가
