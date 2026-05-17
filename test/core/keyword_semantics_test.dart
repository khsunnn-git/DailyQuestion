import "package:dailyquestion/core/keyword_semantics.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  test("semanticKeywordAliasForToken normalizes conversation stems", () {
    expect(semanticKeywordAliasForToken("말한다"), "대화");
    expect(semanticKeywordAliasForToken("통화했다"), "대화");
    expect(semanticKeywordAliasForToken("이야기하고"), "대화");
  });

  test("semanticKeywordAliasForToken normalizes rain stems", () {
    expect(semanticKeywordAliasForToken("비오는"), "비");
    expect(semanticKeywordAliasForToken("비와서"), "비");
    expect(semanticKeywordAliasForToken("빗소리"), "비");
  });

  test("semanticKeywordAliasForToken maps descriptive topic words", () {
    expect(semanticKeywordAliasForToken("정주행중인"), "드라마");
    expect(semanticKeywordAliasForToken("추억돋는다"), "추억");
    expect(semanticKeywordAliasForToken("쉬었다"), "휴식");
  });

  test(
    "semanticKeywordsFromText and artifactKeywordsForText infer cleaner labels",
    () {
      expect(semanticKeywordsFromText("동생이랑 말한다."), contains("대화"));
      expect(artifactKeywordsForText("동생이랑 말한다."), contains("말"));

      expect(semanticKeywordsFromText("비오는 날 창문을 봤다."), contains("비"));
      expect(artifactKeywordsForText("비오는 날 창문을 봤다."), contains("비오"));
    },
  );

  test("semantic keywords capture the topic of the writing", () {
    final List<String> keywords = semanticKeywordsFromText(
      "오랜만에 예전 드라마를 정주행하니까 추억이 올라왔다.",
    );

    expect(keywords, contains("드라마"));
    expect(keywords, contains("추억"));
    expect(
      artifactKeywordsForText("오랜만에 예전 드라마를 정주행하니까 추억이 올라왔다."),
      contains("정주행"),
    );
  });
}
