import 'dart:math' as math;

import 'package:flutter/material.dart';

class GlucoseRingPainter extends CustomPainter {
  GlucoseRingPainter({
    required this.averageGlucose,
    required this.variabilityPercent,
    required this.mostRecentGlucose,
    required this.glucoseUnit,
    required this.rangeLow,
    required this.rangeHigh,
  });
  
  final double averageGlucose;
  final double variabilityPercent;
  final double mostRecentGlucose;
  final String glucoseUnit;
  final double rangeLow;
  final double rangeHigh;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    // Ring dimensions
    final outerRingThickness = radius * 0.15;
    final innerRingThickness = radius * 0.12;
    final outerRingRadius = radius - outerRingThickness / 2;
    final innerRingRadius = radius - outerRingThickness - innerRingThickness / 2 - 8;

    // Color for variability (outer ring)
    final variabilityColor = _getVariabilityColor(variabilityPercent);

    // Draw outer ring (variability)
    final outerPaint = Paint()
      ..color = variabilityColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = outerRingThickness
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, outerRingRadius, outerPaint);

    // Draw inner ring (average glucose) - use custom range
    final innerPaint = Paint()
      ..color = _getGlucoseColorWithRange(averageGlucose, glucoseUnit, rangeLow, rangeHigh)
      ..style = PaintingStyle.stroke
      ..strokeWidth = innerRingThickness
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, innerRingRadius, innerPaint);

    // Draw center text (most recent glucose) - use custom range
    final textSpan = TextSpan(
      text: mostRecentGlucose.toStringAsFixed(0),
      style: TextStyle(
        color: _getGlucoseColorWithRange(mostRecentGlucose, glucoseUnit, rangeLow, rangeHigh),
        fontSize: radius * 0.35,
        fontWeight: FontWeight.bold,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );

    // Draw unit label below
    final unitSpan = TextSpan(
      text: glucoseUnit,
      style: TextStyle(
        color: Colors.grey[600],
        fontSize: radius * 0.12,
        fontWeight: FontWeight.w500,
      ),
    );

    final unitPainter = TextPainter(
      text: unitSpan,
      textDirection: TextDirection.ltr,
    );

    unitPainter.layout();
    unitPainter.paint(
      canvas,
      Offset(
        center.dx - unitPainter.width / 2,
        center.dy + textPainter.height / 2 + 4,
      ),
    );
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

  Color _getGlucoseColorWithRange(double glucose, String unit, double rangeLow, double rangeHigh) {
    // All values are in user's unit, convert to mg/dL for comparison
    final glucoseMgDl = unit == 'mmol/L' ? glucose * 18.0 : glucose;
    final rangeLowMgDl = unit == 'mmol/L' ? rangeLow * 18.0 : rangeLow;
    final rangeHighMgDl = unit == 'mmol/L' ? rangeHigh * 18.0 : rangeHigh;

    if (glucoseMgDl < rangeLowMgDl) {
      return Colors.red; // Low
    } else if (glucoseMgDl <= rangeHighMgDl) {
      return Colors.green; // In range
    } else if (glucoseMgDl <= rangeHighMgDl + 70) {
      return Colors.orange; // Slightly high
    } else {
      return Colors.red; // Very high
    }
  }

  @override
  bool shouldRepaint(GlucoseRingPainter oldDelegate) {
    return oldDelegate.averageGlucose != averageGlucose ||
        oldDelegate.variabilityPercent != variabilityPercent ||
        oldDelegate.mostRecentGlucose != mostRecentGlucose ||
        oldDelegate.glucoseUnit != glucoseUnit ||
        oldDelegate.rangeLow != rangeLow ||
        oldDelegate.rangeHigh != rangeHigh;
  }
}
