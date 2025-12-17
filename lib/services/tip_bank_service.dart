import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  /// Get user's selected health conditions
  Future<List<String>> _getUserConditions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        return ['none']; // Default to general wellness
      }

      final uid = user.uid;
      final answersJson = prefs.getString('health_questionnaire_answers_$uid');

      if (answersJson == null) {
        return ['none'];
      }

      final answers = json.decode(answersJson) as Map<String, dynamic>;
      final conditions = answers['conditions'] as List<dynamic>?;

      if (conditions == null || conditions.isEmpty) {
        return ['none'];
      }

      return conditions.cast<String>();
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

  /// Deduplicate tips
  List<String> _deduplicateTips(List<String> tips) {
    final List<String> unique = [];

    for (final tip in tips) {
      bool isDuplicate = false;

      for (final existingTip in unique) {
        if (_areTipsSimilar(tip, existingTip)) {
          isDuplicate = true;
          break;
        }
      }

      if (!isDuplicate) {
        unique.add(tip);
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

      if (conditions == null || conditions.isEmpty) {
        return null;
      }

      // Get user conditions
      final userConditions = await _getUserConditions();

      // Collect all tips from user's conditions
      final List<String> allTips = [];

      for (final conditionKey in userConditions) {
        final condition = conditions[conditionKey] as Map<String, dynamic>?;

        if (condition == null) {
          continue;
        }

        final tips = condition['tips'] as Map<String, dynamic>?;

        if (tips == null) {
          continue;
        }

        final timeTips = tips[timeBlockName] as List<dynamic>?;

        if (timeTips != null) {
          allTips.addAll(timeTips.cast<String>());
        }
      }

      // If no tips found, fall back to general wellness
      if (allTips.isEmpty) {
        final noneCondition = conditions['none'] as Map<String, dynamic>?;

        if (noneCondition != null) {
          final tips = noneCondition['tips'] as Map<String, dynamic>?;
          if (tips != null) {
            final timeTips = tips[timeBlockName] as List<dynamic>?;
            if (timeTips != null) {
              allTips.addAll(timeTips.cast<String>());
            }
          }
        }
      }

      if (allTips.isEmpty) {
        return null;
      }

      // Deduplicate tips
      final uniqueTips = _deduplicateTips(allTips);

      // Filter out recently shown tips
      final history = await _getTipHistory();
      final availableTips = uniqueTips.where((tip) {
        return !history.any((historyTip) => _areTipsSimilar(tip, historyTip));
      }).toList();

      // If all tips have been shown recently, reset and use all unique tips
      final tipsToUse = availableTips.isEmpty ? uniqueTips : availableTips;

      if (tipsToUse.isEmpty) {
        return null;
      }

      // Select random tip seeded by current date (so same tip all day)
      final today = DateTime.now().toIso8601String().split('T')[0];
      final seed = today.hashCode + timeBlock.index;
      final random = Random(seed);
      final selectedTip = tipsToUse[random.nextInt(tipsToUse.length)];

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
}
