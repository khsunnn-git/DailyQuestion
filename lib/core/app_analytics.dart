import "package:firebase_analytics/firebase_analytics.dart";
import "package:firebase_core/firebase_core.dart";
import "package:flutter/foundation.dart";
import "package:flutter/widgets.dart";

/// Thin wrapper around Firebase Analytics.
///
/// Every call is a no-op when Firebase failed to initialize (e.g. the
/// startup timeout in main.dart), and errors never propagate to callers.
class AppAnalytics {
  AppAnalytics._();

  static bool get _isAvailable => Firebase.apps.isNotEmpty;

  /// Navigator observers to attach to MaterialApp (empty if unavailable).
  static List<NavigatorObserver> navigatorObservers() {
    if (!_isAvailable) {
      return const <NavigatorObserver>[];
    }
    return <NavigatorObserver>[
      FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
    ];
  }

  /// Logged right after the user's answer is saved.
  static Future<void> logAnswerSubmitted({
    required bool isEdit,
    required bool isPublic,
    required bool hasBucketTags,
  }) {
    return _log("answer_submitted", <String, Object>{
      "is_edit": isEdit ? 1 : 0,
      "is_public": isPublic ? 1 : 0,
      "has_bucket_tags": hasBucketTags ? 1 : 0,
    });
  }

  static Future<void> _log(String name, Map<String, Object> parameters) async {
    if (!_isAvailable) {
      return;
    }
    try {
      await FirebaseAnalytics.instance.logEvent(
        name: name,
        parameters: parameters,
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint("[AppAnalytics] logEvent($name) failed: $error");
      }
    }
  }
}
