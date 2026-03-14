import "dart:convert";

import "package:flutter/foundation.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../../core/kst_date_time.dart";
import "report_aggregation_service.dart";
import "report_api_client.dart";
import "report_models.dart";
import "weekly_report_schedule.dart";

enum WeeklyReportStatus { idle, loading, success, error }

class WeeklyReportState {
  const WeeklyReportState({
    required this.status,
    this.report,
    this.snapshot,
    this.slotKey,
    this.generatedAt,
    this.periodStartDate,
    this.periodEndDate,
    this.errorMessage,
  });

  const WeeklyReportState.idle() : this(status: WeeklyReportStatus.idle);

  final WeeklyReportStatus status;
  final WeeklyAiReport? report;
  final WeeklyAggregationSnapshot? snapshot;
  final String? slotKey;
  final DateTime? generatedAt;
  final DateTime? periodStartDate;
  final DateTime? periodEndDate;
  final String? errorMessage;

  bool get isCompact => (snapshot?.recordedDays ?? 0) < 3;

  WeeklyReportState copyWith({
    WeeklyReportStatus? status,
    WeeklyAiReport? report,
    WeeklyAggregationSnapshot? snapshot,
    String? slotKey,
    DateTime? generatedAt,
    DateTime? periodStartDate,
    DateTime? periodEndDate,
    String? errorMessage,
    bool clearError = false,
  }) {
    return WeeklyReportState(
      status: status ?? this.status,
      report: report ?? this.report,
      snapshot: snapshot ?? this.snapshot,
      slotKey: slotKey ?? this.slotKey,
      generatedAt: generatedAt ?? this.generatedAt,
      periodStartDate: periodStartDate ?? this.periodStartDate,
      periodEndDate: periodEndDate ?? this.periodEndDate,
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
  static const String _cachePrefsKey = "weekly_report_cache_v1";

  final ReportAggregationService _aggregationService;
  final ReportApiClient _apiClient;

  Future<void> prepareCurrentWeeklyReport({bool forceRefresh = false}) async {
    final WeeklyReportCacheEntry? cached = await _readCache();
    final WeeklyReportWindow window = currentWeeklyReportWindow();
    if (!forceRefresh && cached != null && cached.slotKey == window.slotKey) {
      value = WeeklyReportState(
        status: WeeklyReportStatus.success,
        report: cached.report,
        snapshot: cached.snapshot,
        slotKey: cached.slotKey,
        generatedAt: cached.generatedAt,
        periodStartDate: cached.periodStartDate,
        periodEndDate: cached.periodEndDate,
      );
      return;
    }

    value = value.copyWith(
      status: WeeklyReportStatus.loading,
      clearError: true,
    );
    try {
      final WeeklyAggregationSnapshot snapshot = await _aggregationService
          .buildWeeklySnapshot(referenceDate: window.referenceDate);
      WeeklyAiReport report = _fallbackReportFor(snapshot);
      if (_apiClient.isConfigured) {
        try {
          report = await _apiClient.analyze(snapshot.payload);
        } catch (_) {
          report = _fallbackReportFor(snapshot);
        }
      }
      final WeeklyReportCacheEntry entry = WeeklyReportCacheEntry(
        slotKey: window.slotKey,
        generatedAt: nowInKst(),
        periodStartDate: window.startDate,
        periodEndDate: window.endDate,
        report: report,
        snapshot: snapshot,
      );
      await _writeCache(entry);
      value = WeeklyReportState(
        status: WeeklyReportStatus.success,
        report: report,
        snapshot: snapshot,
        slotKey: entry.slotKey,
        generatedAt: entry.generatedAt,
        periodStartDate: entry.periodStartDate,
        periodEndDate: entry.periodEndDate,
      );
    } catch (_) {
      if (cached != null) {
        value = WeeklyReportState(
          status: WeeklyReportStatus.success,
          report: cached.report,
          snapshot: cached.snapshot,
          slotKey: cached.slotKey,
          generatedAt: cached.generatedAt,
          periodStartDate: cached.periodStartDate,
          periodEndDate: cached.periodEndDate,
        );
        return;
      }
      value = WeeklyReportState(
        status: WeeklyReportStatus.error,
        errorMessage: "주간 리포트를 불러오지 못했어요. 잠시 후 다시 시도해주세요.",
      );
    }
  }

  Future<void> generateWeeklyReport() async {
    await prepareCurrentWeeklyReport(forceRefresh: true);
  }

  WeeklyAiReport _fallbackReportFor(WeeklyAggregationSnapshot snapshot) {
    if (snapshot.recordedDays < 3) {
      return _aggregationService.buildCompactLocalFallbackReport(snapshot);
    }
    return _aggregationService.buildLocalFallbackReport(snapshot);
  }

  Future<WeeklyReportCacheEntry?> _readCache() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_cachePrefsKey);
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      return WeeklyReportCacheEntry.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache(WeeklyReportCacheEntry entry) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cachePrefsKey, jsonEncode(entry.toJson()));
  }
}

class WeeklyReportCacheEntry {
  const WeeklyReportCacheEntry({
    required this.slotKey,
    required this.generatedAt,
    required this.periodStartDate,
    required this.periodEndDate,
    required this.report,
    required this.snapshot,
  });

  final String slotKey;
  final DateTime generatedAt;
  final DateTime periodStartDate;
  final DateTime periodEndDate;
  final WeeklyAiReport report;
  final WeeklyAggregationSnapshot snapshot;

  factory WeeklyReportCacheEntry.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(String key) {
      final String raw = (json[key] as String?)?.trim() ?? "";
      return DateTime.tryParse(raw) ?? nowInKst();
    }

    return WeeklyReportCacheEntry(
      slotKey: (json["slot_key"] as String?)?.trim() ?? "",
      generatedAt: parseDate("generated_at"),
      periodStartDate: parseDate("period_start_date"),
      periodEndDate: parseDate("period_end_date"),
      report: WeeklyAiReport.fromJson(
        (json["report"] as Map<String, dynamic>?) ?? const <String, dynamic>{},
      ),
      snapshot: WeeklyAggregationSnapshot.fromJson(
        (json["snapshot"] as Map<String, dynamic>?) ??
            const <String, dynamic>{},
      ),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      "slot_key": slotKey,
      "generated_at": generatedAt.toIso8601String(),
      "period_start_date": periodStartDate.toIso8601String(),
      "period_end_date": periodEndDate.toIso8601String(),
      "report": report.toJson(),
      "snapshot": snapshot.toJson(),
    };
  }
}
