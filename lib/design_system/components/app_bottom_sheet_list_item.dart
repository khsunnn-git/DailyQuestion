import "package:flutter/material.dart";

import "../tokens/app_dropdown_tokens.dart";
import "../tokens/app_spacing.dart";
import "../tokens/app_typography.dart";
import "../theme/app_theme.dart";

class AppBottomSheetListItem extends StatefulWidget {
  const AppBottomSheetListItem({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  State<AppBottomSheetListItem> createState() => _AppBottomSheetListItemState();
}

class _AppBottomSheetListItemState extends State<AppBottomSheetListItem> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  AppDropdownItemState get _effectiveState {
    if (widget.selected) {
      return AppDropdownItemState.selected;
    }
    if (_isHovered || _isPressed || _isFocused) {
      return AppDropdownItemState.hovered;
    }
    return AppDropdownItemState.defaultState;
  }

  @override
  Widget build(BuildContext context) {
    final brand = context.appBrandScale;
    final AppDropdownItemStyle style = AppDropdownTokens.itemStyle(
      _effectiveState,
    );

    return FocusableActionDetector(
      onFocusChange: (bool focused) {
        setState(() {
          _isFocused = focused;
        });
      },
      child: MouseRegion(
        onEnter: (_) {
          setState(() {
            _isHovered = true;
          });
        },
        onExit: (_) {
          setState(() {
            _isHovered = false;
          });
        },
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: (_) {
            setState(() {
              _isPressed = true;
            });
          },
          onTapCancel: () {
            setState(() {
              _isPressed = false;
            });
          },
          onTapUp: (_) {
            setState(() {
              _isPressed = false;
            });
          },
          hoverColor: AppDropdownTokens.hoveredBackground,
          splashColor: Colors.transparent,
          highlightColor: AppDropdownTokens.hoveredBackground,
          borderRadius: BorderRadius.circular(AppDropdownTokens.radius),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s8,
              vertical: AppSpacing.s12,
            ),
            decoration: BoxDecoration(
              color: style.backgroundColor,
              borderRadius: BorderRadius.circular(AppDropdownTokens.radius),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    widget.label,
                    style: AppTypography.bodyLargeMedium.copyWith(
                      color: widget.selected
                          ? brand.c500
                          : AppDropdownTokens.defaultText,
                    ),
                  ),
                ),
                SizedBox(
                  width: AppSpacing.s24,
                  height: AppSpacing.s24,
                  child: widget.selected
                      ? Icon(
                          Icons.check,
                          size: AppSpacing.s24,
                          color: brand.c500,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
