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
  final Set<DateTime> _expandedDates = <DateTime>{};

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
      _syncExpandedDates();
    });
  }

  Future<void> _onRefresh() async {
    setState(() => _loading = true);
    await _loadLogs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Insights')),
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
    return groups.map((group) {
      final expanded = _expandedDates.contains(group.date);
      final entryCount = group.entries.length;
      final totalUnits =
          group.entries.fold<double>(0, (sum, entry) => sum + entry.totalBolus);
      final summary =
          '$entryCount log${entryCount == 1 ? '' : 's'} · ${totalUnits.toStringAsFixed(1)} U';

      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            InkWell(
              onTap: () => _toggleGroupExpansion(group.date),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _LogEntryTile.formatDate(group.date),
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(summary, style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      child: const Icon(Icons.keyboard_arrow_down_rounded),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    const Divider(height: 24),
                    ..._buildEntriesForGroup(group),
                  ],
                ),
              ),
              crossFadeState:
                  expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
              sizeCurve: Curves.easeInOut,
            ),
          ],
        ),
      );
    }).toList();
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
      _syncExpandedDates();
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Log deleted')),
    );
  }

  List<_DayGroup> _groupEntriesByDay(List<BolusLogEntry> entries) {
    final map = <DateTime, List<BolusLogEntry>>{};
    for (final entry in entries) {
      final dayKey = _dayKey(entry.timestamp);
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

  void _toggleGroupExpansion(DateTime date) {
    setState(() {
      if (_expandedDates.contains(date)) {
        _expandedDates.remove(date);
      } else {
        _expandedDates.add(date);
      }
    });
  }

  void _syncExpandedDates() {
    final currentDates =
        _entries.map((entry) => _dayKey(entry.timestamp)).toSet();
    _expandedDates.removeWhere((d) => !currentDates.contains(d));
    if (_expandedDates.isEmpty && currentDates.isNotEmpty) {
      DateTime latest = currentDates.first;
      for (final date in currentDates) {
        if (date.isAfter(latest)) {
          latest = date;
        }
      }
      _expandedDates.add(latest);
    }
  }

  DateTime _dayKey(DateTime timestamp) {
    final local = timestamp.toLocal();
    return DateTime(local.year, local.month, local.day);
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
