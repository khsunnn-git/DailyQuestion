import "package:flutter/material.dart";

import "../../design_system/design_system.dart";
import "monthly_report_preview_screen.dart";
import "report_models.dart";
import "weekly_report_sample_seed.dart";
import "weekly_report_store.dart";

class WeeklyReportScreen extends StatefulWidget {
  const WeeklyReportScreen({super.key});

  @override
  State<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends State<WeeklyReportScreen> {
  Future<void> _seedAndAnalyze() async {
    await const WeeklyReportSampleSeed().apply();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Center(child: AppToastMessage(text: "샘플 데이터 7일 저장 완료")),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
          backgroundColor: Colors.transparent,
          elevation: 0,
          padding: EdgeInsets.zero,
          margin: EdgeInsets.fromLTRB(50, 0, 50, 98),
        ),
      );
    await WeeklyReportStore.instance.generateWeeklyReport();
  }

  @override
  void initState() {
    super.initState();
    WeeklyReportStore.instance.generateWeeklyReport();
  }

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    return Scaffold(
      backgroundColor: brand.bg,
      appBar: AppBar(
        title: Text(
          "주간 리포트",
          style: AppTypography.headingXSmall.copyWith(
            color: AppNeutralColors.grey900,
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const MonthlyReportPreviewScreen(),
                ),
              );
            },
            child: const Text("월간"),
          ),
          TextButton(onPressed: _seedAndAnalyze, child: const Text("샘플")),
        ],
      ),
      body: ValueListenableBuilder<WeeklyReportState>(
        valueListenable: WeeklyReportStore.instance,
        builder:
            (BuildContext context, WeeklyReportState state, Widget? child) {
              if (state.status == WeeklyReportStatus.loading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.status == WeeklyReportStatus.error) {
                return _ErrorView(
                  message: state.errorMessage ?? "오류가 발생했어요.",
                  onRetry: WeeklyReportStore.instance.generateWeeklyReport,
                );
              }
              if (state.status != WeeklyReportStatus.success ||
                  state.report == null ||
                  state.snapshot == null) {
                return const SizedBox.shrink();
              }
              return _ReportContent(
                state: state,
                onRefresh: WeeklyReportStore.instance.generateWeeklyReport,
              );
            },
      ),
    );
  }
}

class _ReportContent extends StatelessWidget {
  const _ReportContent({required this.state, required this.onRefresh});

