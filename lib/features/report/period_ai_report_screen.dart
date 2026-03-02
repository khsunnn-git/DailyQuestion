import "package:flutter/material.dart";

import "../../design_system/design_system.dart";
import "period_report_aggregation_service.dart";
import "report_api_client.dart";
import "report_models.dart";

enum _PeriodReportStatus { idle, loading, success, error }

class PeriodAiReportScreen extends StatefulWidget {
  const PeriodAiReportScreen({super.key});

  @override
  State<PeriodAiReportScreen> createState() => _PeriodAiReportScreenState();
}

class _PeriodAiReportScreenState extends State<PeriodAiReportScreen> {
  final PeriodReportAggregationService _aggregationService =
      const PeriodReportAggregationService();
  final ReportApiClient _apiClient = ReportApiClient();

  ReportPeriod _selected = ReportPeriod.monthly;
  _PeriodReportStatus _status = _PeriodReportStatus.idle;
  WeeklyAiReport? _report;
  String? _error;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  Future<void> _generate() async {
    setState(() {
      _status = _PeriodReportStatus.loading;
      _error = null;
    });
    if (!_apiClient.isConfigured) {
      setState(() {
        _status = _PeriodReportStatus.error;
        _error = "REPORT_API_BASE_URL 설정이 필요해요.";
      });
      return;
    }
    try {
      final ReportAnalyzePayload payload = await _aggregationService
          .buildPayloadFor(_selected);
      final WeeklyAiReport response = await _apiClient.analyze(payload);
      setState(() {
        _status = _PeriodReportStatus.success;
        _report = response;
      });
    } catch (_) {
      setState(() {
        _status = _PeriodReportStatus.error;
        _error = "AI 리포트를 불러오지 못했어요. 잠시 후 다시 시도해주세요.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    return Scaffold(
      backgroundColor: brand.bg,
      appBar: AppBar(
        title: Text(
          "AI 리포트",
          style: AppTypography.headingXSmall.copyWith(
            color: AppNeutralColors.grey900,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _generate,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
          children: <Widget>[
            _PeriodSelector(
              selected: _selected,
              onChanged: (ReportPeriod next) {
                setState(() {
                  _selected = next;
                });
                _generate();
              },
            ),
            const SizedBox(height: AppSpacing.s16),
            if (_status == _PeriodReportStatus.loading)
              const Padding(
                padding: EdgeInsets.only(top: 60),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_status == _PeriodReportStatus.error)
              _ErrorCard(message: _error ?? "오류가 발생했어요.", onRetry: _generate)
            else if (_status == _PeriodReportStatus.success && _report != null)
              _ReportBody(report: _report!)
            else
              const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.selected, required this.onChanged});

  final ReportPeriod selected;
  final ValueChanged<ReportPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.s8,
      children: ReportPeriod.values
          .map((ReportPeriod period) {
            final bool active = selected == period;
            final String label = switch (period) {
              ReportPeriod.monthly => "월간",
              ReportPeriod.quarterly => "분기",
              ReportPeriod.yearly => "연간",
            };
            return ChoiceChip(
              label: Text(label),
              selected: active,
              onSelected: (_) => onChanged(period),
              selectedColor: const Color(0xFFEAF5FF),
              labelStyle: AppTypography.bodySmallMedium.copyWith(
                color: active
                    ? const Color(0xFF017AF7)
                    : AppNeutralColors.grey700,
              ),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.pill),
            );
          })
          .toList(growable: false),
    );
  }
}

class _ReportBody extends StatelessWidget {
  const _ReportBody({required this.report});

  final WeeklyAiReport report;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        _Card(
          title: "요약",
          source: report.source,
          body: Text(
            report.summary,
            style: AppTypography.bodyMediumRegular.copyWith(
              color: AppNeutralColors.grey800,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s12),
        _Card(
          title: "인사이트",
          source: report.source,
          body: Column(
            children: report.insights
                .map((String line) => _Bullet(line: line))
                .toList(growable: false),
          ),
        ),
        const SizedBox(height: AppSpacing.s12),
        _Card(
          title: "제안",
          source: report.source,
          body: Column(
            children: report.actions
                .map((String line) => _Bullet(line: line))
                .toList(growable: false),
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({this.title, this.source, this.body, this.child})
    : assert(body != null || child != null);

  final String? title;
  final String? source;
  final Widget? body;
  final Widget? child;

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
      child:
          child ??
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (title != null) ...<Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        title!,
                        style: AppTypography.heading2XSmall.copyWith(
                          color: AppNeutralColors.grey900,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s8,
                        vertical: AppSpacing.s2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF5FF),
                        borderRadius: AppRadius.pill,
                      ),
                      child: Text(
                        "AI",
                        style: AppTypography.captionSmall.copyWith(
                          color: const Color(0xFF017AF7),
                        ),
                      ),
                    ),
                    if (source != null) ...<Widget>[
                      const SizedBox(width: AppSpacing.s6),
                      Builder(
                        builder: (BuildContext context) {
                          final ({String label, Color bg, Color fg}) sourceUi =
                              _sourceBadge(source!);
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.s8,
                              vertical: AppSpacing.s2,
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
                          );
                        },
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.s12),
              ],
              body!,
            ],
          ),
    );
  }

  ({String label, Color bg, Color fg}) _sourceBadge(String source) {
    switch (source) {
      case "ai":
        return (
          label: "실제 AI",
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

class _Bullet extends StatelessWidget {
  const _Bullet({required this.line});

  final String line;

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
              line,
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

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return _Card(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            message,
            style: AppTypography.bodyMediumRegular.copyWith(
              color: AppNeutralColors.grey700,
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          FilledButton(onPressed: () => onRetry(), child: const Text("다시 시도")),
        ],
      ),
    );
  }
}
