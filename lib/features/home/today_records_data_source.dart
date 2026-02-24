import "dart:math";

class OtherTodayRecord {
  const OtherTodayRecord({
    required this.body,
    required this.author,
    required this.isPublic,
    required this.sentimentScore,
    required this.hasBlockedWords,
  });

  final String body;
  final String author;
  final bool isPublic;
  final double sentimentScore;
  final bool hasBlockedWords;
}

abstract final class TodayRecordsDataSource {
  static const List<OtherTodayRecord> rawRecords = <OtherTodayRecord>[
    OtherTodayRecord(
      body:
          "올해는 꼭 해외여행을 다녀오고 싶습니다.\n코로나 이후로 한 번도 비행기를 타본 적이\n없어서, 짧게라도 일본 교토에 가서 벚꽃 시즌을\n직접 보고 사진을 남기는 게 목표예요.",
      author: "익명의 호랑이님 답변",
      isPublic: true,
      sentimentScore: 0.68,
      hasBlockedWords: false,
    ),
    OtherTodayRecord(
      body:
          "올해는 오랫동안 연락하지 못했던 대학 친구에게 먼저 연락해서 꼭 만나고 싶습니다. 연락이\n끊긴 지 벌써 몇 년이 되었는데, 다시 좋은 인연을 이어가고 싶어요.",
      author: "물먹은 하마님 답변",
      isPublic: true,
      sentimentScore: 0.41,
      hasBlockedWords: false,
    ),
    OtherTodayRecord(
      body: "기타로 노래 한 곡 완주하기",
      author: "수영하는 라마님 답변",
      isPublic: true,
      sentimentScore: 0.32,
      hasBlockedWords: false,
    ),
    OtherTodayRecord(
      body:
          "올해는 글쓰기를 꾸준히 이어가고 싶어요. 블로그에 짧은 글이라도 10편 이상은 쓰고, 나중에\n모으면 작은 에세이집으로 엮어보고 싶습니다. 제 생각을 정리하고 기록으로 남기는 습관을 만들고 싶어요.",
      author: "무서운 고양이님 답변",
      isPublic: true,
      sentimentScore: 0.52,
      hasBlockedWords: false,
    ),
    OtherTodayRecord(
      body: "하루 20분 독서 습관 만들기",
      author: "익명의 여우님 답변",
      isPublic: true,
      sentimentScore: 0.27,
      hasBlockedWords: false,
    ),
    OtherTodayRecord(
      body: "나를 위한 운동 루틴 30일 도전",
      author: "웃는 토끼님 답변",
      isPublic: true,
      sentimentScore: 0.48,
      hasBlockedWords: false,
    ),
    OtherTodayRecord(
      body: "감정이 많이 무거워서 오늘은 아무것도 하기 싫어요.",
      author: "익명의 고슴도치님 답변",
      isPublic: true,
      sentimentScore: -0.29,
      hasBlockedWords: false,
    ),
    OtherTodayRecord(
      body: "올해는 가족과 더 자주 대화하는 시간을 만들고 싶어요.",
      author: "익명의 사슴님 답변",
      isPublic: true,
      sentimentScore: 0.36,
      hasBlockedWords: false,
    ),
    OtherTodayRecord(
      body: "공개 설정이 아니라 개인 기록으로만 남겼어요.",
      author: "익명의 너구리님 답변",
      isPublic: false,
      sentimentScore: 0.21,
      hasBlockedWords: false,
    ),
    OtherTodayRecord(
      body: "올해는 일주일에 한 번 새로운 장소를 걸어보려 해요.",
      author: "익명의 고양이님 답변",
      isPublic: true,
      sentimentScore: 0.44,
      hasBlockedWords: false,
    ),
    OtherTodayRecord(
      body: "타인을 향한 모욕 표현이 포함된 문장",
      author: "익명의 늑대님 답변",
      isPublic: true,
      sentimentScore: -0.12,
      hasBlockedWords: true,
    ),
    OtherTodayRecord(
      body: "올해는 그림 그리기를 꾸준히 해보고 싶어요.",
      author: "익명의 펭귄님 답변",
      isPublic: true,
      sentimentScore: 0.39,
      hasBlockedWords: false,
    ),
  ];

  static List<OtherTodayRecord> visiblePublicRecords() {
    return rawRecords
        .where((OtherTodayRecord item) {
          if (!item.isPublic) return false;
          if (item.hasBlockedWords) return false;
          return item.sentimentScore >= -0.25;
        })
        .toList(growable: false);
  }

  static List<OtherTodayRecord> sampledVisibleRecords(DateTime now) {
    final List<OtherTodayRecord> visible = visiblePublicRecords();
    if (visible.isEmpty) {
      return const <OtherTodayRecord>[];
    }
    final int minCount = visible.length < 5 ? visible.length : 5;
    final int maxCount = visible.length < 10 ? visible.length : 10;
    final Random random = Random(
      now.year * 1000000 + now.month * 10000 + now.day * 100 + now.hour,
    );
    final List<OtherTodayRecord> shuffled = List<OtherTodayRecord>.from(visible)
      ..shuffle(random);
    final int count = minCount == maxCount
        ? minCount
        : minCount + random.nextInt(maxCount - minCount + 1);
    return shuffled.take(count).toList(growable: false);
  }
}

