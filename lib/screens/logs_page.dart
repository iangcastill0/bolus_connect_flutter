import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/bolus_log_service.dart';

class LogsPage extends StatefulWidget {
  const LogsPage({super.key, this.refreshTick});

  final ValueListenable<int>? refreshTick;

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  final List<BolusLogEntry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    widget.refreshTick?.addListener(_handleRefreshTick);
    _loadLogs();
  }

  @override
  void didUpdateWidget(covariant LogsPage oldWidget) {
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
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final logs = await BolusLogService.loadEntries();
    if (!mounted) return;
    setState(() {
      _entries
        ..clear()
        ..addAll(logs);
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
      appBar: AppBar(title: const Text('Logs')),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _entries.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 120),
                      Center(child: Text('No bolus calculations logged yet.')),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: _buildDaySections(context),
                  ),
      ),
    );
  }

  List<Widget> _buildDaySections(BuildContext context) {
    final theme = Theme.of(context);
    final groups = _groupEntriesByDay(_entries);
    return groups
        .map((group) => Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Text(
                        _LogEntryTile.formatDate(group.date),
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ..._buildEntriesForGroup(group),
                  ],
                ),
              ),
            ))
        .toList();
  }

  List<Widget> _buildEntriesForGroup(_DayGroup group) {
    final widgets = <Widget>[];
    for (var i = 0; i < group.entries.length; i++) {
      final entry = group.entries[i];
      widgets.add(
        Dismissible(
          key: ValueKey(entry.id),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => _deleteEntry(entry),
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.red.shade400,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.delete, color: Colors.white),
                SizedBox(width: 4),
                Text('Delete', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
          child: _LogEntryTile(entry: entry),
        ),
      );
      if (i < group.entries.length - 1) {
        widgets.add(const Divider(height: 16));
      }
    }
    return widgets;
  }

  Future<void> _deleteEntry(BolusLogEntry entry) async {
    await BolusLogService.removeEntry(entry.id);
    if (!mounted) return;
    setState(() {
      _entries.removeWhere((e) => e.id == entry.id);
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Log deleted')),
    );
  }

  List<_DayGroup> _groupEntriesByDay(List<BolusLogEntry> entries) {
    final map = <DateTime, List<BolusLogEntry>>{};
    for (final entry in entries) {
      final ts = entry.timestamp.toLocal();
      final dayKey = DateTime(ts.year, ts.month, ts.day);
      map.putIfAbsent(dayKey, () => []).add(entry);
    }
    final groups = map.entries
        .map((e) => _DayGroup(date: e.key, entries: e.value))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    for (final group in groups) {
      group.entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }
    return groups;
  }
}

class _LogEntryTile extends StatelessWidget {
  const _LogEntryTile({required this.entry});

  final BolusLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timestamp = entry.timestamp.toLocal();
    final timeLabel = formatTime(timestamp);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(timeLabel, style: theme.textTheme.titleSmall),
              Text('Total: ${entry.totalBolus.toStringAsFixed(1)} U', style: theme.textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              if (entry.glucose != null)
                Text('Glucose: ${formatGlucose(entry)} ${entry.glucoseUnit}'),
              if (entry.carbs != null)
                Text('Carbs: ${entry.carbs!.toStringAsFixed(1)} g'),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Carb ${entry.carbBolus.toStringAsFixed(2)} U • Correction ${entry.correctionBolus.toStringAsFixed(2)} U • Trend ${entry.trendAdjustment.toStringAsFixed(2)} U',
            style: theme.textTheme.bodyMedium,
          ),
          if (entry.notes != null && entry.notes!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Notes: ${entry.notes!}', style: theme.textTheme.bodySmall),
          ],
        ],
      ),
    );
  }

  static String formatDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final month = months[(dt.month - 1).clamp(0, 11)];
    return '$month ${dt.day}, ${dt.year}';
  }

  static String formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  static String formatGlucose(BolusLogEntry entry) {
    final value = entry.glucose ?? 0;
    final decimals = entry.glucoseUnit == 'mmol/L' ? 1 : 0;
    return value.toStringAsFixed(decimals);
  }
}

class _DayGroup {
  _DayGroup({required this.date, required this.entries});

  final DateTime date;
  final List<BolusLogEntry> entries;
}
