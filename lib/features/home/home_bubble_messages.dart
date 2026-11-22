import "home_character_assets.dart";
import "home_fish_growth.dart";
import "home_character_selection_store.dart";
import "home_theme_progression.dart";

/// 홈 캐릭터 말풍선 문구.
///
/// 상황에 맞는 문구를 앞에 두고 기본 문구를 뒤에 붙여 순환시킨다.
/// 말풍선이 한 줄에 들어가도록 문구는 공백 포함 16자 안팎으로 유지한다.

const List<String> homeAnsweredDefaultBubbleMessages = <String>[
  "오늘의 답변을 작성했어요!",
  "소중한 하루가 쌓였어요!",
  "꾸준한 당신을 칭찬해요!",
];

const List<String> homeUnansweredDefaultBubbleMessages = <String>[
  "오늘은 아직 답변하지 않았어요",
  "무엇이든 가볍게 적어보세요",
];

const int _levelRemainingHintMax = 5;

String homeCharacterDisplayName(HomeCharacterType type) {
  return type.displayName;
}

/// 오늘 답변을 마친 뒤 홈 말풍선에 보여줄 문구.
List<String> homeAnsweredBubbleMessages({
  required HomeCharacterType characterType,
  required int totalRecordCount,
  required int streakDays,
}) {
  final String name = homeCharacterDisplayName(characterType);
  final String nameSubject = "$name${_subjectParticle(name)}";
  final int growthCount = currentHomeGrowthRecordCount(totalRecordCount);
  final HomeFishGrowthLevel level = homeFishGrowthLevelForRecordCount(
    growthCount,
  );
  final List<String> messages = <String>[];

  if (totalRecordCount == 1) {
    messages.add("첫 기록을 남겼어요!");
  } else if (level != HomeFishGrowthLevel.level1 &&
      growthCount == level.requiredRecordCount) {
    messages.add("$nameSubject 한 뼘 자랐어요!");
  }

  final int? levelRemaining = _recordsUntilNextLevel(growthCount, level);
  if (levelRemaining != null) {
    if (levelRemaining == 1) {
      messages.add("내일 쓰면 $nameSubject 자라요!");
    } else if (levelRemaining <= _levelRemainingHintMax) {
      final String growthHint = "$name 성장까지 $levelRemaining개 남았어요";
      // 이름이 긴 캐릭터(우파루파)는 말풍선 한 줄을 넘지 않게 이름을 뺀다.
      messages.add(
        growthHint.length <= 16 ? growthHint : "다음 성장까지 $levelRemaining개 남았어요",
      );
    }
  } else {
    final int? themeRemaining = _recordsUntilNextTheme(
      characterType,
      totalRecordCount,
    );
    if (themeRemaining != null) {
      messages.add("새 친구까지 $themeRemaining개 남았어요");
    }
  }

  if (_isRecordMilestone(totalRecordCount)) {
    messages.add("벌써 $totalRecordCount번째 기록이에요!");
  }

  if (streakDays >= 7 && streakDays % 7 == 0) {
    messages.add("$streakDays일 연속! 정말 대단해요");
  } else if (streakDays >= 3) {
    messages.add("벌써 $streakDays일 연속이에요!");
  }

  return <String>[...messages, ...homeAnsweredDefaultBubbleMessages];
}

/// 오늘 아직 답변하지 않았을 때 홈 말풍선에 보여줄 문구.
///
/// [daysSinceLastRecord]는 마지막 기록일로부터 지난 일수(어제면 1),
/// 기록이 없으면 null.
List<String> homeUnansweredBubbleMessages({
  required HomeCharacterType characterType,
  required int totalRecordCount,
  required int streakDays,
  required int? daysSinceLastRecord,
}) {
  final List<String> messages = <String>[];

  if (daysSinceLastRecord == 1 && streakDays >= 1) {
    messages.add("오늘 쓰면 ${streakDays + 1}일 연속이에요!");
  }

  final String? nextAnswerHint = homeNextAnswerHint(
    characterType: characterType,
    totalRecordCount: totalRecordCount,
  );
  if (nextAnswerHint != null) {
    messages.add(nextAnswerHint);
  }

  if (daysSinceLastRecord != null && daysSinceLastRecord >= 2) {
    messages.add("다시 시작해 볼까요?");
  }

  return <String>[...messages, ...homeUnansweredDefaultBubbleMessages];
}

/// 다음 답변 하나로 캐릭터가 자라거나 새 친구(테마)가 열리면 그 안내 문구.
/// 해당 없으면 null. 홈 말풍선과 오늘의 질문 알림 제목에 함께 쓴다.
String? homeNextAnswerHint({
  required HomeCharacterType characterType,
  required int totalRecordCount,
}) {
  final String name = homeCharacterDisplayName(characterType);
  final int growthCount = currentHomeGrowthRecordCount(totalRecordCount);
  final HomeFishGrowthLevel level = homeFishGrowthLevelForRecordCount(
    growthCount,
  );
  final int? levelRemaining = _recordsUntilNextLevel(growthCount, level);
  if (levelRemaining == 1) {
    return "오늘 쓰면 $name${_subjectParticle(name)} 자라요!";
  }
  if (levelRemaining == null &&
      _recordsUntilNextTheme(characterType, totalRecordCount) == 1) {
    return "오늘 쓰면 새 친구를 만나요!";
  }
  return null;
}

/// 다음 성장 단계까지 남은 기록 수. 최고 단계면 null.
int? _recordsUntilNextLevel(int growthCount, HomeFishGrowthLevel level) {
  if (level == HomeFishGrowthLevel.level6) {
    return null;
  }
  final HomeFishGrowthLevel next = HomeFishGrowthLevel.values[level.index + 1];
  return next.requiredRecordCount - growthCount;
}

/// 다음 캐릭터를 고를 수 있을 때까지 남은 기록 수. 이미 고를 수 있으면 null.
int? _recordsUntilNextTheme(HomeCharacterType type, int totalRecordCount) {
  final HomeCharacterSelection selection = HomeCharacterSelectionStore.instance
      .resolve(totalRecordCount);
  if (selection.characterType != type) {
    return null;
  }
  final int remaining = homeRecordsUntilNextCharacterSelection(
    selection: selection,
    totalRecordCount: totalRecordCount,
  );
  return remaining <= 0 ? null : remaining;
}

bool _isRecordMilestone(int count) {
  return count == 10 ||
      count == 30 ||
      count == 50 ||
      (count >= 100 && count % 100 == 0);
}

/// 받침이 있으면 "이", 없으면 "가".
String _subjectParticle(String word) {
  if (word.isEmpty) {
    return "가";
  }
  final int code = word.codeUnitAt(word.length - 1);
  if (code < 0xAC00 || code > 0xD7A3) {
    return "가";
  }
  return (code - 0xAC00) % 28 == 0 ? "가" : "이";
}
