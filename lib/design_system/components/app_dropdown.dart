import "package:flutter/material.dart";

import "../tokens/app_dropdown_tokens.dart";

class AppDropdownItem extends StatelessWidget {
  const AppDropdownItem({
    super.key,
    required this.label,
    this.state = AppDropdownItemState.defaultState,
    this.onTap,
  });

  final String label;
  final AppDropdownItemState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final AppDropdownItemStyle style = AppDropdownTokens.itemStyle(state);
    return InkWell(
      onTap: onTap,
      child: Container(
        height: AppDropdownTokens.itemHeight,
        padding: AppDropdownTokens.itemPadding,
        color: style.backgroundColor,
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                style: AppDropdownTokens.itemTextStyle.copyWith(
                  color: style.textColor,
                ),
              ),
            ),
            SizedBox(
              width: AppDropdownTokens.itemIconSize,
              height: AppDropdownTokens.itemIconSize,
              child: style.showCheck
                  ? Icon(
                      Icons.check,
                      size: AppDropdownTokens.itemIconSize,
                      color: style.textColor,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class AppDropdownMenu extends StatelessWidget {
  const AppDropdownMenu({
    super.key,
    required this.items,
    this.size = AppDropdownMenuSize.lg,
  });

  final List<AppDropdownItem> items;
  final AppDropdownMenuSize size;

  @override
  Widget build(BuildContext context) {
    final AppDropdownMenuStyle style = AppDropdownTokens.menuStyle(size);
    return Container(
      width: style.width,
      height: style.height,
      padding: AppDropdownTokens.menuPadding,
      decoration: BoxDecoration(
        color: AppDropdownTokens.background,
        borderRadius: BorderRadius.circular(AppDropdownTokens.radius),
        boxShadow: style.shadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items,
      ),
    );
  }
}
