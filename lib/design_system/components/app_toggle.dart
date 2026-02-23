import "package:flutter/material.dart";

import "../theme/app_theme.dart";
import "../tokens/app_colors.dart";
import "../tokens/app_controls_tokens.dart";

class AppIconToggle extends StatelessWidget {
  const AppIconToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    final Color trackColor = !enabled
        ? AppNeutralColors.grey100
        : value
        ? brand.c500
        : AppNeutralColors.grey200;
    final Color thumbColor = enabled
        ? AppNeutralColors.white
        : AppNeutralColors.grey50;

    return SizedBox(
      width: AppToggleTokens.iconOnlySize,
      height: AppToggleTokens.iconOnlySize,
      child: Center(
        child: GestureDetector(
          onTap: enabled ? () => onChanged(!value) : null,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            width: 54,
            height: 32,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: trackColor,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Align(
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: thumbColor,
                  shape: BoxShape.circle,
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x1A000000),
                      offset: Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
