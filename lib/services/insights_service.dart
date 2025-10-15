import 'package:flutter/material.dart';
import 'bolus_log_service.dart';

class InsightCard {
  InsightCard({
    required this.title,
    required this.message,
    required this.icon,
    this.color,
    this.data,
  });

  final String title;
  final String message;
  final IconData icon;
  final Color? color;
  final dynamic data; // Can hold chart data or other metadata
}

class InsightsService {
  InsightsService._();

  static Future<List<InsightCard>> generateInsights(
    List<BolusLogEntry> entries,
    String glucoseUnit,
  ) async {
    final insights = <InsightCard>[];

    // 1. Glucose Trend (last 12 hours)
    final glucoseTrendInsight = _generateGlucoseTrend(entries, glucoseUnit);
    if (glucoseTrendInsight != null) {
      insights.add(glucoseTrendInsight);
    }

    // 2. Stress & Cortisol Inference
    final stressInsight = _generateStressInsight(entries);
    if (stressInsight != null) {
      insights.add(stressInsight);
    }

    // 3. Nutrition Pattern
    final nutritionInsight = _generateNutritionInsight(entries);
    if (nutritionInsight != null) {
      insights.add(nutritionInsight);
    }

    // 4. Sleep & Recovery
    final sleepInsight = _generateSleepInsight(entries);
    if (sleepInsight != null) {
      insights.add(sleepInsight);
    }

    // 5. Activity Snapshot
    final activityInsight = _generateActivityInsight(entries);
    if (activityInsight != null) {
      insights.add(activityInsight);
    }

    // 6. Emotional State Summary
    final emotionalInsight = _generateEmotionalInsight(entries);
    if (emotionalInsight != null) {
      insights.add(emotionalInsight);
    }

    return insights;
  }

