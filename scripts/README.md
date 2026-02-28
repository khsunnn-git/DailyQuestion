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

다른 컬렉션에 업로드하려면:

```bash
node scripts/upload_questions.js ./serviceAccountKey.json ./data/questions.template.json my_collection
```
