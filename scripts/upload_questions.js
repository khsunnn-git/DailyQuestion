#!/usr/bin/env node

const fs = require("fs");
const path = require("path");
const admin = require("firebase-admin");

function fail(message) {
  console.error(`\n[upload_questions] ${message}\n`);
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

function validateQuestion(item, index) {
  const label = `questions[${index}]`;
  if (!item || typeof item !== "object") {
    fail(`${label} must be an object.`);
  }
  if (typeof item.dayOfYear !== "number" || item.dayOfYear < 1 || item.dayOfYear > 365) {
    fail(`${label}.dayOfYear must be a number between 1 and 365.`);
  }
  if (typeof item.base !== "string" || item.base.trim().length === 0) {
    fail(`${label}.base must be a non-empty string.`);
  }
  if (item.active !== undefined && typeof item.active !== "boolean") {
    fail(`${label}.active must be a boolean.`);
  }
}

async function uploadQuestions({ serviceAccountPath, questionsPath, collectionId }) {
  const serviceAccount = loadJson(serviceAccountPath);
  const questions = loadJson(questionsPath);

  if (!Array.isArray(questions) || questions.length === 0) {
    fail("questions JSON must be a non-empty array.");
  }

  const seen = new Set();
  questions.forEach((item, index) => {
    validateQuestion(item, index);
    if (seen.has(item.dayOfYear)) {
      fail(`Duplicate dayOfYear detected: ${item.dayOfYear}`);
    }
    seen.add(item.dayOfYear);
  });

  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
  const db = admin.firestore();

  const chunkSize = 400;
  for (let i = 0; i < questions.length; i += chunkSize) {
    const chunk = questions.slice(i, i + chunkSize);
    const batch = db.batch();

    chunk.forEach((item) => {
      const ref = db.collection(collectionId).doc(String(item.dayOfYear));
      batch.set(
        ref,
        {
          dayOfYear: item.dayOfYear,
          base: item.base.trim(),
          active: item.active ?? true,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    });

    await batch.commit();
    console.log(`[upload_questions] uploaded ${Math.min(i + chunk.length, questions.length)}/${questions.length}`);
  }

  console.log("[upload_questions] done");
}

async function main() {
  const serviceAccountPathArg = process.argv[2];
  const questionsPathArg = process.argv[3];
  const collectionId = process.argv[4] || "daily_questions";

  if (!serviceAccountPathArg || !questionsPathArg) {
    fail(
      "Usage:\nnode scripts/upload_questions.js <serviceAccountKey.json> <questions.json> [collectionId]\n",
    );
  }

  const serviceAccountPath = path.resolve(process.cwd(), serviceAccountPathArg);
  const questionsPath = path.resolve(process.cwd(), questionsPathArg);

  if (!fs.existsSync(serviceAccountPath)) {
    fail(`service account file not found: ${serviceAccountPath}`);
  }
  if (!fs.existsSync(questionsPath)) {
    fail(`questions file not found: ${questionsPath}`);
  }

  await uploadQuestions({ serviceAccountPath, questionsPath, collectionId });
}

main().catch((error) => {
  fail(error?.stack || error?.message || String(error));
});
