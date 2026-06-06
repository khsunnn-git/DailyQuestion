import "dart:convert";

import "package:shared_preferences/shared_preferences.dart";

import "../../core/kst_date_time.dart";
import "report_models.dart";

class CachedAiReportEntry {
  const CachedAiReportEntry({
    required this.cacheKey,
    required this.periodKey,
    required this.generatedAt,
    required this.startDate,
    required this.endDate,
    required this.payload,
    required this.report,
  });

  final String cacheKey;
  final String periodKey;
  final DateTime generatedAt;
  final DateTime startDate;
  final DateTime endDate;
  final ReportAnalyzePayload payload;
  final WeeklyAiReport report;

  factory CachedAiReportEntry.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(String key) {
      final String raw = (json[key] as String?)?.trim() ?? "";
      return DateTime.tryParse(raw) ?? nowInKst();
    }

    return CachedAiReportEntry(
      cacheKey: (json["cache_key"] as String?)?.trim() ?? "",
      periodKey: (json["period_key"] as String?)?.trim() ?? "",
      generatedAt: parseDate("generated_at"),
      startDate: parseDate("start_date"),
      endDate: parseDate("end_date"),
      payload: ReportAnalyzePayload.fromJson(
        (json["payload"] as Map<String, dynamic>?) ?? const <String, dynamic>{},
      ),
      report: WeeklyAiReport.fromJson(
        (json["report"] as Map<String, dynamic>?) ?? const <String, dynamic>{},
      ),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      "cache_key": cacheKey,
      "period_key": periodKey,
      "generated_at": generatedAt.toIso8601String(),
      "start_date": startDate.toIso8601String(),
      "end_date": endDate.toIso8601String(),
      "payload": payload.toJson(),
      "report": report.toJson(),
    };
  }
}

class AiReportCacheStore {
  static const String _prefsKey = "ai_report_cache_v2";

  const AiReportCacheStore();

  Future<Map<String, CachedAiReportEntry>> readAll() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_prefsKey);
    if (raw == null || raw.trim().isEmpty) {
      return <String, CachedAiReportEntry>{};
    }

    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return <String, CachedAiReportEntry>{};
      }

      final Map<String, CachedAiReportEntry> entries =
          <String, CachedAiReportEntry>{};
      decoded.forEach((String key, dynamic value) {
        if (value is! Map<String, dynamic>) {
          return;
        }
        final CachedAiReportEntry entry = CachedAiReportEntry.fromJson(value);
        if (entry.cacheKey.trim().isEmpty || entry.summaryText.isEmpty) {
          return;
        }
        entries[key] = entry;
      });
      return entries;
    } catch (_) {
      return <String, CachedAiReportEntry>{};
    }
  }

  Future<void> upsert(CachedAiReportEntry entry) async {
    if (entry.report.summary.trim().isEmpty) {
      return;
    }
    final Map<String, CachedAiReportEntry> entries = await readAll();
    entries[entry.cacheKey] = entry;
    await _writeAll(entries);
  }

  Future<void> _writeAll(Map<String, CachedAiReportEntry> entries) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final Map<String, Object?> json = entries.map<String, Object?>(
      (String key, CachedAiReportEntry value) =>
          MapEntry<String, Object?>(key, value.toJson()),
    );
    await prefs.setString(_prefsKey, jsonEncode(json));
  }
}

extension on CachedAiReportEntry {
  String get summaryText => report.summary.trim();
}
