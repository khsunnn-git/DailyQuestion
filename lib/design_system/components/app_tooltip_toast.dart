import "package:flutter/material.dart";

import "../tokens/app_tooltip_toast_tokens.dart";

class AppToastMessage extends StatelessWidget {
  const AppToastMessage({
    super.key,
    required this.text,
    this.maxWidth = AppToastTokens.maxWidth,
  });

  final String text;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding: AppToastTokens.padding,
        decoration: BoxDecoration(
          color: AppToastTokens.background,
          borderRadius: AppToastTokens.radius,
          boxShadow: AppToastTokens.shadow,
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: AppToastTokens.textStyle.copyWith(color: AppToastTokens.textColor),
        ),
      ),
    );
  }
}

class AppTooltipBubble extends StatelessWidget {
  const AppTooltipBubble({
    super.key,
    required this.text,
    this.direction = AppBubbleDirection.upCenter,
  });

  final String text;
  final AppBubbleDirection direction;

  bool get _isUp => direction == AppBubbleDirection.upLeft ||
      direction == AppBubbleDirection.upCenter ||
      direction == AppBubbleDirection.upRight;

  Alignment get _pointerAlignment {
    switch (direction) {
      case AppBubbleDirection.upLeft:
      case AppBubbleDirection.downLeft:
        return Alignment.centerLeft;
      case AppBubbleDirection.upRight:
      case AppBubbleDirection.downRight:
        return Alignment.centerRight;
      default:
        return Alignment.center;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget pointer = Align(
      alignment: _pointerAlignment,
      child: Padding(
        padding: AppTooltipTokens.pointerHorizontalPadding,
        child: CustomPaint(
          size: const Size(AppTooltipTokens.pointerWidth, AppTooltipTokens.pointerHeight),
          painter: _TrianglePainter(
            color: AppTooltipTokens.background,
            up: _isUp,
          ),
        ),
      ),
    );

    final Widget body = Container(
      padding: AppTooltipTokens.contentPadding,
      decoration: const BoxDecoration(
        color: AppTooltipTokens.background,
        borderRadius: AppTooltipTokens.radius,
      ),
      child: Text(
        text,
        style: AppTooltipTokens.textStyle.copyWith(color: AppTooltipTokens.textColor),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _isUp ? <Widget>[pointer, body] : <Widget>[body, pointer],
    );
  }
}

class AppSpeechBubble extends StatelessWidget {
  const AppSpeechBubble({
    super.key,
    required this.text,
    this.variant = AppSpeechBubbleVariant.primary,
    this.direction = AppBubbleDirection.left,
  });

  final String text;
  final AppSpeechBubbleVariant variant;
  final AppBubbleDirection direction;

  bool get _primary => variant == AppSpeechBubbleVariant.primary;

  @override
  Widget build(BuildContext context) {
    final Color background =
        _primary ? AppSpeechBubbleTokens.primaryBackground : AppSpeechBubbleTokens.whiteBackground;
    final Color textColor =
        _primary ? AppSpeechBubbleTokens.primaryText : AppSpeechBubbleTokens.whiteText;

    final bool left = direction == AppBubbleDirection.left;
    final bool right = direction == AppBubbleDirection.right;
    final bool up = direction == AppBubbleDirection.up;
    final bool down = direction == AppBubbleDirection.down;

    final Widget bubble = Container(
      padding: AppSpeechBubbleTokens.padding,
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppSpeechBubbleTokens.radius,
        boxShadow: _primary ? null : AppSpeechBubbleTokens.whiteShadow,
      ),
      child: Text(
        text,
        style: AppSpeechBubbleTokens.textStyle.copyWith(color: textColor),
      ),
    );

    final Widget pointer = CustomPaint(
      size: const Size(10, 6),
      painter: _TrianglePainter(
        color: background,
        up: down,
        rotateQuarterTurns: left
            ? 3
            : right
                ? 1
                : 0,
      ),
    );

    if (up || down) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: up ? <Widget>[pointer, bubble] : <Widget>[bubble, pointer],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: left ? <Widget>[pointer, bubble] : <Widget>[bubble, pointer],
    );
  }
}

class _TrianglePainter extends CustomPainter {
  const _TrianglePainter({
    required this.color,
    required this.up,
    this.rotateQuarterTurns = 0,
  });

  final Color color;
  final bool up;
  final int rotateQuarterTurns;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    for (int i = 0; i < rotateQuarterTurns; i++) {
      canvas.translate(size.width / 2, size.height / 2);
      canvas.rotate(1.5708);
      canvas.translate(-size.width / 2, -size.height / 2);
    }

    final Paint paint = Paint()..color = color;
    final Path path = Path();
    if (up) {
      path.moveTo(size.width / 2, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width / 2, size.height);
    }
    path.close();
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter oldDelegate) {
    return color != oldDelegate.color ||
        up != oldDelegate.up ||
        rotateQuarterTurns != oldDelegate.rotateQuarterTurns;
  }
}
