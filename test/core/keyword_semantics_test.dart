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

  test(
    "semanticKeywordsFromText and artifactKeywordsForText infer cleaner labels",
    () {
      expect(semanticKeywordsFromText("동생이랑 말한다."), contains("대화"));
      expect(artifactKeywordsForText("동생이랑 말한다."), contains("말"));

      expect(semanticKeywordsFromText("비오는 날 창문을 봤다."), contains("비"));
      expect(artifactKeywordsForText("비오는 날 창문을 봤다."), contains("비오"));
    },
  );
}
