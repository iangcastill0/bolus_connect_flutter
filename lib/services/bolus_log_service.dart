import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Canonical exercise log structure
/// Corresponds to logs.exercise[] from data dictionary
class ExerciseLog {
  const ExerciseLog({
    required this.ts,
    required this.type,
    required this.durationMin,
    required this.intensity,
    this.rpe,
    this.note,
  });

  final DateTime ts;
  final String type; // e.g., "Running", "Swimming", "Walking"
  final int durationMin;
  final String intensity; // "low" | "mod" | "vig"
  final int? rpe; // Rate of Perceived Exertion (1-10 scale)
  final String? note;

  Map<String, dynamic> toMap() => {
        'ts': ts.toIso8601String(),
        'type': type,
        'duration_min': durationMin,
        'intensity': intensity,
        if (rpe != null) 'rpe_1_10': rpe,
        if (note != null) 'note': note,
      };

  factory ExerciseLog.fromMap(Map<String, dynamic> map) {
    return ExerciseLog(
      ts: DateTime.tryParse(map['ts'] as String? ?? '') ?? DateTime.now(),
      type: map['type'] as String? ?? '',
      durationMin: map['duration_min'] as int? ?? 0,
      intensity: map['intensity'] as String? ?? 'mod',
      rpe: map['rpe_1_10'] as int?,
      note: map['note'] as String?,
    );
  }
}

/// Canonical sleep log structure
/// Corresponds to logs.sleep[] from data dictionary
class SleepLog {
  const SleepLog({
    required this.bedtime,
    required this.wakeup,
    required this.durationH,
    required this.quality,
    this.note,
  });

  final DateTime bedtime;
  final DateTime wakeup;
  final double durationH;
  final int quality; // 1-5 scale
  final String? note;

  Map<String, dynamic> toMap() => {
        'bedtime': bedtime.toIso8601String(),
        'wakeup': wakeup.toIso8601String(),
        'duration_h': durationH,
        'quality_1_5': quality,
        if (note != null) 'note': note,
      };

  factory SleepLog.fromMap(Map<String, dynamic> map) {
    return SleepLog(
      bedtime: DateTime.tryParse(map['bedtime'] as String? ?? '') ??
          DateTime.now(),
      wakeup: DateTime.tryParse(map['wakeup'] as String? ?? '') ??
          DateTime.now(),
      durationH: (map['duration_h'] as num?)?.toDouble() ?? 0.0,
      quality: map['quality_1_5'] as int? ?? 3,
      note: map['note'] as String?,
    );
  }
}

/// Canonical mood log structure
/// Corresponds to logs.mood[] from data dictionary
class MoodLog {
  const MoodLog({
    required this.ts,
    required this.stress,
    this.note,
  });

  final DateTime ts;
  final int stress; // 1-5 scale
  final String? note;

  Map<String, dynamic> toMap() => {
        'ts': ts.toIso8601String(),
        'stress_1_5': stress,
        if (note != null) 'note': note,
      };

  factory MoodLog.fromMap(Map<String, dynamic> map) {
    return MoodLog(
      ts: DateTime.tryParse(map['ts'] as String? ?? '') ?? DateTime.now(),
      stress: map['stress_1_5'] as int? ?? 3,
      note: map['note'] as String?,
    );
  }
}

class BolusLogEntry {
  BolusLogEntry({
    required this.timestamp,
    this.glucose,
    required this.glucoseUnit,
    this.carbs,
    required this.carbBolus,
    required this.correctionBolus,
    required this.trendAdjustment,
    required this.totalBolus,
    this.notes,
    String? id,
    this.exerciseLog,
    this.sleepLog,
    this.moodLog,
  }) : id = id ?? '${timestamp.microsecondsSinceEpoch}';

  final DateTime timestamp;
  final double? glucose;
  final String glucoseUnit;
  final double? carbs;
  final double carbBolus;
  final double correctionBolus;
  final double trendAdjustment;
  final double totalBolus;
  final String? notes;
  final String id;

  // Canonical log structures
  final ExerciseLog? exerciseLog;
  final SleepLog? sleepLog;
  final MoodLog? moodLog;

  Map<String, dynamic> toMap() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'glucose': glucose,
        'glucoseUnit': glucoseUnit,
        'carbs': carbs,
        'carbBolus': carbBolus,
        'correctionBolus': correctionBolus,
        'trendAdjustment': trendAdjustment,
        'totalBolus': totalBolus,
        'notes': notes,
        // Canonical log structures
        if (exerciseLog != null) 'exerciseLog': exerciseLog!.toMap(),
        if (sleepLog != null) 'sleepLog': sleepLog!.toMap(),
        if (moodLog != null) 'moodLog': moodLog!.toMap(),
      };

  String toJson() => jsonEncode(toMap());

  factory BolusLogEntry.fromJson(String jsonStr) {
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    return BolusLogEntry.fromMap(map);
  }

  factory BolusLogEntry.fromMap(Map<String, dynamic> map) {
    double? castDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    ExerciseLog? parseExerciseLog(dynamic value) {
      if (value == null) return null;
      if (value is Map<String, dynamic>) {
        try {
          return ExerciseLog.fromMap(value);
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    SleepLog? parseSleepLog(dynamic value) {
      if (value == null) return null;
      if (value is Map<String, dynamic>) {
        try {
          return SleepLog.fromMap(value);
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    MoodLog? parseMoodLog(dynamic value) {
      if (value == null) return null;
      if (value is Map<String, dynamic>) {
        try {
          return MoodLog.fromMap(value);
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    return BolusLogEntry(
      timestamp: DateTime.tryParse(map['timestamp'] as String? ?? '') ??
          DateTime.now(),
      glucose: castDouble(map['glucose']),
      glucoseUnit: map['glucoseUnit'] as String? ?? 'mg/dL',
      carbs: castDouble(map['carbs']),
      carbBolus: castDouble(map['carbBolus']) ?? 0,
      correctionBolus: castDouble(map['correctionBolus']) ?? 0,
      trendAdjustment: castDouble(map['trendAdjustment']) ?? 0,
      totalBolus: castDouble(map['totalBolus']) ?? 0,
      notes: map['notes'] as String?,
      id: map['id'] as String? ??
          (map['timestamp'] as String? ??
              '${DateTime.now().microsecondsSinceEpoch}'),
      exerciseLog: parseExerciseLog(map['exerciseLog']),
      sleepLog: parseSleepLog(map['sleepLog']),
      moodLog: parseMoodLog(map['moodLog']),
    );
  }
}

class BolusLogService {
  BolusLogService._();

  static const _storageKey = 'bolus_log_entries_v1';
  static const _maxEntries = 100;

  static Future<List<BolusLogEntry>> loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_storageKey) ?? <String>[];
    return stored
        .map((jsonStr) {
          try {
            return BolusLogEntry.fromJson(jsonStr);
          } catch (_) {
            return null;
          }
        })
        .whereType<BolusLogEntry>()
        .toList();
  }

  static Future<void> addEntry(BolusLogEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_storageKey) ?? <String>[];
    stored.insert(0, entry.toJson());
    if (stored.length > _maxEntries) {
      stored.removeRange(_maxEntries, stored.length);
    }
    await prefs.setStringList(_storageKey, stored);
  }

  static Future<void> removeEntry(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_storageKey) ?? <String>[];
    stored.removeWhere((jsonStr) {
      try {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        final entryId = map['id'] as String? ?? map['timestamp'] as String?;
        return entryId == id;
      } catch (_) {
        return false;
      }
    });
    await prefs.setStringList(_storageKey, stored);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
