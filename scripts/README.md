# Firestore Question Upload Scripts

## 1) 설치

프로젝트 루트에서:

```bash
npm init -y
npm i firebase-admin
```

## 2) 365개 템플릿 생성

```bash
node scripts/generate_question_template.js
```

생성 파일: `data/questions.template.json`

## 3) 템플릿 수정

`data/questions.template.json`에서 각 `base` 문구를 실제 질문으로 바꿔주세요.

## 4) Firestore 업로드

Firebase 콘솔에서 서비스 계정 키(JSON) 발급 후, 프로젝트 루트에 `serviceAccountKey.json`으로 저장하고:

```bash
node scripts/upload_questions.js ./serviceAccountKey.json ./data/questions.template.json
```

기본 컬렉션은 `daily_questions`입니다.

업로드 시 각 질문 문서에 아래 필드를 함께 반영할 수 있습니다.

- `dayOfYear` (number)
- `base` (string)
- `active` (boolean)
- `primaryCategory` (string, optional)
- `tags` (string[], optional)

## 5) 질문 + 태깅 병합(권장)

샘플 태깅 파일(`data/question_category_tagging_sample.json`)처럼 `dayOfYear` 기반 태깅 데이터를 질문 JSON에 합칩니다.

```bash
node scripts/merge_question_tags.js ./data/questions_2026_single.json ./data/question_category_tagging_sample.json ./data/questions_2026_tagged.json
```

생성 파일(`questions_2026_tagged.json`)을 그대로 업로드하면 `primaryCategory`, `tags`가 함께 저장됩니다.

```bash
node scripts/upload_questions.js ./serviceAccountKey.json ./data/questions_2026_tagged.json
```

다른 컬렉션에 업로드하려면:

```bash
node scripts/upload_questions.js ./serviceAccountKey.json ./data/questions.template.json my_collection
```

## 6) AI 리포트 백엔드 실행

앱의 `POST /v1/report/analyze`를 처리하는 로컬 서버입니다.

```bash
npm run report-api
```

기본 포트: `8787` (`PORT` 환경변수로 변경 가능)

실제 OpenAI 분석을 쓰려면:

```bash
OPENAI_API_KEY=sk-... OPENAI_MODEL=gpt-4.1-mini npm run report-api
```

`OPENAI_API_KEY`가 없으면 서버 fallback 리포트를 반환합니다.

Flutter 앱 연결:

- Android 에뮬레이터: `http://10.0.2.2:8787`
- Android 실기기(같은 Wi-Fi): `http://<내PC_IP>:8787`

실행 예:

```bash
flutter run --dart-define=REPORT_API_BASE_URL=http://10.0.2.2:8787
```
