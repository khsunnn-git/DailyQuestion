import "dart:async";
import "dart:convert";
import "dart:io";

import "package:flutter/foundation.dart";

import "report_models.dart";

class ReportApiClient {
  ReportApiClient({
    String? baseUrl,
    HttpClient? httpClient,
    Duration? timeout,
    bool? isReleaseMode,
    String? envBaseUrl,
  }) : _baseUrls = _resolveBaseUrls(
         baseUrl,
         envBaseUrl: envBaseUrl ?? _envBaseUrl,
         isReleaseMode: isReleaseMode ?? kReleaseMode,
       ),
       _hasExplicitBaseUrl = _hasExplicitlyConfiguredBaseUrl(
         baseUrl,
         envBaseUrl: envBaseUrl ?? _envBaseUrl,
       ),
       _httpClient = httpClient ?? HttpClient(),
       _timeout = timeout ?? const Duration(seconds: 15);

  static const String _envBaseUrl = String.fromEnvironment(
    "REPORT_API_BASE_URL",
  );
  static const String _releaseBaseUrl =
      "https://us-central1-dailyquestion-29840.cloudfunctions.net/reportAiApi";

  final List<String> _baseUrls;
  final bool _hasExplicitBaseUrl;
  final HttpClient _httpClient;
  final Duration _timeout;

  bool get isConfigured => _baseUrls.isNotEmpty;

  Future<WeeklyAiReport> analyze(ReportAnalyzePayload payload) async {
    if (!isConfigured) {
      throw const ReportApiException("REPORT_API_BASE_URL is not configured.");
    }
    ReportApiException? lastApiError;
    Object? lastTransportError;

    for (final String baseUrl in _baseUrls) {
      try {
        return await _analyzeWithBaseUrl(baseUrl, payload);
      } on ReportApiException catch (error) {
        if (_hasExplicitBaseUrl || !_shouldTryNextCandidate(error)) {
          rethrow;
        }
        lastApiError = error;
      } on SocketException catch (error) {
        if (_hasExplicitBaseUrl) {
          rethrow;
        }
        lastTransportError = error;
      } on HttpException catch (error) {
        if (_hasExplicitBaseUrl) {
          rethrow;
        }
        lastTransportError = error;
      } on TimeoutException catch (error) {
        if (_hasExplicitBaseUrl) {
          rethrow;
        }
        lastTransportError = error;
      }
    }

    if (lastApiError != null) {
      throw lastApiError;
    }
    if (lastTransportError != null) {
      throw ReportApiException("No reachable report API endpoint was found.");
    }

    throw const ReportApiException("REPORT_API_BASE_URL is not configured.");
  }

  Future<WeeklyAiReport> analyzeOpenAiOnly(ReportAnalyzePayload payload) async {
    final WeeklyAiReport report = await analyze(payload);
    if (!report.isFromOpenAi) {
      throw const ReportApiException(
        "AI report is not ready because the response did not come from OpenAI.",
      );
    }
    return report;
  }

  Future<WeeklyAiReport> _analyzeWithBaseUrl(
    String baseUrl,
    ReportAnalyzePayload payload,
  ) async {
    final Uri uri = _analyzeUri(baseUrl);
    if (kDebugMode) {
      debugPrint("[ai_report_api] request $uri");
    }
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
        statusCode: response.statusCode,
      );
    }
    final Object? decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const ReportApiException(
        "Analyze API response is not JSON object.",
      );
    }
    final WeeklyAiReport report = WeeklyAiReport.fromJson(decoded);
    if (kDebugMode) {
      debugPrint(
        "[ai_report_api] success $uri "
        "source=${report.source} openAi=${report.isFromOpenAi}",
      );
    }
    return report;
  }

  Uri _analyzeUri(String baseUrl) {
    final String normalizedBase = baseUrl.endsWith("/")
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    if (normalizedBase.endsWith("/v1/report/analyze")) {
      return Uri.parse(normalizedBase);
    }
    return Uri.parse("$normalizedBase/v1/report/analyze");
  }

  bool _shouldTryNextCandidate(ReportApiException error) {
    final int? statusCode = error.statusCode;
    return statusCode == 404 || statusCode == 405;
  }

  static bool _hasExplicitlyConfiguredBaseUrl(
    String? baseUrl, {
    required String envBaseUrl,
  }) {
    if (baseUrl != null) {
      return baseUrl.trim().isNotEmpty;
    }
    return envBaseUrl.trim().isNotEmpty;
  }

  static List<String> _resolveBaseUrls(
    String? baseUrl, {
    required String envBaseUrl,
    required bool isReleaseMode,
  }) {
    if (baseUrl != null) {
      final String normalized = baseUrl.trim();
      return normalized.isEmpty ? const <String>[] : <String>[normalized];
    }

    final String normalizedEnvBaseUrl = envBaseUrl.trim();
    if (normalizedEnvBaseUrl.isNotEmpty) {
      return <String>[normalizedEnvBaseUrl];
    }

    if (isReleaseMode) {
      return const <String>[_releaseBaseUrl];
    }

    final List<String> urls = <String>[];
    if (Platform.isAndroid) {
      urls.add("http://10.0.2.2:8787");
    }
    urls.add("http://127.0.0.1:8787");
    urls.add("http://localhost:8787");
    urls.add(_releaseBaseUrl);
    return urls;
  }
}

class ReportApiException implements Exception {
  const ReportApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => "ReportApiException: $message";
}
