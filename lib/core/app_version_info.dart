import "package:flutter/services.dart";

class AppVersionInfo {
  const AppVersionInfo({required this.rawVersion});

  static const AppVersionInfo unknown = AppVersionInfo(rawVersion: "버전 정보 없음");
  static const String _pubspecAssetPath = "pubspec.yaml";
  static final RegExp _versionPattern = RegExp(
    r"^version:\s*([^\s#]+)",
    multiLine: true,
  );

  final String rawVersion;

  String get displayLabel {
    if (rawVersion == unknown.rawVersion) {
      return rawVersion;
    }
    return "v$rawVersion 최신 버전";
  }

  static Future<AppVersionInfo> load({AssetBundle? bundle}) async {
    try {
      final AssetBundle assetBundle = bundle ?? rootBundle;
      final String pubspec = await assetBundle.loadString(_pubspecAssetPath);
      return parsePubspec(pubspec);
    } catch (_) {
      return unknown;
    }
  }

  static AppVersionInfo parsePubspec(String pubspecContents) {
    final RegExpMatch? match = _versionPattern.firstMatch(pubspecContents);
    final String? rawVersion = match?.group(1)?.trim();
    if (rawVersion == null || rawVersion.isEmpty) {
      return unknown;
    }
    return AppVersionInfo(rawVersion: rawVersion);
  }
}
