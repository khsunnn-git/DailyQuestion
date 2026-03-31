const Set<String> _rainArtifactKeywords = <String>{"비오", "비온", "비와", "비내"};

final RegExp _conversationTokenPattern = RegExp(
  r"^(대화|통화|얘기|이야기|수다|말하|말해|말했|말한|말할|말함|이야기하|얘기하|통화하)",
);
final RegExp _conversationTextPattern = RegExp(
  r"(대화|통화|얘기|이야기|수다|말하|말해|말했|말한|말할|말하다|이야기하|얘기하|통화하)",
);
final RegExp _rainTokenPattern = RegExp(r"^(비오|비온|비와|비가|비내|빗)");
final RegExp _rainTextPattern = RegExp(r"(비오|비온|비오는|비와|비가|비내|빗소리|빗길)");

String? semanticKeywordAliasForToken(String token) {
  final String normalized = token
      .trim()
      .replaceAll(RegExp(r"\s+"), "")
      .toLowerCase();
  if (normalized.isEmpty) {
    return null;
  }
  if (_conversationTokenPattern.hasMatch(normalized)) {
    return "대화";
  }
  if (_rainTokenPattern.hasMatch(normalized)) {
    return "비";
  }
  return null;
}

List<String> semanticKeywordsFromText(String text) {
  final String normalized = text
      .trim()
      .replaceAll(RegExp(r"\s+"), "")
      .toLowerCase();
  if (normalized.isEmpty) {
    return const <String>[];
  }

  final Set<String> result = <String>{};
  if (_conversationTextPattern.hasMatch(normalized)) {
    result.add("대화");
  }
  if (_rainTextPattern.hasMatch(normalized)) {
    result.add("비");
  }
  return result.toList(growable: false);
}

Set<String> artifactKeywordsForText(String text) {
  final List<String> semanticKeywords = semanticKeywordsFromText(text);
  if (semanticKeywords.isEmpty) {
    return const <String>{};
  }

  final Set<String> result = <String>{};
  if (semanticKeywords.contains("대화")) {
    result.add("말");
  }
  if (semanticKeywords.contains("비")) {
    result.addAll(_rainArtifactKeywords);
  }
  return result;
}
