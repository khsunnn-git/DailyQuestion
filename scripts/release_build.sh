#!/bin/bash
# 데일리퀘스천 배포용 빌드 (검사 → 테스트 → 안드로이드 aab → iOS ipa)
# 사용법: cd ~/Documents/DailyQuestion && bash scripts/release_build.sh
set -e
cd "$(dirname "$0")/.."

VERSION_LINE=$(grep '^version:' pubspec.yaml)
VERSION=$(echo "$VERSION_LINE" | sed -E 's/version: *([0-9.]+)\+([0-9]+).*/\1/')
BUILD=$(echo "$VERSION_LINE" | sed -E 's/version: *([0-9.]+)\+([0-9]+).*/\2/')
mkdir -p release_uploads

echo ""
echo "▶ 데일리퀘스천 $VERSION ($BUILD) 빌드를 시작해요."

echo ""
echo "▶ 1/5 패키지 준비"
flutter pub get

echo ""
echo "▶ 2/5 코드 검사 (경고는 표시만 하고 계속 진행해요)"
flutter analyze --no-fatal-infos --no-fatal-warnings

echo ""
echo "▶ 3/5 테스트"
flutter test

echo ""
echo "▶ 4/5 안드로이드 앱 번들 (Play Console용)"
flutter build appbundle --release
AAB="release_uploads/DailyQuestion_Android_${VERSION}_${BUILD}_UPLOAD_THIS.aab"
cp build/app/outputs/bundle/release/app-release.aab "$AAB"
echo "  ✓ $AAB"

echo ""
echo "▶ 5/5 iOS (App Store Connect용)"
if flutter build ipa --release; then
  IPA_SRC=$(ls build/ios/ipa/*.ipa | head -n 1)
  IPA="release_uploads/DailyQuestion_iOS_${VERSION}_${BUILD}_UPLOAD_THIS.ipa"
  cp "$IPA_SRC" "$IPA"
  echo "  ✓ $IPA"
else
  echo ""
  echo "  ⚠ ipa 내보내기에 실패했어요. 아카이브는 만들어졌을 수 있어요."
  echo "    open build/ios/archive/Runner.xcarchive"
  echo "    → Xcode Organizer → Distribute App → App Store Connect 로 올려주세요."
fi

echo ""
echo "▶ 끝! release_uploads 폴더를 확인하세요."
open release_uploads 2>/dev/null || true
