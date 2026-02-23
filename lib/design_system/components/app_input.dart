import "package:flutter/material.dart";

import "../theme/app_theme.dart";
import "../tokens/app_colors.dart";
import "../tokens/app_input_tokens.dart";
import "../tokens/app_spacing.dart";

class AppTextInput extends StatelessWidget {
  const AppTextInput({
    super.key,
    this.label = "레이블",
    this.placeholder = "플레이스홀더",
    this.value,
    this.size = AppInputSize.md,
    this.state = AppInputFieldState.defaultState,
    this.supportingMessage = "메세지 내용",
    this.counter = "(1/10)",
    this.showCounter = true,
    this.onClearTap,
  });

  final String label;
  final String placeholder;
  final String? value;
  final AppInputSize size;
  final AppInputFieldState state;
  final String supportingMessage;
  final String counter;
  final bool showCounter;
  final VoidCallback? onClearTap;

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    final bool hasValue =
        (value?.isNotEmpty ?? false) ||
        state != AppInputFieldState.defaultState;
    final double fieldHeight = size == AppInputSize.md
        ? AppInputTokens.fieldHeightMd
        : AppInputTokens.fieldHeightSm;
    final TextStyle labelStyle = size == AppInputSize.md
        ? AppInputTokens.mdLabelStyle
        : AppInputTokens.smLabelStyle;
    final TextStyle textStyle = size == AppInputSize.md
        ? AppInputTokens.mdTextStyle
        : AppInputTokens.smTextStyle;
    final TextStyle supportingStyle = size == AppInputSize.md
        ? AppInputTokens.supportingMdStyle
        : AppInputTokens.supportingSmStyle;

    return SizedBox(
      width: AppInputTokens.fieldWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: labelStyle.copyWith(color: Colors.black)),
          const SizedBox(height: AppInputTokens.fieldGap),
          Container(
            height: fieldHeight,
            padding: AppInputTokens.fieldPadding,
            decoration: BoxDecoration(
              color: AppInputTokens.backgroundColor(state),
              borderRadius: AppInputTokens.radius,
              border: Border.all(
                color: AppInputTokens.borderColor(state, brand: brand),
              ),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    _displayText(state, value, placeholder),
                    style: textStyle.copyWith(
                      color: AppInputTokens.textColor(
                        state,
                        hasValue: hasValue,
                      ),
                    ),
                  ),
                ),
                if (_showTrailingIcon(state))
                  GestureDetector(
                    onTap: onClearTap,
                    child: Icon(
                      _trailingIcon(state),
                      size: AppInputTokens.actionIconSize,
                      color: AppInputTokens.supportingColor(
                        state,
                        brand: brand,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          _InputSupporting(
            message: supportingMessage,
            counter: counter,
            showCounter: showCounter,
            color: AppInputTokens.supportingColor(state, brand: brand),
            style: supportingStyle,
            icon: _supportIcon(state),
            iconSize: AppInputTokens.iconSize,
          ),
        ],
      ),
    );
  }
}

class AppSelectField extends StatelessWidget {
  const AppSelectField({
    super.key,
    this.text = "리스트명",
    this.state = AppInputFieldState.defaultState,
    this.onTap,
  });

  final String text;
  final AppInputFieldState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    return InkWell(
      onTap: onTap,
      borderRadius: AppInputTokens.radius,
      child: Container(
        width: AppInputTokens.fieldWidth,
        height: AppInputTokens.selectHeight,
        padding: AppInputTokens.fieldPadding,
        decoration: BoxDecoration(
          color: AppInputTokens.backgroundColor(state),
          borderRadius: AppInputTokens.radius,
          border: Border.all(
            color: AppInputTokens.borderColor(state, brand: brand),
          ),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                text,
                style: AppInputTokens.mdTextStyle.copyWith(
                  color: state == AppInputFieldState.disabled
                      ? AppNeutralColors.grey300
                      : AppNeutralColors.grey900,
                ),
              ),
            ),
            Icon(
              state == AppInputFieldState.defaultState
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              size: AppInputTokens.actionIconSize,
              color: state == AppInputFieldState.disabled
                  ? AppNeutralColors.grey300
                  : AppNeutralColors.grey700,
            ),
          ],
        ),
      ),
    );
  }
}

class AppTextArea extends StatelessWidget {
  const AppTextArea({
    super.key,
    this.placeholder = "플레이스홀더",
    this.value,
    this.state = AppInputFieldState.defaultState,
    this.usage = AppTextAreaUsage.bottomSheet,
    this.supportingMessage = "메세지 내용",
    this.counter = "(1/10)",
  });

