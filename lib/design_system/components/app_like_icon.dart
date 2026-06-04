import "package:flutter/material.dart";

import "../tokens/app_icon.dart";

class AppLikeIcon extends StatelessWidget {
  const AppLikeIcon({
    super.key,
    this.selected = false,
    this.size = AppIconSize.s16,
    this.color = AppIconColor.primary,
    this.semanticLabel,
  });

  final bool selected;
  final double size;
  final Color color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Icon(
        selected ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        size: size,
        color: color,
        semanticLabel: semanticLabel,
      ),
    );
  }
}
