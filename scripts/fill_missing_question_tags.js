#!/usr/bin/env node

const fs = require("fs");
const path = require("path");

function fail(message) {
  console.error(`\n[fill_missing_question_tags] ${message}\n`);
  process.exit(1);
}

function loadJson(filePath) {
  try {
    return JSON.parse(fs.readFileSync(filePath, "utf8"));
  } catch (error) {
    fail(`JSON 파일을 읽지 못했습니다: ${filePath}\n${error.message}`);
  }
}

const CATEGORY_KEYWORDS = {
  감정: [
    "기분",
    "행복",
    "설렘",
    "감사",
    "웃",
    "위로",
    "평온",
    "마음",
    "감동",
    "좋았던",
  ],
  에너지: ["에너지", "피곤", "지침", "방전", "컨디션", "리듬", "활력", "기운"],
  스트레스: ["스트레스", "걱정", "불안", "화", "서운", "속상", "예민", "갈등", "유혹", "흔들"],
  루틴: ["루틴", "패턴", "습관", "반복", "아침", "잠", "수면", "정리", "시간대", "생활", "기상"],
  관계: ["친구", "사람", "연락", "관계", "사랑", "공감", "부탁", "대화", "오해", "응원", "갈등"],
  성장: ["성장", "도전", "목표", "미래", "배우", "바꾸", "변화", "용기", "결정", "성숙", "기특", "강점"],
  회복: ["힐링", "휴식", "산책", "편안", "쉼", "리셋", "위로", "안정", "카페", "풍경", "자연"],
  취향: ["좋아하는", "취향", "음악", "노래", "영화", "드라마", "게임", "음식", "과일", "커피", "음료", "브랜드", "선물", "색"],
  "일/학습": ["일", "공부", "집중", "미루", "업무", "계획", "성과", "성공", "소비", "지출"],
  "여행/경험": ["여행", "도시", "바다", "산", "휴가", "전시", "공연", "경험", "떠나", "코스", "활동"],
  건강: ["건강", "운동", "수면", "물", "스트레칭", "온도", "산책", "피로", "체력"],
  자기인식: ["나를", "나다운", "소개", "기준", "가치관", "속마음", "키워드", "기억되고", "솔직", "장점", "약점"],
};

const FALLBACK_PRIMARY = "자기인식";
const DEFAULT_TAGS_BY_PRIMARY = {
  감정: ["감정", "회복", "자기인식"],
  에너지: ["에너지", "루틴", "건강"],
  스트레스: ["스트레스", "회복", "루틴"],
  루틴: ["루틴", "건강", "에너지"],
  관계: ["관계", "감정", "자기인식"],
  성장: ["성장", "자기인식", "루틴"],
  회복: ["회복", "감정", "스트레스"],
  취향: ["취향", "감정", "회복"],
  "일/학습": ["일/학습", "집중", "성장"],
  "여행/경험": ["여행/경험", "취향", "회복"],
  건강: ["건강", "루틴", "에너지"],
  자기인식: ["자기인식", "감정", "성장"],
};

function scoreCategories(question) {
  const scores = {};
  for (const category of Object.keys(CATEGORY_KEYWORDS)) {
    scores[category] = 0;
    for (const keyword of CATEGORY_KEYWORDS[category]) {
      if (question.includes(keyword)) {
        scores[category] += keyword.length >= 3 ? 2 : 1;
      }
    }
  }
  return scores;
}

function topCategories(scores, limit = 3) {
  return Object.entries(scores)
    .sort((a, b) => {
      if (b[1] !== a[1]) return b[1] - a[1];
      return a[0].localeCompare(b[0], "ko");
    })
    .filter(([, score]) => score > 0)
    .slice(0, limit)
    .map(([category]) => category);
}

function ensureTags(primary, tags) {
  const set = new Set();
  set.add(primary);
  for (const tag of tags) {
    if (typeof tag === "string" && tag.trim().length > 0) {
      set.add(tag.trim());
    }
  }
  const defaults = DEFAULT_TAGS_BY_PRIMARY[primary] || DEFAULT_TAGS_BY_PRIMARY[FALLBACK_PRIMARY];
  for (const tag of defaults) {
    if (set.size >= 3) break;
    set.add(tag);
  }
  return Array.from(set).slice(0, 3);
}

function fillMissing(input) {
  return input.map((item) => {
    const hasPrimary =
      typeof item.primaryCategory === "string" && item.primaryCategory.trim().length > 0;
    const hasTags = Array.isArray(item.tags) && item.tags.length > 0;
    if (hasPrimary && hasTags) {
      return {
        ...item,
        primaryCategory: item.primaryCategory.trim(),
        tags: ensureTags(item.primaryCategory.trim(), item.tags),
      };
    }

    const question = String(item.base || "");
    const scores = scoreCategories(question);
    const ranked = topCategories(scores, 3);
    const primary = hasPrimary ? item.primaryCategory.trim() : (ranked[0] || FALLBACK_PRIMARY);
    const tags = hasTags ? item.tags : ranked;

    return {
      ...item,
      primaryCategory: primary,
      tags: ensureTags(primary, tags),
    };
  });
}

function main() {
  const inputPathArg = process.argv[2];
  const outputPathArg = process.argv[3] || "data/questions_2026_tagged.json";
  if (!inputPathArg) {
    fail(
      "Usage:\nnode scripts/fill_missing_question_tags.js <input.json> [output.json]\n",
    );
  }

  const inputPath = path.resolve(process.cwd(), inputPathArg);
  const outputPath = path.resolve(process.cwd(), outputPathArg);
  if (!fs.existsSync(inputPath)) {
    fail(`input file not found: ${inputPath}`);
  }

  const input = loadJson(inputPath);
  if (!Array.isArray(input)) {
    fail("input JSON must be an array.");
  }

  const output = fillMissing(input);
  fs.mkdirSync(path.dirname(outputPath), { recursive: true });
  fs.writeFileSync(outputPath, `${JSON.stringify(output, null, 2)}\n`, "utf8");

  const missing = output.filter(
    (q) =>
      !(typeof q.primaryCategory === "string" && q.primaryCategory.trim()) ||
      !Array.isArray(q.tags) ||
      q.tags.length === 0,
  );
  console.log(
    `[fill_missing_question_tags] created: ${outputPath} (missing: ${missing.length})`,
  );
}

main();