  final String placeholder;
  final String? value;
  final AppInputFieldState state;
  final AppTextAreaUsage usage;
  final String supportingMessage;
  final String counter;

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    final bool isLong = usage == AppTextAreaUsage.textArea;
    final bool hasValue = value?.isNotEmpty ?? false;
    final Color borderColor = state == AppInputFieldState.error
        ? AppSemanticColors.error500
        : state == AppInputFieldState.focus
        ? brand.c300
        : state == AppInputFieldState.success
        ? brand.c500
        : Colors.transparent;

    return SizedBox(
      width: AppInputTokens.textAreaWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            height: isLong
                ? AppInputTokens.textAreaBoxHeight
                : AppInputTokens.textAreaBottomSheetHeight,
            padding: AppInputTokens.textAreaPadding,
            decoration: BoxDecoration(
              color: _textAreaBackground(state, usage),
              borderRadius: AppInputTokens.radius,
              border: Border.all(color: borderColor),
            ),
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                height: AppInputTokens.textAreaInputPreviewHeight,
                child: Text(
                  _displayText(state, value, placeholder, focusedText: "입력중ㅣ"),
                  style: AppInputTokens.mdTextStyle.copyWith(
                    color: AppInputTokens.textColor(state, hasValue: hasValue),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppInputTokens.textAreaGap),
          _InputSupporting(
            message: supportingMessage,
            counter: counter,
            color: AppInputTokens.supportingColor(state, brand: brand),
            style: AppInputTokens.supportingMdStyle,
            icon: _supportIcon(state),
            iconSize: AppInputTokens.iconSize,
          ),
        ],
      ),
    );
  }
}

class AppEditableTextArea extends StatefulWidget {
  const AppEditableTextArea({
    super.key,
    required this.controller,
    required this.focusNode,
    this.hintText = "무엇이든 가볍게 적어보세요",
    this.height = 370,
    this.enabled = true,
    this.backgroundColor,
    this.borderColor,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final double height;
  final bool enabled;
  final Color? backgroundColor;
  final Color? borderColor;

  @override
  State<AppEditableTextArea> createState() => _AppEditableTextAreaState();
}

class _AppEditableTextAreaState extends State<AppEditableTextArea> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(covariant AppEditableTextArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_handleFocusChanged);
      widget.focusNode.addListener(_handleFocusChanged);
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleFocusChanged);
    super.dispose();
  }

  void _handleFocusChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.enabled ? () => widget.focusNode.requestFocus() : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        height: widget.height,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s12,
        ),
        decoration: BoxDecoration(
          color: widget.enabled
              ? (widget.backgroundColor ?? AppNeutralColors.white)
              : AppNeutralColors.grey50,
          borderRadius: AppInputTokens.radius,
          border: Border.all(
            color: widget.borderColor ?? Colors.transparent,
            width: 1,
          ),
        ),
        child: TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          enabled: widget.enabled,
          cursorColor: AppNeutralColors.grey900,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          minLines: null,
          maxLines: null,
          expands: true,
          textAlignVertical: TextAlignVertical.top,
          style: AppInputTokens.mdTextStyle.copyWith(
            color: widget.enabled
                ? AppNeutralColors.grey900
                : AppNeutralColors.grey300,
          ),
          decoration: InputDecoration(
            isCollapsed: true,
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            hintText: widget.hintText,
            hintStyle: AppInputTokens.mdTextStyle.copyWith(
              color: widget.enabled
                  ? AppNeutralColors.grey400
                  : AppNeutralColors.grey300,
            ),
          ),
        ),
      ),
    );
  }
}

class AppTextButtonField extends StatelessWidget {
  const AppTextButtonField({
    super.key,
    this.placeholder = "플레이스홀더",
    this.value,
    this.state = AppInputFieldState.defaultState,
    this.supportingMessage = "메세지 내용",
    this.buttonLabel = "버튼",
    this.onButtonTap,
    this.onClearTap,
  });

  final String placeholder;
  final String? value;
  final AppInputFieldState state;
  final String supportingMessage;
  final String buttonLabel;
  final VoidCallback? onButtonTap;
  final VoidCallback? onClearTap;

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    final bool hasValue = value?.isNotEmpty ?? false;

