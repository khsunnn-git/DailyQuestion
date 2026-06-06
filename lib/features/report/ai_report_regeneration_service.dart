import "dart:async";

import "package:flutter/foundation.dart";

import "../../core/kst_date_time.dart";
import "../question/today_question_store.dart";
import "ai_report_cache_store.dart";
import "ai_report_timeline.dart";
import "period_report_aggregation_service.dart";
import "report_aggregation_service.dart";
import "report_api_client.dart";
import "report_models.dart";

final AiReportRegenerationService _aiReportRegenerationService =
    AiReportRegenerationService();

Future<void> startAiReportRegenerationService() {
  return _aiReportRegenerationService.start();
}

Future<void> queueAiReportRegeneration() {
  return _aiReportRegenerationService.queueRegeneration();
}

class AiReportRegenerationService {
  AiReportRegenerationService({
    AiReportCacheStore? cacheStore,
    ReportAggregationService? weeklyAggregationService,
    PeriodReportAggregationService? periodAggregationService,
    ReportApiClient? apiClient,
  }) : _cacheStore = cacheStore ?? const AiReportCacheStore(),
       _weeklyAggregationService =
           weeklyAggregationService ?? const ReportAggregationService(),
       _periodAggregationService =
           periodAggregationService ?? const PeriodReportAggregationService(),
       _apiClient = apiClient ?? ReportApiClient();

  final AiReportCacheStore _cacheStore;
  final ReportAggregationService _weeklyAggregationService;
  final PeriodReportAggregationService _periodAggregationService;
  final ReportApiClient _apiClient;

  bool _started = false;
  bool _running = false;
  bool _queued = false;

  Future<void> start() async {
    if (_started) {
      return;
    }
    _started = true;
    unawaited(queueRegeneration());
  }

