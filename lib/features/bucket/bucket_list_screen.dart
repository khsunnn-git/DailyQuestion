import "package:flutter/material.dart";

import "../../design_system/design_system.dart";
import "../home/my_records_screen.dart";
import "../question/today_question_answer_screen.dart";

class BucketListScreen extends StatelessWidget {
  const BucketListScreen({super.key});

  static const String _emptyBucketAsset =
      "assets/images/bucket/bucketlist_empty_state_note.png";

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    return Scaffold(
      backgroundColor: brand.bg,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.s20,
                49,
                AppSpacing.s20,
                AppNavigationBar.totalHeight(context) + 80,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const SizedBox(width: 24, height: 24),
                      Expanded(
                        child: Text(
                          "버킷리스트",
                          textAlign: TextAlign.center,
                          style: AppTypography.headingXSmall.copyWith(
                            color: AppNeutralColors.grey900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 24, height: 24),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s16,
                          vertical: AppSpacing.s8,
                        ),
                        decoration: BoxDecoration(
                          color: AppNeutralColors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: AppElevation.level1,
                        ),
                        child: Text(
                          "오늘의 질문을 아직 저장된\n버킷리스트가 없어요 추가해볼까요?!",
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmallMedium.copyWith(
                            color: AppNeutralColors.grey700,
                          ),
                        ),
                      ),
                      CustomPaint(
                        size: const Size(10, 6),
                        painter: _BubbleTailPainter(),
                      ),
                      const SizedBox(height: AppSpacing.s16),
                      Image.asset(
                        _emptyBucketAsset,
                        width: 140,
                        height: 140,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
          Positioned(
            left: AppSpacing.s20,
            right: AppSpacing.s20,
            bottom: AppNavigationBar.totalHeight(context) + AppSpacing.s32,
            child: SizedBox(
              height: AppSpacing.s48,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const TodayQuestionAnswerScreen(),
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: brand.c500,
                  foregroundColor: AppNeutralColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.s8),
                  ),
                  textStyle: AppTypography.buttonMedium,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s24,
                  ),
                ),
                child: const Text("버킷리스트 추가"),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AppNavigationBar(
              currentIndex: 1,
              onTap: (int index) {
                if (index == 0) {
                  Navigator.of(
                    context,
                  ).popUntil((Route<dynamic> route) => route.isFirst);
                  return;
                }
                if (index == 2) {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const MyRecordsScreen(),
                    ),
                  );
                }
              },
              items: const <AppNavigationBarItemData>[
                AppNavigationBarItemData(
                  label: "오늘의 질문",
                  icon: Icons.home_outlined,
                ),
                AppNavigationBarItemData(
                  label: "버킷리스트",
                  icon: Icons.format_list_bulleted,
                ),
                AppNavigationBarItemData(
                  label: "나의기록",
                  icon: Icons.assignment_outlined,
                ),
                AppNavigationBarItemData(
                  label: "더보기",
                  icon: Icons.more_horiz,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = AppNeutralColors.white;
    final Path path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
