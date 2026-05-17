final List<_SemanticKeywordRule> _semanticKeywordRules = <_SemanticKeywordRule>[
  _SemanticKeywordRule(
    label: "대화",
    tokenPattern: RegExp(r"^(대화|통화|얘기|이야기|수다|말하|말해|말했|말한|말할|말함|이야기하|얘기하|통화하)"),
    textPattern: RegExp(r"(대화|통화|얘기|이야기|수다|말하|말해|말했|말한|말할|말하다|이야기하|얘기하|통화하)"),
    artifactKeywords: <String>{"말"},
  ),
  _SemanticKeywordRule(
    label: "비",
    tokenPattern: RegExp(r"^(비오|비온|비와|비가|비내|빗)"),
    textPattern: RegExp(r"(비오|비온|비오는|비와|비가|비내|빗소리|빗길)"),
    artifactKeywords: <String>{"비오", "비온", "비와", "비내"},
  ),
  _SemanticKeywordRule(
    label: "드라마",
    tokenPattern: RegExp(r"^(드라마|정주행|몰아보|시리즈|회차|에피소드|넷플릭스|티빙|웨이브|디즈니)"),
    textPattern: RegExp(r"(드라마|정주행|몰아보|시리즈|회차|에피소드|넷플릭스|티빙|웨이브|디즈니)"),
    artifactKeywords: <String>{
      "정주행",
      "몰아보기",
      "시리즈",
      "회차",
      "에피소드",
      "넷플릭스",
      "티빙",
      "웨이브",
      "디즈니",
    },
  ),
  _SemanticKeywordRule(
    label: "영화",
    tokenPattern: RegExp(r"^(영화|극장|상영|관람)"),
    textPattern: RegExp(r"(영화|극장|상영|관람)"),
  ),
  _SemanticKeywordRule(
    label: "추억",
    tokenPattern: RegExp(r"^(추억|회상|그리움|옛생각|향수|추억돋)"),
    textPattern: RegExp(r"(추억|회상|그리움|옛생각|향수|추억돋)"),
  ),
  _SemanticKeywordRule(
    label: "휴식",
    tokenPattern: RegExp(r"^(휴식|쉼|쉬|멍때리|낮잠|누워)"),
    textPattern: RegExp(r"(휴식|쉼|쉬고|쉬는|쉬었|멍때리|낮잠|누워)"),
  ),
  _SemanticKeywordRule(
    label: "가족",
    tokenPattern: RegExp(r"^(가족|엄마|아빠|부모|동생|언니|오빠|형|누나|할머니|할아버지)"),
    textPattern: RegExp(r"(가족|엄마|아빠|부모|동생|언니|오빠|형|누나|할머니|할아버지)"),
  ),
  _SemanticKeywordRule(
    label: "일",
    tokenPattern: RegExp(r"^(회사|업무|출근|퇴근|야근|회의|미팅|프로젝트|마감|직장)"),
    textPattern: RegExp(r"(회사|업무|출근|퇴근|야근|회의|미팅|프로젝트|마감|직장)"),
  ),
  _SemanticKeywordRule(
    label: "여행",
    tokenPattern: RegExp(r"^(여행|공항|비행기|호텔|숙소|휴가|투어|관광)"),
    textPattern: RegExp(r"(여행|공항|비행기|호텔|숙소|휴가|투어|관광)"),
  ),
  _SemanticKeywordRule(
    label: "운동",
    tokenPattern: RegExp(r"^(운동|산책|러닝|조깅|헬스|요가|필라테스|수영|걷)"),
    textPattern: RegExp(r"(운동|산책|러닝|조깅|헬스|요가|필라테스|수영|걷기|걸었)"),
  ),
  _SemanticKeywordRule(
    label: "독서",
    tokenPattern: RegExp(r"^(독서|책|소설|에세이|만화|읽)"),
    textPattern: RegExp(r"(독서|책|소설|에세이|만화|읽고|읽는|읽었)"),
  ),
  _SemanticKeywordRule(
    label: "음악",
    tokenPattern: RegExp(r"^(음악|노래|플레이리스트|멜로디|가사|앨범|듣)"),
    textPattern: RegExp(r"(음악|노래|플레이리스트|멜로디|가사|앨범|들으며|들으니|들었)"),
  ),
];

String? semanticKeywordAliasForToken(String token) {
  final String normalized = token
      .trim()
      .replaceAll(RegExp(r"\s+"), "")
      .toLowerCase();
  if (normalized.isEmpty) {
    return null;
  }
  for (final _SemanticKeywordRule rule in _semanticKeywordRules) {
    if (rule.tokenPattern.hasMatch(normalized)) {
      return rule.label;
    }
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
  for (final _SemanticKeywordRule rule in _semanticKeywordRules) {
    if (rule.textPattern.hasMatch(normalized)) {
      result.add(rule.label);
    }
  }
  return result.toList(growable: false);
}

Set<String> artifactKeywordsForText(String text) {
  final String normalized = text
      .trim()
      .replaceAll(RegExp(r"\s+"), "")
      .toLowerCase();
  if (normalized.isEmpty) {
    return const <String>{};
  }

  final Set<String> result = <String>{};
  for (final _SemanticKeywordRule rule in _semanticKeywordRules) {
    if (rule.textPattern.hasMatch(normalized)) {
      result.addAll(rule.artifactKeywords);
    }
  }
  return result;
}

class _SemanticKeywordRule {
  const _SemanticKeywordRule({
    required this.label,
    required this.tokenPattern,
    required this.textPattern,
    this.artifactKeywords = const <String>{},
  });

  final String label;
  final RegExp tokenPattern;
  final RegExp textPattern;
  final Set<String> artifactKeywords;
}
