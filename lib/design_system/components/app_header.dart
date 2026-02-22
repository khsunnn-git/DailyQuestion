import "package:flutter/material.dart";

import "../tokens/app_navigation_tokens.dart";

class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    required this.title,
    this.leading = Icons.arrow_back,
    this.trailing = Icons.edit_outlined,
    this.onLeadingPressed,
    this.onTrailingPressed,
  });

  final String title;
  final IconData leading;
  final IconData trailing;
  final VoidCallback? onLeadingPressed;
  final VoidCallback? onTrailingPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppHeaderTokens.width,
      height: AppHeaderTokens.height,
      child: Padding(
        padding: AppHeaderTokens.padding,
        child: Row(
          children: <Widget>[
            IconButton(
              onPressed: onLeadingPressed,
              icon: Icon(leading, size: AppHeaderTokens.iconSize),
            ),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: AppHeaderTokens.titleStyle.copyWith(
                  color: AppHeaderTokens.titleColor,
                ),
              ),
            ),
            IconButton(
              onPressed: onTrailingPressed,
              icon: Icon(trailing, size: AppHeaderTokens.iconSize),
            ),
          ],
        ),
      ),
    );
  }
}
