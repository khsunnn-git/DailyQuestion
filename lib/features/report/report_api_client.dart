import "dart:async";
import "dart:convert";
import "dart:io";

import "report_models.dart";

class ReportApiClient {
  ReportApiClient({String? baseUrl, HttpClient? httpClient, Duration? timeout})
    : _baseUrl =
          (baseUrl ?? const String.fromEnvironment("REPORT_API_BASE_URL"))
              .trim(),
      _httpClient = httpClient ?? HttpClient(),
      _timeout = timeout ?? const Duration(seconds: 15);

  final String _baseUrl;
  final HttpClient _httpClient;
  final Duration _timeout;

  bool get isConfigured => _baseUrl.isNotEmpty;

  Future<WeeklyAiReport> analyze(ReportAnalyzePayload payload) async {
    if (!isConfigured) {
      throw const ReportApiException("REPORT_API_BASE_URL is not configured.");
    }
    final Uri uri = Uri.parse("$_baseUrl/v1/report/analyze");
    final HttpClientRequest request = await _httpClient
        .postUrl(uri)
        .timeout(_timeout);
    request.headers.set(HttpHeaders.contentTypeHeader, "application/json");
    request.add(utf8.encode(jsonEncode(payload.toJson())));

    final HttpClientResponse response = await request.close().timeout(_timeout);
    final String raw = await utf8.decoder.bind(response).join();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ReportApiException(
        "Analyze API failed with ${response.statusCode}: $raw",
      );
    }
    final Object? decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const ReportApiException(
        "Analyze API response is not JSON object.",
      );
    }
    return WeeklyAiReport.fromJson(decoded);
  }
}

class ReportApiException implements Exception {
  const ReportApiException(this.message);

  final String message;

  @override
  String toString() => "ReportApiException: $message";
}