  final WeeklyReportState state;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final WeeklyAiReport report = state.report!;
    final WeeklyAggregationSnapshot snapshot = state.snapshot!;
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        children: <Widget>[
          _ScoreCard(report: report, snapshot: snapshot),
          const SizedBox(height: AppSpacing.s16),
          _SectionCard(
            title: "요약",
            children: <Widget>[
              Text(
                report.summary,
                style: AppTypography.bodyMediumRegular.copyWith(
                  color: AppNeutralColors.grey800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s16),
          _SectionCard(
            title: "인사이트",
            children: report.insights.isEmpty
                ? <Widget>[_EmptyText(text: "아직 인사이트가 없어요.")]
                : report.insights
                      .map((String item) => _BulletText(text: item))
                      .toList(growable: false),
          ),
          const SizedBox(height: AppSpacing.s16),
          _SectionCard(
            title: "다음 액션",
            children: report.actions.isEmpty
                ? <Widget>[_EmptyText(text: "추천 액션이 아직 없어요.")]
                : report.actions
                      .map((String item) => _BulletText(text: item))
                      .toList(growable: false),
          ),
          const SizedBox(height: AppSpacing.s16),
          _SectionCard(
            title: "핵심 키워드",
            children: snapshot.topKeywords.isEmpty
                ? <Widget>[_EmptyText(text: "아직 추출된 키워드가 없어요.")]
                : <Widget>[
                    Wrap(
                      spacing: AppSpacing.s8,
                      runSpacing: AppSpacing.s8,
                      children: snapshot.topKeywords
                          .map(
                            (String item) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.s12,
                                vertical: AppSpacing.s8,
                              ),
                              decoration: BoxDecoration(
                                color: AppNeutralColors.grey100,
                                borderRadius: AppRadius.pill,
                              ),
                              child: Text(
                                item,
                                style: AppTypography.captionMedium.copyWith(
                                  color: AppNeutralColors.grey800,
                                ),
                              ),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ],
          ),
        ],
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.report, required this.snapshot});

  final WeeklyAiReport report;
  final WeeklyAggregationSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    final ({String label, Color bg, Color fg}) sourceUi = _sourceBadge(
      report.source,
    );
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppNeutralColors.white,
        borderRadius: AppRadius.br16,
        boxShadow: AppElevation.level1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            "이번 주 점수",
            style: AppTypography.bodySmallMedium.copyWith(
              color: AppNeutralColors.grey500,
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                "${report.weeklyScore}",
                style: AppTypography.headingLarge.copyWith(color: brand.c500),
              ),
              const SizedBox(width: 4),
              Text(
                "/ 5",
                style: AppTypography.headingXSmall.copyWith(
                  color: AppNeutralColors.grey500,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s8,
                  vertical: AppSpacing.s4,
                ),
                decoration: BoxDecoration(
                  color: sourceUi.bg,
                  borderRadius: AppRadius.pill,
                ),
                child: Text(
                  sourceUi.label,
                  style: AppTypography.captionSmall.copyWith(
                    color: sourceUi.fg,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s16),
          Row(
            children: <Widget>[
              _MetricChip(label: "기분", value: snapshot.averageMood),
              const SizedBox(width: AppSpacing.s8),
              _MetricChip(label: "에너지", value: snapshot.averageEnergy),
              const SizedBox(width: AppSpacing.s8),
              _MetricChip(label: "스트레스", value: snapshot.averageStress),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          Text(
            "기록일 ${snapshot.recordedDays}/${snapshot.targetDays}",
            style: AppTypography.captionMedium.copyWith(
              color: AppNeutralColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  ({String label, Color bg, Color fg}) _sourceBadge(String source) {
    switch (source) {
      case "ai":
        return (
          label: "AI",
          bg: const Color(0xFFEAF5FF),
          fg: const Color(0xFF017AF7),
        );
      case "server-fallback":
        return (
          label: "서버 Fallback",
          bg: const Color(0xFFFFF4E8),
          fg: const Color(0xFFFF8C2B),
        );
      case "local-fallback":
        return (
          label: "로컬 Fallback",
          bg: AppNeutralColors.grey100,
          fg: AppNeutralColors.grey700,
        );
      default:
        return (
          label: source,
          bg: AppNeutralColors.grey100,
          fg: AppNeutralColors.grey700,
        );
    }
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s8,
          vertical: AppSpacing.s12,
        ),
        decoration: BoxDecoration(
          color: AppNeutralColors.grey100,
          borderRadius: AppRadius.br8,
        ),
        child: Column(
          children: <Widget>[
            Text(
              label,
              style: AppTypography.captionSmall.copyWith(
                color: AppNeutralColors.grey500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value.toStringAsFixed(1),
              style: AppTypography.bodyMediumSemiBold.copyWith(
                color: AppNeutralColors.grey900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppNeutralColors.white,
        borderRadius: AppRadius.br16,
        boxShadow: AppElevation.level1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: AppTypography.heading2XSmall.copyWith(
              color: AppNeutralColors.grey900,
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          ...children,
        ],
      ),
    );
  }
}

class _BulletText extends StatelessWidget {
  const _BulletText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            "• ",
            style: AppTypography.bodyMediumMedium.copyWith(
              color: AppNeutralColors.grey700,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodyMediumRegular.copyWith(
                color: AppNeutralColors.grey800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyText extends StatelessWidget {
  const _EmptyText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.bodyMediumRegular.copyWith(
        color: AppNeutralColors.grey500,
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMediumRegular.copyWith(
                color: AppNeutralColors.grey700,
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            FilledButton(
              onPressed: () {
                onRetry();
              },
              child: const Text("다시 시도"),
            ),
          ],
        ),
      ),
    );
  }
}
