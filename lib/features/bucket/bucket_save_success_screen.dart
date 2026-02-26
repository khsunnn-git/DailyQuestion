import "dart:async";

import "package:flutter/material.dart";

import "../../design_system/design_system.dart";

class BucketSaveSuccessScreen extends StatefulWidget {
  const BucketSaveSuccessScreen({
    super.key,
    this.title = "버킷리스트 저장!",
    this.subtitle,
    this.imageAsset = successAsset,
    this.autoCloseDuration = const Duration(seconds: 2),
  });

  static const String successAsset =
      "assets/images/bucket/bucketlist_save_success.png";
  static const String completionAsset =
      "assets/images/bucket/bucketlist_complete_success.png";

  final String title;
  final String? subtitle;
  final String imageAsset;
  final Duration autoCloseDuration;

  @override
  State<BucketSaveSuccessScreen> createState() =>
      _BucketSaveSuccessScreenState();
}

class _BucketSaveSuccessScreenState extends State<BucketSaveSuccessScreen> {
  Timer? _autoCloseTimer;

  @override
  void initState() {
    super.initState();
    _autoCloseTimer = Timer(widget.autoCloseDuration, _close);
  }

  @override
  void dispose() {
    _autoCloseTimer?.cancel();
    super.dispose();
  }

  void _close() {
    if (!mounted) {
      return;
    }
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    return Scaffold(
      backgroundColor: brand.bg,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s20,
          49,
          AppSpacing.s20,
          AppSpacing.s24,
        ),
        child: Column(
          children: <Widget>[
            const SizedBox(height: AppSpacing.s24),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: AppTypography.headingLarge.copyWith(
                        color: AppNeutralColors.grey900,
                      ),
                    ),
                    if (widget.subtitle != null) ...<Widget>[
                      const SizedBox(height: AppSpacing.s8),
                      Text(
                        widget.subtitle!,
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyLargeMedium.copyWith(
                          color: AppNeutralColors.grey600,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.s24),
                    Image.asset(
                      widget.imageAsset,
                      width: widget.subtitle == null ? 160 : 200,
                      height: widget.subtitle == null ? 160 : 200,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: _close,
                style: FilledButton.styleFrom(
                  backgroundColor: brand.c500,
                  foregroundColor: AppNeutralColors.white,
                  textStyle: AppTypography.buttonLarge,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.s8),
                  ),
                ),
                child: const Text("확인"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
