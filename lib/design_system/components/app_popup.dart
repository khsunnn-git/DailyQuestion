import "package:flutter/material.dart";

import "../tokens/app_popup_tokens.dart";

class AppPopup extends StatelessWidget {
  const AppPopup({
    super.key,
    required this.title,
    required this.body,
    required this.actions,
    this.width = AppPopupTokens.mobileWidth,
  });

  final String title;
  final String body;
  final List<Widget> actions;
  final double width;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: AppPopupTokens.maxWidth,
        minHeight: AppPopupTokens.minHeight,
      ),
      child: Container(
        width: width,
        padding: AppPopupTokens.contentPadding,
        decoration: BoxDecoration(
          color: AppPopupTokens.background,
          borderRadius: AppPopupTokens.radius,
          boxShadow: AppPopupTokens.shadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppPopupTokens.titleStyle.copyWith(
                color: AppPopupTokens.titleColor,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: AppPopupTokens.contentGap),
            Text(
              body,
              textAlign: TextAlign.center,
              style: AppPopupTokens.bodyStyle.copyWith(
                color: AppPopupTokens.bodyColor,
                decoration: TextDecoration.none,
              ),
            ),
            if (actions.isNotEmpty) ...<Widget>[
              const SizedBox(height: AppPopupTokens.contentGap),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: actions
                    .expand(
                      (Widget e) =>
                          <Widget>[e, const SizedBox(width: AppPopupTokens.actionGap)],
                    )
                    .toList()
                  ..removeLast(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AppDimmedOverlay extends StatelessWidget {
  const AppDimmedOverlay({
    super.key,
    required this.child,
    this.alignment = Alignment.center,
  });

  final Widget child;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppPopupTokens.dimmed,
      child: Align(
        alignment: alignment,
        child: child,
      ),
    );
  }
}

class AppStreakPillCard extends StatelessWidget {
  const AppStreakPillCard({
    super.key,
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppStreakPillTokens.padding,
      decoration: BoxDecoration(
        color: AppStreakPillTokens.background,
        borderRadius: AppStreakPillTokens.radius,
        boxShadow: AppStreakPillTokens.shadow,
      ),
      child: Text(
        text,
        style: AppStreakPillTokens.textStyle.copyWith(color: AppStreakPillTokens.textColor),
      ),
    );
  }
}
