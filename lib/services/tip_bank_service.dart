import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'health_questionnaire_service.dart';

/// Time block for tips
enum TimeBlock {
  morning, // 04:00-11:59
  afternoon, // 12:00-17:59
  evening, // 18:00-23:59
  late, // 00:00-03:59 (shows evening tips)
}

/// Service for managing health tips based on user conditions
class TipBankService {
  static const String _tipHistoryKey = 'tip_history';
  static const String _lastShownDateKey = 'last_shown_date';
  static const int _maxHistorySize = 7; // Keep last 7 tips
  static const String _legacyPrefsKeyPrefix = 'health_questionnaire_answers_';
  static const Map<String, String> _codeAliases = {
    'i10': 'hypertension',
    'hypertension': 'hypertension',
    'i11': 'hypertension',
    'i12': 'hypertension',
    'i13': 'hypertension',
    'i25.10': 'hypertension',
    'i25.2': 'hypertension',
    'i20.9': 'hypertension',
    'i50.9': 'hypertension',
    'i50.2': 'hypertension',
    'i73.9': 'hypertension',
    'e78.5': 'dyslipidemia',
    'e78.0': 'dyslipidemia',
    'e78.1': 'dyslipidemia',
    'e78.6': 'dyslipidemia',
    'e11': 'type2_diabetes',
    'r73.01': 'type2_diabetes',
    'r73.03': 'type2_diabetes',
    'e88.81': 'type2_diabetes',
    'e66.9': 'obesity',
    'e66.01': 'obesity',
    'e66.02': 'obesity',
    'k76.0': 'nafld',
    'k75.81': 'nafld',
    'k21.9': 'gerd',
    'k58.9': 'gerd',
    'e28.2': 'pcos',
    'e03.9': 'none',
    'e06.3': 'none',
    'e05.90': 'none',
    'e55.9': 'none',
    'e29.1': 'none',
    'g47.33': 'sleep_apnea',
    'f51.04': 'insomnia',
    'g47.30': 'sleep_apnea',
    'n18.1': 'ckd',
    'n18.2': 'ckd',
    'n18.3': 'ckd',
    'n18.4': 'ckd',
    'n18.5': 'ckd',
    'n18.6': 'ckd',
    'e11.21': 'ckd',
    'm06.9': 'rheumatoid_arthritis',
    'l40.50': 'rheumatoid_arthritis',
    'l40.0': 'rheumatoid_arthritis',
    'f33.9': 'depression',
    'f41.1': 'anxiety',
    'm10.9': 'none',
    'e79.0': 'none',
    'g43.909': 'migraine',
    'd64.9': 'none',
  };

