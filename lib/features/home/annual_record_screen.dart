import "package:flutter/material.dart";

import "../../design_system/design_system.dart";
import "../bucket/bucket_list_screen.dart";

class AnnualRecordScreen extends StatelessWidget {
  const AnnualRecordScreen({
    super.key,
    required this.question,
    required this.entries,
    required this.continuousYears,
  });

  final String question;
  final List<AnnualRecordEntry> entries;
  final int continuousYears;

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    return Scaffold(
      backgroundColor: brand.bg,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.s20,
                49,
                AppSpacing.s20,
                AppNavigationBar.totalHeight(context) + AppSpacing.s20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints.tightFor(
                            width: 24,
                            height: 24,
                          ),
                          icon: const Icon(
                            Icons.arrow_back,
                            size: 24,
                            color: AppNeutralColors.grey900,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          "연간 기록",
                          textAlign: TextAlign.center,
                          style: AppTypography.headingXSmall.copyWith(
                            color: AppNeutralColors.grey900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 24, height: 24),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s24),
                  Container(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.s8,
                      AppSpacing.s24,
                      AppSpacing.s8,
                      AppSpacing.s24,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: brand.c200, width: 1),
                      ),
                    ),
                    child: Column(
                      children: <Widget>[
                        Text(
                          question,
                          textAlign: TextAlign.center,
                          style: AppTypography.headingLarge.copyWith(
                            color: AppNeutralColors.grey900,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s16),
                        Text(
                          "연간 $continuousYears년째 기록중",
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmallRegular.copyWith(
                            color: AppNeutralColors.grey600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s24),
                  ...entries.map(
                    (AnnualRecordEntry entry) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.s16),
                      child: _AnnualRecordCard(entry: entry),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AppNavigationBar(
              currentIndex: 2,
              onTap: (int index) {
                if (index == 0) {
                  Navigator.of(context).popUntil(
                    (Route<dynamic> route) => route.isFirst,
                  );
                  return;
                }
                if (index == 1) {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const BucketListScreen(),
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

class AnnualRecordEntry {
  const AnnualRecordEntry({
    required this.year,
    required this.answer,
    required this.dateLabel,
  });

  final int year;
  final String answer;
  final String dateLabel;
}

class _AnnualRecordCard extends StatelessWidget {
  const _AnnualRecordCard({required this.entry});

  final AnnualRecordEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppNeutralColors.white,
        borderRadius: AppRadius.br16,
        boxShadow: AppElevation.level1,
      ),
      child: Column(
        children: <Widget>[
          Text(
            entry.answer,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMediumMedium.copyWith(
              color: AppNeutralColors.grey900,
            ),
          ),
          const SizedBox(height: AppSpacing.s24),
          Text(
            entry.dateLabel,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmallSemiBold.copyWith(
              color: context.appBrandScale.c500,
            ),
          ),
        ],
      ),
    );
  }
}
