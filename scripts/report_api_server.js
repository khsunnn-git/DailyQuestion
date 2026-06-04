#!/usr/bin/env node

const http = require("http");

const PORT = Number(process.env.PORT || 8787);
const OPENAI_API_KEY = process.env.OPENAI_API_KEY || "";
const OPENAI_MODEL = process.env.OPENAI_MODEL || "gpt-4.1-mini";

function sendJson(res, statusCode, body) {
  res.writeHead(statusCode, {
    "Content-Type": "application/json; charset=utf-8",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, Authorization",
  });
  res.end(JSON.stringify(body));
}

function parseBody(req) {
  return new Promise((resolve, reject) => {
    let raw = "";
    req.on("data", (chunk) => {
      raw += chunk.toString("utf8");
      if (raw.length > 1024 * 1024) {
        reject(new Error("Request body too large"));
      }
    });
    req.on("end", () => {
      try {
        resolve(raw ? JSON.parse(raw) : {});
      } catch (error) {
        reject(new Error("Invalid JSON body"));
      }
    });
    req.on("error", reject);
  });
}

function asNumber(value) {
  if (typeof value === "number") return value;
  if (typeof value === "string") {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : null;
  }
  return null;
}

function buildEmotionSummary(payload) {
  const metrics = payload?.metrics || {};
  const positiveDays = asNumber(metrics.positive_day_count) || 0;
  const burdenDays = asNumber(metrics.burden_day_count) || 0;
  const stableDays = asNumber(metrics.stable_day_count) || 0;
  const recordedDays =
    asNumber(metrics.recorded_days) || positiveDays + burdenDays + stableDays;
  const trendDelta = asNumber(metrics.trend_delta) || 0;

  let balanceText = "아직 감정 흐름을 읽을 만큼 체크인 데이터가 충분하지 않아요.";
  if (recordedDays > 0) {
    if (positiveDays >= burdenDays + 2) {
      balanceText = "이번 주에는 전반적으로 긍정적인 생각과 안도감이 더 자주 보였어요.";
    } else if (burdenDays >= positiveDays + 2) {
      balanceText = "이번 주에는 해야 할 일이나 긴장감처럼 부담 신호가 조금 더 크게 드러났어요.";
    } else if (positiveDays > burdenDays) {
      balanceText = "부담도 있었지만 전체 톤은 조금 더 밝고 긍정적인 편이었어요.";
    } else if (burdenDays > positiveDays) {
      balanceText = "긍정적인 순간도 있었지만 전체적으로는 부담감이 조금 더 앞섰어요.";
    } else {
      balanceText = "이번 주에는 긍정과 부담이 함께 섞여 있었고 한쪽으로 크게 기울지는 않았어요.";
    }
  }

  let flowText = "한 주 전체의 감정 톤은 비교적 안정적으로 유지됐어요.";
  if (trendDelta > 0.45) {
    flowText = "주 초보다 주 후반에 마음이 한결 가벼워진 흐름이 보여요.";
  } else if (trendDelta > 0.15) {
    flowText = "주 후반으로 갈수록 조금 더 편안해졌어요.";
  } else if (trendDelta < -0.45) {
    flowText = "주 후반으로 갈수록 피로와 부담이 눈에 띄게 커졌어요.";
  } else if (trendDelta < -0.15) {
    flowText = "주 후반에는 초반보다 에너지나 기분이 살짝 내려갔어요.";
  }

  const countsText = recordedDays > 0
    ? `기록한 날 중 긍정 신호 ${positiveDays}일, 부담 신호 ${burdenDays}일, 안정 흐름 ${stableDays}일이었어요.`
    : "";

  return {
    summary: `${balanceText} ${flowText}`.trim(),
    countsText,
  };
}

