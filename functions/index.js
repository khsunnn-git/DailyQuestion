/* eslint-disable require-jsdoc */
const {setGlobalOptions} = require("firebase-functions");
const {onRequest} = require("firebase-functions/https");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

setGlobalOptions({maxInstances: 10});
admin.initializeApp();

const OPENAI_API_URL = "https://api.openai.com/v1/responses";
const OPENAI_MODEL = process.env.OPENAI_MODEL || "gpt-4.1-mini";

function setCorsHeaders(response) {
  response.set("Access-Control-Allow-Origin", "*");
  response.set("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  response.set("Access-Control-Allow-Headers", "Content-Type, Authorization");
}

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

function buildCompactFallbackReport(payload) {
  const metrics = payload && payload.metrics ? payload.metrics : {};
  const recordedDays = asNumber(metrics.recorded_days) || 0;
  const targetDays = asNumber(metrics.target_days) || 7;
  const completion = targetDays > 0 ?
    Math.round((recordedDays / targetDays) * 100) :
    0;
  const weeklyScore = Math.max(
      0,
      Math.min(5, Math.round(asNumber(metrics.weekly_score) || 0)),
  );
  const topKeywords = Array.isArray(payload && payload.top_keywords) ?
    payload.top_keywords.filter((x) => typeof x === "string").slice(0, 2) :
    [];
  const keywordText = topKeywords.length > 0 ?
    `지금까지 자주 나온 키워드는 ${topKeywords.join(", ")} 입니다.` :
    "아직 뚜렷한 키워드가 많지 않아요.";

  return {
    summary:
      `이번 주는 ${recordedDays}일 기록했어요. ` +
      `아직 데이터가 많지 않아 간단한 리포트로 정리했어요. ${keywordText}`,
    insights: [
      `기록률은 ${completion}%예요. 3일 이상 기록이 쌓이면 더 풍부한 리포트를 만들 수 있어요.`,
    ],
    weekly_score: weeklyScore,
    monthly_score: null,
    actions: ["다음 주에는 3일 이상 가볍게 기록해보세요."],
    source: "server-fallback",
  };
}

function buildFallbackReport(payload) {
  const metrics = payload && payload.metrics ? payload.metrics : {};
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
  const targetDays = asNumber(metrics.target_days) || 7;
  const completion = targetDays > 0 ?
    Math.round((recordedDays / targetDays) * 100) :
    0;
  const topKeywords = Array.isArray(payload && payload.top_keywords) ?
    payload.top_keywords.filter((x) => typeof x === "string").slice(0, 3) :
    [];

  const insights = [
    `기분 ${avgMood.toFixed(1)} / 에너지 ${avgEnergy.toFixed(1)} / ` +
      `스트레스 ${avgStress.toFixed(1)} 점으로 집계됐어요.`,
    topKeywords.length > 0 ?
      `자주 등장한 키워드는 ${topKeywords.join(", ")} 입니다.` :
      "아직 키워드 데이터가 충분하지 않아요.",
    `기록률은 ${completion}%(${recordedDays}/${targetDays})예요.`,
  ];

  const actions = [
    "다음 주 미션: 점수가 좋았던 날의 행동 1개를 주 3회 반복해보세요.",
    "다음 주 미션: 힘들었던 날의 원인 1개를 줄이고 대안 행동을 1개 정해보세요.",
    "다음 주 미션: 하루 마무리 전에 1분 체크인을 고정해보세요.",
  ];

  return {
    summary: `이번 주 평균 점수는 ${weeklyScore}/5점이고 기록률은 ${completion}%예요.`,
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
    required: ["summary", "insights", "weekly_score", "actions"],
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

async function createOpenAIReport(payload) {
  const apiKey = `${process.env.OPENAI_API_KEY || ""}`.trim();
  if (!apiKey) {
    throw new Error("OPENAI_API_KEY is not configured");
  }

  const metrics = payload && payload.metrics ? payload.metrics : {};
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
              text:
                "너는 한국어 라이프 저널 주간 리포트 에디터다. " +
                "사용자가 쉽게 읽을 수 있도록 따뜻하고 간결하게 작성한다. " +
                "metrics.recorded_days가 3 미만이면 간단 리포트로 " +
                "작성하고 insights는 최대 1개, actions는 " +
                "최대 1개만 작성한다. " +
                "그 외에는 insights 2~4개, actions 2~3개를 작성한다. " +
                "summary는 2~3문장 이내로 작성한다. " +
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
          name: "weekly_report",
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
  const insights = Array.isArray(parsed.insights) ?
    parsed.insights
        .map((x) => `${x}`.trim())
        .filter(Boolean)
        .slice(0, recordedDays < 3 ? 1 : 5) :
    [];
  const actions = Array.isArray(parsed.actions) ?
    parsed.actions
        .map((x) => `${x}`.trim())
        .filter(Boolean)
        .slice(0, recordedDays < 3 ? 1 : 3) :
    [];

  return {
    summary: `${parsed.summary || ""}`.trim() || "주간 리포트를 생성했어요.",
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
