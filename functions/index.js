/* eslint-disable require-jsdoc */
const {setGlobalOptions} = require("firebase-functions");
const {HttpsError, onCall, onRequest} = require("firebase-functions/https");
const {onSchedule} = require("firebase-functions/scheduler");
const crypto = require("crypto");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

setGlobalOptions({maxInstances: 10});
admin.initializeApp();

const OPENAI_API_URL = "https://api.openai.com/v1/responses";
const OPENAI_MODEL = process.env.OPENAI_MODEL || "gpt-4.1-mini";

function normalizedString(value) {
  return `${value || ""}`.trim();
}

function normalizedSlot(value) {
  if (typeof value === "number" && Number.isInteger(value)) {
    return value;
  }
  if (typeof value === "string" && /^\d+$/.test(value.trim())) {
    return Number.parseInt(value.trim(), 10);
  }
  return -1;
}

function validateLikePayload(data) {
  const questionDateKey = normalizedString(data && data.questionDateKey);
  const questionSlot = normalizedSlot(data && data.questionSlot);
  const answerDocId = normalizedString(data && data.answerDocId);

  if (!/^\d{8}$/.test(questionDateKey)) {
    throw new HttpsError(
        "invalid-argument",
        "questionDateKey must be yyyyMMdd.",
    );
  }
  if (questionSlot < 0 || questionSlot > 2) {
    throw new HttpsError(
        "invalid-argument",
        "questionSlot must be 0, 1, or 2.",
    );
  }
  if (!answerDocId || answerDocId.length > 160 || answerDocId.includes("/")) {
    throw new HttpsError(
        "invalid-argument",
        "answerDocId is invalid.",
    );
  }

  return {questionDateKey, questionSlot, answerDocId};
}

function setCorsHeaders(response) {
  response.set("Access-Control-Allow-Origin", "*");
  response.set("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  response.set("Access-Control-Allow-Headers", "Content-Type, Authorization");
}

exports.togglePublicAnswerLike = onCall(async (request) => {
  const uid = request.auth && request.auth.uid ?
    `${request.auth.uid}`.trim() :
    "";
  if (!uid) {
    throw new HttpsError(
        "unauthenticated",
        "Sign in is required to like a public answer.",
    );
  }

  const payload = validateLikePayload(request.data || {});
  return togglePublicAnswerLikeForUid(uid, payload);
});

async function togglePublicAnswerLikeForUid(uid, payload) {
  const {questionDateKey, questionSlot, answerDocId} = payload;
  const db = admin.firestore();
  const answerRef = db
      .collection("public_answers")
      .doc(questionDateKey)
      .collection("slots")
      .doc(`slot_${questionSlot}`)
      .collection("answers")
      .doc(answerDocId);
  const likeRef = answerRef.collection("likes").doc(uid);

  return db.runTransaction(async (transaction) => {
    const answerSnapshot = await transaction.get(answerRef);
    if (!answerSnapshot.exists) {
      throw new HttpsError(
          "not-found",
          "Public answer does not exist.",
      );
    }

    const likeSnapshot = await transaction.get(likeRef);
    const currentCount = Math.max(
        0,
        Math.trunc(asNumber(answerSnapshot.get("likeCount")) || 0),
    );
    const timestamp = admin.firestore.FieldValue.serverTimestamp();

    if (likeSnapshot.exists) {
      const nextCount = Math.max(0, currentCount - 1);
      transaction.delete(likeRef);
      transaction.update(answerRef, {
        likeCount: nextCount,
        updatedAt: timestamp,
      });
      return {liked: false, likeCount: nextCount};
    }

    const nextCount = currentCount + 1;
    transaction.set(likeRef, {
      userUid: uid,
      createdAt: timestamp,
    });
    transaction.update(answerRef, {
      likeCount: nextCount,
      updatedAt: timestamp,
    });
    return {liked: true, likeCount: nextCount};
  });
}

exports.togglePublicAnswerLikeApi = onRequest(async (request, response) => {
  setCorsHeaders(response);
  if (request.method === "OPTIONS") {
    return response.status(204).send("");
  }
  if (request.method !== "POST") {
    response.set("Allow", "POST");
    return response.status(405).json({message: "Method Not Allowed"});
  }

  try {
    const authHeader = `${request.headers.authorization || ""}`;
    const token = authHeader.startsWith("Bearer ") ?
      authHeader.slice(7).trim() :
      "";
    if (!token) {
      return response.status(401).json({message: "Authorization required."});
    }

    const decodedToken = await admin.auth().verifyIdToken(token);
    const uid = `${decodedToken.uid || ""}`.trim();
    if (!uid) {
      return response.status(401).json({message: "Authorization required."});
    }

    const result = await togglePublicAnswerLikeForUid(
        uid,
        validateLikePayload(request.body || {}),
    );
    return response.status(200).json(result);
  } catch (error) {
    logger.error("togglePublicAnswerLikeApi failed", error);
    if (error instanceof HttpsError) {
      const statusByCode = {
        "invalid-argument": 400,
        "unauthenticated": 401,
        "permission-denied": 403,
        "not-found": 404,
      };
      return response
          .status(statusByCode[error.code] || 500)
          .json({message: error.message, code: error.code});
    }
    return response.status(500).json({message: "Internal Server Error"});
  }
});

function asNumber(value) {
  if (typeof value === "number") {
    return value;
  }
  if (typeof value === "string") {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : null;
  }
  return null;
}

function buildEmotionSummary(payload) {
  const metrics = payload && payload.metrics ? payload.metrics : {};
  const recordedDays = asNumber(metrics.recorded_days) ||
    (asNumber(metrics.positive_day_count) || 0) +
      (asNumber(metrics.burden_day_count) || 0) +
      (asNumber(metrics.stable_day_count) || 0);
  const positiveDays = asNumber(metrics.positive_day_count) || 0;
  const burdenDays = asNumber(metrics.burden_day_count) || 0;
  const stableDays = asNumber(metrics.stable_day_count) || 0;
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

  const countsText = recordedDays > 0 ?
    "기록한 날 중 " +
      `긍정 신호 ${positiveDays}일, 부담 신호 ${burdenDays}일, ` +
      `안정 흐름 ${stableDays}일이었어요.` :
    "";

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
  const value = `${dateKey || ""}`.trim();
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
      dateLabel:
        `${day && typeof day.date_key === "string" ? day.date_key : ""}`,
      weekdayLabel: weekdayLabelFromKey(day && day.date_key),
      answer: day && typeof day.answer === "string" ? day.answer : "",
    };
    if (selected === null ||
      (pickMax ?
        evidence.score > selected.score :
        evidence.score < selected.score)) {
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
}) {
  const insights = [];
  if (hasCheckinData) {
    insights.push(
        `기분 평균 ${avgMood.toFixed(1)}점, 에너지 평균 ${avgEnergy.toFixed(1)}점, ` +
        `스트레스 평균 ${avgStress.toFixed(1)}점입니다.`,
    );
  } else {
    insights.push("기분/에너지/스트레스 체크인 기록이 아직 없어서 평균 점수는 집계되지 않았어요.");
  }

  const bestDay = pickDayEvidence(payload, true);
  const hardestDay = pickDayEvidence(payload, false);
  const periodKey = normalizedReportPeriod(payload);

  if (hasCheckinData && bestDay) {
    insights.push(
        `${periodKey === "weekly" ? "이번 한 주" : "이 기간에는"} ` +
        `${bestDay.weekdayLabel}에 컨디션이 좋았어요.`,
    );
  }

  if (hasCheckinData) {
    if (
      hardestDay &&
      (!bestDay || hardestDay.dateLabel !== bestDay.dateLabel)
    ) {
      insights.push(`${hardestDay.weekdayLabel}은 상대적으로 컨디션이 저조했어요.`);
    } else if (bestDay) {
      insights.push("요일별 컨디션 차이는 비교적 고르게 유지됐어요.");
    }
  }

  const cues = collectPreferredActionCues(
      payload,
      hardestDay ? hardestDay.answer : "",
  );
  if (cues.length > 0) {
    const cue = cues[0];
    const lead = hardestDay ?
      `${hardestDay.weekdayLabel}처럼 컨디션이 낮았던 날에도 회복 단서가 남아 있었어요.` :
      `기록에서 ${cue.shortLabel}가 반복해서 보여요.`;
    insights.push(`${lead} 다음에 비슷하게 지치는 날엔 ${cue.recommendation}`);
  }
  return insights;
}

