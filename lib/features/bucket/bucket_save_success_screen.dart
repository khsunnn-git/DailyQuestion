import "dart:async";

import "package:flutter/material.dart";

import "../../design_system/design_system.dart";

class BucketSaveSuccessScreen extends StatefulWidget {
  const BucketSaveSuccessScreen({super.key});

  static const String successAsset =
      "assets/images/bucket/bucketlist_save_success.png";

  @override
  State<BucketSaveSuccessScreen> createState() =>
      _BucketSaveSuccessScreenState();
}

class _BucketSaveSuccessScreenState extends State<BucketSaveSuccessScreen> {
  Timer? _autoCloseTimer;

  @override
  void initState() {
    super.initState();
    _autoCloseTimer = Timer(const Duration(seconds: 3), _close);
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
                      "버킷리스트 저장!",
                      textAlign: TextAlign.center,
                      style: AppTypography.headingLarge.copyWith(
                        color: AppNeutralColors.grey900,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s24),
                    Image.asset(
                      BucketSaveSuccessScreen.successAsset,
                      width: 160,
                      height: 160,
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
