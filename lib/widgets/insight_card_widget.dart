import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/insights_service.dart';

class InsightCardWidget extends StatefulWidget {
  const InsightCardWidget({
    super.key,
    required this.insight,
  });

  final InsightCard insight;

  @override
  State<InsightCardWidget> createState() => _InsightCardWidgetState();
}

class _InsightCardWidgetState extends State<InsightCardWidget> {
  int? _selectedIndex;
  String _glucoseUnit = 'mg/dL';

  @override
  void initState() {
    super.initState();
    _loadGlucoseUnit();
  }

  Future<void> _loadGlucoseUnit() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _glucoseUnit = prefs.getString('glucoseUnit') ?? 'mg/dL';
    });
  }

  void _handlePanUpdate(DragUpdateDetails details, Size size, List<Map<String, dynamic>> dataPoints) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final localPosition = box.globalToLocal(details.globalPosition);

    // Calculate which data point is closest to the touch
    final touchX = localPosition.dx;
    final dataPointWidth = size.width / (dataPoints.length - 1);
    final index = (touchX / dataPointWidth).round().clamp(0, dataPoints.length - 1);

    setState(() {
      _selectedIndex = index;
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    setState(() {
      _selectedIndex = null;
    });
  }

  String _formatGlucoseValue(double glucoseMgDl) {
    if (_glucoseUnit == 'mmol/L') {
      return (glucoseMgDl / 18.0).toStringAsFixed(1);
    } else {
      return glucoseMgDl.toStringAsFixed(0);
    }
  }

  String _formatTime(DateTime timestamp) {
    final hour = timestamp.hour % 12 == 0 ? 12 : timestamp.hour % 12;
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final period = timestamp.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasChartData = widget.insight.data is List && (widget.insight.data as List).isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (widget.insight.color ?? theme.colorScheme.primary)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    widget.insight.icon,
                    color: widget.insight.color ?? theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.insight.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Mini chart if available
            if (hasChartData) ...[
              GestureDetector(
                onPanUpdate: (details) {
                  _handlePanUpdate(
                    details,
                    const Size(double.infinity, 60),
                    widget.insight.data as List<Map<String, dynamic>>,
                  );
                },
                onPanEnd: _handlePanEnd,
                onTapUp: (details) {
                  final RenderBox box = context.findRenderObject() as RenderBox;
                  final size = box.size;
                  final dataPoints = widget.insight.data as List<Map<String, dynamic>>;
                  final localPosition = box.globalToLocal(details.globalPosition);

                  final touchX = localPosition.dx;
                  final dataPointWidth = size.width / (dataPoints.length - 1);
                  final index = (touchX / dataPointWidth).round().clamp(0, dataPoints.length - 1);

                  setState(() {
                    _selectedIndex = index;
                  });

                  // Auto-hide after 2 seconds
                  Future.delayed(const Duration(seconds: 2), () {
                    if (mounted) {
                      setState(() {
                        _selectedIndex = null;
                      });
                    }
                  });
                },
                child: SizedBox(
                  height: 60,
                  child: CustomPaint(
                    painter: _MiniGlucoseChartPainter(
                      dataPoints: widget.insight.data as List<Map<String, dynamic>>,
                      color: widget.insight.color ?? theme.colorScheme.primary,
                      selectedIndex: _selectedIndex,
                    ),
                    size: const Size(double.infinity, 60),
                  ),
                ),
              ),
              // Display selected value
              if (_selectedIndex != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: (widget.insight.color ?? theme.colorScheme.primary)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bloodtype,
                        size: 16,
                        color: widget.insight.color ?? theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_formatGlucoseValue((widget.insight.data as List<Map<String, dynamic>>)[_selectedIndex!]['glucose'])} $_glucoseUnit',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: widget.insight.color ?? theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime((widget.insight.data as List<Map<String, dynamic>>)[_selectedIndex!]['time']),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
            ],
            // Message
            Text(
              widget.insight.message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniGlucoseChartPainter extends CustomPainter {
  _MiniGlucoseChartPainter({
    required this.dataPoints,
    required this.color,
    this.selectedIndex,
  });

  final List<Map<String, dynamic>> dataPoints;
  final Color color;
  final int? selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    // Find min/max glucose values for scaling
    final glucoseValues = dataPoints.map((p) => p['glucose'] as double).toList();
    final minGlucose = glucoseValues.reduce((a, b) => a < b ? a : b);
    final maxGlucose = glucoseValues.reduce((a, b) => a > b ? a : b);
    final range = maxGlucose - minGlucose;

    // Add some padding to the range
    final paddedMin = minGlucose - (range * 0.1);
    final paddedMax = maxGlucose + (range * 0.1);
    final paddedRange = paddedMax - paddedMin;

    // Create path for the line
    final path = Path();
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Create gradient fill
    final fillPath = Path();
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          color.withValues(alpha: 0.05),
          color.withValues(alpha: 0.3),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    // Plot points
    for (var i = 0; i < dataPoints.length; i++) {
      final glucose = dataPoints[i]['glucose'] as double;
      final x = (i / (dataPoints.length - 1)) * size.width;
      final y = size.height - ((glucose - paddedMin) / paddedRange * size.height);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    // Complete fill path
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // Draw fill and line
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Draw dots at each point
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (var i = 0; i < dataPoints.length; i++) {
      final glucose = dataPoints[i]['glucose'] as double;
      final x = (i / (dataPoints.length - 1)) * size.width;
      final y = size.height - ((glucose - paddedMin) / paddedRange * size.height);

      // Draw regular dot
      canvas.drawCircle(Offset(x, y), 2.5, dotPaint);

      // Draw highlighted dot if selected
      if (i == selectedIndex) {
        // Draw white background circle
        final highlightBgPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x, y), 6, highlightBgPaint);

        // Draw colored ring
        final highlightRingPaint = Paint()
          ..color = color
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;
        canvas.drawCircle(Offset(x, y), 6, highlightRingPaint);

        // Draw center dot
        canvas.drawCircle(Offset(x, y), 3, dotPaint);

        // Draw vertical line to bottom
        final linePaint = Paint()
          ..color = color.withValues(alpha: 0.3)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;
        canvas.drawLine(Offset(x, y), Offset(x, size.height), linePaint);
      }
    }
  }

  @override
  bool shouldRepaint(_MiniGlucoseChartPainter oldDelegate) {
    return oldDelegate.dataPoints != dataPoints ||
           oldDelegate.color != color ||
           oldDelegate.selectedIndex != selectedIndex;
  }
}
