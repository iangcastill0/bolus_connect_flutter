import 'package:flutter/material.dart';

/// Summary screen showing synthesized health profile results
/// Displays after user completes health questionnaire for first time
class ProfileSummaryPage extends StatelessWidget {
  const ProfileSummaryPage({
    super.key,
    required this.metrics,
  });

  final ProfileMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false, // Prevent back button from dismissing
      child: Scaffold(
        body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              // Header
              Icon(
                Icons.analytics_outlined,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Your Starting Profile',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'These scores are not diagnoses. They help us tailor insights, habits, and reminders to your rhythm.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Metrics Cards
              _MetricCard(
                icon: Icons.fitness_center,
                title: 'Activity Index',
                value: metrics.activityLabel,
                score: metrics.activityIndex,
                color: _getActivityColor(metrics.activityIndex),
              ),
              const SizedBox(height: 16),
              _MetricCard(
                icon: Icons.psychology,
                title: 'Stress Load',
                value: metrics.stressLabel,
                score: metrics.stressLoad,
                color: _getStressColor(metrics.stressLoad),
              ),
              const SizedBox(height: 16),
              _MetricCard(
                icon: Icons.bedtime,
                title: 'Sleep Quality',
                value: metrics.sleepLabel,
                score: metrics.sleepQuality,
                color: _getSleepColor(metrics.sleepQuality),
              ),
              const SizedBox(height: 16),
              _MetricCard(
                icon: Icons.restaurant,
                title: 'Nutrition Quality',
                value: metrics.nutritionLabel,
                score: metrics.nutritionQuality,
                color: _getNutritionColor(metrics.nutritionQuality),
              ),
              const SizedBox(height: 16),
              _MetricCard(
                icon: Icons.favorite,
                title: 'Emotional Wellbeing',
                value: metrics.emotionalWellbeingLabel,
                score: metrics.emotionalWellbeing,
                color: _getEmotionalColor(metrics.emotionalWellbeing),
              ),

              const SizedBox(height: 40),

              // Continue Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _handleContinue(context),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Continue to App',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      ),
    );
  }

  void _handleContinue(BuildContext context) {
    // Return to main app by popping the summary screen
    // This allows the caller to continue with any additional setup steps
    Navigator.of(context).pop();
  }

