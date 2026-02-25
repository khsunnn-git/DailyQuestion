import "dart:ui";

import "package:flutter/material.dart";

import "../tokens/app_navigation_tokens.dart";

class AppNavigationBarItemData {
  const AppNavigationBarItemData({required this.label, required this.icon});

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

  static double totalHeight(BuildContext context) {
    final double bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return AppNavigationBarTokens.height + bottomInset;
  }

  @override
  Widget build(BuildContext context) {
    final Color focusedColor = Theme.of(context).colorScheme.primary;
    final double bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppNavigationBarTokens.blurSigma,
          sigmaY: AppNavigationBarTokens.blurSigma,
        ),
        child: Container(
          width: AppNavigationBarTokens.width,
          height: AppNavigationBarTokens.height + bottomInset,
          color: AppNavigationBarTokens.backgroundColor,
          padding: AppNavigationBarTokens.padding.add(
            EdgeInsets.only(bottom: bottomInset),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List<Widget>.generate(items.length, (int index) {
              final bool focused = index == currentIndex;
              final Color color = focused
                  ? focusedColor
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
                        style: AppNavigationBarTokens.labelStyle.copyWith(
                          color: color,
                        ),
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
