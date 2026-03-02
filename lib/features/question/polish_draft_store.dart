import "dart:convert";

import "package:shared_preferences/shared_preferences.dart";

class PolishDraftStore {
  PolishDraftStore._();

  static final PolishDraftStore instance = PolishDraftStore._();

  static const String _storageKey = "question_polish_drafts_v1";

  Future<void> saveDraft({
    required String key,
    required String originalText,
    required String polishedText,
  }) async {
    final String normalizedKey = key.trim();
    if (normalizedKey.isEmpty) {
      return;
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> all = _readMap(prefs.getString(_storageKey));
    all[normalizedKey] = <String, Object?>{
      "original_text": originalText,
      "polished_text": polishedText,
      "updated_at_ms": DateTime.now().millisecondsSinceEpoch,
    };
    await prefs.setString(_storageKey, jsonEncode(all));
  }

  Future<Map<String, dynamic>?> readDraft(String key) async {
    final String normalizedKey = key.trim();
    if (normalizedKey.isEmpty) {
      return null;
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> all = _readMap(prefs.getString(_storageKey));
    final Object? raw = all[normalizedKey];
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    if (raw is Map) {
      return raw.map(
        (Object? k, Object? v) => MapEntry<String, dynamic>(k.toString(), v),
      );
    }
    return null;
  }

  Map<String, dynamic> _readMap(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return <String, dynamic>{};
    }
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return decoded.map(
          (Object? k, Object? v) => MapEntry<String, dynamic>(k.toString(), v),
        );
      }
      return <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }
}
