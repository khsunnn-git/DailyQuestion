#!/usr/bin/env node

const fs = require("fs");
const path = require("path");

function fail(message) {
  console.error(`\n[merge_question_tags] ${message}\n`);
  process.exit(1);
}

function loadJson(filePath) {
  try {
    const text = fs.readFileSync(filePath, "utf8");
    return JSON.parse(text);
  } catch (error) {
    fail(`JSON 파일을 읽지 못했습니다: ${filePath}\n${error.message}`);
  }
}

function normalizeTagsPayload(payload) {
  if (Array.isArray(payload)) {
    return payload;
  }
  if (payload && Array.isArray(payload.samples)) {
    return payload.samples;
  }
  fail("태깅 파일 형식이 올바르지 않습니다. 배열 또는 { samples: [] } 형태여야 합니다.");
}

function main() {
  const questionsPathArg = process.argv[2];
  const tagsPathArg = process.argv[3];
  const outputPathArg = process.argv[4] || "data/questions.tagged.json";

  if (!questionsPathArg || !tagsPathArg) {
    fail(
      "Usage:\nnode scripts/merge_question_tags.js <questions.json> <tags.json> [output.json]\n",
    );
  }

  const questionsPath = path.resolve(process.cwd(), questionsPathArg);
  const tagsPath = path.resolve(process.cwd(), tagsPathArg);
  const outputPath = path.resolve(process.cwd(), outputPathArg);

  if (!fs.existsSync(questionsPath)) {
    fail(`questions file not found: ${questionsPath}`);
  }
  if (!fs.existsSync(tagsPath)) {
    fail(`tags file not found: ${tagsPath}`);
  }

  const questions = loadJson(questionsPath);
  const rawTags = loadJson(tagsPath);
  const tags = normalizeTagsPayload(rawTags);

  if (!Array.isArray(questions)) {
    fail("questions JSON must be an array.");
  }

  const tagByDay = new Map();
  for (const item of tags) {
    if (!item || typeof item !== "object") {
      continue;
    }
    if (typeof item.dayOfYear !== "number") {
      continue;
    }
    tagByDay.set(item.dayOfYear, item);
  }

  const merged = questions.map((q) => {
    const tag = tagByDay.get(q.dayOfYear);
    const primaryCategory =
      tag && typeof tag.primary === "string" && tag.primary.trim().length > 0
        ? tag.primary.trim()
        : q.primaryCategory ?? null;
    const tagsList = tag && Array.isArray(tag.tags)
      ? tag.tags.map((t) => String(t).trim()).filter((t) => t.length > 0)
      : Array.isArray(q.tags)
        ? q.tags.map((t) => String(t).trim()).filter((t) => t.length > 0)
        : [];

    const result = {
      dayOfYear: q.dayOfYear,
      base: q.base,
      active: q.active ?? true,
      tags: tagsList,
    };
    if (typeof primaryCategory === "string" && primaryCategory.length > 0) {
      result.primaryCategory = primaryCategory;
    }
    return result;
  });

  fs.mkdirSync(path.dirname(outputPath), { recursive: true });
  fs.writeFileSync(outputPath, `${JSON.stringify(merged, null, 2)}\n`, "utf8");
  console.log(`[merge_question_tags] created: ${outputPath}`);
}

main();