const RECOVERY_ACTION_CUES = [
  {
    patterns: ["산책", "걷기", "걷다"],
    subject: "산책이",
    shortLabel: "산책",
    recommendation: "짧게라도 산책해보세요.",
  },
  {
    patterns: ["음악", "노래", "플레이리스트"],
    subject: "음악을 듣는 시간이",
    shortLabel: "음악 듣기",
    recommendation: "좋아하는 음악 1~2곡을 들어보세요.",
  },
  {
    patterns: ["친구", "대화", "통화", "가족", "엄마", "아빠", "동생", "연인"],
    subject: "가까운 사람과 나누는 대화가",
    shortLabel: "가까운 사람과 대화하기",
    recommendation: "믿는 사람 한 명에게 짧게라도 먼저 연락해보세요.",
  },
  {
    patterns: ["휴식", "쉬기", "쉼", "멍", "혼자"],
    subject: "혼자 조용히 쉬는 시간이",
    shortLabel: "잠깐 쉬기",
    recommendation: "잠깐이라도 혼자 편하게 쉬는 시간을 만들어보세요.",
  },
  {
    patterns: ["샤워", "목욕", "반신욕"],
    subject: "따뜻한 샤워 같은 몸을 풀어주는 시간이",
    shortLabel: "따뜻한 샤워",
    recommendation: "따뜻한 샤워로 몸의 긴장을 먼저 풀어보세요.",
  },
  {
    patterns: ["스트레칭", "운동", "러닝", "헬스", "요가"],
    subject: "가볍게 몸을 움직이는 시간이",
    shortLabel: "가벼운 움직임",
    recommendation: "스트레칭이나 가벼운 움직임으로 몸부터 깨워보세요.",
  },
  {
    patterns: ["기록", "일기", "메모", "글"],
    subject: "생각을 적어보는 시간이",
    shortLabel: "짧게 기록하기",
    recommendation: "지금 드는 생각을 3줄만 적어보세요.",
  },
  {
    patterns: ["드라마", "정주행", "넷플릭스", "시리즈"],
    subject: "드라마를 보는 시간이",
    shortLabel: "좋아하는 드라마 보기",
    recommendation: "전에 언급한 드라마와 비슷한 다음 에피소드나 새 시리즈 한 편을 골라보세요.",
  },
  {
    patterns: ["영화", "극장", "시네마"],
    subject: "영화를 보는 시간이",
    shortLabel: "영화 보기",
    recommendation: "부담 없는 영화 한 편을 골라 마음을 잠깐 다른 장면에 맡겨보세요.",
  },
  {
    patterns: ["야구", "야구장", "직관", "경기", "응원"],
    subject: "야구를 보는 시간이",
    shortLabel: "야구 관람",
    recommendation: "집에서 경기 하이라이트를 보거나 여유가 있으면 가까운 야구 경기 관람을 계획해보세요.",
  },
];

function bestDayText(payload) {
  const evidence = pickDayEvidence(payload, true);
  return evidence ? evidence.answer : "";
}

function weekdayLabelFromKey(dateKey) {
  const value = String(dateKey || "").trim();
  if (!/^\d{8}$/.test(value)) {
    return "해당 요일";
  }
  const year = Number.parseInt(value.slice(0, 4), 10);
  const month = Number.parseInt(value.slice(4, 6), 10);
  const day = Number.parseInt(value.slice(6, 8), 10);
  const date = new Date(year, month - 1, day);
  const weekdays = ["일요일", "월요일", "화요일", "수요일", "목요일", "금요일", "토요일"];
  return weekdays[date.getDay()] || "해당 요일";
}

function withObjectParticle(word) {
  const value = String(word || "").trim();
  if (!value) {
    return value;
  }
  const lastCode = value.codePointAt(value.length - 1);
  const isHangul = lastCode >= 0xac00 && lastCode <= 0xd7a3;
  const hasBatchim = isHangul && (lastCode - 0xac00) % 28 !== 0;
  return `${value}${hasBatchim ? "을" : "를"}`;
}

function pickDayEvidence(payload, pickMax) {
  const days = Array.isArray(payload && payload.days) ? payload.days : [];
  let selected = null;
  for (const day of days) {
    const score = asNumber(day && day.day_score);
    if (score === null) {
      continue;
    }
    const evidence = {
      score,
      dateLabel: `${day && typeof day.date_key === "string" ? day.date_key : ""}`,
      weekdayLabel: weekdayLabelFromKey(day && day.date_key),
      answer: day && typeof day.answer === "string" ? day.answer : "",
    };
    if (selected === null ||
      (pickMax ? evidence.score > selected.score : evidence.score < selected.score)) {
      selected = evidence;
    }
  }
  return selected;
}

