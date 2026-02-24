import "package:flutter/material.dart";

import "../tokens/app_loading_tokens.dart";

typedef AppLottieBuilder = Widget Function(
  String lottieUrl,
  double size,
);

class AppLoadingIndicator extends StatefulWidget {
  const AppLoadingIndicator({
    super.key,
    this.size = AppLoadingTokens.size,
    this.lottieBuilder,
    this.fit = BoxFit.contain,
    this.semanticLabel = "Loading",
  });

  final double size;
  final AppLottieBuilder? lottieBuilder;
  final BoxFit fit;
  final String semanticLabel;

  @override
  State<AppLoadingIndicator> createState() => _AppLoadingIndicatorState();
}

class _AppLoadingIndicatorState extends State<AppLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget child = widget.lottieBuilder != null
        ? widget.lottieBuilder!(AppLoadingTokens.lottieSourceUrl, widget.size)
        : Image.network(
            AppLoadingTokens.fallbackImageUrl,
            width: widget.size,
            height: widget.size,
            fit: widget.fit,
            errorBuilder: (_, _, _) => SizedBox(
              width: widget.size,
              height: widget.size,
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );

    return Semantics(
      label: widget.semanticLabel,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: RotationTransition(turns: _controller, child: child),
      ),
    );
  }
}
