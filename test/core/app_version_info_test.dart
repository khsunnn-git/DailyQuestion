import "package:dailyquestion/core/app_version_info.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  test("parses the current app version from pubspec contents", () {
    const String pubspec = """
name: dailyquestion
version: 2.0.4+43
""";

    final AppVersionInfo versionInfo = AppVersionInfo.parsePubspec(pubspec);

    expect(versionInfo.rawVersion, "2.0.4+43");
    expect(versionInfo.displayLabel, "v2.0.4+43 최신 버전");
  });

  test("falls back when the version line is missing", () {
    final AppVersionInfo versionInfo = AppVersionInfo.parsePubspec("name: app");

    expect(versionInfo, AppVersionInfo.unknown);
  });
}
