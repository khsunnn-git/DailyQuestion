const {setGlobalOptions} = require("firebase-functions");
const {onRequest} = require("firebase-functions/https");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

setGlobalOptions({maxInstances: 10});
admin.initializeApp();

/**
 * Public answer report API
 * POST /v1/reports
 */
exports.reportsApi = onRequest(async (request, response) => {
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
