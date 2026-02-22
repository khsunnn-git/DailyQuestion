import "package:flutter/material.dart";

import "../tokens/app_loading_tokens.dart";

typedef AppLottieBuilder = Widget Function(
  String lottieUrl,
  double size,
);

class AppLoadingIndicator extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final Widget child = lottieBuilder != null
        ? lottieBuilder!(AppLoadingTokens.lottieSourceUrl, size)
        : Image.network(
            AppLoadingTokens.fallbackImageUrl,
            width: size,
            height: size,
            fit: fit,
            errorBuilder: (_, __, ___) => SizedBox(
              width: size,
              height: size,
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );

    return Semantics(
      label: semanticLabel,
      child: SizedBox(
        width: size,
        height: size,
        child: child,
      ),
    );
  }
}
