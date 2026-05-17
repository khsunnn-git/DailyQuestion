import "dart:convert";
import "dart:io";

import "package:dailyquestion/features/report/report_api_client.dart";
import "package:dailyquestion/features/report/report_models.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  test("analyze uses explicit report api base url", () async {
    final HttpServer server = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      0,
    );
    addTearDown(() => server.close(force: true));

    server.listen((HttpRequest request) async {
      expect(request.method, "POST");
      expect(request.uri.path, "/v1/report/analyze");

      final String raw = await utf8.decoder.bind(request).join();
      final Map<String, dynamic> payload =
          jsonDecode(raw) as Map<String, dynamic>;
      expect(payload["period"], "monthly");

      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode(<String, Object?>{
          "summary": "테스트 요약",
          "emotion_summary": "테스트 감정 요약",
          "insights": <String>["인사이트 1"],
          "actions": <String>["액션 1"],
          "weekly_score": 4,
          "source": "ai",
        }),
      );
      await request.response.close();
    });

    final ReportApiClient client = ReportApiClient(
      baseUrl: "http://${server.address.address}:${server.port}",
    );

    final WeeklyAiReport report = await client.analyze(
      const ReportAnalyzePayload(
        period: "monthly",
        startDate: "2026-03-01",
        endDate: "2026-03-31",
        metrics: <String, Object?>{},
        days: <Map<String, Object?>>[],
        entriesCompact: <String>[],
        topKeywords: <String>[],
        representativeAnswers: <String>[],
      ),
    );

    expect(report.summary, "테스트 요약");
    expect(report.insights, const <String>["인사이트 1"]);
    expect(report.actions, const <String>["액션 1"]);
    expect(report.isFromOpenAi, isTrue);
  });

  test("analyzeOpenAiOnly rejects fallback responses", () async {
    final HttpServer server = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      0,
    );
    addTearDown(() => server.close(force: true));

    server.listen((HttpRequest request) async {
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode(<String, Object?>{
          "summary": "fallback",
          "emotion_summary": "fallback",
          "insights": <String>["인사이트 1"],
          "actions": <String>["액션 1"],
          "weekly_score": 4,
          "source": "server-fallback",
        }),
      );
      await request.response.close();
    });

    final ReportApiClient client = ReportApiClient(
      baseUrl: "http://${server.address.address}:${server.port}",
    );

    expect(
      () => client.analyzeOpenAiOnly(
        const ReportAnalyzePayload(
          period: "monthly",
          startDate: "2026-03-01",
          endDate: "2026-03-31",
          metrics: <String, Object?>{},
          days: <Map<String, Object?>>[],
          entriesCompact: <String>[],
          topKeywords: <String>[],
          representativeAnswers: <String>[],
        ),
      ),
      throwsA(isA<ReportApiException>()),
    );
  });

  test("explicit empty base url keeps report api client disabled", () {
    final ReportApiClient client = ReportApiClient(baseUrl: "");

    expect(client.isConfigured, isFalse);
  });

  test("release build falls back to deployed report api url", () {
    final ReportApiClient client = ReportApiClient(
      isReleaseMode: true,
      envBaseUrl: "",
    );

    expect(client.isConfigured, isTrue);
  });

  test("env base url is preferred over release default", () {
    final ReportApiClient client = ReportApiClient(
      isReleaseMode: true,
      envBaseUrl: "https://example.com/report",
    );

    expect(client.isConfigured, isTrue);
  });
}
