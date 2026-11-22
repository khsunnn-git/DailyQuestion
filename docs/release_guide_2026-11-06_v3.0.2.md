# DailyQuestion Release Guide

Version: `3.0.2+212`
Date: `2026-11-06`

## Android
```bash
flutter build appbundle --release
```

- Play Console 업로드 파일: `release_uploads/DailyQuestion_Android_3.0.2_212_UPLOAD_THIS.aab`
  (원본: `build/app/outputs/bundle/release/app-release.aab`)
- 서명: `android/key.properties`의 업로드 키 (git 미추적)

## iOS
```bash
flutter build ipa --release
```

- App Store Connect 업로드 파일: `release_uploads/DailyQuestion_iOS_3.0.2_212_UPLOAD_THIS.ipa`
  (원본: `build/ios/ipa/*.ipa`)
- 서명: Automatic, Team `A79M56B4C8`
- 2026-11-06 빌드 결과: 아카이브(`build/ios/archive/Runner.xcarchive`, 3.0.2/212)는 성공,
  ipa 내보내기는 실패 — Apple 개발자 약관(PLA) 갱신 미동의, 이 Mac에 iOS Distribution 인증서 없음
- 해결:
  1. https://developer.apple.com/account 로그인 → 새 약관 동의 (계정 소유자만 가능)
  2. `open build/ios/archive/Runner.xcarchive` → Xcode Organizer → Distribute App → App Store Connect
     (Xcode가 배포 인증서를 자동으로 만들어 서명하고 바로 업로드)

## 체크 포인트
- Android versionName `3.0.2`, versionCode `212`
- iOS CFBundleShortVersionString `3.0.2`, CFBundleVersion `212`
- 출시 전 분석 0건, 테스트 166개 통과

## 스토어 정보 업데이트 (이번 버전 필수)
Firebase Analytics가 새로 들어가서 개인정보 항목을 갱신해야 합니다.
- App Store Connect → 앱 개인정보 보호: "사용 데이터 > 제품 상호작용", "식별자 > 기기 ID"를
  "분석" 목적, "사용자와 연결되지 않음", "추적에 사용 안 함"으로 추가
- Play Console → 데이터 보안: "앱 활동 > 앱 상호작용", "기기 또는 기타 ID"를 "분석" 목적으로 추가
- AI 리포트에 닉네임이 함께 전달됨(OpenAI) — 개인정보처리방침의 AI 리포트 항목에 닉네임 포함 여부 확인

## 서버 (이미 배포됨, 2026-11-06)
- `reportAiApi`: 새 OpenAI 계정 키, 키워드 제거, 네 가지 축(지금 마음·즐거움·휴식·꿈) 대화형 리포트,
  계절 활동·다른 분들 활동·버킷리스트 추천, 출력 한도 상향
- `aggregateCommunityActivities`: 매일 05:30(KST) 공개 답변 익명 활동 집계 (Cloud Scheduler)

## 실기기 확인
- 보라 테마: `--dart-define=DEBUG_PREVIEW_THEME=purple --dart-define=DEBUG_PREVIEW_SCREEN=home`
- 백구 꼬리 흔들기·눈 깜빡임, 빈 버킷리스트 백구 이미지
- 답변 저장 후 Firebase DebugView에 `answer_submitted` 표시
- release 빌드에서 알림 아이콘이 정상 표시되는지