function buildWeeklyInsights({
  payload,
  hasCheckinData,
  avgMood,
  avgEnergy,
  avgStress,
  topKeywords,
}) {
  const insights = [];
  if (hasCheckinData) {
    insights.push(
      `기분 평균 ${avgMood.toFixed(1)}점, 에너지 평균 ${avgEnergy.toFixed(1)}점, ` +
        `스트레스 평균 ${avgStress.toFixed(1)}점입니다.`
    );
  } else {
    insights.push("기분/에너지/스트레스 체크인 기록이 아직 없어서 평균 점수는 집계되지 않았어요.");
  }

  const bestDay = pickDayEvidence(payload, true);
  const hardestDay = pickDayEvidence(payload, false);
  const leadKeyword = topKeywords.length > 0 ? topKeywords[0] : "";
  const periodKey = normalizedReportPeriod(payload);

  if (hasCheckinData && bestDay) {
    if (leadKeyword) {
      insights.push(
        `${periodKey === "weekly" ? "이번 한 주" : "이 기간에는"} ${bestDay.weekdayLabel}에 컨디션이 좋았고, ` +
          `${withObjectParticle(leadKeyword)} 자주 언급하셨어요.`
      );
    } else {
      insights.push(
        `${periodKey === "weekly" ? "이번 한 주" : "이 기간에는"} ${bestDay.weekdayLabel}에 컨디션이 좋았어요.`
      );
    }
  } else if (leadKeyword) {
    insights.push(
      `${periodKey === "weekly" ? "이번 한 주에는" : "이 기간에는"} ${withObjectParticle(leadKeyword)} 자주 언급하셨어요.`
    );
  }

  if (hasCheckinData) {
    if (hardestDay && (!bestDay || hardestDay.dateLabel !== bestDay.dateLabel)) {
      insights.push(`${hardestDay.weekdayLabel}은 상대적으로 컨디션이 저조했어요.`);
    } else if (bestDay) {
      insights.push("요일별 컨디션 차이는 비교적 고르게 유지됐어요.");
    }
  }

  if (topKeywords.length > 0) {
    insights.push(`최근 자주 나온 키워드는 ${topKeywords.slice(0, 3).join(", ")} 입니다.`);
  } else {
    insights.push("최근 자주 나온 키워드는 아직 더 모이면 선명해질 거예요.");
  }

  const cues = collectPreferredActionCues(payload, hardestDay ? hardestDay.answer : "");
  if (cues.length > 0) {
    const cue = cues[0];
    const lead = hardestDay
      ? `${hardestDay.weekdayLabel}처럼 컨디션이 낮았던 날에도 회복 단서가 남아 있었어요.`
      : `기록에서 ${cue.shortLabel}가 반복해서 보여요.`;
    insights.push(`${lead} 다음에 비슷하게 지치는 날엔 ${cue.recommendation}`);
  }
  return insights;
}

function matchesCuePattern(text, pattern) {
  const normalizedText = String(text || "").trim().toLowerCase();
  const normalizedPattern = String(pattern || "").trim().toLowerCase();
  if (!normalizedText || !normalizedPattern) {
    return false;
  }
  if (normalizedText === normalizedPattern) {
    return true;
  }
  if (normalizedText.split(/\s+/).includes(normalizedPattern)) {
    return true;
  }
  if (normalizedPattern.length < 2) {
    return false;
  }
  return normalizedText.includes(normalizedPattern);
}

function collectPreferredActionCues(payload, prioritizedText = "") {
  const texts = [
    ...(Array.isArray(payload?.representative_answers)
      ? payload.representative_answers.filter((x) => typeof x === "string")
      : []),
    ...(Array.isArray(payload?.days)
      ? payload.days
          .map((day) => (typeof day?.answer === "string" ? day.answer : ""))
          .filter(Boolean)
      : []),
    ...(Array.isArray(payload?.top_keywords)
      ? payload.top_keywords.filter((x) => typeof x === "string")
      : []),
  ];
  const topKeywords = Array.isArray(payload?.top_keywords)
    ? payload.top_keywords.filter((x) => typeof x === "string")
    : [];
  const scores = [];
  for (const cue of RECOVERY_ACTION_CUES) {
    let score = 0;
      for (const text of texts) {
        for (const pattern of cue.patterns) {
          if (!matchesCuePattern(text, pattern)) {
            continue;
          }
          score += topKeywords.includes(pattern) ? 2 : 1;
        }
      }
      for (const pattern of cue.patterns) {
        if (matchesCuePattern(prioritizedText, pattern)) {
          score += 3;
        }
      }
      if (score > 0) {
        scores.push({ cue, score });
      }
  }
  scores.sort((a, b) => {
    if (b.score !== a.score) {
      return b.score - a.score;
    }
    return a.cue.shortLabel.localeCompare(b.cue.shortLabel, "ko");
  });
  return scores.slice(0, 3).map((item) => item.cue);
}

