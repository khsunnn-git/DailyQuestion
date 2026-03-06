import "dart:async";
import "dart:convert";
import "dart:io";

import "../question/today_question_store.dart";

class MatgimKeywordApiClient {
  MatgimKeywordApiClient({
    String? endpoint,
    String? authToken,
    HttpClient? httpClient,
    Duration? timeout,
  }) : _endpoint =
           (endpoint ??
                   const String.fromEnvironment(
                     "MATGIM_KEYWORD_API_URL",
                     defaultValue: "https://api.matgim.ai/54edkvw2hn/api-keyword",
                   ))
               .trim(),
       _authToken =
           (authToken ?? const String.fromEnvironment("MATGIM_AUTH_TOKEN")).trim(),
       _httpClient = httpClient ?? HttpClient(),
       _timeout = timeout ?? const Duration(seconds: 10);

  final String _endpoint;
  final String _authToken;
  final HttpClient _httpClient;
  final Duration _timeout;

  bool get isConfigured => _endpoint.isNotEmpty && _authToken.isNotEmpty;

  Future<Map<String, int>> extractFromRecords(
    List<TodayQuestionRecord> records, {
    int keywordCount = 12,
  }) async {
    if (!isConfigured) {
      throw const MatgimKeywordApiException(
        "MATGIM_KEYWORD_API_URL or MATGIM_AUTH_TOKEN is not configured.",
      );
    }

    final String query = _buildQuery(records);
    if (query.trim().isEmpty) {
      return const <String, int>{};
    }

    final Uri uri = Uri.parse(_endpoint);
    final HttpClientRequest request = await _httpClient
        .postUrl(uri)
        .timeout(_timeout);
    request.headers.set(HttpHeaders.contentTypeHeader, "application/json");
    request.headers.set("x-auth-token", _authToken);
    request.add(
      utf8.encode(
        jsonEncode(<String, Object>{
          "queryString": query,
          "keyword_count": keywordCount,
        }),
      ),
    );

    final HttpClientResponse response = await request.close().timeout(_timeout);
    final String raw = await utf8.decoder.bind(response).join();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw MatgimKeywordApiException(
        "Keyword API failed with ${response.statusCode}: $raw",
      );
    }

    final Object? decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const MatgimKeywordApiException(
        "Keyword API response is not JSON object.",
      );
    }

    final Object? status = decoded["status"];
    if (status != "success") {
      final Object? message = decoded["message"];
      throw MatgimKeywordApiException(
        "Keyword API returned non-success status: $status ${message ?? ""}",
      );
    }

    final Object? keywords = decoded["keywords"];
    if (keywords is! Map) {
      return const <String, int>{};
    }

    final Map<String, int> result = <String, int>{};
    for (final MapEntry<dynamic, dynamic> entry in keywords.entries) {
      final String key = entry.key?.toString().trim() ?? "";
      if (key.isEmpty) {
        continue;
      }
      final int value = _toInt(entry.value);
      if (value <= 0) {
        continue;
      }
      result[key] = value;
    }
    return result;
  }

  static int _toInt(Object? value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) {
      final int? parsed = int.tryParse(value);
      if (parsed != null) return parsed;
      final double? asDouble = double.tryParse(value);
      if (asDouble != null) return asDouble.round();
    }
    return 0;
  }

  String _buildQuery(List<TodayQuestionRecord> records) {
    final StringBuffer buffer = StringBuffer();
    for (final TodayQuestionRecord record in records) {
      final String answer = record.answer.trim();
      if (answer.isNotEmpty) {
        buffer.writeln(answer);
      }
      for (final String tag in record.bucketTags) {
        final String normalized = tag.trim();
        if (normalized.isNotEmpty) {
          buffer.writeln(normalized);
        }
      }
      if (record.bucketTag != null && record.bucketTag!.trim().isNotEmpty) {
        buffer.writeln(record.bucketTag!.trim());
      }
    }
    return buffer.toString().trim();
  }
}

class MatgimKeywordApiException implements Exception {
  const MatgimKeywordApiException(this.message);

  final String message;

  @override
  String toString() => "MatgimKeywordApiException: $message";
}
