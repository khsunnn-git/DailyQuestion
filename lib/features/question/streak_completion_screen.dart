import "dart:async";

import "package:flutter/material.dart";

import "../../design_system/design_system.dart";

class StreakCompletionScreen extends StatefulWidget {
  const StreakCompletionScreen({
    super.key,
    required this.streakDays,
    required this.weeklyCompleted,
  });

  final int streakDays;
  final List<bool> weeklyCompleted;

  @override
  State<StreakCompletionScreen> createState() => _StreakCompletionScreenState();
}

class _StreakCompletionScreenState extends State<StreakCompletionScreen> {
  static const String _celebrationImageAsset =
      "assets/images/question/streak_celebration.png";
  Timer? _autoCloseTimer;

  @override
  void initState() {
    super.initState();
    _autoCloseTimer = Timer(const Duration(seconds: 2), _close);
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

  String _buildSubtitle() {
    final int streak = widget.streakDays;
    if (streak % 30 == 0) {
      final int months = streak ~/ 30;
      return "$months달 동안 당신의 생각을 이어왔어요. 멋져요.";
    }
    if (streak == 7) {
      return "일주일 동안 꾸준히 기록했어요. 대단해요";
    }
    if (streak == 3) {
      return "벌써 $streak일 연속 기록이에요! 잘하고 있어요!";
    }
    return "매일 방문하며 자신을 더 알아가보세요!";
  }

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    final List<String> weekdays = const <String>[
      "월",
      "화",
      "수",
      "목",
      "금",
      "토",
      "일",
    ];
    return Scaffold(
      backgroundColor: brand.bg,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _close,
        child: Padding(
          padding: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: _close,
                        icon: const Icon(
                          Icons.arrow_back,
                          color: AppNeutralColors.grey900,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s24),
                    GestureDetector(
                      onTap: () {},
                      child: Column(
                        children: <Widget>[
                          Image.asset(
                            _celebrationImageAsset,
                            width: 150,
                            height: 150,
                            fit: BoxFit.contain,
                            errorBuilder:
                                (_, Object error, StackTrace? stackTrace) =>
                                    Container(
                                      width: 150,
                                      height: 150,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: AppNeutralColors.grey100,
                                        borderRadius: AppRadius.br16,
                                      ),
                                      child: Text(
                                        "이미지 로드 실패",
                                        style: AppTypography.captionMedium
                                            .copyWith(
                                              color: AppNeutralColors.grey600,
                                            ),
                                      ),
                                    ),
                          ),
                          const SizedBox(height: AppSpacing.s24),
                          Text(
                            "연속 ${widget.streakDays}번째 기록 완료!",
                            textAlign: TextAlign.center,
                            style: AppTypography.headingLarge.copyWith(
                              color: AppNeutralColors.grey900,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.s8),
                          Text(
                            _buildSubtitle(),
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyLargeMedium.copyWith(
                              color: AppNeutralColors.grey600,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.s24),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpacing.s32),
                            decoration: BoxDecoration(
                              color: AppNeutralColors.white,
                              borderRadius: AppRadius.br16,
                              boxShadow: AppElevation.level1,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List<Widget>.generate(7, (int index) {
                                final bool completed =
                                    index < widget.weeklyCompleted.length &&
                                    widget.weeklyCompleted[index];
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Text(
                                      weekdays[index],
                                      style: AppTypography.bodySmallMedium
                                          .copyWith(
                                            color: AppNeutralColors.grey900,
                                          ),
                                    ),
                                    const SizedBox(height: AppSpacing.s8),
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: completed
                                            ? AppSemanticColors.success500
                                            : AppNeutralColors.grey100,
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        border: completed
                                            ? Border.all(
                                                color: AppSemanticColors
                                                    .success600,
                                              )
                                            : null,
                                      ),
                                      alignment: Alignment.center,
                                      child: completed
                                          ? const Icon(
                                              Icons.star_rounded,
                                              size: 20,
                                              color: AppNeutralColors.white,
                                            )
                                          : null,
                                    ),
                                  ],
                                );
                              }),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.s24),
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: FilledButton(
                              onPressed: _close,
                              style: FilledButton.styleFrom(
                                backgroundColor: brand.c500,
                                shape: const StadiumBorder(),
                                overlayColor: Colors.transparent,
                                splashFactory: NoSplash.splashFactory,
                              ),
                              child: Text(
                                "확인",
                                style: AppTypography.buttonMedium.copyWith(
                                  color: AppNeutralColors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
            ),
          ),
        ),
      ),
    );
  }
}
