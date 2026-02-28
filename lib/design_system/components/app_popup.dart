import "package:flutter/material.dart";

import "../tokens/app_popup_tokens.dart";

class AppPopup extends StatelessWidget {
  const AppPopup({
    super.key,
    required this.title,
    required this.body,
    required this.actions,
    this.width = AppPopupTokens.mobileWidth,
    this.contentPadding = AppPopupTokens.contentPadding,
    this.actionTopGap = AppPopupTokens.contentGap,
  });

  final String title;
  final String body;
  final List<Widget> actions;
  final double width;
  final EdgeInsets contentPadding;
  final double actionTopGap;

  @override
  Widget build(BuildContext context) {
    final bool hasBody = body.trim().isNotEmpty;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: AppPopupTokens.maxWidth),
      child: Container(
        width: width,
        padding: contentPadding,
        decoration: BoxDecoration(
          color: AppPopupTokens.background,
          borderRadius: AppPopupTokens.radius,
          boxShadow: AppPopupTokens.shadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppPopupTokens.textHorizontalInset,
              ),
              child: Text(
                title,
                textAlign: TextAlign.left,
                style: AppPopupTokens.titleStyle.copyWith(
                  color: AppPopupTokens.titleColor,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
            if (hasBody) ...<Widget>[
              const SizedBox(height: AppPopupTokens.textGap),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppPopupTokens.textHorizontalInset,
                ),
                child: Text(
                  body,
                  textAlign: TextAlign.left,
                  style: AppPopupTokens.bodyStyle.copyWith(
                    color: AppPopupTokens.bodyColor,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ],
            if (actions.isNotEmpty) ...<Widget>[
              SizedBox(height: actionTopGap),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children:
                    actions
                        .expand(
                          (Widget e) => <Widget>[
                            e,
                            const SizedBox(width: AppPopupTokens.actionGap),
                          ],
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
      child: Align(alignment: alignment, child: child),
    );
  }
}

class AppStreakPillCard extends StatelessWidget {
  const AppStreakPillCard({super.key, required this.text});

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
        style: AppStreakPillTokens.textStyle.copyWith(
          color: AppStreakPillTokens.textColor,
        ),
      ),
    );
  }
}