  Color _getActivityColor(int score) {
    if (score >= 70) return Colors.green;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  Color _getStressColor(int score) {
    if (score <= 40) return Colors.green;
    if (score <= 70) return Colors.orange;
    return Colors.red;
  }

  Color _getSleepColor(int score) {
    if (score >= 70) return Colors.green;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  Color _getNutritionColor(int score) {
    if (score >= 70) return Colors.green;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  Color _getEmotionalColor(int score) {
    if (score >= 60) return Colors.green;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.score,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String value;
  final int score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$score/100',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    children: [
                      Center(
                        child: SizedBox(
                          width: 80,
                          height: 80,
                          child: CircularProgressIndicator(
                            value: score / 100,
                            strokeWidth: 8,
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          '$score',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Synthesized health profile metrics
class ProfileMetrics {
  const ProfileMetrics({
    required this.activityIndex,
    required this.activityLabel,
    required this.stressLoad,
    required this.stressLabel,
    required this.sleepQuality,
    required this.sleepLabel,
    required this.nutritionQuality,
    required this.nutritionLabel,
    required this.emotionalWellbeing,
    required this.emotionalWellbeingLabel,
    required this.completedAt,
  });

  final int activityIndex; // 0-100
  final String activityLabel; // e.g., "Moderate (58/100)"
  final int stressLoad; // 0-100
  final String stressLabel; // e.g., "High (72/100)"
  final int sleepQuality; // 0-100
  final String sleepLabel; // e.g., "Fair (60/100)"
  final int nutritionQuality; // 0-100
  final String nutritionLabel; // e.g., "Balanced (67/100)"
  final int emotionalWellbeing; // 0-100
  final String emotionalWellbeingLabel; // e.g., "Stable" or "Support Recommended"
  final DateTime completedAt;

  /// Calculate metrics from health questionnaire answers
  factory ProfileMetrics.fromAnswers(Map<String, dynamic> answers) {
    // Data is nested under 'baseline' key in the questionnaire answers
    final baseline = answers['baseline'] as Map<String, dynamic>?;

    final activityData = baseline?['activity'] as Map<String, dynamic>?;
    final stressData = baseline?['stress'] as Map<String, dynamic>?;
    final sleepData = baseline?['sleep'] as Map<String, dynamic>?;
    final nutritionData = baseline?['nutrition'] as Map<String, dynamic>?;
    final psychData = baseline?['psych'] as Map<String, dynamic>?;

    // Calculate Activity Index from IPAQ-SF (MET minutes)
    final activityIndex = _calculateActivityIndex(activityData);
    final activityLabel = _getActivityLabel(activityIndex);

    // Calculate Stress Load from PSS-4 (0-16 scale, inverted and normalized)
    final stressLoad = _calculateStressLoad(stressData);
    final stressLabel = _getStressLabel(stressLoad);

    // Calculate Sleep Quality from ISI-7 (0-28 scale, inverted and normalized)
    final sleepQuality = _calculateSleepQuality(sleepData);
    final sleepLabel = _getSleepLabel(sleepQuality);

    // Calculate Nutrition Quality from REAP-S
    final nutritionQuality = _calculateNutritionQuality(nutritionData);
    final nutritionLabel = _getNutritionLabel(nutritionQuality);

    // Calculate Emotional Wellbeing from PAID-5 (0-20 scale, inverted)
    final emotionalWellbeing = _calculateEmotionalWellbeing(psychData);
    final emotionalLabel = _getEmotionalLabel(emotionalWellbeing);

    return ProfileMetrics(
      activityIndex: activityIndex,
      activityLabel: activityLabel,
      stressLoad: stressLoad,
      stressLabel: stressLabel,
      sleepQuality: sleepQuality,
      sleepLabel: sleepLabel,
      nutritionQuality: nutritionQuality,
      nutritionLabel: nutritionLabel,
      emotionalWellbeing: emotionalWellbeing,
      emotionalWellbeingLabel: emotionalLabel,
      completedAt: DateTime.now(),
    );
  }

  static int _calculateActivityIndex(Map<String, dynamic>? data) {
    if (data == null) return 50; // Default moderate

    // Use canonical MET minutes if available
    final canonical = data['canonical'] as Map<String, dynamic>?;
    final metMinutes = canonical?['met_minutes_week'] as num? ?? 0;

    // WHO guidelines: 600 MET-min/week = moderate, 1200+ = high
    // Scale: 0 = 0 MET-min, 50 = 600 MET-min, 100 = 1800+ MET-min
    if (metMinutes >= 1800) return 100;
    if (metMinutes >= 1200) return 85;
    if (metMinutes >= 600) return 65;
    if (metMinutes >= 300) return 40;
    if (metMinutes > 0) return 25;
    return 10;
  }

  static String _getActivityLabel(int score) {
    if (score >= 85) return 'High';
    if (score >= 65) return 'Moderate';
    if (score >= 40) return 'Low-Moderate';
    return 'Low';
  }

  static int _calculateStressLoad(Map<String, dynamic>? data) {
    if (data == null) return 50; // Default moderate

    final canonical = data['canonical'] as Map<String, dynamic>?;
    final pss4Score = canonical?['pss4_score'] as int? ?? 0;

    // PSS-4: 0-16 scale (higher = more stress)
    // Convert to 0-100: 0 = no stress (100), 16 = high stress (100)
    // Inverted: lower PSS-4 = better score
    final normalized = ((16 - pss4Score) / 16 * 100).round().clamp(0, 100);
    // But for "Stress Load" we want higher = worse, so invert again
    return (100 - normalized).clamp(0, 100);
  }

  static String _getStressLabel(int score) {
    if (score >= 75) return 'High';
    if (score >= 50) return 'Moderate-High';
    if (score >= 25) return 'Moderate';
    return 'Low';
  }

  static int _calculateSleepQuality(Map<String, dynamic>? data) {
    if (data == null) return 50; // Default moderate

    final canonical = data['canonical'] as Map<String, dynamic>?;
    final isiScore = canonical?['isi_score'] as int? ?? 0;

    // ISI-7: 0-28 scale (higher = worse insomnia)
    // 0-7 = no insomnia, 8-14 = subthreshold, 15-21 = moderate, 22-28 = severe
    // Convert to quality score: 0 ISI = 100 quality, 28 ISI = 0 quality
    return ((28 - isiScore) / 28 * 100).round().clamp(0, 100);
  }

  static String _getSleepLabel(int score) {
    if (score >= 75) return 'Good';
    if (score >= 50) return 'Fair';
    if (score >= 25) return 'Poor';
    return 'Very Poor';
  }

  static int _calculateNutritionQuality(Map<String, dynamic>? data) {
    if (data == null) return 50; // Default moderate

    final canonical = data['canonical'] as Map<String, dynamic>?;
    final rawScore = canonical?['raw_score'] as int? ?? 0;

    // REAP-S: typically 0-4 per item, 7 items = 0-28 max
    // Higher score = better nutrition
    // Normalize to 0-100
    final maxScore = 28;
    return ((rawScore / maxScore) * 100).round().clamp(0, 100);
  }

  static String _getNutritionLabel(int score) {
    if (score >= 75) return 'Excellent';
    if (score >= 60) return 'Balanced';
    if (score >= 40) return 'Fair';
    return 'Needs Improvement';
  }

  static int _calculateEmotionalWellbeing(Map<String, dynamic>? data) {
    if (data == null) return 50; // Default moderate

    final canonical = data['canonical'] as Map<String, dynamic>?;
    final paidScore = canonical?['raw_score'] as int? ?? 0;

    // PAID-5: 0-20 scale (higher = more distress)
    // Convert to wellbeing score: 0 PAID = 100 wellbeing, 20 PAID = 0 wellbeing
    return ((20 - paidScore) / 20 * 100).round().clamp(0, 100);
  }

  static String _getEmotionalLabel(int score) {
    if (score >= 60) return 'Stable';
    if (score >= 40) return 'Mild Distress';
    return 'Support Recommended';
  }

  Map<String, dynamic> toMap() {
    return {
      'activity_index': activityIndex,
      'activity_label': activityLabel,
      'stress_load': stressLoad,
      'stress_label': stressLabel,
      'sleep_quality': sleepQuality,
      'sleep_label': sleepLabel,
      'nutrition_quality': nutritionQuality,
      'nutrition_label': nutritionLabel,
      'emotional_wellbeing': emotionalWellbeing,
      'emotional_wellbeing_label': emotionalWellbeingLabel,
      'completed_at': completedAt.toIso8601String(),
    };
  }
}
