import "package:dailyquestion/design_system/design_system.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  testWidgets("AppLikeIcon renders the outline heart by default", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Center(child: AppLikeIcon())),
    );

    final Icon icon = tester.widget<Icon>(find.byType(Icon));

    expect(icon.icon, Icons.favorite_border_rounded);
    expect(icon.size, AppIconSize.s16);
    expect(icon.color, AppIconColor.primary);
  });

  testWidgets("AppLikeIcon renders filled selected state and size variants", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(child: AppLikeIcon(selected: true, size: AppIconSize.s40)),
      ),
    );

    final Size iconSize = tester.getSize(find.byType(AppLikeIcon));
    final Icon icon = tester.widget<Icon>(find.byType(Icon));

    expect(iconSize, const Size.square(AppIconSize.s40));
    expect(icon.icon, Icons.favorite_rounded);
    expect(icon.size, AppIconSize.s40);
  });
}
