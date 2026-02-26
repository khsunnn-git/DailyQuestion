#!/usr/bin/env node

const fs = require("fs");
const path = require("path");

const outputPathArg = process.argv[2] || "data/questions.template.json";
const outputPath = path.resolve(process.cwd(), outputPathArg);

const data = Array.from({ length: 365 }, (_, index) => {
  const day = index + 1;
  return {
    dayOfYear: day,
    base: `기본 질문 ${day}`,
    reserve: [`예비 질문 ${day}-1`, `예비 질문 ${day}-2`],
    active: true,
  };
});

fs.mkdirSync(path.dirname(outputPath), { recursive: true });
fs.writeFileSync(outputPath, `${JSON.stringify(data, null, 2)}\n`, "utf8");

console.log(`created: ${outputPath}`);
