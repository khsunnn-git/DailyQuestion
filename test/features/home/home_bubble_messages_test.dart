import "package:dailyquestion/features/home/home_bubble_messages.dart";
import "package:dailyquestion/features/home/home_character_assets.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  group("homeAnsweredBubbleMessages", () {
    List<String> answered({
      HomeCharacterType type = HomeCharacterType.fish,
      required int total,
      int streak = 1,
    }) {
      return homeAnsweredBubbleMessages(
        characterType: type,
        totalRecordCount: total,
        streakDays: streak,
      );
    }

    test("always ends with the default messages", () {
      final List<String> messages = answered(total: 20);
      expect(
        messages.sublist(messages.length - 3),
        homeAnsweredDefaultBubbleMessages,
      );
    });

    test("celebrates the first record", () {
      expect(answered(total: 1).first, "첫 기록을 남겼어요!");
    });

    test("hints growth when one record is left", () {
      // 물고기 레벨2는 기록 3개부터.
      expect(answered(total: 2), contains("내일 쓰면 물고기가 자라요!"));
    });

    test("shows remaining count when 2 to 5 records are left", () {
      // 레벨3은 10개부터.
      expect(answered(total: 5), contains("물고기 성장까지 5개 남았어요"));
      expect(answered(total: 4).any((String m) => m.contains("성장까지")), isFalse);
    });

    test("announces a fresh level up", () {
      expect(answered(total: 10).first, "물고기가 한 뼘 자랐어요!");
    });

    test("uses the 이 particle for 새싹", () {
      // 새싹 성장 기록 = 전체 - 60. 성장 3개(레벨2)가 되는 순간.
      expect(
        answered(type: HomeCharacterType.tree, total: 63).first,
        "새싹이 한 뼘 자랐어요!",
      );
    });

    test("points to the next character selection at max level", () {
      expect(answered(total: 50), contains("새 친구까지 10개 남았어요"));
      // 구버전 백구(180부터)도 60개를 채우면 다음 캐릭터를 고를 수 있다.
      expect(
        answered(type: HomeCharacterType.dog, total: 230),
        contains("새 친구까지 10개 남았어요"),
      );
      expect(
        answered(
          type: HomeCharacterType.dog,
          total: 240,
        ).any((String m) => m.contains("새 친구")),
        isFalse,
      );
    });

    test("marks record milestones", () {
      expect(answered(total: 30), contains("벌써 30번째 기록이에요!"));
      expect(answered(total: 200), contains("벌써 200번째 기록이에요!"));
    });

    test("praises streaks", () {
      expect(answered(total: 20, streak: 3), contains("벌써 3일 연속이에요!"));
      expect(answered(total: 20, streak: 14), contains("14일 연속! 정말 대단해요"));
      expect(
        answered(total: 20, streak: 2).any((String m) => m.contains("연속")),
        isFalse,
      );
    });

    test("keeps every message within 16 characters", () {
      for (final HomeCharacterType type in HomeCharacterType.values) {
        for (int total = 1; total <= 240; total++) {
          for (final int streak in <int>[1, 3, 7, 21, 99]) {
            for (final String m in answered(
              type: type,
              total: total,
              streak: streak,
            )) {
              expect(m.length, lessThanOrEqualTo(16), reason: m);
            }
          }
        }
      }
    });
  });

  group("homeUnansweredBubbleMessages", () {
    List<String> unanswered({
      HomeCharacterType type = HomeCharacterType.fish,
      required int total,
      int streak = 0,
      int? daysSince,
    }) {
      return homeUnansweredBubbleMessages(
        characterType: type,
        totalRecordCount: total,
        streakDays: streak,
        daysSinceLastRecord: daysSince,
      );
    }

    test("shows only defaults for a brand new user", () {
      expect(unanswered(total: 0), homeUnansweredDefaultBubbleMessages);
    });

    test("encourages continuing a streak from yesterday", () {
      expect(
        unanswered(total: 20, streak: 4, daysSince: 1).first,
        "오늘 쓰면 5일 연속이에요!",
      );
    });

    test("hints growth when one record is left", () {
      expect(
        unanswered(total: 9, streak: 1, daysSince: 1),
        contains("오늘 쓰면 물고기가 자라요!"),
      );
    });

    test("hints the next theme when one record is left", () {
      expect(unanswered(total: 59, daysSince: 3), contains("오늘 쓰면 새 친구를 만나요!"));
    });

    test("welcomes back after a missed day", () {
      final List<String> messages = unanswered(
        total: 20,
        streak: 3,
        daysSince: 2,
      );
      expect(messages, contains("다시 시작해 볼까요?"));
      expect(messages.any((String m) => m.contains("연속")), isFalse);
    });

    test("keeps every message within 16 characters", () {
      for (final HomeCharacterType type in HomeCharacterType.values) {
        for (int total = 0; total <= 240; total++) {
          for (final int streak in <int>[0, 1, 9, 98]) {
            for (final int? daysSince in <int?>[null, 1, 2, 10]) {
              for (final String m in unanswered(
                type: type,
                total: total,
                streak: streak,
                daysSince: daysSince,
              )) {
                expect(m.length, lessThanOrEqualTo(16), reason: m);
              }
            }
          }
        }
      }
    });
  });
}
