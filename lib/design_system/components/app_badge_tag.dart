import "package:flutter/material.dart";

import "../tokens/app_badge_tag_tokens.dart";

class AppBucketBadge extends StatelessWidget {
  const AppBucketBadge({
    super.key,
    required this.text,
    required this.backgroundColor,
  });

  final String text;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppBadgeTokens.bucketHeight,
      padding: AppBadgeTokens.bucketPadding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppBadgeTokens.bucketRadius,
      ),
      child: Center(
        child: Text(
          text,
          style: AppBadgeTokens.bucketTextStyle.copyWith(color: AppBadgeTokens.bucketTextColor),
        ),
      ),
    );
  }
}

class AppBucketTag extends StatelessWidget {
  const AppBucketTag({
    super.key,
    required this.text,
    required this.state,
    this.onDeleteTap,
    this.onAddTap,
  });

  final String text;
  final AppBucketTagState state;
  final VoidCallback? onDeleteTap;
  final VoidCallback? onAddTap;

  @override
  Widget build(BuildContext context) {
    final AppBucketTagStyle style = AppBucketTagTokens.style(state);
    return Container(
      height: AppBucketTagTokens.height,
      padding: AppBucketTagTokens.defaultPadding,
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: AppBucketTagTokens.radius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (style.showHash)
            Text(
              "# ",
              style: AppBucketTagTokens.textStyle.copyWith(color: style.textColor),
            ),
          Text(
            text,
            style: AppBucketTagTokens.textStyle.copyWith(color: style.textColor),
          ),
          if (style.showDelete) ...<Widget>[
            const SizedBox(width: AppBucketTagTokens.innerGap),
            GestureDetector(
              onTap: onDeleteTap,
              child: Icon(Icons.close, size: AppBucketTagTokens.iconSize, color: style.textColor),
            ),
          ],
          if (style.showAdd) ...<Widget>[
            const SizedBox(width: AppBucketTagTokens.innerGap),
            GestureDetector(
              onTap: onAddTap,
              child: Icon(Icons.add, size: AppBucketTagTokens.iconSize, color: style.textColor),
            ),
          ],
        ],
      ),
    );
  }
}