function hardMoodTheme(payload) {
  const metrics = payload?.metrics || {};
  const texts = [
    ...(Array.isArray(payload?.representative_answers)
      ? payload.representative_answers.filter((x) => typeof x === "string")
      : []),
    ...(Array.isArray(payload?.entries_compact)
      ? payload.entries_compact.filter((x) => typeof x === "string")
      : []),
  ];
  const joined = texts.join(" ");
  if (/불안|걱정|스트레스|예민/.test(joined)) {
    return "걱정이나 긴장감";
  }
  if (/피곤|지쳐|수면|잠/.test(joined)) {
    return "유난히 기운이 빠지는 느낌";
  }
  if (/외롭|혼자|관계/.test(joined)) {
    return "마음이 허전한 느낌";
  }
  if (/일정|집중|미룸|해야/.test(joined)) {
    return "해야 할 일이 몰려 답답한 느낌";
  }
  if ((asNumber(metrics.avg_stress) || 0) >= 4) {
    return "부담이 크게 올라오는 날";
  }
  if ((asNumber(metrics.avg_energy) || 0) <= 2.5) {
    return "에너지가 뚝 떨어지는 날";
  }
  return "마음이 가라앉는 날";
}

function hardThemeLead(theme) {
  const normalized = String(theme || "").trim();
  if (!normalized) {
    return "";
  }
  if (normalized.endsWith("날")) {
    return `${normalized}에는 `;
  }
  if (normalized.endsWith("느낌") || normalized.endsWith("긴장감")) {
    return `${normalized}이 들 때는 `;
  }
  return `${normalized}이 올라올 때는 `;
}

function normalizedReportPeriod(payload) {
  const raw = String(payload?.period || "weekly").trim().toLowerCase();
  switch (raw) {
    case "monthly":
    case "quarterly":
    case "yearly":
      return raw;
    default:
      return "weekly";
  }
}

function reportPeriodLabel(periodKey) {
  switch (periodKey) {
    case "monthly":
      return "월간";
    case "quarterly":
      return "분기";
    case "yearly":
      return "연간";
    default:
      return "주간";
  }
}

function buildPersonalizedActions(payload, compact = false) {
  const actions = [];
  const seen = new Set();
  const periodKey = normalizedReportPeriod(payload);
  const periodWindow = periodKey === "weekly" ? "이번 주" : "이 기간";
  const periodReviewWindow = periodKey === "weekly" ? "이번 주" : "이 기간에";
  const cues = collectPreferredActionCues(payload, bestDayText(payload));
  const theme = hardMoodTheme(payload);
  const topKeywords = Array.isArray(payload?.top_keywords)
    ? payload.top_keywords.filter((x) => typeof x === "string")
    : [];
  const communityIdeas = Array.isArray(payload?.community_recovery_ideas)
    ? payload.community_recovery_ideas.filter((x) => typeof x === "string")
    : [];

  function add(action) {
    const normalized = String(action || "")
      .trim()
      .replace(/^(다음\s*주\s*미션|다음\s*주\s*액션|다음\s*액션)\s*[:：-]?\s*/u, "");
    if (!normalized || seen.has(normalized)) {
      return;
    }
    seen.add(normalized);
    actions.push(normalized);
  }

  if (cues.length > 0) {
    const cue = cues[0];
    add(
      `${periodWindow} 기록에서는 ${cue.subject} 기분을 환기하는 데 도움이 된 흔적이 보여요. ` +
        `다음에 마음이 가라앉는 날엔 ${cue.recommendation}`
    );
  }

  if (!compact && communityIdeas.length > 0) {
    add(communityIdeas[0]);
  }

  if (!compact) {
    if (cues.length > 1) {
      const cue = cues[1];
      add(
        `${hardThemeLead(theme)}` +
          `${cue.shortLabel} 같은 작은 회복 행동부터 먼저 해보세요.`
      );
    } else if (cues.length > 0) {
      add(
        `${hardThemeLead(theme)}버티기보다 ` +
          `${cues[0].shortLabel} 같은 작은 회복 행동부터 먼저 해보세요.`
      );
    }
  }

  if (!compact && topKeywords.length > 0) {
    add(
      `${periodWindow} 자주 보인 키워드는 ${topKeywords[0]}예요. ` +
        `${topKeywords[0]}와 연결된 작은 행동 하나를 다시 꺼내 해보세요.`
    );
  }

  add(
    `기분이 좋지 않은 날엔 ${periodReviewWindow} 조금 괜찮았던 행동 1가지를 먼저 다시 해보세요.`
  );
  add("마음이 복잡한 날엔 해결부터 하려 하기보다 지금 할 수 있는 가장 작은 행동 1개만 시작해보세요.");

  return actions.slice(0, compact ? 1 : 3);
}

