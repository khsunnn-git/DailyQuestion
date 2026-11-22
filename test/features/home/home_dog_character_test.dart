import "package:dailyquestion/features/home/home_dog_character.dart";
import "package:dailyquestion/features/home/home_fish_growth.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";

String? _shownBodyAsset(WidgetTester tester) {
  for (final Image image in tester.widgetList<Image>(find.byType(Image))) {
    // 화면 크기로 줄여 읽기 때문에 ResizeImage로 감싸져 있다.
    final ImageProvider<Object> raw = image.image;
    final ImageProvider<Object> provider = raw is ResizeImage
        ? raw.imageProvider
        : raw;
    if (provider is AssetImage && !provider.assetName.contains("_tail")) {
      return provider.assetName;
    }
  }
  return null;
}

void main() {
  test("모든 레벨의 몸·눈감음·꼬리 프레임이 번들에 있다", () async {
    for (final HomeFishGrowthLevel level in HomeFishGrowthLevel.values) {
      for (final String asset in <String>[
        HomeDogCharacter.baseAssetFor(level),
        HomeDogCharacter.blinkAssetFor(level),
        HomeDogCharacter.tailAssetFor(level),
      ]) {
        final ByteData data = await rootBundle.load(asset);
        expect(data.lengthInBytes, greaterThan(0), reason: asset);
      }
    }
  });

  testWidgets("눈을 깜빡였다가 다시 뜨고, 꼬리는 계속 흔든다", (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: HomeDogCharacter(
            growthLevel: HomeFishGrowthLevel.level3,
            size: 150,
          ),
        ),
      ),
    );
    const String open = "assets/images/home/characters/dog/level_3_base.webp";
    const String closed =
        "assets/images/home/characters/dog/level_3_blink.webp";
    expect(_shownBodyAsset(tester), open);

    Transform tail() => tester.widget<Transform>(
      find
          .ancestor(
            of: find.byType(Image).first,
            matching: find.byType(Transform),
          )
          .first,
    );
    final Matrix4 before = tail().transform.clone();
    await tester.pump(const Duration(milliseconds: 200));
    expect(tail().transform, isNot(equals(before)));

    // 최대 대기 4.8초 안에 한 번은 눈을 감는다.
    bool sawBlink = false;
    for (int i = 0; i < 60 && !sawBlink; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      sawBlink = _shownBodyAsset(tester) == closed;
    }
    expect(sawBlink, isTrue);
    await tester.pump(const Duration(milliseconds: 400));
    expect(_shownBodyAsset(tester), open);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets("움직임 줄이기 설정이면 멈춰 있는다", (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: HomeDogCharacter(
            growthLevel: HomeFishGrowthLevel.level1,
            size: 150,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 6));
    expect(tester.hasRunningAnimations, isFalse);
    expect(
      _shownBodyAsset(tester),
      "assets/images/home/characters/dog/level_1_base.webp",
    );
  });
}