  /// Load tip bank from assets
  Future<Map<String, dynamic>> _loadTipBank() async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/tip_bank.json');
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      // If tip bank fails to load, return empty structure
      return {'conditions': {}};
    }
  }

  /// Get current time block based on device local time
  TimeBlock getCurrentTimeBlock() {
    final now = DateTime.now();
    final hour = now.hour;

    if (hour >= 4 && hour < 12) {
      return TimeBlock.morning;
    } else if (hour >= 12 && hour < 18) {
      return TimeBlock.afternoon;
    } else if (hour >= 18 && hour < 24) {
      return TimeBlock.evening;
    } else {
      // Late night (00:00-03:59) shows evening tips
      return TimeBlock.late;
    }
  }

  /// Get time block name for JSON lookup
  String _getTimeBlockName(TimeBlock block) {
    switch (block) {
      case TimeBlock.morning:
        return 'morning';
      case TimeBlock.afternoon:
        return 'afternoon';
      case TimeBlock.evening:
      case TimeBlock.late:
        return 'evening';
    }
  }

  /// Get user's selected health conditions (ICD-10 codes where available).
  Future<List<String>> _getUserConditions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return ['none'];

      final uid = user.uid;

      // New baseline store (supports codes)
      final baselineAnswers =
          await HealthQuestionnaireService.loadAnswersForUser(uid);
      final baseline = baselineAnswers?['baseline'] as Map<String, dynamic>?;
      final medical = baseline?['medical'] as Map<String, dynamic>?;
      final conditions = medical?['conditions'] as List<dynamic>?;
      if (conditions != null && conditions.isNotEmpty) {
        final codes = conditions
            .map((c) {
              if (c is Map) return (c['code'] ?? c['label'])?.toString();
              return c?.toString();
            })
            .whereType<String>()
            .map((c) => c.trim())
            .where((c) => c.isNotEmpty)
            .toList();
        if (codes.isNotEmpty) return codes;
      }

      // Legacy storage fallback
      final legacyJson = prefs.getString('$_legacyPrefsKeyPrefix$uid');
      if (legacyJson != null) {
        final decoded = json.decode(legacyJson);
        if (decoded is Map<String, dynamic>) {
          final legacyConditions = decoded['conditions'] as List<dynamic>?;
          if (legacyConditions != null && legacyConditions.isNotEmpty) {
            return legacyConditions
                .map((c) => c.toString().trim())
                .where((c) => c.isNotEmpty)
                .toList();
          }
        }
      }

      return ['none']; // Default to general wellness
    } catch (e) {
      return ['none'];
    }
  }

  /// Get tip history for current user
  Future<List<String>> _getTipHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        return [];
      }

      final uid = user.uid;
      final historyJson = prefs.getString('${_tipHistoryKey}_$uid');

      if (historyJson == null) {
        return [];
      }

      final history = json.decode(historyJson) as List<dynamic>;
      return history.cast<String>();
    } catch (e) {
      return [];
    }
  }

  /// Save tip to history
  Future<void> _saveTipToHistory(String tip) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        return;
      }

      final uid = user.uid;
      final history = await _getTipHistory();

      // Add tip to history
      history.insert(0, tip);

      // Keep only last N tips
      if (history.length > _maxHistorySize) {
        history.removeRange(_maxHistorySize, history.length);
      }

      await prefs.setString('${_tipHistoryKey}_$uid', json.encode(history));
    } catch (e) {
      // Silently fail
    }
  }

  /// Check if we already showed a tip today
  Future<String?> _getLastShownDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        return null;
      }

      final uid = user.uid;
      return prefs.getString('${_lastShownDateKey}_$uid');
    } catch (e) {
      return null;
    }
  }

  /// Save today's date as last shown
  Future<void> _saveLastShownDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        return;
      }

      final uid = user.uid;
      final today = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD
      await prefs.setString('${_lastShownDateKey}_$uid', today);
    } catch (e) {
      // Silently fail
    }
  }

  /// Simple fuzzy match to detect similar tips
  bool _areTipsSimilar(String tip1, String tip2) {
    // Normalize: lowercase and remove extra spaces
    final normalized1 = tip1.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
    final normalized2 = tip2.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');

    // Exact match
    if (normalized1 == normalized2) {
      return true;
    }

    // Check if one contains most of the other (simple similarity)
    final words1 = normalized1.split(' ').where((w) => w.length > 3).toSet();
    final words2 = normalized2.split(' ').where((w) => w.length > 3).toSet();

    if (words1.isEmpty || words2.isEmpty) {
      return false;
    }

    final intersection = words1.intersection(words2).length;
    final union = words1.union(words2).length;

    // If more than 70% of words overlap, consider similar
    return (intersection / union) > 0.7;
  }

  /// Deduplicate tips while preserving weight counts for overlaps.
  List<({String tip, int weight})> _deduplicateTipsWithWeights(
    Map<String, int> weightedTips,
  ) {
    final List<({String tip, int weight})> unique = [];

    for (final entry in weightedTips.entries) {
      final tip = entry.key;
      final weight = entry.value;
      bool merged = false;

      for (var i = 0; i < unique.length; i++) {
        final existing = unique[i];
        if (_areTipsSimilar(tip, existing.tip)) {
          unique[i] = (tip: existing.tip, weight: existing.weight + weight);
          merged = true;
          break;
        }
      }

      if (!merged) {
        unique.add((tip: tip, weight: weight));
      }
    }

    return unique;
  }

  /// Get tip for current time and conditions
  Future<String?> getTipOfTheDay({bool force = false}) async {
    try {
      // Check if we already showed a tip today (unless forced)
      if (!force) {
        final lastShownDate = await _getLastShownDate();
        final today = DateTime.now().toIso8601String().split('T')[0];

        if (lastShownDate == today) {
          // Already showed tip today, return null
          return null;
        }
      }

      // Get time block
      final timeBlock = getCurrentTimeBlock();
      final timeBlockName = _getTimeBlockName(timeBlock);

      // Load tip bank
      final tipBank = await _loadTipBank();
      final conditions = tipBank['conditions'] as Map<String, dynamic>?;
      if (conditions == null || conditions.isEmpty) return null;

      // Build index by ICD code for faster matching
      final Map<String, Map<String, dynamic>> codeIndex = {};
      conditions.forEach((key, value) {
        if (value is! Map<String, dynamic>) return;
        final icd = value['icd10']?.toString() ?? '';
        final codes = _extractCodes(icd)..add(key.toLowerCase());
        for (final code in codes) {
          if (code.isEmpty) continue;
          codeIndex[code] = value;
        }
      });

      final userConditions = await _getUserConditions();

      // Collect weighted tips; overlapping conditions increase weight
      final Map<String, int> weightedTips = {};
      for (final userCodeRaw in userConditions) {
        final codeKey = userCodeRaw.toLowerCase();
        final canonicalKey = (_codeAliases[codeKey] ?? codeKey).toLowerCase();
        final condition = codeIndex[canonicalKey] ??
            (conditions[canonicalKey] as Map<String, dynamic>?) ??
            codeIndex[codeKey] ??
            (conditions[codeKey] as Map<String, dynamic>?);
        if (condition == null) continue;

        final tips = condition['tips'] as Map<String, dynamic>?;
        if (tips == null) continue;
        final timeTips = tips[timeBlockName] as List<dynamic>?;
        if (timeTips == null) continue;

        for (final tip in timeTips.cast<String>()) {
          weightedTips[tip] = (weightedTips[tip] ?? 0) + 1;
        }
      }

      // If no tips found, fall back to general wellness
      if (weightedTips.isEmpty) {
        final noneCondition = conditions['none'] as Map<String, dynamic>?;
        final tips = noneCondition?['tips'] as Map<String, dynamic>?;
        final timeTips = tips?[timeBlockName] as List<dynamic>?;
        if (timeTips != null) {
          for (final tip in timeTips.cast<String>()) {
            weightedTips[tip] = (weightedTips[tip] ?? 0) + 1;
          }
        }
      }

      if (weightedTips.isEmpty) return null;

      // Deduplicate with fuzzy match and carry combined weights
      final uniqueTips = _deduplicateTipsWithWeights(weightedTips);

      // Filter out recently shown tips
      final history = await _getTipHistory();
      final availableTips = uniqueTips.where((entry) {
        return !history.any((historyTip) => _areTipsSimilar(entry.tip, historyTip));
      }).toList();

      // If all tips have been shown recently, reset and use all unique tips
      final tipsToUse = availableTips.isEmpty ? uniqueTips : availableTips;

      if (tipsToUse.isEmpty) {
        return null;
      }

      // Select weighted random tip seeded by current date (so same tip all day)
      final today = DateTime.now().toIso8601String().split('T')[0];
      final seed = today.hashCode + timeBlock.index;
      final random = Random(seed);
      final totalWeight =
          tipsToUse.fold<int>(0, (sum, t) => sum + max(1, t.weight));
      final roll = random.nextInt(totalWeight);
      int cumulative = 0;
      String selectedTip = tipsToUse.first.tip;
      for (final entry in tipsToUse) {
        cumulative += max(1, entry.weight);
        if (roll < cumulative) {
          selectedTip = entry.tip;
          break;
        }
      }

      // Save to history and mark as shown today
      await _saveTipToHistory(selectedTip);
      await _saveLastShownDate();

      return selectedTip;
    } catch (e) {
      // Return null on error
      return null;
    }
  }

  /// Clear tip history (useful for testing)
  Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        return;
      }

      final uid = user.uid;
      await prefs.remove('${_tipHistoryKey}_$uid');
      await prefs.remove('${_lastShownDateKey}_$uid');
    } catch (e) {
      // Silently fail
    }
  }

  /// Extract normalized codes from an icd10 string (supports delimiters like /, comma, dash).
  Set<String> _extractCodes(String icdRaw) {
    final cleaned = icdRaw.replaceAll('–', '-');
    final parts = cleaned.split(RegExp(r'[\\/,\s]'));
    final codes = <String>{};
    for (final part in parts) {
      final trimmed = part.trim().toLowerCase();
      if (trimmed.isEmpty) continue;
      codes.add(trimmed);
      // Keep upper-case variant for lookups
      codes.add(trimmed.toUpperCase());
    }
    final tokenMatches =
        RegExp(r'[A-Za-z]\d+(?:\.\d+)?').allMatches(cleaned.toUpperCase());
    for (final m in tokenMatches) {
      codes.add(m.group(0)!);
      codes.add(m.group(0)!.toLowerCase());
    }
    return codes;
  }
}