    return SizedBox(
      width: AppInputTokens.textButtonWidth,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  height: AppInputTokens.textButtonHeight,
                  padding: AppInputTokens.fieldPadding,
                  decoration: BoxDecoration(
                    color: AppInputTokens.backgroundColor(state),
                    borderRadius: AppInputTokens.radius,
                    border: Border.all(
                      color: AppInputTokens.borderColor(
                        state,
                        brand: brand,
                        successUseLight: true,
                      ),
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          _displayText(
                            state,
                            value,
                            placeholder,
                            focusedText: "입력중ㅣ",
                          ),
                          style: AppInputTokens.mdTextStyle.copyWith(
                            color: AppInputTokens.textColor(
                              state,
                              hasValue: hasValue,
                            ),
                          ),
                        ),
                      ),
                      if (state == AppInputFieldState.focus ||
                          state == AppInputFieldState.error)
                        GestureDetector(
                          onTap: onClearTap,
                          child: Icon(
                            Icons.close,
                            size: AppInputTokens.actionIconSize,
                            color: AppInputTokens.supportingColor(
                              state,
                              brand: brand,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.s4),
                _InputSupporting(
                  message: supportingMessage,
                  counter: "",
                  showCounter: false,
                  color: AppInputTokens.supportingColor(state, brand: brand),
                  style: AppInputTokens.supportingSmStyle,
                  icon: _supportIcon(state),
                  iconSize: AppInputTokens.iconSize,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppInputTokens.fieldGap),
          SizedBox(
            width: AppInputTokens.textButtonActionWidth,
            height: AppInputTokens.textButtonHeight,
            child: FilledButton(
              onPressed: state == AppInputFieldState.disabled
                  ? null
                  : onButtonTap,
              style: FilledButton.styleFrom(
                elevation: 0,
                padding: EdgeInsets.zero,
                shape: const RoundedRectangleBorder(
                  borderRadius: AppInputTokens.radius,
                ),
                backgroundColor: AppInputTokens.actionBackground(
                  state,
                  brand: brand,
                ),
                disabledBackgroundColor: AppInputTokens.actionBackground(
                  state,
                  brand: brand,
                ),
                foregroundColor: AppInputTokens.actionForeground(
                  state,
                  brand: brand,
                ),
                disabledForegroundColor: AppInputTokens.actionForeground(
                  state,
                  brand: brand,
                ),
              ),
              child: Text(
                buttonLabel,
                style: AppInputTokens.actionButtonStyle.copyWith(
                  color: AppInputTokens.actionForeground(state, brand: brand),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputSupporting extends StatelessWidget {
  const _InputSupporting({
    required this.message,
    required this.counter,
    required this.color,
    required this.style,
    required this.icon,
    required this.iconSize,
    this.showCounter = true,
  });

  final String message;
  final String counter;
  final Color color;
  final TextStyle style;
  final IconData icon;
  final double iconSize;
  final bool showCounter;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppInputTokens.supportingPadding,
      child: Row(
        children: <Widget>[
          Icon(icon, size: iconSize, color: color),
          const SizedBox(width: AppInputTokens.supportingGap),
          Expanded(
            child: Text(message, style: style.copyWith(color: color)),
          ),
          if (showCounter && counter.isNotEmpty)
            Text(counter, style: style.copyWith(color: color)),
        ],
      ),
    );
  }
}

Color _textAreaBackground(AppInputFieldState state, AppTextAreaUsage usage) {
  if (state == AppInputFieldState.disabled) {
    return AppNeutralColors.grey50;
  }
  if (usage == AppTextAreaUsage.bottomSheet) {
    return AppNeutralColors.grey50;
  }
  return AppNeutralColors.white;
}

String _displayText(
  AppInputFieldState state,
  String? value,
  String placeholder, {
  String focusedText = "|",
}) {
  if (state == AppInputFieldState.focus) {
    return focusedText;
  }
  if (value != null && value.isNotEmpty) {
    return value;
  }
  if (state == AppInputFieldState.success ||
      state == AppInputFieldState.error) {
    return "입력한 텍스트";
  }
  return placeholder;
}

bool _showTrailingIcon(AppInputFieldState state) {
  return state == AppInputFieldState.focus ||
      state == AppInputFieldState.success ||
      state == AppInputFieldState.error;
}

IconData _trailingIcon(AppInputFieldState state) {
  switch (state) {
    case AppInputFieldState.success:
      return Icons.check;
    case AppInputFieldState.error:
      return Icons.error_outline;
    case AppInputFieldState.focus:
    case AppInputFieldState.defaultState:
    case AppInputFieldState.disabled:
      return Icons.close;
  }
}

IconData _supportIcon(AppInputFieldState state) {
  if (state == AppInputFieldState.success) {
    return Icons.check;
  }
  return Icons.info_outline;
}