function matchesCuePattern(text, pattern) {
  const normalizedText = `${text || ""}`.trim().toLowerCase();
  const normalizedPattern = `${pattern || ""}`.trim().toLowerCase();
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
  const representativeAnswers = Array.isArray(
      payload && payload.representative_answers,
  ) ?
    payload.representative_answers.filter((x) => typeof x === "string") :
    [];
  const days = Array.isArray(payload && payload.days) ? payload.days : [];
  const texts = [
    ...representativeAnswers,
    ...days
        .map((day) => day && typeof day.answer === "string" ? day.answer : "")
        .filter(Boolean),
  ];
  const scores = [];
  for (const cue of RECOVERY_ACTION_CUES) {
    let score = 0;
    for (const text of texts) {
      for (const pattern of cue.patterns) {
        if (!matchesCuePattern(text, pattern)) {
          continue;
        }
        score += 1;
      }
    }
    for (const pattern of cue.patterns) {
      if (matchesCuePattern(prioritizedText, pattern)) {
        score += 3;
      }
    }
    if (score > 0) {
      scores.push({cue, score});
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
  const metrics = payload && payload.metrics ? payload.metrics : {};
  const representativeAnswers = Array.isArray(
      payload && payload.representative_answers,
  ) ?
    payload.representative_answers.filter((x) => typeof x === "string") :
    [];
  const entriesCompact = Array.isArray(payload && payload.entries_compact) ?
    payload.entries_compact.filter((x) => typeof x === "string") :
    [];
  const texts = [
    ...representativeAnswers,
    ...entriesCompact,
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
  const normalized = `${theme || ""}`.trim();
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
  const raw = `${payload && payload.period ? payload.period : "weekly"}`
      .trim()
      .toLowerCase();
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
  const communityIdeas = Array.isArray(
      payload && payload.community_recovery_ideas,
  ) ?
    payload.community_recovery_ideas.filter((x) => typeof x === "string") :
    [];

  function add(action) {
    const normalized = `${action || ""}`.trim()
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
        `다음에 마음이 가라앉는 날엔 ${cue.recommendation}`,
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
          `${cue.shortLabel} 같은 작은 회복 행동부터 먼저 해보세요.`,
      );
    } else if (cues.length > 0) {
      add(
          `${hardThemeLead(theme)}버티기보다 ` +
          `${cues[0].shortLabel} 같은 작은 회복 행동부터 먼저 해보세요.`,
      );
    }
  }

  add(
      `기분이 좋지 않은 날엔 ${periodReviewWindow} 조금 괜찮았던 행동 1가지를 먼저 다시 해보세요.`,
  );
  add("마음이 복잡한 날엔 해결부터 하려 하기보다 지금 할 수 있는 가장 작은 행동 1개만 시작해보세요.");

  return actions.slice(0, compact ? 1 : 3);
}

function buildCompactFallbackReport(payload) {
  const metrics = payload && payload.metrics ? payload.metrics : {};
  const periodKey = normalizedReportPeriod(payload);
  const periodIntro = periodKey === "weekly" ? "이번 주는" : "이 기간에는";
  const recordedDays = asNumber(metrics.recorded_days) || 0;
  const targetDays = asNumber(metrics.target_days) || 7;
  const completion = targetDays > 0 ?
    Math.round((recordedDays / targetDays) * 100) :
    0;
  const weeklyScore = Math.max(
      0,
      Math.min(5, Math.round(asNumber(metrics.weekly_score) || 0)),
  );
  const emotionSummary = buildEmotionSummary(payload);

  return {
    summary:
      `${periodIntro} ${recordedDays}일 기록했어요. ` +
      "아직 데이터가 많지 않아 간단한 " +
      `${reportPeriodLabel(periodKey)} 리포트로 정리했어요.`,
    emotion_summary:
      `${emotionSummary.summary} ` +
      "조금만 더 기록이 쌓이면 긍정 흐름과 부담 흐름을 더 자세하게 읽어드릴 수 있어요.",
    insights: [
      `기록률은 ${completion}%예요. 3일 이상 기록이 쌓이면 더 풍부한 리포트를 만들 수 있어요.`,
    ],
    weekly_score: weeklyScore,
    monthly_score: null,
    actions: buildPersonalizedActions(payload, true),
    source: "server-fallback",
  };
}

function buildFallbackReport(payload) {
  const metrics = payload && payload.metrics ? payload.metrics : {};
  const periodKey = normalizedReportPeriod(payload);
  const periodWindow = periodKey === "weekly" ? "이번 주" : "이 기간";
  const flowLabel = periodKey === "weekly" ? "주간 컨디션" : "이 기간 흐름";
  const recordedDays = asNumber(metrics.recorded_days) || 0;
  if (recordedDays < 3) {
    return buildCompactFallbackReport(payload);
  }

  const weeklyScore = Math.max(
      0,
      Math.min(5, Math.round(asNumber(metrics.weekly_score) || 0)),
  );
  const avgMood = asNumber(metrics.avg_mood) || 0;
  const avgEnergy = asNumber(metrics.avg_energy) || 0;
  const avgStress = asNumber(metrics.avg_stress) || 0;
  const checkinRecordedDays = asNumber(metrics.checkin_recorded_days) || 0;
  const hasCheckinData =
    checkinRecordedDays > 0 ||
    avgMood > 0 ||
    avgEnergy > 0 ||
    avgStress > 0;
  const targetDays = asNumber(metrics.target_days) || 7;
  const completion = targetDays > 0 ?
    Math.round((recordedDays / targetDays) * 100) :
    0;
  const emotionSummary = buildEmotionSummary(payload);
  const insights = buildWeeklyInsights({
    payload,
    hasCheckinData,
    avgMood,
    avgEnergy,
    avgStress,
  });

  const actions = buildPersonalizedActions(payload);

  return {
    summary: hasCheckinData ?
      `${periodWindow} 평균 점수는 ${weeklyScore}/5점, 기록률은 ${completion}%예요. ` +
        `${flowLabel}은 비교적 안정적인 편이었어요.` :
      `${periodWindow} 기록률은 ${completion}%예요. ` +
        "감정 체크인 데이터가 아직 부족해서 평균 점수는 집계되지 않았어요.",
    emotion_summary: emotionSummary.summary,
    insights,
    weekly_score: weeklyScore,
    monthly_score: null,
    actions,
    source: "server-fallback",
  };
}

function reportSchema() {
  return {
    type: "object",
    additionalProperties: false,
    properties: {
      summary: {type: "string"},
      emotion_summary: {type: "string"},
      insights: {
        type: "array",
        items: {type: "string"},
        maxItems: 5,
      },
      weekly_score: {
        type: "integer",
        minimum: 0,
        maximum: 5,
      },
      actions: {
        type: "array",
        items: {type: "string"},
        maxItems: 3,
      },
    },
    required: [
      "summary",
      "emotion_summary",
      "insights",
      "weekly_score",
      "actions",
    ],
  };
}

function outputTextFromResponse(data) {
  if (data && typeof data.output_text === "string" && data.output_text.trim()) {
    return data.output_text.trim();
  }
  const items = data && Array.isArray(data.output) ? data.output : [];
  for (const item of items) {
    const content = item && Array.isArray(item.content) ? item.content : [];
    for (const part of content) {
      if (part && typeof part.text === "string" && part.text.trim()) {
        return part.text.trim();
      }
    }
  }
  return "";
}

/**
 * 키워드 추출은 정확도가 낮아 리포트에 쓰지 않는다.
 * 예전 버전 앱이 보내는 top_keywords / days[].keywords /
 * entries_compact의 키워드 칸을 GPT에 넘기기 전에 지운다.
 * @param {object} payload
 * @return {object}
 */
function withoutKeywords(payload) {
  if (!payload || typeof payload !== "object") {
    return payload;
  }
  const cleaned = {...payload};
  delete cleaned.top_keywords;
  if (Array.isArray(cleaned.days)) {
    cleaned.days = cleaned.days.map((day) => {
      if (!day || typeof day !== "object") {
        return day;
      }
      const copy = {...day};
      delete copy.keywords;
      if (typeof copy.compact_line === "string") {
        copy.compact_line = stripKeywordColumn(copy.compact_line);
      }
      return copy;
    });
  }
  if (Array.isArray(cleaned.entries_compact)) {
    cleaned.entries_compact = cleaned.entries_compact.map((line) =>
      typeof line === "string" ? stripKeywordColumn(line) : line,
    );
  }
  return cleaned;
}

/**
 * "12) \"답변\" | 8/6/4 | 산책,음악" → "12) \"답변\" | 8/6/4"
 * @param {string} line
 * @return {string}
 */
function stripKeywordColumn(line) {
  return line.replace(/^(.*\|\s*[-\d]+\/[-\d]+\/[-\d]+)\s*\|[^|]*$/, "$1");
}

/* ---------- 다른 분들이 요즘 하는 활동 (공개 답변 익명 집계) ---------- */
/* eslint-disable max-len -- 한국어 프롬프트 문장은 줄을 나누면 읽기 어려워서 */

const COMMUNITY_DAILY_COLLECTION = "community_activity_daily";
const COMMUNITY_MIN_PEOPLE = 3; // 이보다 적은 사람이 한 활동은 추천하지 않는다 (개인이 드러나지 않게).
const COMMUNITY_WINDOW_DAYS = 30;
const COMMUNITY_CATCHUP_DAYS = 7; // 공개 답변 보관 기간과 같게.
const COMMUNITY_SITUATIONS = ["지칠 때", "쉬고 싶을 때", "즐거울 때", "새로 해본 것", "평소 즐기는 것"];

function pad2(value) {
  return `${value}`.padStart(2, "0");
}

function kstDateKey(date) {
  const kst = new Date(date.getTime() + 9 * 60 * 60 * 1000);
  return `${kst.getUTCFullYear()}${pad2(kst.getUTCMonth() + 1)}${pad2(kst.getUTCDate())}`;
}

function shiftDateKey(dateKey, days) {
  const y = Number(dateKey.slice(0, 4));
  const m = Number(dateKey.slice(4, 6));
  const d = Number(dateKey.slice(6, 8));
  const date = new Date(Date.UTC(y, m - 1, d + days));
  return `${date.getUTCFullYear()}${pad2(date.getUTCMonth() + 1)}${pad2(date.getUTCDate())}`;
}

function personHash(value) {
  return crypto.createHash("sha256").update(`dq-community:${value}`).digest("hex").slice(0, 12);
}

async function loadPublicAnswersForDate(dateKey) {
  const slotRefs = await admin.firestore()
      .collection("public_answers").doc(dateKey).collection("slots").listDocuments();
  const answers = [];
  for (const slotRef of slotRefs) {
    const snapshot = await slotRef.collection("answers").get();
    snapshot.forEach((doc) => {
      const data = doc.data() || {};
      if (data.moderationStatus && data.moderationStatus !== "published") {
        return;
      }
      const answer = normalizedString(data.answerText);
      if (!answer) {
        return;
      }
      const person = normalizedString(data.authorUid) ||
        normalizedString(data.deviceAnonId) || doc.id;
      answers.push({
        person: personHash(person),
        question: normalizedString(data.questionText),
        answer: answer.slice(0, 300),
      });
    });
  }
  return answers;
}

function communityExtractionSchema() {
  return {
    type: "object",
    additionalProperties: false,
    properties: {
      items: {
        type: "array",
        items: {
          type: "object",
          additionalProperties: false,
          properties: {
            i: {type: "integer"},
            activities: {
              type: "array",
              maxItems: 3,
              items: {
                type: "object",
                additionalProperties: false,
                properties: {
                  name: {type: "string"},
                  situation: {type: "string", enum: COMMUNITY_SITUATIONS},
                },
                required: ["name", "situation"],
              },
            },
          },
          required: ["i", "activities"],
        },
      },
    },
    required: ["items"],
  };
}

const COMMUNITY_EXTRACTION_PROMPT = [
  "너는 일기 앱 사용자들이 공개로 올린 짧은 글에서 '다른 사람도 따라 해 볼 만한 활동'을 뽑는다.",
  "- 글쓴이가 실제로 했거나 즐겨 하는 활동만 뽑는다. 하고 싶다고만 한 것, 싫다고 한 것은 뽑지 않는다.",
  "- name은 2~12자의 짧은 한국어 명사구로 일반화한다. 예: 한강 산책, 전시 관람, 뜨개질, 러닝, 동네 카페 탐방, 플레이리스트 듣기, 친구와 통화, 반신욕, 단풍 구경.",
  "- 가게·회사·사람 이름, 주소처럼 글쓴이를 알 수 있는 정보는 절대 넣지 않는다. 노래·드라마 제목도 '음악 듣기', '드라마 정주행'처럼 일반화한다.",
  "- 같은 활동은 모든 글에서 같은 name으로 쓴다.",
  "- situation은 그 활동을 한 맥락이다: 지칠 때 / 쉬고 싶을 때 / 즐거울 때 / 새로 해본 것 / 평소 즐기는 것.",
  "- 일·공부 자체, 먹기·자기 같은 기본 생활, 활동이 없는 글은 빈 배열로 둔다.",
  "- 입력의 i를 그대로 돌려준다.",
].join("\n");

async function extractCommunityActivities(answers) {
  const apiKey = `${process.env.OPENAI_API_KEY || ""}`.trim();
  if (!apiKey || answers.length === 0) {
    return [];
  }
  const results = [];
  const chunkSize = 60;
  for (let start = 0; start < answers.length; start += chunkSize) {
    const chunk = answers.slice(start, start + chunkSize);
    const response = await fetch(OPENAI_API_URL, {
      method: "POST",
      headers: {"Content-Type": "application/json", "Authorization": `Bearer ${apiKey}`},
      body: JSON.stringify({
        model: OPENAI_MODEL,
        store: false,
        input: [
          {role: "system", content: [{type: "input_text", text: COMMUNITY_EXTRACTION_PROMPT}]},
          {
            role: "user",
            content: [{
              type: "input_text",
              text: JSON.stringify(chunk.map((item, index) => ({i: index, q: item.question, a: item.answer}))),
            }],
          },
        ],
        text: {format: {type: "json_schema", name: "community_activities", strict: true, schema: communityExtractionSchema()}},
        max_output_tokens: 4000,
      }),
    });
    if (!response.ok) {
      throw new Error(`OpenAI community extraction failed: ${response.status} ${await response.text()}`);
    }
    const parsed = JSON.parse(outputTextFromResponse(await response.json()) || "{}");
    for (const item of Array.isArray(parsed.items) ? parsed.items : []) {
      const source = chunk[item && item.i];
      if (!source || !Array.isArray(item.activities)) {
        continue;
      }
      for (const activity of item.activities) {
        const name = normalizedString(activity && activity.name).slice(0, 20);
        if (name && COMMUNITY_SITUATIONS.includes(activity.situation)) {
          results.push({person: source.person, name, situation: activity.situation});
        }
      }
    }
  }
  return results;
}

function groupCommunityActivities(rows) {
  const groups = new Map();
  for (const row of rows) {
    const key = `${row.name}|${row.situation}`;
    if (!groups.has(key)) {
      groups.set(key, {name: row.name, situation: row.situation, persons: new Set()});
    }
    groups.get(key).persons.add(row.person);
  }
  return [...groups.values()].map((group) => ({
    name: group.name,
    situation: group.situation,
    people: group.persons.size,
    person_hashes: [...group.persons],
  }));
}

/**
 * 하루치 공개 답변을 익명 활동 집계로 바꿔 저장한다. 원문은 저장하지 않는다.
 * 이미 처리한 날은 건너뛴다.
 * @param {string} dateKey YYYYMMDD (KST)
 * @return {Promise<string>} 처리 결과
 */
async function aggregateCommunityActivitiesForDate(dateKey) {
  const ref = admin.firestore().collection(COMMUNITY_DAILY_COLLECTION).doc(dateKey);
  if ((await ref.get()).exists) {
    return `${dateKey}: already done`;
  }
  const answers = await loadPublicAnswersForDate(dateKey);
  const activities = groupCommunityActivities(await extractCommunityActivities(answers));
  await ref.set({
    date_key: dateKey,
    answer_count: answers.length,
    activities,
    processed_at: admin.firestore.FieldValue.serverTimestamp(),
  });
  return `${dateKey}: ${answers.length} answers → ${activities.length} activities`;
}

exports.aggregateCommunityActivities = onSchedule(
    {schedule: "30 5 * * *", timeZone: "Asia/Seoul", timeoutSeconds: 540, memory: "512MiB"},
    async () => {
      const today = kstDateKey(new Date());
      // 어제까지, 공개 답변이 남아 있는 기간 중 아직 처리 안 한 날을 채운다.
      for (let offset = COMMUNITY_CATCHUP_DAYS; offset >= 1; offset -= 1) {
        const dateKey = shiftDateKey(today, -offset);
        try {
          logger.info("community activities", await aggregateCommunityActivitiesForDate(dateKey));
        } catch (error) {
          logger.error(`community activities ${dateKey} failed`, error);
        }
      }
    },
);

const COMMUNITY_CACHE_MS = 60 * 60 * 1000;
const communityCache = new Map();

/**
 * 리포트 마지막 날 기준 최근 30일 동안 다른 분들이 많이 한 활동.
 * @param {string} endDateKey YYYYMMDD
 * @return {Promise<Array<{name: string, situation: string, people: number}>>}
 */
async function loadCommunityActivities(endDateKey) {
  const cached = communityCache.get(endDateKey);
  if (cached && Date.now() - cached.at < COMMUNITY_CACHE_MS) {
    return cached.value;
  }
  let value = [];
  try {
    const startKey = shiftDateKey(endDateKey, -(COMMUNITY_WINDOW_DAYS - 1));
    const snapshot = await admin.firestore().collection(COMMUNITY_DAILY_COLLECTION)
        .where("date_key", ">=", startKey)
        .where("date_key", "<=", endDateKey)
        .get();
    const groups = new Map();
    snapshot.forEach((doc) => {
      const activities = (doc.data() || {}).activities;
      for (const activity of Array.isArray(activities) ? activities : []) {
        const key = `${activity.name}|${activity.situation}`;
        if (!groups.has(key)) {
          groups.set(key, {name: activity.name, situation: activity.situation, persons: new Set()});
        }
        const persons = groups.get(key).persons;
        (Array.isArray(activity.person_hashes) ? activity.person_hashes : []).forEach((hash) => persons.add(hash));
      }
    });
    value = [...groups.values()]
        .map((group) => ({name: group.name, situation: group.situation, people: group.persons.size}))
        .filter((item) => item.people >= COMMUNITY_MIN_PEOPLE)
        .sort((a, b) => b.people - a.people)
        .slice(0, 10);
  } catch (error) {
    logger.warn("community activities unavailable", error);
  }
  communityCache.set(endDateKey, {at: Date.now(), value});
  return value;
}

/* eslint-enable max-len */

/* ---------- 인사이트용 입력 보강 ---------- */
/* eslint-disable max-len -- 한국어 프롬프트 문장은 줄을 나누면 읽기 어려워서 */

const QUESTION_TAG_CACHE_MS = 6 * 60 * 60 * 1000;
let questionTagCache = null;
let questionTagCacheLoadedAt = 0;

function compactText(value) {
  return normalizedString(value).replace(/\s+/g, "");
}

/**
 * 앱에 보이는 질문(Firestore daily_questions)의 태그를 읽어 캐시한다.
 * 실패해도 리포트는 태그 없이 계속 만든다.
 * @return {Promise<{byDay: Map, byText: Map}>}
 */
async function loadQuestionTags() {
  const now = Date.now();
  if (questionTagCache && now - questionTagCacheLoadedAt < QUESTION_TAG_CACHE_MS) {
    return questionTagCache;
  }
  try {
    const snapshot = await admin.firestore().collection("daily_questions").get();
    const byDay = new Map();
    const byText = new Map();
    snapshot.forEach((doc) => {
      const data = doc.data() || {};
      const tags = Array.isArray(data.tags) ?
        data.tags.filter((tag) => typeof tag === "string") :
        [];
      const day = Number(data.dayOfYear || doc.id);
      const base = normalizedString(data.base);
      if (Number.isInteger(day)) {
        byDay.set(day, {base, tags});
      }
      if (base) {
        byText.set(compactText(base), tags);
      }
    });
    questionTagCache = {byDay, byText};
    questionTagCacheLoadedAt = now;
  } catch (error) {
    logger.warn("question tags unavailable", error);
    if (!questionTagCache) {
      questionTagCache = {byDay: new Map(), byText: new Map()};
    }
  }
  return questionTagCache;
}

// 질문 태그 → 인사이트 축. '지금 마음'은 모든 답변의 분위기로 읽으므로 태그로 나누지 않는다.
const INSIGHT_LENS_TAGS = {
  joy: ["취향", "여행/경험", "음악", "관계"],
  rest: ["회복", "스트레스", "에너지", "건강", "루틴"],
  dreams_goals: ["성장", "목표", "동기", "의사결정"],
};

function lensesForTags(tags) {
  return Object.keys(INSIGHT_LENS_TAGS)
      .filter((lens) => INSIGHT_LENS_TAGS[lens].some((tag) => tags.includes(tag)));
}

function koreanSeason(month) {
  if (month >= 3 && month <= 5) return "봄";
  if (month >= 6 && month <= 8) return "여름";
  if (month >= 9 && month <= 11) return "가을";
  return "겨울";
}

// 달마다 한국에서 많이 하는 계절 활동. GPT는 사용자 취향과 이어지는 것만 골라 쓴다.
// 실시간 전시·축제 이름이 아니라 '종류'만 담는다 (구체 일정은 추후 월 1회 검색으로 보강).
const MONTHLY_SEASON_IDEAS = {
  1: ["눈 오는 날 고궁·한옥마을 걷기", "온천·찜질방에서 몸 녹이기", "새해 다이어리·버킷리스트 쓰기", "겨울 바다 보러 가기", "미술관 겨울 기획전 보기"],
  2: ["실내 클라이밍·볼링 같은 새 운동 체험", "북카페에서 책 한 권 끝내기", "봄맞이 방 정리·화분 들이기", "따뜻한 차 마시는 찻집 투어"],
  3: ["매화·산수유 꽃길 걷기", "봄 신상 전시·팝업스토어 구경", "자전거 타기 시작하기", "새 취미 원데이 클래스 듣기"],
  4: ["벚꽃길 산책·피크닉", "야외 플리마켓 구경", "가까운 수목원·식물원 가기", "봄 음악 페스티벌"],
  5: ["한강·공원 피크닉", "야외 공연·재즈 페스티벌", "장미 정원 산책", "당일치기 근교 여행", "야구장 직관"],
  6: ["저녁 노을 보며 산책", "수국 명소 가기", "루프탑·야외 영화 상영", "제철 과일 디저트 카페 찾기"],
  7: ["계곡·바다 물놀이", "시원한 미술관·박물관 전시", "여름 음악 페스티벌", "야시장·밤 산책"],
  8: ["별 보러 근교 가기", "실내 전시·영화관에서 더위 피하기", "여름 휴가 짧은 여행", "아침 일찍 걷기"],
  9: ["선선한 저녁 한강·공원 걷기", "가을 음악 페스티벌", "책 축제·북페어", "코스모스·억새 명소 가기"],
  10: ["단풍길 걷기·등산", "억새·핑크뮬리 명소", "가을 야외 전시·비엔날레", "캠핑·불멍", "야구 가을야구 직관"],
  11: ["늦가을 단풍 끝물 산책", "연말 기획 전시·미술관", "온천 여행", "따뜻한 카페에서 책 읽기", "첫 겨울 옷 정리·뜨개질 같은 손 취미"],
  12: ["크리스마스 마켓·빛 축제", "연말 공연·콘서트", "한 해 사진 정리하며 돌아보기", "따뜻한 음식 맛집 찾기", "눈 오는 날 산책"],
};

function seasonContext(payload) {
  const raw = normalizedString(payload && payload.end_date).replace(/-/g, "");
  const month = Number(raw.slice(4, 6));
  if (!Number.isInteger(month) || month < 1 || month > 12) {
    return {};
  }
  const nextMonth = month === 12 ? 1 : month + 1;
  // 주간 리포트는 남은 이번 달, 그 외 기간은 다음 달에 할 활동을 제안한다.
  const ideaMonth = normalizedReportPeriod(payload) === "weekly" ? month : nextMonth;
  return {
    month,
    season: koreanSeason(month),
    next_month: nextMonth,
    next_season: koreanSeason(nextMonth),
    suggestion_month: ideaMonth,
    season_ideas: MONTHLY_SEASON_IDEAS[ideaMonth] || [],
  };
}

/**
 * 답변마다 질문 태그와 인사이트 축(lenses)을 붙이고,
 * 체크인 비율·계절 같은 해석용 context를 더한다.
 * @param {object} payload 앱이 보낸 리포트 입력
 * @return {Promise<object>}
 */
async function enrichPayloadForInsights(payload) {
  if (!payload || typeof payload !== "object" || !Array.isArray(payload.days)) {
    return payload;
  }
  const tagIndex = await loadQuestionTags();
  let answeredDays = 0;
  let checkinDays = 0;
  const lensCounts = {joy: 0, rest: 0, dreams_goals: 0};
  const days = payload.days.map((day) => {
    if (!day || typeof day !== "object" || !normalizedString(day.answer)) {
      return day;
    }
    answeredDays += 1;
    if (day.mood_score != null || day.energy_score != null || day.stress_score != null) {
      checkinDays += 1;
    }
    let tags = tagIndex.byText.get(compactText(day.question));
    if (!tags) {
      const byDay = tagIndex.byDay.get(Number(day.day_of_year));
      // 질문 글이 없을 때만 날짜로 찾는다 (글이 다르면 다른 질문일 수 있음).
      tags = byDay && !normalizedString(day.question) ? byDay.tags : [];
    }
    const lenses = lensesForTags(tags);
    lenses.forEach((lens) => {
      lensCounts[lens] += 1;
    });
    return {...day, question_tags: tags, lenses};
  });
  const rawIdeas = Array.isArray(payload.community_recovery_ideas) ?
    payload.community_recovery_ideas.filter((x) => typeof x === "string") :
    [];
  // 월간 이상 리포트는 이 칸에 사용자 본인의 버킷리스트("카테고리|제목")를 담아 보낸다.
  const openBucketList = rawIdeas.filter((x) => x.includes("|"))
      .map((x) => {
        const [category, title] = x.split("|").map((part) => part.trim());
        return title ? `${title}${category ? ` (${category})` : ""}` : category;
      })
      .filter(Boolean);
  const endKey = normalizedString(payload.end_date).replace(/-/g, "") ||
    kstDateKey(new Date());
  const communityActivities = await loadCommunityActivities(endKey);
  const cleaned = {...payload};
  delete cleaned.community_recovery_ideas;
  return {
    ...cleaned,
    days,
    open_bucket_list: openBucketList,
    community_activities: communityActivities,
    context: {
      answered_days: answeredDays,
      checkin_days: checkinDays,
      checkin_coverage: answeredDays > 0 ?
        Math.round((checkinDays / answeredDays) * 100) / 100 :
        0,
      lens_counts: lensCounts,
      ...seasonContext(payload),
    },
  };
}

function insightSystemPrompt(periodKey, periodLabel) {
  const notWeekly = periodKey !== "weekly";
  const lengthRule = {
    weekly: "insights 3개, actions 2~3개.",
    monthly: "insights 3~4개, actions 3개.",
    quarterly: "insights 4개, actions 3개. 기간 초반과 후반, 계절이 바뀌며 달라진 마음을 비교한다.",
    yearly: "insights 4개, actions 3개. 한 해의 흐름(계절별 마음 변화, 가장 즐거웠던 순간들의 공통점, 바라던 것의 변화)을 돌아본다.",
  }[periodKey] || "insights 3개, actions 2~3개.";
  return [
    `너는 사용자의 ${periodLabel} 일기를 읽고 다정하게 말을 건네는 친구다.`,
    "목표는 사용자가 '나에 대해 새로 알게 되는 것'을 얻게 하는 것이다. 기록을 다시 요약하거나 분석 보고서처럼 쓰지 않는다.",
    "",
    "[입력 읽는 법]",
    "- 핵심 재료는 days[].question과 days[].answer다. 질문은 날짜별로 정해져 있으니 질문 주제와 상관없이 답변 속 활동·사람·장소·감정 표현을 읽는다.",
    "- days[].lenses는 질문 주제 힌트다. joy=즐거움(취향·여행·음악·관계), rest=휴식·회복(회복·스트레스·에너지·건강), dreams_goals=꿈·목표(성장·목표·동기).",
    "- 기분 점수(mood/energy/stress)는 context.checkin_coverage 비율만큼만 있다. 0.5 미만이면 점수 평균을 말하지 말고 쓰신 글의 분위기로 마음을 읽는다.",
    "",
    "[말투]",
    "- 친한 친구가 일기를 읽고 건네는 말처럼 공감하는 해요체로 쓴다. '~습니다', '~확인돼요', '~로 나타났어요' 같은 보고서 말투를 쓰지 않는다.",
    "- payload.nickname이 있으면 전체에서 1~2번만 '닉네임님'으로 부른다(예: 혜선님). 없으면 이름 없이 쓴다.",
    "- 날짜나 횟수를 괄호로 나열하지 않는다. 근거는 문장 속에 자연스럽게 녹인다. 날짜가 꼭 필요하면 '10월 초', '지난주 주말'처럼 넓게 말한다.",
    "- '체크인', '답변', '데이터', '기록에서 확인' 같은 앱 내부 표현 대신 '쓰신 글', '그날'처럼 말한다.",
    "- 한 문장은 짧게, 한 항목은 1~2문장.",
    "",
    "[insights] 아래 역할 순서로, 근거가 있는 것만 쓴다.",
    "1. 지금 마음에 공감하기: 무엇 때문에 마음이 어땠는지. 예) '마감이나 회의 때문에 지친 날이 많았네요.'",
    "2. 지난 기록을 떠올려 주며 권하기: 이 사람에게 효과가 있었던 회복 방법을 다시 꺼내 준다. 예) '지난번에 속상할 때 밤편지를 들으셨던데, 이번에도 같은 곡을 들어보시는 건 어떠세요?'",
    "3. 새로운 발견: 여러 날의 글을 연결해야 보이는, 사용자가 스스로 몰랐을 법한 점을 '~라는 점이 발견되었어요' 형태로 쓴다. 예) '가을의 선선한 날씨와 걷기를 좋아하는 취향이 혜선님의 회복에 중요하다는 점이 발견되었어요.'",
    "4. 즐거움이나 꿈 이야기: 좋아하는 것, 가고 싶은 곳, 바라는 변화를 짚어 준다. 예) '제주나 교토처럼 바다와 골목이 있는 곳을 자주 떠올리셨어요.'",
    "- '일요일에 컨디션이 좋았어요', '산책을 했어요' 같은 단순 사실 나열은 쓰지 않는다.",
    "- 예시 문장은 말투 참고용이다. 입력에 근거가 없으면 그대로 베끼지 않는다.",
    "",
    "[actions] 짧은 두 문장: 상황이나 계절에 대한 한마디 + 가벼운 권유. '~해보세요.' 또는 '~어떠세요?'로 끝낸다.",
    "예) '가을 날씨가 선선해지는 것 같아요. 내장산이나 가까운 단풍 명소를 걸어보세요.'",
    "3개면 역할을 나눈다.",
    "(1) 이미 효과가 있었던 회복 방법을 다음에 지칠 때 다시 써 보도록 권하기.",
    "(2) 좋아하는 활동을 한 단계 넓힌 추천. 예) 산책하며 음악 듣기 → 새 산책 코스와 플레이리스트, 카페 탐방 → 다른 동네 카페, 여행을 꿈꿈 → 짧은 근교 여행. context.season_ideas(context.suggestion_month월에 많이 하는 활동: 전시·축제·자연·여행 등) 중 취향과 맞는 게 있으면 엮어서 권한다.",
    "(3) 지치게 한 일을 조금 덜어 줄 작은 시도.",
    "- 장소는 사용자가 쓴 곳이나 널리 알려진 곳만, 사는 지역을 모르니 '가까운 ~'처럼 쓴다. 전시·공연 이름이나 날짜는 지어내지 않는다.",
    "- community_activities는 같은 앱을 쓰는 다른 분들이 최근 30일 동안 공개 글에 쓴 활동이다(name=활동, situation=언제 했는지, people=몇 명). 이 사람의 취향이나 지금 마음과 이어지는 활동이 있으면 actions 중 1개를 이렇게 권한다. 예) '같은 앱을 쓰는 다른 분들은 요즘 지칠 때 한강을 달리며 기분을 푼대요. 걷기를 좋아하시니 한번 가볍게 따라 해보시는 건 어떠세요?' 인원은 '많은 분들이', '여러 분이'처럼 말하고, 정확한 숫자나 다른 사람의 글 내용은 쓰지 않는다. 이어지는 게 없으면 쓰지 않는다.",
    "- open_bucket_list는 이 사람이 적어 둔 아직 못 한 버킷리스트다. 좋아하는 것·계절과 맞으면 '적어 두신 ~, 이번 달에 해보시는 건 어떠세요?'처럼 꺼내 준다.",
    "- 앞에 '다음 주 미션:', '계절 제안:' 같은 라벨을 붙이지 않는다.",
    "",
    "[분량·형식]",
    `- metrics.recorded_days가 3 미만이면 insights 1개(공감), actions 1개. 그 외에는 ${lengthRule}`,
    "- summary는 2문장: 이 기간 마음을 한마디로 공감 + 가장 중요한 새로운 발견.",
    "- emotion_summary는 내부 용도의 짧은 정리 문장.",
    notWeekly ?
      "- 'weekly'가 아니므로 '이번 주', '다음 주' 대신 '이번 달', '이 기간' 등 payload.period에 맞는 표현을 쓴다." :
      "- 기간 표현은 '이번 주', '다음 주'를 쓴다.",
    "",
    "[금지]",
    "- '키워드'라는 단어, 키워드 나열 문장.",
    "- '긍정 신호 n일', '최고 컨디션 데이터', '저점 데이터 부족' 같은 메타 표현.",
    "- 직장인·학생·부모 같은 생활 패턴 가정. '퇴근 후', '출근길' 같은 표현은 쓰신 글에 그 맥락이 있을 때만.",
    "- 쓰신 글에 없는 활동을 '이미 잘 맞는 방식'처럼 단정하기.",
  ].join("\n");
}

/* eslint-enable max-len */
async function createOpenAIReport(payload) {
  const apiKey = `${process.env.OPENAI_API_KEY || ""}`.trim();
  if (!apiKey) {
    throw new Error("OPENAI_API_KEY is not configured");
  }

  const metrics = payload && payload.metrics ? payload.metrics : {};
  const periodKey = normalizedReportPeriod(payload);
  const periodLabel = reportPeriodLabel(periodKey);
  const recordedDays = asNumber(metrics.recorded_days) || 0;
  const response = await fetch(OPENAI_API_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model: OPENAI_MODEL,
      input: [
        {
          role: "system",
          content: [
            {
              type: "input_text",
              text: insightSystemPrompt(periodKey, periodLabel),
            },
          ],
        },
        {
          role: "user",
          content: [
            {
              type: "input_text",
              text: JSON.stringify(
                  await enrichPayloadForInsights(withoutKeywords(payload)),
              ),
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
      // 한국어 JSON이 잘려 대체 리포트로 넘어가던 문제(2026-10) 때문에 여유 있게 잡는다.
      max_output_tokens: recordedDays < 3 ? 700 : 1600,
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
  const insights = Array.isArray(parsed.insights) ?
    parsed.insights
        .map((x) => `${x}`.trim())
        .filter(Boolean)
        .filter((item) =>
          !item.includes("긍정 신호") &&
          !item.includes("부담 신호") &&
          !item.includes("최고 컨디션 데이터") &&
          !item.includes("저점 데이터"))
        .slice(0, recordedDays < 3 ? 1 : 5) :
    [];
  const actions = Array.isArray(parsed.actions) ?
    parsed.actions
        .map(
            (x) => `${x}`.trim().replace(
                /^(다음\s*주\s*미션|다음\s*주\s*액션|다음\s*액션)\s*[:：-]?\s*/u,
                "",
            ),
        )
        .filter(Boolean)
        .slice(0, recordedDays < 3 ? 1 : 3) :
    [];

  return {
    summary: `${parsed.summary || ""}`.trim()
        .replace("좋았던 순간과 힘들었던 순간이 분명하게 구분되는 한 주였습니다.", "")
        .trim() || "주간 리포트를 생성했어요.",
    emotion_summary:
      `${parsed.emotion_summary || ""}`.trim() ||
      "이번 주 마음 흐름을 정리했어요.",
    insights,
    weekly_score: Math.max(
        0,
        Math.min(5, Math.round(asNumber(parsed.weekly_score) || 0)),
    ),
    monthly_score: null,
    actions,
    source: "ai",
  };
}

/**
 * Public answer report API
 * POST /v1/reports
 */
exports.reportsApi = onRequest(async (request, response) => {
  setCorsHeaders(response);
  if (request.method === "OPTIONS") {
    return response.status(204).send("");
  }
  if (request.method !== "POST") {
    response.set("Allow", "POST");
    return response.status(405).json({message: "Method Not Allowed"});
  }

  try {
    const authHeader = `${request.headers.authorization || ""}`;
    const token = authHeader.startsWith("Bearer ") ?
      authHeader.slice(7).trim() :
      "";

    let reporterUid = null;
    if (token) {
      try {
        const decodedToken = await admin.auth().verifyIdToken(token);
        reporterUid = decodedToken.uid || null;
      } catch (error) {
        logger.warn("Invalid auth token. Continue as anonymous report.", error);
      }
    }

    const payload = request.body || {};
    const reason = `${payload.reason || ""}`.trim();
    const targetId = `${payload.targetId || ""}`.trim();
    const targetType = `${payload.targetType || ""}`.trim();
    const questionDateKey = `${payload.questionDateKey || ""}`.trim();
    const authorName = `${payload.authorName || ""}`.trim();
    const answerPreview = `${payload.answerPreview || ""}`.trim();
    const reportedAt = `${payload.reportedAt || ""}`.trim();

    if (!reason || !targetId || !targetType) {
      return response.status(400).json({
        message: "reason, targetId, targetType are required.",
      });
    }

    const docRef = await admin.firestore().collection("reports").add({
      reason,
      targetId,
      targetType,
      questionDateKey: questionDateKey || null,
      authorName: authorName || null,
      answerPreview: answerPreview || null,
      reporterUid,
      reportedAt: reportedAt || new Date().toISOString(),
      status: "open",
      source: "mobile_app",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return response.status(201).json({
      reportId: docRef.id,
      message: "Report submitted.",
    });
  } catch (error) {
    logger.error("reportsApi failed", error);
    return response.status(500).json({message: "Internal Server Error"});
  }
});

exports.reportAiApi = onRequest(async (request, response) => {
  setCorsHeaders(response);
  if (request.method === "OPTIONS") {
    return response.status(204).send("");
  }

  const path = `${request.path || "/"}`;
  if (request.method === "GET" && path === "/health") {
    return response.status(200).json({ok: true, service: "weekly-report-ai"});
  }
  if (request.method !== "POST") {
    response.set("Allow", "POST");
    return response.status(405).json({message: "Method Not Allowed"});
  }
  if (path !== "/v1/report/analyze" && path !== "/") {
    return response.status(404).json({message: "Not Found"});
  }

  try {
    const payload = request.body || {};
    let report;
    if (`${process.env.OPENAI_API_KEY || ""}`.trim()) {
      try {
        report = await createOpenAIReport(payload);
      } catch (error) {
        logger.error("reportAiApi OpenAI failed, fallback used", error);
        report = buildFallbackReport(payload);
      }
    } else {
      report = buildFallbackReport(payload);
    }
    return response.status(200).json(report);
  } catch (error) {
    logger.error("reportAiApi failed", error);
    return response.status(400).json({
      error: "bad_request",
      message: error.message || "Invalid request",
    });
  }
});