  Future<void> queueRegeneration() async {
    if (_running) {
      _queued = true;
      return;
    }

    _running = true;
    try {
      do {
        _queued = false;
        await _regenerateMissingReports();
      } while (_queued);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint("[ai_report_regeneration] failed: $error");
        debugPrintStack(stackTrace: stackTrace);
      }
    } finally {
      _running = false;
    }
  }

  Future<void> _regenerateMissingReports() async {
    await TodayQuestionStore.instance.initialize();
    final List<TodayQuestionRecord> records = TodayQuestionStore.instance.value
        .where((TodayQuestionRecord item) => item.answer.trim().isNotEmpty)
        .toList(growable: false);
    if (records.isEmpty) {
      return;
    }

    records.sort(
      (TodayQuestionRecord a, TodayQuestionRecord b) =>
          a.createdAt.compareTo(b.createdAt),
    );
    final DateTime firstRecordDate = _dateOnly(records.first.createdAt);
    final DateTime now = nowInKst();
    final DateTime today = _dateOnly(now);
    final List<_AiReportRegenerationTarget> targets =
        _buildRegenerationTargets(firstRecordDate: firstRecordDate, now: now)
            .where((_AiReportRegenerationTarget target) {
              return target.enabled &&
                  target.endDate.isBefore(today.add(const Duration(days: 1))) &&
                  !target.endDate.isBefore(firstRecordDate);
            })
            .toList(growable: false);
    if (targets.isEmpty) {
      return;
    }

    final Map<String, CachedAiReportEntry> cached = await _cacheStore.readAll();
    for (final _AiReportRegenerationTarget target in targets) {
      final CachedAiReportEntry? entry = cached[target.cacheKey];
      if (entry != null && !_shouldRefresh(entry.report)) {
        continue;
      }

      final CachedAiReportEntry? regenerated = await _regenerateTarget(target);
      if (regenerated == null) {
        continue;
      }
      cached[target.cacheKey] = regenerated;
      await _cacheStore.upsert(regenerated);
    }
  }

  bool _shouldRefresh(WeeklyAiReport report) {
    return _apiClient.isConfigured && !report.isFromOpenAi;
  }

  Future<CachedAiReportEntry?> _regenerateTarget(
    _AiReportRegenerationTarget target,
  ) async {
    late final ReportAnalyzePayload payload;
    late final WeeklyAiReport fallbackReport;

    switch (target.period) {
      case _AiReportRegenerationPeriod.weekly:
        final WeeklyAggregationSnapshot snapshot =
            await _weeklyAggregationService.buildWeeklySnapshotForWindow(
              startDate: target.startDate,
              endDate: target.endDate,
            );
        if (snapshot.recordedDays == 0 &&
            snapshot.payload.entriesCompact.isEmpty) {
          return null;
        }
        payload = snapshot.payload;
        fallbackReport = snapshot.recordedDays < 3
            ? _weeklyAggregationService.buildCompactLocalFallbackReport(
                snapshot,
              )
            : _weeklyAggregationService.buildLocalFallbackReport(snapshot);
      case _AiReportRegenerationPeriod.monthly:
      case _AiReportRegenerationPeriod.quarterly:
        final ReportPeriod period = switch (target.period) {
          _AiReportRegenerationPeriod.monthly => ReportPeriod.monthly,
          _AiReportRegenerationPeriod.quarterly => ReportPeriod.quarterly,
          _AiReportRegenerationPeriod.weekly => throw StateError(
            "weekly not supported",
          ),
        };
        payload = await _periodAggregationService.buildPayloadForSelection(
          period: period,
          year: target.startDate.year,
          month: target.startDate.month,
        );
        if (_recordedDays(payload) == 0 && payload.entriesCompact.isEmpty) {
          return null;
        }
        fallbackReport = _periodAggregationService.buildLocalFallbackReport(
          payload: payload,
          period: period,
          year: target.startDate.year,
          month: target.startDate.month,
        );
    }

    WeeklyAiReport report = fallbackReport;
    if (_apiClient.isConfigured) {
      try {
        final WeeklyAiReport aiReport = await _apiClient.analyzeOpenAiOnly(
          payload,
        );
        report = target.period == _AiReportRegenerationPeriod.weekly
            ? _weeklyAggregationService.tuneWeeklyReport(
                report: aiReport,
                snapshot: await _weeklyAggregationService
                    .buildWeeklySnapshotForWindow(
                      startDate: target.startDate,
                      endDate: target.endDate,
                    ),
              )
            : aiReport;
      } catch (error) {
        if (kDebugMode) {
          debugPrint(
            "[ai_report_regeneration] fallback for ${target.cacheKey}: $error",
          );
        }
      }
    }

    return CachedAiReportEntry(
      cacheKey: target.cacheKey,
      periodKey: target.period.cachePeriodKey,
      generatedAt: target.generatedAt,
      startDate: target.startDate,
      endDate: target.endDate,
      payload: payload,
      report: report,
    );
  }

  List<_AiReportRegenerationTarget> _buildRegenerationTargets({
    required DateTime firstRecordDate,
    required DateTime now,
  }) {
    final DateTime cursorStart = DateTime(
      firstRecordDate.year,
      firstRecordDate.month,
    );
    final DateTime cursorEnd = DateTime(now.year, now.month);
    final List<_AiReportRegenerationTarget> targets =
        <_AiReportRegenerationTarget>[];

    DateTime cursor = cursorStart;
    while (!cursor.isAfter(cursorEnd)) {
      targets.addAll(
        buildWeeklyAiReportTimelineOptions(
          year: cursor.year,
          month: cursor.month,
          now: now,
        ).map(
          (AiReportTimelineOption option) => _AiReportRegenerationTarget(
            cacheKey: option.id,
            period: _AiReportRegenerationPeriod.weekly,
            startDate: option.startDate,
            endDate: option.endDate,
            generatedAt: option.generatedAt,
            enabled: option.enabled,
          ),
        ),
      );

      if (cursor.month == 12) {
        cursor = DateTime(cursor.year + 1);
      } else {
        cursor = DateTime(cursor.year, cursor.month + 1);
      }
    }

    for (int year = firstRecordDate.year; year <= now.year; year++) {
      targets.addAll(
        buildMonthlyAiReportTimelineOptions(
          year: year,
          firstRecordDate: firstRecordDate,
          now: now,
        ).map(
          (AiReportTimelineOption option) => _AiReportRegenerationTarget(
            cacheKey: option.id,
            period: _AiReportRegenerationPeriod.monthly,
            startDate: option.startDate,
            endDate: option.endDate,
            generatedAt: option.generatedAt,
            enabled: option.enabled,
          ),
        ),
      );
      targets.addAll(
        buildQuarterlyAiReportTimelineOptions(
          year: year,
          firstRecordDate: firstRecordDate,
          now: now,
        ).map(
          (AiReportTimelineOption option) => _AiReportRegenerationTarget(
            cacheKey: option.id,
            period: _AiReportRegenerationPeriod.quarterly,
            startDate: option.startDate,
            endDate: option.endDate,
            generatedAt: option.generatedAt,
            enabled: option.enabled,
          ),
        ),
      );
    }

    targets.sort(
      (_AiReportRegenerationTarget a, _AiReportRegenerationTarget b) =>
          a.generatedAt.compareTo(b.generatedAt),
    );
    return targets;
  }

  int _recordedDays(ReportAnalyzePayload payload) {
    final Object? raw = payload.metrics["recorded_days"];
    if (raw is int) {
      return raw;
    }
    if (raw is num) {
      return raw.round();
    }
    if (raw is String) {
      return int.tryParse(raw) ?? payload.days.length;
    }
    return payload.days.length;
  }

  DateTime _dateOnly(DateTime value) {
    final DateTime normalized = toKst(value);
    return DateTime(normalized.year, normalized.month, normalized.day);
  }
}

enum _AiReportRegenerationPeriod {
  weekly,
  monthly,
  quarterly;

  String get cachePeriodKey => switch (this) {
    _AiReportRegenerationPeriod.weekly => "weekly",
    _AiReportRegenerationPeriod.monthly => "monthly",
    _AiReportRegenerationPeriod.quarterly => "quarterly",
  };
}

class _AiReportRegenerationTarget {
  const _AiReportRegenerationTarget({
    required this.cacheKey,
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.generatedAt,
    required this.enabled,
  });

  final String cacheKey;
  final _AiReportRegenerationPeriod period;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime generatedAt;
  final bool enabled;
}
