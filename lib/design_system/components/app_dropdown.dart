import "package:flutter/material.dart";

import "../tokens/app_dropdown_tokens.dart";

class AppDropdownItem extends StatefulWidget {
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
  State<AppDropdownItem> createState() => _AppDropdownItemState();
}

class _AppDropdownItemState extends State<AppDropdownItem> {
  bool _isHovered = false;

  AppDropdownItemState get _effectiveState {
    if (widget.state == AppDropdownItemState.selected) {
      return AppDropdownItemState.selected;
    }
    if (_isHovered || widget.state == AppDropdownItemState.hovered) {
      return AppDropdownItemState.hovered;
    }
    return AppDropdownItemState.defaultState;
  }

  @override
  Widget build(BuildContext context) {
    final AppDropdownItemStyle style = AppDropdownTokens.itemStyle(
      _effectiveState,
    );
    return MouseRegion(
      onEnter: (_) => setState(() {
        _isHovered = true;
      }),
      onExit: (_) => setState(() {
        _isHovered = false;
      }),
      child: InkWell(
        onTap: widget.onTap,
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Container(
          height: AppDropdownTokens.itemHeight,
          padding: AppDropdownTokens.itemPadding,
          color: style.backgroundColor,
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  widget.label,
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
      padding: AppDropdownTokens.menuPadding,
      decoration: BoxDecoration(
        color: AppDropdownTokens.background,
        borderRadius: BorderRadius.circular(AppDropdownTokens.radius),
        boxShadow: style.shadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items,
      ),
    );
  }
}