function buildFallbackReport(payload) {
  const metrics = payload?.metrics || {};
  const periodKey = normalizedReportPeriod(payload);
  const periodWindow = periodKey === "weekly" ? "이번 주" : "이 기간";
  const flowLabel = periodKey === "weekly" ? "주간 컨디션" : "이 기간 흐름";
  const recordedDays = asNumber(metrics.recorded_days) || 0;
  if (recordedDays < 3) {
    return buildCompactFallbackReport(payload);
  }
  const weeklyScore = Math.max(0, Math.min(5, Math.round(asNumber(metrics.weekly_score) || 0)));
  const avgMood = asNumber(metrics.avg_mood) || 0;
  const avgEnergy = asNumber(metrics.avg_energy) || 0;
  const avgStress = asNumber(metrics.avg_stress) || 0;
  const checkinRecordedDays = asNumber(metrics.checkin_recorded_days) || 0;
  const hasCheckinData =
    checkinRecordedDays > 0 || avgMood > 0 || avgEnergy > 0 || avgStress > 0;
  const targetDays = asNumber(metrics.target_days) || 7;
  const completion = targetDays > 0 ? Math.round((recordedDays / targetDays) * 100) : 0;
  const topKeywords = Array.isArray(payload?.top_keywords)
    ? payload.top_keywords.filter((x) => typeof x === "string").slice(0, 3)
    : [];
  const emotionSummary = buildEmotionSummary(payload);
  const insights = buildWeeklyInsights({
    payload,
    hasCheckinData,
    avgMood,
    avgEnergy,
    avgStress,
    topKeywords,
  });

  const actions = buildPersonalizedActions(payload);

  return {
    summary: hasCheckinData
      ? `${periodWindow} 평균 점수는 ${weeklyScore}/5점, 기록률은 ${completion}%예요. ${flowLabel}은 비교적 안정적인 편이었어요.`
      : `${periodWindow} 기록률은 ${completion}%예요. 감정 체크인 데이터가 아직 부족해서 평균 점수는 집계되지 않았어요.`,
    emotion_summary: emotionSummary.summary,
    insights,
    weekly_score: weeklyScore,
    monthly_score: null,
    actions,
    source: "server-fallback",
  };
}

function buildCompactFallbackReport(payload) {
  const metrics = payload?.metrics || {};
  const periodKey = normalizedReportPeriod(payload);
  const periodIntro = periodKey === "weekly" ? "이번 주는" : "이 기간에는";
  const weeklyScore = Math.max(0, Math.min(5, Math.round(asNumber(metrics.weekly_score) || 0)));
  const recordedDays = asNumber(metrics.recorded_days) || 0;
  const targetDays = asNumber(metrics.target_days) || 7;
  const completion = targetDays > 0 ? Math.round((recordedDays / targetDays) * 100) : 0;
  const topKeywords = Array.isArray(payload?.top_keywords)
    ? payload.top_keywords.filter((x) => typeof x === "string").slice(0, 2)
    : [];
  const keywordText = topKeywords.length > 0
    ? `지금까지 자주 나온 키워드는 ${topKeywords.join(", ")} 입니다.`
    : "아직 뚜렷한 키워드가 많지 않아요.";
  const emotionSummary = buildEmotionSummary(payload);

  return {
    summary:
      `${periodIntro} ${recordedDays}일 기록했어요. ` +
      `아직 데이터가 많지 않아 간단한 ${reportPeriodLabel(periodKey)} 리포트로 정리했어요. ${keywordText}`,
    emotion_summary:
      `${emotionSummary.summary} ` +
      "조금만 더 기록이 쌓이면 긍정 흐름과 부담 흐름을 더 자세하게 읽어드릴 수 있어요.",
    insights: [`기록률은 ${completion}%예요. 3일 이상 기록이 쌓이면 더 풍부한 리포트를 만들 수 있어요.`],
    weekly_score: weeklyScore,
    monthly_score: null,
    actions: buildPersonalizedActions(payload, true),
    source: "server-fallback",
  };
}

