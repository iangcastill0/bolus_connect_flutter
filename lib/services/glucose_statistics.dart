import 'dart:math' as math;

import 'package:shared_preferences/shared_preferences.dart';
import 'bolus_log_service.dart';

class GlucoseStatistics {
  GlucoseStatistics({
    required this.averageGlucose,
    required this.standardDeviation,
    required this.variabilityPercent,
    required this.mostRecentGlucose,
    required this.glucoseUnit,
    required this.count,
    required this.rangeLow,
    required this.rangeHigh,
  });

  final double averageGlucose;
  final double standardDeviation;
  final double variabilityPercent;
  final double mostRecentGlucose;
  final String glucoseUnit;
  final int count;
  final double rangeLow;
  final double rangeHigh;

  static Future<GlucoseStatistics?> fromEntries(
    List<BolusLogEntry> entries, {
    Duration lookbackWindow = const Duration(hours: 12),
  }) async {
    if (entries.isEmpty) return null;

    // Load glucose range from preferences
    final prefs = await SharedPreferences.getInstance();
    final rangeLowMgdl = double.tryParse(prefs.getString('glucoseRangeLow') ?? '') ?? 70.0;
    final rangeHighMgdl = double.tryParse(prefs.getString('glucoseRangeHigh') ?? '') ?? 180.0;

    // Filter entries within lookback window
    final cutoff = DateTime.now().subtract(lookbackWindow);
    final recentEntries = entries
        .where((e) => e.timestamp.isAfter(cutoff) && e.glucose != null)
        .toList();

    if (recentEntries.isEmpty) return null;

    // Get most recent entry
    final mostRecent = recentEntries.first;

    // Convert all glucose values to mg/dL for consistent calculations
    final glucoseValues = recentEntries.map((e) {
      final glucose = e.glucose!;
      return e.glucoseUnit == 'mmol/L' ? glucose * 18.0 : glucose;
    }).toList();

    if (glucoseValues.isEmpty) return null;

    // Calculate average
    final sum = glucoseValues.reduce((a, b) => a + b);
    final average = sum / glucoseValues.length;

    // Calculate standard deviation
    final variance = glucoseValues
            .map((g) => math.pow(g - average, 2))
            .reduce((a, b) => a + b) /
        glucoseValues.length;
    final sd = math.sqrt(variance);

    // Calculate coefficient of variation (CV%) - a measure of variability
    final cvPercent = (sd / average) * 100;

    // Convert average back to user's preferred unit
    final averageInUserUnit = mostRecent.glucoseUnit == 'mmol/L'
        ? average / 18.0
        : average;

    final mostRecentGlucose = mostRecent.glucose!;

    // Convert range to user's preferred unit
    final rangeLowInUserUnit = mostRecent.glucoseUnit == 'mmol/L'
        ? rangeLowMgdl / 18.0
        : rangeLowMgdl;
    final rangeHighInUserUnit = mostRecent.glucoseUnit == 'mmol/L'
        ? rangeHighMgdl / 18.0
        : rangeHighMgdl;

    return GlucoseStatistics(
      averageGlucose: averageInUserUnit,
      standardDeviation: sd,
      variabilityPercent: cvPercent,
      mostRecentGlucose: mostRecentGlucose,
      glucoseUnit: mostRecent.glucoseUnit,
      count: glucoseValues.length,
      rangeLow: rangeLowInUserUnit,
      rangeHigh: rangeHighInUserUnit,
    );
  }

  String getVariabilityLabel() {
    if (variabilityPercent < 20) {
      return 'Stable';
    } else if (variabilityPercent < 30) {
      return 'Moderate';
    } else {
      return 'Variable';
    }
  }

  String getTimeInRangeLabel() {
    // This is a simplified label based on average and custom range
    final glucoseMgDl = glucoseUnit == 'mmol/L' ? averageGlucose * 18.0 : averageGlucose;
    final rangeLowMgDl = glucoseUnit == 'mmol/L' ? rangeLow * 18.0 : rangeLow;
    final rangeHighMgDl = glucoseUnit == 'mmol/L' ? rangeHigh * 18.0 : rangeHigh;

    if (glucoseMgDl < rangeLowMgDl) {
      return 'Low';
    } else if (glucoseMgDl <= rangeHighMgDl) {
      return 'In Range';
    } else {
      return 'High';
    }
  }
}
