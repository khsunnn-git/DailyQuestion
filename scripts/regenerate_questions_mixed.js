#!/usr/bin/env node

const fs = require("fs");

const path = "data/questions.template.json";
const rows = JSON.parse(fs.readFileSync(path, "utf8"));

const casualTopics = [
  "아침 루틴",
  "출근/등교 준비",
  "식사 시간",
  "휴식 시간",
  "퇴근 후 시간",
  "주말 계획",
  "잠들기 전 시간",
  "핸드폰 사용",
  "집 정리",
  "산책 시간",
  "커피/차 한 잔",
  "음악 듣는 시간",
  "씻는 시간",
  "메모 습관",
  "하루 일정",
  "집중 시간",
  "이동 시간",
  "대화 시간",
  "취미 시간",
  "자기 전 정리",
];

const growthTopics = [
  "목표 설정",
  "우선순위 정리",
  "실행 습관",
  "집중력",
  "시간 관리",
  "체력 관리",
  "기록 습관",
  "학습 루틴",
  "업무/공부 방식",
  "문제 해결",
  "결정력",
  "완료 기준",
  "작은 성취",
  "복기 습관",
  "미루는 습관 개선",
  "스트레스 관리",
  "에너지 분배",
  "경계 설정",
  "자기 점검",
  "계획 수정",
];

const emotionTopics = [
  "마음 상태",
  "감정 표현",
  "불안 다루기",
  "관계 거리",
  "대화 태도",
  "자기 신뢰",
  "비교 습관",
  "회복 감각",
  "안정감",
  "기대감",
  "실망감",
  "감사함",
  "외로움",
  "소속감",
  "자기 존중",
  "내적 기준",
  "삶의 톤",
  "심리적 여유",
  "관계 만족도",
  "감정 회복",
];

const timePhrases = ["오늘", "이번 주", "요즘", "이번 달", "지금"];

const baseCasualTemplates = [
  "{time} {topic}에서 가장 만족스러웠던 순간은 언제였나요?",
  "{time} {topic} 관련해서 조금 더 편해지려면 무엇을 바꾸고 싶나요?",
  "{time} {topic}에서 줄이고 싶은 부담 한 가지는 무엇인가요?",
  "{time} {topic}에서 유지하고 싶은 좋은 부분은 무엇인가요?",
  "{time} {topic} 관련해서 가장 먼저 챙기고 싶은 것은 무엇인가요?",
  "{time} {topic} 관련해서 더 가볍게 갈 수 있는 작은 선택은 무엇인가요?",
];

const baseGrowthTemplates = [
  "{time} {topic} 관점에서 가장 먼저 손봐야 할 지점은 무엇인가요?",
  "{time} {topic} 관련해서 가장 현실적인 변화 한 가지는 무엇인가요?",
  "{time} {topic}에서 스스로 칭찬할 만한 선택은 무엇이었나요?",
  "{time} {topic} 관련해 방해되는 반복 패턴이 있다면 무엇인가요?",
  "{time} {topic}에서 덜 중요한 것을 하나 뺀다면 무엇인가요?",
  "{time} {topic} 관련해 지금 당장 시작할 수 있는 가장 쉬운 단계는 무엇인가요?",
];

const baseEmotionTemplates = [
  "{time} {topic} 관련해 가장 자주 드는 마음은 무엇인가요?",
  "{time} {topic} 관련해 흔들리는 순간에는 어떤 공통점이 있나요?",
  "{time} {topic} 관련해 지키기 위해 내려놓아야 할 것은 무엇인가요?",
  "{time} {topic} 관점으로 보면 지금 덜 중요한 것은 무엇인가요?",
  "{time} {topic} 관련해 한 문장으로 정리하면 어떻게 말할 수 있을까요?",
  "{time} {topic}에서 나를 안정시키는 요소는 무엇인가요?",
];

const actionLeads = ["오늘", "지금", "이번 주", "요즘", "이번 달"];