function reportSchema() {
  return {
    type: "object",
    additionalProperties: false,
    properties: {
      summary: { type: "string" },
      emotion_summary: { type: "string" },
      insights: {
        type: "array",
        items: { type: "string" },
        maxItems: 5,
      },
      weekly_score: {
        type: "integer",
        minimum: 0,
        maximum: 5,
      },
      actions: {
        type: "array",
        items: { type: "string" },
        maxItems: 3,
      },
    },
    required: ["summary", "emotion_summary", "insights", "weekly_score", "actions"],
  };
}

function outputTextFromResponse(data) {
  if (typeof data?.output_text === "string" && data.output_text.trim()) {
    return data.output_text.trim();
  }
  const items = Array.isArray(data?.output) ? data.output : [];
  for (const item of items) {
    const content = Array.isArray(item?.content) ? item.content : [];
    for (const part of content) {
      if (typeof part?.text === "string" && part.text.trim()) {
        return part.text.trim();
      }
    }
  }
  return "";
}

async function createOpenAIReport(payload) {
  const recordedDays = asNumber(payload?.metrics?.recorded_days) || 0;
  const periodKey = normalizedReportPeriod(payload);
  const periodLabel = reportPeriodLabel(periodKey);

  const response = await fetch("https://api.openai.com/v1/responses", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${OPENAI_API_KEY}`,
    },
    body: JSON.stringify({
      model: OPENAI_MODEL,
      input: [
        {
          role: "system",
          content: [
            {
              type: "input_text",
              text:
                `너는 한국어 라이프 저널 ${periodLabel} 리포트 에디터다. ` +
                "사용자가 쉽게 읽을 수 있도록 따뜻하고 간결하게 작성한다. " +
                "payload.period를 보고 기간 표현을 정확히 맞춘다. " +
                (periodKey === "weekly"
                  ? ""
                  : "weekly가 아닌 경우 '이번 주', '다음 주' 같은 표현은 쓰지 말고 '이 기간' 또는 해당 기간 표현을 사용한다. ") +
                "metrics.recorded_days가 3 미만이면 간단 리포트로 작성하고 insights는 최대 1개, actions는 최대 1개만 작성한다. " +
                "그 외에는 insights 2~4개, actions 2~3개를 작성한다. " +
                "summary는 2~3문장 이내로 작성한다. " +
                "emotion_summary는 내부 용도로만 쓰일 짧은 정리 문장으로 작성한다. " +
                "가능하면 metrics의 positive_day_count, burden_day_count, trend_delta, top_keywords, representative_answers를 근거로 쓴다. " +
                "summary와 insights는 추상적이기보다 구체적으로 쓰고, '좋았던 순간과 힘들었던 순간이 분명하게 구분됐다' 같은 모호한 문장은 피한다. " +
                "metrics.checkin_recorded_days가 0이거나 avg_mood, avg_energy, avg_stress가 모두 0이면 평균 점수를 실제 0점처럼 쓰지 말고 감정 체크인 데이터가 아직 부족하다고 표현한다. " +
                "insights는 가능하면 4개 이내로 쓰고, 첫 문장은 기분/에너지/스트레스 평균 점수, 다음 문장은 컨디션이 좋았던 요일과 자주 언급한 키워드, 그다음 문장은 상대적으로 컨디션이 저조했던 요일과 그 날의 답변 단서, 마지막 문장은 최근 자주 나온 키워드 2~3개가 어떤 회복 행동으로 이어질 수 있는지 정리하는 형식으로 작성한다. " +
                "'긍정 신호 n일/부담 신호 n일', '최고 컨디션 데이터', '저점 데이터 부족' 같은 메타 표현은 쓰지 않는다. " +
                "actions는 사용자의 representative_answers와 top_keywords를 바탕으로 개인화한다. " +
                "actions는 '안부를 보내라'처럼 추상적으로 끝내지 말고, 기록에 나온 드라마, 야구, 음악, 산책, 카페, 책 같은 구체 활동이 있으면 다음 에피소드 보기, 야구 경기 관람 계획하기, 플레이리스트 2곡 듣기처럼 한 단계 큰 제안으로 확장한다. " +
                "community_recovery_ideas가 있으면 그중 1개 정도는 다른 사람들의 공개답변에서 보인 아이디어로 자연스럽게 녹여도 된다. " +
                "직장인, 학생, 부모 같은 생활 패턴을 임의로 가정하지 말고, '퇴근 후', '출근 전', '점심시간' 같은 표현은 입력에 그런 맥락이 있을 때만 쓴다. " +
                "기록에 직접 등장하지 않은 활동을 '이미 잘 맞는 방식'처럼 단정하지 않는다. " +
                "actions 문장 앞에 '다음 주 미션:' 같은 라벨은 붙이지 않는다. " +
                "actions는 모두 '~해보세요.'로 끝낸다.",
            },
          ],
        },
        {
          role: "user",
          content: [
            {
              type: "input_text",
              text: JSON.stringify(payload),
            },
          ],
        },
      ],
      text: {
        format: {
          type: "json_schema",
          name: "period_report",
          strict: true,
          schema: reportSchema(),
        },
      },
      max_output_tokens: recordedDays < 3 ? 320 : 700,
    }),
  });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`OpenAI API failed: ${response.status} ${text}`);
  }

  const data = await response.json();
  const rawText = outputTextFromResponse(data);
  if (!rawText) {
    throw new Error("OpenAI response is empty");
  }
  const parsed = JSON.parse(rawText);
  return {
    summary: String(parsed.summary || "").trim() || "리포트를 생성했어요.",
    emotion_summary:
      String(parsed.emotion_summary || "").trim() || "이번 주 마음 흐름을 정리했어요.",
    insights: Array.isArray(parsed.insights)
      ? parsed.insights
          .map((x) => String(x).trim())
          .filter(Boolean)
          .filter(
            (item) =>
              !item.includes("긍정 신호") &&
              !item.includes("부담 신호") &&
              !item.includes("최고 컨디션 데이터") &&
              !item.includes("저점 데이터")
          )
          .slice(0, recordedDays < 3 ? 1 : 5)
      : [],
    weekly_score: Math.max(0, Math.min(5, Math.round(asNumber(parsed.weekly_score) || 0))),
    monthly_score:
      parsed.monthly_score === null || parsed.monthly_score === undefined
        ? null
        : Math.round(asNumber(parsed.monthly_score) || 0),
    actions: Array.isArray(parsed.actions)
      ? parsed.actions
          .map((x) => String(x).trim())
          .map((item) =>
            item.replace(/^(다음\s*주\s*미션|다음\s*주\s*액션|다음\s*액션)\s*[:：-]?\s*/u, "")
          )
          .filter(Boolean)
          .slice(0, recordedDays < 3 ? 1 : 3)
      : [],
    source: "ai",
  };
}

const server = http.createServer(async (req, res) => {
  if (req.method === "OPTIONS") {
    return sendJson(res, 200, { ok: true });
  }

  if (req.method === "GET" && req.url === "/health") {
    return sendJson(res, 200, { ok: true, service: "report-api" });
  }

  if (req.method === "POST" && req.url === "/v1/report/analyze") {
    try {
      const payload = await parseBody(req);
      let report;
      if (OPENAI_API_KEY.trim().length > 0) {
        try {
          report = await createOpenAIReport(payload);
        } catch (error) {
          console.error("[report_api] OpenAI failed, fallback used:", error.message);
          report = buildFallbackReport(payload);
        }
      } else {
        report = buildFallbackReport(payload);
      }
      return sendJson(res, 200, report);
    } catch (error) {
      return sendJson(res, 400, {
        error: "bad_request",
        message: error.message || "Invalid request",
      });
    }
  }

  return sendJson(res, 404, { error: "not_found" });
});

server.listen(PORT, () => {
  console.log(`[report_api] listening on http://localhost:${PORT}`);
});
