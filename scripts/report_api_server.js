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

function buildFallbackReport(payload) {
  const metrics = payload?.metrics || {};
  const weeklyScore = Math.max(0, Math.min(5, Math.round(asNumber(metrics.weekly_score) || 0)));
  const avgMood = asNumber(metrics.avg_mood) || 0;
  const avgEnergy = asNumber(metrics.avg_energy) || 0;
  const avgStress = asNumber(metrics.avg_stress) || 0;
  const recordedDays = asNumber(metrics.recorded_days) || 0;
  const targetDays = asNumber(metrics.target_days) || 7;
  const completion = targetDays > 0 ? Math.round((recordedDays / targetDays) * 100) : 0;
  const topKeywords = Array.isArray(payload?.top_keywords)
    ? payload.top_keywords.filter((x) => typeof x === "string").slice(0, 3)
    : [];

  const insights = [
    `기분 ${avgMood.toFixed(1)} / 에너지 ${avgEnergy.toFixed(1)} / 스트레스 ${avgStress.toFixed(1)} 점으로 집계됐어요.`,
    topKeywords.length > 0
      ? `자주 등장한 키워드는 ${topKeywords.join(", ")} 입니다.`
      : "아직 키워드 데이터가 충분하지 않아요.",
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

async function createOpenAIReport(payload) {
  const compact = Array.isArray(payload?.entries_compact)
    ? payload.entries_compact.filter((x) => typeof x === "string").slice(0, 50)
    : [];

  const prompt = [
    "너는 한국어 라이프 저널 리포트 분석가다.",
    "입력은 사용자의 주간 기록 요약이다.",
    "반드시 JSON만 출력한다.",
    "필수 필드: summary(string), insights(string[]), weekly_score(number), monthly_score(number|null), actions(string[]), source(string).",
    "actions는 실행 가능한 문장 3개로 작성하고 각 문장은 '~해보세요.'로 끝낸다.",
    "insights는 3~5개, 짧고 근거 중심으로 작성한다.",
    "",
    "입력 데이터:",
    JSON.stringify(payload),
    "",
    "entries_compact:",
    compact.join("\n"),
  ].join("\n");

  const response = await fetch("https://api.openai.com/v1/responses", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${OPENAI_API_KEY}`,
    },
    body: JSON.stringify({
      model: OPENAI_MODEL,
      input: prompt,
      text: { format: { type: "json_object" } },
      max_output_tokens: 700,
    }),
  });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`OpenAI API failed: ${response.status} ${text}`);
  }

  const data = await response.json();
  const rawText =
    data?.output_text ||
    data?.output?.[0]?.content?.[0]?.text ||
    data?.choices?.[0]?.message?.content ||
    "";
  if (!rawText) {
    throw new Error("OpenAI response is empty");
  }
  const parsed = JSON.parse(rawText);
  return {
    summary: String(parsed.summary || "").trim() || "리포트를 생성했어요.",
    insights: Array.isArray(parsed.insights)
      ? parsed.insights.map((x) => String(x).trim()).filter(Boolean).slice(0, 5)
      : [],
    weekly_score: Math.max(0, Math.min(5, Math.round(asNumber(parsed.weekly_score) || 0))),
    monthly_score:
      parsed.monthly_score === null || parsed.monthly_score === undefined
        ? null
        : Math.round(asNumber(parsed.monthly_score) || 0),
    actions: Array.isArray(parsed.actions)
      ? parsed.actions.map((x) => String(x).trim()).filter(Boolean).slice(0, 3)
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