const actionContexts = [
  "시작 신호",
  "집중 블록",
  "중간 점검",
  "마무리 루틴",
  "우선순위 정리",
  "할 일 개수 조절",
  "휴대폰 사용 제한",
  "에너지 관리",
  "작은 완료",
  "복귀 규칙",
  "기록 방식",
  "시간 블록",
  "대화 방식",
  "일정 조정",
  "준비 루틴",
  "리셋 타이밍",
  "정리 시간",
  "쉬는 시간",
  "집중 환경",
  "회의/수업 준비",
  "퇴근/하교 이후 시간",
  "저녁 루틴",
  "아침 루틴",
  "메모 습관",
  "체력 배분",
  "속도 조절",
  "알림 설정",
  "방해요소 차단",
  "작업 순서",
];

const actionTemplates = [
  "{lead} {ctx} 기준으로 10분 안에 할 수 있는 행동은 무엇인가요?",
  "{lead} 일정에서 {ctx} 관련해 비워둘 시간은 언제인가요?",
  "{lead} {ctx} 시작을 가장 쉽게 만드는 방법은 무엇인가요?",
  "{lead} {ctx}가 무너지지 않게 하는 최소 기준은 무엇인가요?",
  "{lead} {ctx} 유지를 위해 한 가지 거절한다면 무엇을 거절할까요?",
  "{lead} 계획이 틀어져도 {ctx}를 다시 회복하는 방법은 무엇인가요?",
];

const perspectiveThemes = [
  "불안",
  "기대",
  "동기",
  "기준",
  "압박감",
  "안정감",
  "자기신뢰",
  "관계 만족도",
  "회복력",
  "집중력",
  "감정 상태",
  "삶의 톤",
  "내적 기준",
  "비교 습관",
  "자기대화",
  "스트레스",
  "방향감",
  "우선 가치",
  "회복 감각",
  "관계 거리",
  "일의 만족감",
  "학습 몰입도",
  "생활 리듬",
  "심리적 여유",
  "자기 효능감",
  "집중 지속력",
  "경계 감각",
  "정서 안정",
  "의사결정 확신",
];

const perspectiveScopes = [
  "하루를 돌아보면",
  "최근 일주일 기준으로",
  "요즘 패턴을 보면",
  "지금 상태를 보면",
  "일/공부 맥락에서는",
  "관계 안에서는",
  "스트레스가 높을 때는",
  "에너지가 낮을 때는",
];

const perspectiveTemplates = [
  "{scope} {theme} 관련해 흔들리는 순간에는 어떤 공통점이 있나요?",
  "{scope} 지금의 선택을 {theme} 기준으로 보면 무엇이 가장 중요할까요?",
  "{scope} {theme}과 관련해 반복되는 생각 패턴은 무엇인가요?",
  "{scope} {theme} 유지를 위해 내려놓아야 할 것은 무엇인가요?",
  "{scope} 오늘의 선택이 {theme}에 남길 영향은 무엇일까요?",
  "{scope} {theme}를 한 문장으로 요약하면 어떻게 표현할 수 있을까요?",
];

function product2(templates, valuesA, valuesB, keyA, keyB) {
  const out = [];
  for (const template of templates) {
    for (const a of valuesA) {
      for (const b of valuesB) {
        out.push(
          template
            .replaceAll(keyA, a)
            .replaceAll(keyB, b),
        );
      }
    }
  }
  return out;
}

function pickUnique(pool, ref, used, step) {
  let i = ref.value;
  while (used.has(pool[i % pool.length])) {
    i += step;
  }
  const value = pool[i % pool.length];
  used.add(value);
  ref.value = i + step;
  return value;
}

