import "package:flutter/material.dart";

import "../theme/app_theme.dart";
import "../tokens/app_colors.dart";
import "../tokens/app_badge_tag_tokens.dart";

class AppAiBadge extends StatelessWidget {
  const AppAiBadge({super.key, this.label = "AI"});

  final String label;

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    return Container(
      height: AppBadgeTokens.aiHeight,
      padding: AppBadgeTokens.aiPadding,
      decoration: BoxDecoration(
        color: brand.c100,
        borderRadius: AppBadgeTokens.aiRadius,
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: AppBadgeTokens.aiTextStyle.copyWith(color: brand.c500),
      ),
    );
  }
}

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
          style: AppBadgeTokens.bucketTextStyle.copyWith(
            color: AppBadgeTokens.bucketTextColor,
          ),
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
              style: AppBucketTagTokens.textStyle.copyWith(
                color: style.textColor,
              ),
            ),
          Text(
            text,
            style: AppBucketTagTokens.textStyle.copyWith(
              color: style.textColor,
            ),
          ),
          if (style.showDelete) ...<Widget>[
            const SizedBox(width: AppBucketTagTokens.innerGap),
            GestureDetector(
              onTap: onDeleteTap,
              child: Icon(
                Icons.close,
                size: AppBucketTagTokens.iconSize,
                color: style.textColor,
              ),
            ),
          ],
          if (style.showAdd) ...<Widget>[
            const SizedBox(width: AppBucketTagTokens.innerGap),
            GestureDetector(
              onTap: onAddTap,
              child: Icon(
                Icons.add,
                size: AppBucketTagTokens.iconSize,
                color: style.textColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
