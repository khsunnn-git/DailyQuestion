class PublicRecordModeration {
  PublicRecordModeration._();

  static const double hideThreshold = -0.75;
  static const double reviewThreshold = -0.45;

  // 앱 1차 버전: 로컬 휴리스틱.
  // 추후 Cloud NLP 점수를 서버에서 저장하면 그 값을 우선 사용한다.
  static ModerationResult classifyForUpload(String text) {
    final String normalized = text.trim().toLowerCase();
    if (normalized.isEmpty) {
      return const ModerationResult(
        status: ModerationStatus.published,
        score: 0,
        reason: "empty",
      );
    }

    int riskHits = 0;
    for (final String token in _highRiskTokens) {
      if (normalized.contains(token)) {
        riskHits += 1;
      }
    }

    int negativeHits = 0;
    for (final String token in _negativeTokens) {
      if (normalized.contains(token)) {
        negativeHits += 1;
      }
    }

    double score = 0;
    score -= riskHits * 0.45;
    score -= negativeHits * 0.18;
    if (score < -1) {
      score = -1;
    }

    if (riskHits > 0 || score <= hideThreshold) {
      return ModerationResult(
        status: ModerationStatus.hidden,
        score: score,
        reason: riskHits > 0 ? "high_risk_token" : "negative_score",
      );
    }
    if (score <= reviewThreshold) {
      return const ModerationResult(
        status: ModerationStatus.review,
        score: reviewThreshold,
        reason: "needs_review",
      );
    }
    return ModerationResult(
      status: ModerationStatus.published,
      score: score,
      reason: "pass",
    );
  }

  static bool shouldHideOnFeed({
    required String body,
    String? moderationStatus,
    double? sentimentScore,
  }) {
    final String status = (moderationStatus ?? "").trim().toLowerCase();
    if (status.isNotEmpty && status != "published") {
      return true;
    }

    if (sentimentScore != null && sentimentScore <= reviewThreshold) {
      return true;
    }

    final ModerationResult fallback = classifyForUpload(body);
    return fallback.status != ModerationStatus.published;
  }

  static const List<String> _highRiskTokens = <String>[
    "죽고 싶",
    "죽고싶",
    "자해",
    "극단적 선택",
    "극단적인 선택",
    "목숨",
  ];

  static const List<String> _negativeTokens = <String>[
    "우울",
    "불안",
    "무기력",
    "절망",
    "힘들어",
    "괴로워",
    "외로워",
    "슬퍼",
    "눈물",
  ];
}

enum ModerationStatus { published, review, hidden }

class ModerationResult {
  const ModerationResult({
    required this.status,
    required this.score,
    required this.reason,
  });

  final ModerationStatus status;
  final double score;
  final String reason;
}
