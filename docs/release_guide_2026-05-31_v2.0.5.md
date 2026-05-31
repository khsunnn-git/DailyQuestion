# DailyQuestion Release Guide

Version: `2.0.5+44`
Date: `2026-05-31`

## Android
```bash
flutter build appbundle
flutter build apk --release
```

- Play Console 업로드 파일: `build/app/outputs/bundle/release/app-release.aab`
- 테스트용 설치 파일: `build/app/outputs/flutter-apk/app-release.apk`
- 실기기 확인: 알림 권한 허용 후 정확한 알람 권한/배터리 최적화 제외를 거절해도 오늘의 질문 알림 예약이 유지되는지 확인해주세요.

## iOS
```bash
flutter build ipa
```

- App Store Connect 업로드 파일: `build/ios/ipa/*.ipa`
- 업로드 전 확인: Xcode에서 배포용 Signing Team, Bundle Identifier, Provisioning Profile이 현재 계정과 맞아야 합니다.

## 체크 포인트
- 앱 버전 표기: `2.0.5+44`
- Android versionName: `2.0.5`
- Android versionCode: `44`
- iOS CFBundleShortVersionString: `2.0.5`
- iOS CFBundleVersion: `44`

## 이번 배포 주요 포인트
- Android 알림 필수 권한 기준 완화
- 정확한 알람 권한 미허용 시 inexact fallback 예약 유지
- 배터리 최적화 제외 권한 미허용 시에도 앱 진입/예약 유지
