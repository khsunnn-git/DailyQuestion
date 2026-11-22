# DailyQuestion Release Guide

Version: `3.1.0+213`
Date: `2026-11-22`

## 한 번에 빌드하기
터미널에서 아래 한 줄을 실행하면 검사 → 테스트 → 안드로이드 → iOS 순서로 진행돼요.

```bash
cd ~/Documents/DailyQuestion && bash scripts/release_build.sh
```

끝나면 `release_uploads/` 폴더에 업로드할 파일이 생겨요.
- Play Console: `DailyQuestion_Android_3.1.0_213_UPLOAD_THIS.aab`
- App Store Connect: `DailyQuestion_iOS_3.1.0_213_UPLOAD_THIS.ipa`

## iOS ipa가 안 만들어지면
지난 배포(3.0.2) 때처럼 ipa 내보내기가 실패할 수 있어요 (Apple 약관 미동의 또는 배포 인증서 없음).
1. https://developer.apple.com/account 로그인 → 새 약관이 있으면 동의 (계정 소유자만 가능)
2. 터미널에서 `open build/ios/archive/Runner.xcarchive`
3. Xcode Organizer → Distribute App → App Store Connect → Upload

## 체크 포인트
- Android versionName `3.1.0`, versionCode `213`
- iOS CFBundleShortVersionString `3.1.0`, CFBundleVersion `213`
- 테스트 184개 통과 (2026-11-22, Android Studio에서 확인)

## 스토어 정보
- 개인정보 수집 항목 변경 없음 (고른 캐릭터는 기기에만 저장)
- 스크린샷: 새 캐릭터 선택 화면을 넣으면 좋아요 (선택 사항)

## 이번 버전 동작 요약 (문의 대응용)
- 새 가입자: 약관동의 다음에 캐릭터 선택 화면 → 닉네임 설정
- 기존 이용자: 업데이트 후 처음 홈에 들어오면 지금 키우던 캐릭터(물고기→새싹→돌맹이→백구 순서)를
  저장하고 이어서 키움. 그 캐릭터로 60회를 채우면 선택 화면이 뜸
- 백구를 이미 다 키운 이용자(기록 240개 이상)는 업데이트 후 바로 선택 화면이 뜸
- 선택 화면은 뒤로가기로 닫을 수 없음 (하나를 골라야 함)
- 데이터 전체 삭제 시 고른 캐릭터도 초기화

## 출시 전 실기기 확인
Android Studio 실행 목록의 "캐릭터 테마 테스트" 항목으로 각 단계를 바로 볼 수 있어요. (디버그 빌드에서만 동작)
- 1: 캐릭터 선택 화면
- 2: 회원가입 처음부터 (앱 삭제 후)
- 3-x: 캐릭터별 모습과 움직임
- 4-x: 예고 팝업, 60회 완료 후 선택
- 5-x: 기존 이용자
