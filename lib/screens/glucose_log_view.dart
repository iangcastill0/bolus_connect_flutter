import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/bolus_log_service.dart';

class GlucoseLogView extends StatefulWidget {
  const GlucoseLogView({super.key});

  @override
  State<GlucoseLogView> createState() => _GlucoseLogViewState();
}

class _GlucoseLogViewState extends State<GlucoseLogView> {
  List<BolusLogEntry> _entries = [];
  bool _loading = true;
  double _rangeLow = 70.0;
  double _rangeHigh = 180.0;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final logs = await BolusLogService.loadEntries();
    if (!mounted) return;

    // Load glucose range from preferences
    final prefs = await SharedPreferences.getInstance();
    final rangeLowMgdl = double.tryParse(prefs.getString('glucoseRangeLow') ?? '') ?? 70.0;
    final rangeHighMgdl = double.tryParse(prefs.getString('glucoseRangeHigh') ?? '') ?? 180.0;

    // Filter only entries with glucose values
    final glucoseEntries = logs.where((e) => e.glucose != null).toList();

    setState(() {
      _entries = glucoseEntries;
      _rangeLow = rangeLowMgdl;
      _rangeHigh = rangeHighMgdl;
      _loading = false;
    });
  }

  Future<void> _onRefresh() async {
    setState(() => _loading = true);
    await _loadLogs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Glucose Log'),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _entries.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 120),
                      Center(
                        child: Text('No glucose readings yet.'),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _entries.length,
                    itemBuilder: (context, index) {
                      final entry = _entries[index];
                      return _GlucoseEntryCard(
                        entry: entry,
                        rangeLow: _rangeLow,
                        rangeHigh: _rangeHigh,
                      );
                    },
                  ),
      ),
    );
  }
}

class _GlucoseEntryCard extends StatelessWidget {
  const _GlucoseEntryCard({
    required this.entry,
    required this.rangeLow,
    required this.rangeHigh,
  });

  final BolusLogEntry entry;
  final double rangeLow;
  final double rangeHigh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timestamp = entry.timestamp.toLocal();
    final glucose = entry.glucose!;
    final glucoseMgDl = entry.glucoseUnit == 'mmol/L' ? glucose * 18.0 : glucose;

    final color = _getGlucoseColor(glucoseMgDl);
    final statusLabel = _getGlucoseLabel(glucoseMgDl);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Glucose value with colored indicator
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color, width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    entry.glucoseUnit == 'mmol/L'
                        ? glucose.toStringAsFixed(1)
                        : glucose.toStringAsFixed(0),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    entry.glucoseUnit,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          statusLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDateTime(timestamp),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  if (entry.carbs != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.restaurant,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${entry.carbs!.toStringAsFixed(0)}g carbs',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (entry.totalBolus > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.medication,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${entry.totalBolus.toStringAsFixed(1)}U insulin',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getGlucoseColor(double glucoseMgDl) {
    if (glucoseMgDl < rangeLow) {
      return Colors.red;
    } else if (glucoseMgDl <= rangeHigh) {
      return Colors.green;
    } else if (glucoseMgDl <= rangeHigh + 70) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  String _getGlucoseLabel(double glucoseMgDl) {
    if (glucoseMgDl < rangeLow) {
      return 'Low';
    } else if (glucoseMgDl <= rangeHigh) {
      return 'In Range';
    } else if (glucoseMgDl <= rangeHigh + 70) {
      return 'High';
    } else {
      return 'Very High';
    }
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final difference = now.difference(dt);

    // If today, show time
    if (difference.inDays == 0 && dt.day == now.day) {
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return 'Today at $hour:$minute $period';
    }

    // If yesterday
    if (difference.inDays == 1 ||
        (dt.day == now.day - 1 && difference.inHours < 48)) {
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return 'Yesterday at $hour:$minute $period';
    }

    // Otherwise show full date
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final month = months[(dt.month - 1).clamp(0, 11)];
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$month ${dt.day} at $hour:$minute $period';
  }
}
