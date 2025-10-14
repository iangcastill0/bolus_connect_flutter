import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

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

    return BolusLogEntry(
      timestamp: DateTime.tryParse(map['timestamp'] as String? ?? '') ?? DateTime.now(),
      glucose: castDouble(map['glucose']),
      glucoseUnit: map['glucoseUnit'] as String? ?? 'mg/dL',
      carbs: castDouble(map['carbs']),
      carbBolus: castDouble(map['carbBolus']) ?? 0,
      correctionBolus: castDouble(map['correctionBolus']) ?? 0,
      trendAdjustment: castDouble(map['trendAdjustment']) ?? 0,
      totalBolus: castDouble(map['totalBolus']) ?? 0,
      notes: map['notes'] as String?,
      id: map['id'] as String? ?? (map['timestamp'] as String? ?? '${DateTime.now().microsecondsSinceEpoch}'),
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
