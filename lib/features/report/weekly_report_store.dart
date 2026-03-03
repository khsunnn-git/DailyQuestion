import "package:flutter/foundation.dart";

import "report_aggregation_service.dart";
import "report_api_client.dart";
import "report_models.dart";

enum WeeklyReportStatus { idle, loading, success, error }

class WeeklyReportState {
  const WeeklyReportState({
    required this.status,
    this.report,
    this.snapshot,
    this.errorMessage,
  });

  const WeeklyReportState.idle() : this(status: WeeklyReportStatus.idle);

  final WeeklyReportStatus status;
  final WeeklyAiReport? report;
  final WeeklyAggregationSnapshot? snapshot;
  final String? errorMessage;

  WeeklyReportState copyWith({
    WeeklyReportStatus? status,
    WeeklyAiReport? report,
    WeeklyAggregationSnapshot? snapshot,
    String? errorMessage,
    bool clearError = false,
  }) {
    return WeeklyReportState(
      status: status ?? this.status,
      report: report ?? this.report,
      snapshot: snapshot ?? this.snapshot,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class WeeklyReportStore extends ValueNotifier<WeeklyReportState> {
  WeeklyReportStore({
    ReportAggregationService? aggregationService,
    ReportApiClient? apiClient,
  }) : _aggregationService =
           aggregationService ?? const ReportAggregationService(),
       _apiClient = apiClient ?? ReportApiClient(),
       super(const WeeklyReportState.idle());

  static final WeeklyReportStore instance = WeeklyReportStore();

  final ReportAggregationService _aggregationService;
  final ReportApiClient _apiClient;
  static const bool _enableAiForWeekly = false;

  Future<void> generateWeeklyReport() async {
    value = value.copyWith(
      status: WeeklyReportStatus.loading,
      clearError: true,
    );
    try {
      final WeeklyAggregationSnapshot snapshot = await _aggregationService
          .buildWeeklySnapshot();
      WeeklyAiReport report;
      if (_enableAiForWeekly && _apiClient.isConfigured) {
        try {
          report = await _apiClient.analyze(snapshot.payload);
        } catch (_) {
          report = _aggregationService.buildLocalFallbackReport(snapshot);
        }
      } else {
        report = _aggregationService.buildLocalFallbackReport(snapshot);
      }

      value = WeeklyReportState(
        status: WeeklyReportStatus.success,
        report: report,
        snapshot: snapshot,
      );
    } catch (_) {
      value = WeeklyReportState(
        status: WeeklyReportStatus.error,
        errorMessage: "주간 리포트를 불러오지 못했어요. 잠시 후 다시 시도해주세요.",
      );
    }
  }
}