const baseCasualPool = product2(
  baseCasualTemplates,
  timePhrases,
  casualTopics,
  "{time}",
  "{topic}",
);
const baseGrowthPool = product2(
  baseGrowthTemplates,
  timePhrases,
  growthTopics,
  "{time}",
  "{topic}",
);
const baseEmotionPool = product2(
  baseEmotionTemplates,
  timePhrases,
  emotionTopics,
  "{time}",
  "{topic}",
);
const reserve1Pool = product2(
  actionTemplates,
  actionLeads,
  actionContexts,
  "{lead}",
  "{ctx}",
);
const reserve2Pool = product2(
  perspectiveTemplates,
  perspectiveScopes,
  perspectiveThemes,
  "{scope}",
  "{theme}",
);

const reserve2PoolUnique = [...new Set(reserve2Pool)];

const reserve1PoolUnique = [...new Set(reserve1Pool)];

if (reserve1PoolUnique.length < 365 || reserve2PoolUnique.length < 365) {
  throw new Error("reserve pool is smaller than 365.");
}

const dedupBaseCasualPool = [...new Set(baseCasualPool)];
const dedupBaseGrowthPool = [...new Set(baseGrowthPool)];
const dedupBaseEmotionPool = [...new Set(baseEmotionPool)];

if (
  dedupBaseCasualPool.length < 130 ||
  dedupBaseGrowthPool.length < 130 ||
  dedupBaseEmotionPool.length < 130
) {
  throw new Error("base pools are too small.");
}

const baseCasualFinal = dedupBaseCasualPool;
const baseGrowthFinal = dedupBaseGrowthPool;
const baseEmotionFinal = dedupBaseEmotionPool;

const reserve1Final = reserve1PoolUnique;
const reserve2Final = reserve2PoolUnique;

const baseCasualSize = baseCasualFinal.length;
const baseGrowthSize = baseGrowthFinal.length;
const baseEmotionSize = baseEmotionFinal.length;
const reserve1Size = reserve1Final.length;
const reserve2Size = reserve2Final.length;

if (
  !baseCasualSize ||
  !baseGrowthSize ||
  !baseEmotionSize ||
  !reserve1Size ||
  !reserve2Size
) {
  throw new Error("empty pool.");
}

const mix = ["casual", "growth", "emotion"];
const usedBase = new Set();
const usedR1 = new Set();
const usedR2 = new Set();

const refCasual = { value: 3 };
const refGrowth = { value: 11 };
const refEmotion = { value: 7 };
const refR1 = { value: 5 };
const refR2 = { value: 13 };

for (let day = 0; day < 365; day++) {
  const type = mix[day % mix.length];
  let base;
  if (type === "casual") {
    base = pickUnique(baseCasualFinal, refCasual, usedBase, 29);
  } else if (type === "growth") {
    base = pickUnique(baseGrowthFinal, refGrowth, usedBase, 31);
  } else {
    base = pickUnique(baseEmotionFinal, refEmotion, usedBase, 37);
  }

  const reserve1 = pickUnique(reserve1Final, refR1, usedR1, 19);
  const reserve2 = pickUnique(reserve2Final, refR2, usedR2, 23);

  rows[day].dayOfYear = day + 1;
  rows[day].base = base;
  rows[day].reserve = [reserve1, reserve2];
  rows[day].active = true;
}

function duplicateGroupCount(values) {
  const map = new Map();
  values.forEach((v) => map.set(v, (map.get(v) || 0) + 1));
  return [...map.values()].filter((v) => v > 1).length;
}

fs.writeFileSync(path, `${JSON.stringify(rows, null, 2)}\n`);

console.log("regenerated questions.");
console.log("dup(base):", duplicateGroupCount(rows.map((v) => v.base)));
console.log("dup(reserve1):", duplicateGroupCount(rows.map((v) => v.reserve[0])));
console.log("dup(reserve2):", duplicateGroupCount(rows.map((v) => v.reserve[1])));
console.log("pool sizes:", {
  baseCasualSize,
  baseGrowthSize,
  baseEmotionSize,
  reserve1Size,
  reserve2Size,
});
