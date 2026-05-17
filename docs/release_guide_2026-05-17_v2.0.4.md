# DailyQuestion Release Guide

Version: `2.0.4+43`
Date: `2026-05-17`

## Android
```bash
flutter build appbundle
flutter build apk --release
```

- Play Console 업로드 파일: `build/app/outputs/bundle/release/app-release.aab`
- 테스트용 설치 파일: `build/app/outputs/flutter-apk/app-release.apk`
- 알림 안정성 확인: Android 13+ 알림 권한, 정확한 알람 권한, 배터리 최적화 제외 안내 배너 노출을 실기기에서 확인해주세요.

## iOS
```bash
flutter build ipa
```

- App Store Connect 업로드 파일: `build/ios/ipa/*.ipa`
- 업로드 전 확인: Xcode에서 배포용 Signing Team, Bundle Identifier, Provisioning Profile이 현재 계정과 맞아야 합니다.
- 아카이브가 `Unable to find a destination matching the provided destination specifier: { generic:1, platform:iOS }`로 실패하면 Xcode `Settings > Components`에서 최신 iOS 플랫폼을 먼저 설치해주세요.

## 체크 포인트
- 앱 버전 표기: `2.0.4+43`
- Android versionName: `2.0.4`
- Android versionCode: `43`
- iOS CFBundleShortVersionString: `2.0.4`
- iOS CFBundleVersion: `43`

## 이번 배포 주요 포인트
- 새싹 테마 성장 주기 초기화 및 테마별 캐릭터 레벨 계산 정리
- 안드로이드 배터리 최적화 제외 안내 추가
- AI 리포트 집계/캐시/타임라인 안정화
- 온보딩, 의견 보내기, 알림/설정 화면 보강
