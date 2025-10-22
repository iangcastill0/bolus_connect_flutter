import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/bolus_log_service.dart';
import '../services/glucose_statistics.dart';
import '../services/insights_service.dart';
import '../widgets/add_glucose_modal.dart';
import '../widgets/add_exercise_modal.dart';
import '../widgets/add_mood_modal.dart';
import '../widgets/insight_card_widget.dart';
import '../widgets/log_meal_modal.dart';
import '../widgets/record_sleep_modal.dart';
import 'glucose_log_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.refreshTick});

  final ValueListenable<int>? refreshTick;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  GlucoseStatistics? _stats;
  List<InsightCard> _insights = [];
  bool _loading = true;
  String _coachingHint = '';

  // Coaching hints that rotate based on app opens
  static const List<String> _coachingHints = [
    'Try checking your glucose two hours after lunch today.',
    'Evening walks help reduce next-day highs.',
    'Stable sleep equals stable glucose variability.',
    'Protein before carbs can help stabilize post-meal spikes.',
    'Stress management techniques may improve your glucose control.',
    'Consistent meal timing supports better glucose patterns.',
    'Light activity after meals can help lower glucose levels.',
    'Hydration plays a key role in glucose management.',
  ];

  @override
  void initState() {
    super.initState();
    widget.refreshTick?.addListener(_handleRefreshTick);
    _loadData();
    _selectCoachingHint();
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshTick != widget.refreshTick) {
      oldWidget.refreshTick?.removeListener(_handleRefreshTick);
      widget.refreshTick?.addListener(_handleRefreshTick);
    }
  }

  @override
  void dispose() {
    widget.refreshTick?.removeListener(_handleRefreshTick);
    super.dispose();
  }

  void _handleRefreshTick() {
    _loadData();
  }

  void _selectCoachingHint() {
    // Rotate hints based on current day to keep it fresh but stable throughout the day
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    final hintIndex = dayOfYear % _coachingHints.length;
    setState(() {
      _coachingHint = _coachingHints[hintIndex];
    });
  }

  Future<void> _loadData() async {
    final entries = await BolusLogService.loadEntries();
    if (!mounted) return;

    final stats = await GlucoseStatistics.fromEntries(entries);
    if (!mounted) return;

    // Generate insights
    final glucoseUnit = stats?.glucoseUnit ?? 'mg/dL';
    final insights = await InsightsService.generateInsights(entries, glucoseUnit);
    if (!mounted) return;

    setState(() {
      _stats = stats;
      _insights = insights;
      _loading = false;
    });
  }

  Future<void> _onRefresh() async {
    setState(() => _loading = true);
    await _loadData();
  }

  void _showQuickAddMenu(BuildContext context) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width - 50,
        kToolbarHeight + 10,
        10,
        0,
      ),
      items: [
        PopupMenuItem(
          value: 'exercise',
          child: Row(
            children: const [
              Icon(Icons.fitness_center),
              SizedBox(width: 12),
              Text('Add Exercise'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'sleep',
          child: Row(
            children: const [
              Icon(Icons.bedtime),
              SizedBox(width: 12),
              Text('Record Sleep'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'mood',
          child: Row(
            children: const [
              Icon(Icons.mood),
              SizedBox(width: 12),
              Text('Add Mood/Stress'),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value != null) {
        _handleQuickAddSelection(context, value);
      }
    });
  }

  void _handleQuickAddSelection(BuildContext context, String selection) {
    switch (selection) {
      case 'glucose':
        _showAddGlucoseModal(context);
        break;
      case 'meal':
        _showLogMealModal(context);
        break;
      case 'exercise':
        _showAddExerciseModal(context);
        break;
      case 'sleep':
        _showRecordSleepModal(context);
        break;
      case 'mood':
        _showAddMoodModal(context);
        break;
    }
  }

  void _showAddGlucoseModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddGlucoseModal(
        onSaved: () {
          _loadData(); // Refresh the home page data
        },
      ),
    );
  }

  void _showLogMealModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => LogMealModal(
        onSaved: () {
          _loadData(); // Refresh the home page data
        },
      ),
    );
  }

  void _showAddExerciseModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddExerciseModal(
        onSaved: () {
          _loadData(); // Refresh the home page data
        },
      ),
    );
  }

  void _showRecordSleepModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => RecordSleepModal(
        onSaved: () {
          _loadData(); // Refresh the home page data
        },
      ),
    );
  }

  void _showAddMoodModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddMoodModal(
        onSaved: () {
          _loadData(); // Refresh the home page data
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.add,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            onPressed: () => _showQuickAddMenu(context),
            tooltip: 'Quick Add',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _stats == null
                ? _buildEmptyState(context)
                : _buildRingView(context),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(
                  Icons.bloodtype_outlined,
                  size: 80,
                  color: theme.colorScheme.primary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 24),
                Text(
                  'Add your first glucose reading to start tracking.',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Use the Bolus calculator to record glucose readings.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRingView(BuildContext context) {
    final theme = Theme.of(context);
    final stats = _stats!;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 20),
        // Most Recent Glucose
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const GlucoseLogView(),
              ),
            );
          },
          child: Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    'Last Glucose',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    stats.glucoseUnit == 'mmol/L'
                        ? stats.mostRecentGlucose.toStringAsFixed(1)
                        : stats.mostRecentGlucose.toStringAsFixed(0),
                    style: theme.textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _getGlucoseColor(stats.mostRecentGlucose, stats),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    stats.glucoseUnit,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _getGlucoseColor(stats.mostRecentGlucose, stats)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getGlucoseLabel(stats.mostRecentGlucose, stats),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: _getGlucoseColor(stats.mostRecentGlucose, stats),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        // Statistics Cards
        Text(
          'Last 12 Hours',
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Average',
                value: stats.glucoseUnit == 'mmol/L'
                    ? stats.averageGlucose.toStringAsFixed(1)
                    : stats.averageGlucose.toStringAsFixed(0),
                unit: stats.glucoseUnit,
                icon: Icons.show_chart,
                color: _getGlucoseColor(stats.averageGlucose, stats),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Variability',
                value: stats.variabilityPercent.toStringAsFixed(1),
                unit: '%',
                subtitle: stats.getVariabilityLabel(),
                icon: Icons.trending_up,
                color: _getVariabilityColor(stats.variabilityPercent),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Readings',
                value: stats.count.toString(),
                unit: 'logs',
                icon: Icons.list_alt,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Status',
                value: stats.getTimeInRangeLabel(),
                icon: Icons.check_circle_outline,
                color: _getStatusColor(stats),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        // Insights Section
        if (_insights.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Insights',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(
                Icons.auto_awesome,
                size: 20,
                color: theme.colorScheme.primary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._insights.map((insight) => InsightCardWidget(insight: insight)),
        ],
        const SizedBox(height: 24),
        Center(
          child: TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GlucoseLogView(),
                ),
              );
            },
            icon: const Icon(Icons.history),
            label: const Text('View Full History'),
          ),
        ),
        const SizedBox(height: 32),
        // Coaching Hint Banner
        if (_coachingHint.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.lightbulb_outline,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Coach Hint',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _coachingHint,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Color _getGlucoseColor(double glucose, GlucoseStatistics stats) {
    final glucoseMgDl = stats.glucoseUnit == 'mmol/L' ? glucose * 18.0 : glucose;
    final rangeLowMgDl = stats.glucoseUnit == 'mmol/L' ? stats.rangeLow * 18.0 : stats.rangeLow;
    final rangeHighMgDl = stats.glucoseUnit == 'mmol/L' ? stats.rangeHigh * 18.0 : stats.rangeHigh;

    if (glucoseMgDl < rangeLowMgDl) {
      return Colors.red;
    } else if (glucoseMgDl <= rangeHighMgDl) {
      return Colors.green;
    } else if (glucoseMgDl <= rangeHighMgDl + 70) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  String _getGlucoseLabel(double glucose, GlucoseStatistics stats) {
    final glucoseMgDl = stats.glucoseUnit == 'mmol/L' ? glucose * 18.0 : glucose;
    final rangeLowMgDl = stats.glucoseUnit == 'mmol/L' ? stats.rangeLow * 18.0 : stats.rangeLow;
    final rangeHighMgDl = stats.glucoseUnit == 'mmol/L' ? stats.rangeHigh * 18.0 : stats.rangeHigh;

    if (glucoseMgDl < rangeLowMgDl) {
      return 'Low';
    } else if (glucoseMgDl <= rangeHighMgDl) {
      return 'In Range';
    } else if (glucoseMgDl <= rangeHighMgDl + 70) {
      return 'High';
    } else {
      return 'Very High';
    }
  }

  Color _getVariabilityColor(double variabilityPercent) {
    // Low variability (stable): green
    // Medium variability: yellow/orange
    // High variability: red
    if (variabilityPercent < 20) {
      return Colors.green;
    } else if (variabilityPercent < 30) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  Color _getStatusColor(GlucoseStatistics stats) {
    // Use the same logic as glucose color for consistency
    return _getGlucoseColor(stats.averageGlucose, stats);
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    this.unit,
    this.subtitle,
    required this.icon,
    this.color,
  });

  final String label;
  final String value;
  final String? unit;
  final String? subtitle;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: color ?? theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                if (unit != null) ...[
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      unit!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: color?.withValues(alpha: 0.15) ??
                         theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: color ?? theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
