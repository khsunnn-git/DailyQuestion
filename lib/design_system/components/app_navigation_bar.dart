import "dart:ui";

import "package:flutter/material.dart";

import "../tokens/app_navigation_tokens.dart";

class AppNavigationBarItemData {
  const AppNavigationBarItemData({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;
}

class AppNavigationBar extends StatelessWidget {
  const AppNavigationBar({
    super.key,
    required this.items,
    required this.currentIndex,
    this.onTap,
  }) : assert(items.length == 4, "Navigation item count must be 4");

  final List<AppNavigationBarItemData> items;
  final int currentIndex;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppNavigationBarTokens.blurSigma,
          sigmaY: AppNavigationBarTokens.blurSigma,
        ),
        child: Container(
          width: AppNavigationBarTokens.width,
          height: AppNavigationBarTokens.height,
          color: AppNavigationBarTokens.backgroundColor,
          padding: AppNavigationBarTokens.padding,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List<Widget>.generate(items.length, (int index) {
              final bool focused = index == currentIndex;
              final Color color = focused
                  ? AppNavigationBarTokens.focusedColor
                  : AppNavigationBarTokens.unfocusedColor;
              return SizedBox(
                width: AppNavigationBarTokens.itemWidth,
                child: InkWell(
                  onTap: onTap == null ? null : () => onTap!(index),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        items[index].icon,
                        size: AppNavigationBarTokens.itemIconSize,
                        color: color,
                      ),
                      const SizedBox(height: AppNavigationBarTokens.itemGap),
                      Text(
                        items[index].label,
                        textAlign: TextAlign.center,
                        style: AppNavigationBarTokens.labelStyle.copyWith(color: color),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
