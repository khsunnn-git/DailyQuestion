import "package:flutter/material.dart";

import "../../design_system/design_system.dart";
import "../home/home_character_assets.dart";
import "../home/home_theme_progression.dart";
import "../question/today_question_store.dart";

class CurrentProfileCharacterAvatar extends StatelessWidget {
  const CurrentProfileCharacterAvatar({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    return ValueListenableBuilder<List<TodayQuestionRecord>>(
      valueListenable: TodayQuestionStore.instance,
      builder:
          (BuildContext context, List<TodayQuestionRecord> records, Widget? _) {
            final HomeCharacterType characterType = resolveHomeCharacterType(
              brand,
            );
            final int growthRecordCount = homeGrowthRecordCountForCharacter(
              characterType: characterType,
              totalRecordCount: records.length,
            );
            final String assetPath = HomeCharacterAssets.assetForRecordCount(
              characterType,
              growthRecordCount,
            );
            final EdgeInsets imagePadding = switch (characterType) {
              HomeCharacterType.tree => EdgeInsets.fromLTRB(
                size * 0.125,
                size * 0.125,
                size * 0.125,
                size * 0.0625,
              ),
              HomeCharacterType.fish => EdgeInsets.fromLTRB(
                size * 0.09375,
                size * 0.09375,
                size * 0.09375,
                size * 0.03125,
              ),
            };
            final Offset imageOffset = switch (characterType) {
              HomeCharacterType.tree => Offset(0, size * 0.03125),
              HomeCharacterType.fish => Offset(0, size * 0.015625),
            };

            return SizedBox(
              width: size,
              height: size,
              child: Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: brand.c100,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Padding(
                      padding: imagePadding,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Transform.translate(
                          offset: imageOffset,
                          child: Image.asset(assetPath, fit: BoxFit.contain),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
    );
  }
}
