import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class HealthQuestionnaireService {
  HealthQuestionnaireService._();

  static const _storageKey = 'health_questionnaire_answers_by_user_v1';

  /// Returns true once the questionnaire has stored answers for [userId].
  static Future<bool> isCompletedForUser(String userId) async {
    final all = await _loadAll();
    return all[userId] is Map;
  }

  /// Persists answers for the signed-in [userId].
  static Future<void> saveAnswersForUser(
    String userId,
    Map<String, dynamic> answers,
  ) async {
    final all = await _loadAll();
    all[userId] = answers;
    await _saveAll(all);
  }

  /// Loads previously stored answers for [userId], if any.
  static Future<Map<String, dynamic>?> loadAnswersForUser(String userId) async {
    final all = await _loadAll();
    final entry = all[userId];
    if (entry is Map<String, dynamic>) {
      return entry;
    }
    if (entry is Map) {
      return entry.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }

  /// Removes stored answers for [userId].
  static Future<void> clearForUser(String userId) async {
    final all = await _loadAll();
    if (all.remove(userId) != null) {
      await _saveAll(all);
    }
  }

  /// Removes all stored questionnaire answers.
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  /// Marks the profile for [userId] as successfully synced at the current time.
  static Future<void> markSynced(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString == null) return;
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is! Map) return;
      final mutable =
          decoded.map((key, value) => MapEntry(key.toString(), value));
      final entry = mutable[userId];
      if (entry is Map) {
        entry['lastSyncedAt'] = DateTime.now().toIso8601String();
        mutable[userId] = entry;
        await prefs.setString(_storageKey, jsonEncode(mutable));
      }
    } catch (_) {
      // Ignore invalid persisted data.
    }
  }

  static Future<Map<String, dynamic>> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString == null) return <String, dynamic>{};
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    } catch (_) {
      // Ignore malformed data and fall through.
    }
    return <String, dynamic>{};
  }

  static Future<void> _saveAll(Map<String, dynamic> answersByUser) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(answersByUser));
  }
}
