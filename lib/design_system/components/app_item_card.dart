import "package:flutter/material.dart";

import "../tokens/app_item_tokens.dart";

class AppItemCard extends StatelessWidget {
  const AppItemCard({
    super.key,
    required this.image,
    required this.itemName,
    required this.price,
    this.state = AppItemCardState.defaultState,
    this.coinIcon,
    this.onTap,
  });

  final ImageProvider image;
  final String itemName;
  final String price;
  final AppItemCardState state;
  final Widget? coinIcon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppItemCardTokens.radius,
      onTap: onTap,
      child: Container(
        width: AppItemCardTokens.width,
        height: AppItemCardTokens.height,
        padding: AppItemCardTokens.padding,
        decoration: BoxDecoration(
          color: AppItemCardTokens.backgroundColor,
          borderRadius: AppItemCardTokens.radius,
          border: AppItemCardTokens.border(state),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              width: AppItemCardTokens.itemImageSize,
              height: AppItemCardTokens.itemImageSize,
              child: Image(image: image),
            ),
            const SizedBox(height: AppItemCardTokens.gap),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox(
                  width: AppItemCardTokens.coinIconSize,
                  height: AppItemCardTokens.coinIconSize,
                  child:
                      coinIcon ??
                      const FittedBox(fit: BoxFit.contain, child: Text("🪙")),
                ),
                Text(
                  price,
                  style: AppItemCardTokens.priceStyle.copyWith(
                    color: AppItemCardTokens.textColor,
                  ),
                ),
              ],
            ),
            Text(
              itemName,
              textAlign: TextAlign.center,
              style: AppItemCardTokens.nameStyle.copyWith(
                color: AppItemCardTokens.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