  static InsightCard? _generateGlucoseTrend(
    List<BolusLogEntry> entries,
    String glucoseUnit,
  ) {
    final cutoff = DateTime.now().subtract(const Duration(hours: 12));
    final recentGlucose = entries
        .where((e) => e.timestamp.isAfter(cutoff) && e.glucose != null)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp)); // Sort oldest to newest

    if (recentGlucose.isEmpty) {
      return InsightCard(
        title: 'Glucose Trend',
        message: 'Add glucose readings to see your pattern.',
        icon: Icons.trending_up,
        color: Colors.grey,
      );
    }

    // Convert to mg/dL for calculations
    final glucoseValues = recentGlucose.map((e) {
      final glucose = e.glucose!;
      return e.glucoseUnit == 'mmol/L' ? glucose * 18.0 : glucose;
    }).toList();

    // Calculate trend - compare most recent reading to oldest reading
    final firstReading = glucoseValues.first;  // Oldest (after sorting)
    final lastReading = glucoseValues.last;     // Most recent (after sorting)
    final diff = lastReading - firstReading;

    String message;
    Color? color;

    // Debug: Print to console
    print('Glucose Trend Analysis:');
    print('  First reading (oldest): ${firstReading.toStringAsFixed(1)} mg/dL');
    print('  Last reading (newest): ${lastReading.toStringAsFixed(1)} mg/dL');
    print('  Difference: ${diff.toStringAsFixed(1)} mg/dL');

    if (diff > 15) {
      message = 'Rising trend detected. Consider checking post-meal timing.';
      color = Colors.orange;
    } else if (diff < -15) {
      message = 'Lowering trend observed. Good control or check for lows.';
      color = Colors.green;
    } else {
      message = 'Stable pattern maintained over last 12 hours.';
      color = Colors.green;
    }

    // Prepare chart data points
    final chartData = recentGlucose
        .map((e) => {
              'time': e.timestamp,
              'glucose': e.glucoseUnit == 'mmol/L' ? e.glucose! * 18.0 : e.glucose!,
            })
        .toList();

    return InsightCard(
      title: 'Glucose Trend (12h)',
      message: message,
      icon: Icons.show_chart,
      color: color,
      data: chartData,
    );
  }

  static InsightCard? _generateStressInsight(List<BolusLogEntry> entries) {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final recentMoodEntries = entries
        .where((e) =>
            e.timestamp.isAfter(cutoff) &&
            e.notes != null &&
            e.notes!.contains('Stress Level:'))
        .toList();

    if (recentMoodEntries.isEmpty) {
      return null;
    }

    // Extract stress levels from notes
    final stressLevels = <int>[];
    for (final entry in recentMoodEntries) {
      final match = RegExp(r'Stress Level: (\d)').firstMatch(entry.notes!);
      if (match != null) {
        stressLevels.add(int.parse(match.group(1)!));
      }
    }

    if (stressLevels.isEmpty) return null;

    final avgStress = stressLevels.reduce((a, b) => a + b) / stressLevels.length;

    String message;
    Color? color;

    if (avgStress > 4) {
      message =
          'Stress levels elevated this week. Consider a short walk or breathing exercises.';
      color = Colors.red;
    } else if (avgStress > 3) {
      message =
          'Moderate stress detected. Try adding a relaxation routine after meals.';
      color = Colors.orange;
    } else {
      message = 'Stress levels stable. Keep up your current routine.';
      color = Colors.green;
    }

    return InsightCard(
      title: 'Stress & Cortisol',
      message: message,
      icon: Icons.psychology,
      color: color,
    );
  }

  static InsightCard? _generateNutritionInsight(List<BolusLogEntry> entries) {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final recentMeals = entries
        .where((e) =>
            e.timestamp.isAfter(cutoff) &&
            e.notes != null &&
            e.notes!.contains('Meal:'))
        .toList();

    if (recentMeals.isEmpty) {
      return null;
    }

    // Analyze carb patterns
    final dinnerMeals = recentMeals
        .where((e) => e.notes!.contains('Meal: Dinner') && e.carbs != null)
        .toList();

    if (dinnerMeals.isNotEmpty) {
      final avgDinnerCarbs =
          dinnerMeals.map((e) => e.carbs!).reduce((a, b) => a + b) /
              dinnerMeals.length;

      if (avgDinnerCarbs > 60) {
        return InsightCard(
          title: 'Nutrition Pattern',
          message:
              'High-carb dinner trend detected. Try adding protein earlier in the meal.',
          icon: Icons.restaurant_menu,
          color: Colors.orange,
        );
      }
    }

    // Check meal frequency
    final mealsPerDay = recentMeals.length / 7;
    if (mealsPerDay < 2) {
      return InsightCard(
        title: 'Nutrition Pattern',
        message:
            'Limited meal logging. Track more meals for better insights.',
        icon: Icons.restaurant_menu,
        color: Colors.blue,
      );
    }

    return InsightCard(
      title: 'Nutrition Pattern',
      message: 'Balanced meal timing observed. Keep logging for more insights.',
      icon: Icons.restaurant_menu,
      color: Colors.green,
    );
  }

  static InsightCard? _generateSleepInsight(List<BolusLogEntry> entries) {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final recentSleep = entries
        .where((e) =>
            e.timestamp.isAfter(cutoff) &&
            e.notes != null &&
            e.notes!.contains('Sleep:'))
        .toList();

    if (recentSleep.isEmpty) {
      return null;
    }

    // Extract sleep hours
    final sleepHours = <double>[];
    for (final entry in recentSleep) {
      final match = RegExp(r'Sleep: ([\d.]+) hours').firstMatch(entry.notes!);
      if (match != null) {
        sleepHours.add(double.parse(match.group(1)!));
      }
    }

    if (sleepHours.isEmpty) return null;

    final avgSleep = sleepHours.reduce((a, b) => a + b) / sleepHours.length;

    String message;
    Color? color;

    if (avgSleep < 6) {
      message =
          'Sleep average below 6 hours. Poor sleep can affect glucose control.';
      color = Colors.red;
    } else if (avgSleep < 7) {
      message =
          'Sleep improving but aim for 7+ hours for optimal glucose control.';
      color = Colors.orange;
    } else {
      message =
          'Consistent sleep pattern. Good foundation for glucose control.';
      color = Colors.green;
    }

    return InsightCard(
      title: 'Sleep & Recovery',
      message: message,
      icon: Icons.bedtime,
      color: color,
    );
  }

  static InsightCard? _generateActivityInsight(List<BolusLogEntry> entries) {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final recentExercise = entries
        .where((e) =>
            e.timestamp.isAfter(cutoff) &&
            e.notes != null &&
            e.notes!.contains('Exercise:'))
        .toList();

    if (recentExercise.isEmpty) {
      return InsightCard(
        title: 'Activity Snapshot',
        message:
            'No exercise logged this week. Even a 10-minute walk can help glucose control.',
        icon: Icons.directions_run,
        color: Colors.grey,
      );
    }

    // Count sessions this week
    final sessionsThisWeek = recentExercise.length;
    final targetSessions = 3; // WHO recommendation: 150 min/week ≈ 3 sessions

    String message;
    Color? color;

    if (sessionsThisWeek >= targetSessions) {
      message = 'Great work! You\'ve met your activity goal for this week.';
      color = Colors.green;
    } else {
      final remaining = targetSessions - sessionsThisWeek;
      message =
          'You\'re $remaining session${remaining == 1 ? '' : 's'} away from this week\'s movement goal.';
      color = Colors.blue;
    }

    return InsightCard(
      title: 'Activity Snapshot',
      message: message,
      icon: Icons.fitness_center,
      color: color,
    );
  }

  static InsightCard? _generateEmotionalInsight(List<BolusLogEntry> entries) {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final recentMood = entries
        .where((e) =>
            e.timestamp.isAfter(cutoff) &&
            e.notes != null &&
            e.notes!.contains('Mood:'))
        .toList();

    if (recentMood.isEmpty) {
      return null;
    }

    // Analyze mood patterns
    final moods = <String>[];
    for (final entry in recentMood) {
      final match = RegExp(r'Mood: ([^\n]+)').firstMatch(entry.notes!);
      if (match != null) {
        moods.add(match.group(1)!);
      }
    }

    if (moods.isEmpty) return null;

    final positiveMoods = moods
        .where((m) => m.contains('Happy') || m == 'Neutral')
        .length;
    final totalMoods = moods.length;
    final positiveRatio = positiveMoods / totalMoods;

    String message;
    Color? color;

    if (positiveRatio < 0.4) {
      message =
          'Mood has been low recently. Consider reaching out to your care team.';
      color = Colors.red;
    } else if (positiveRatio < 0.7) {
      message =
          'Mixed emotions this week. Short reflections after meals may help.';
      color = Colors.orange;
    } else {
      message = 'Motivation stable. Keep using positive habits and reflections.';
      color = Colors.green;
    }

    return InsightCard(
      title: 'Emotional State',
      message: message,
      icon: Icons.mood,
      color: color,
    );
  }
}
