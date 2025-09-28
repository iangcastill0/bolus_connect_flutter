import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';

enum BodyView { front, back }

class BodyRegion {
  const BodyRegion({
    required this.id,
    required this.label,
    required this.view,
    required this.buildPath,
  });

  final String id;
  final String label;
  final BodyView view;
  final Path Function() buildPath;
}

const Size _baseDiagramSize = Size(120, 300);
const double _centerX = _baseDiagramSize.width / 2;

class SelectableBodyDiagram extends StatelessWidget {
  const SelectableBodyDiagram({
    super.key,
    required this.view,
    required this.selectedRegions,
    required this.onRegionToggle,
  });

  final BodyView view;
  final Set<String> selectedRegions;
  final ValueChanged<String> onRegionToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AspectRatio(
      aspectRatio: _baseDiagramSize.width / _baseDiagramSize.height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) {
              final region = _hitTestRegion(details.localPosition, size);
              if (region != null) {
                onRegionToggle(region.id);
              }
            },
            child: CustomPaint(
              painter: _BodyDiagramPainter(
                view: view,
                regions: _regions,
                selectedRegions: selectedRegions,
                theme: theme,
              ),
            ),
          );
        },
      ),
    );
  }

  BodyRegion? _hitTestRegion(Offset tapPosition, Size widgetSize) {
    if (widgetSize.width <= 0 || widgetSize.height <= 0) return null;
    final scaleX = _baseDiagramSize.width / widgetSize.width;
    final scaleY = _baseDiagramSize.height / widgetSize.height;
    final transformed = Offset(tapPosition.dx * scaleX, tapPosition.dy * scaleY);
    for (final region in _regions.where((r) => r.view == view)) {
      final path = region.buildPath();
      if (path.contains(transformed)) {
        return region;
      }
    }
    return null;
  }
}

class _BodyDiagramPainter extends CustomPainter {
  _BodyDiagramPainter({
    required this.view,
    required this.regions,
    required this.selectedRegions,
    required this.theme,
  });

  final BodyView view;
  final List<BodyRegion> regions;
  final Set<String> selectedRegions;
  final ThemeData theme;

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / _baseDiagramSize.width;
    final scaleY = size.height / _baseDiagramSize.height;
    canvas.save();
    canvas.scale(scaleX, scaleY);

    final baseFill = Paint()
      ..color = theme.colorScheme.surfaceVariant.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    final outline = Paint()
      ..color = theme.colorScheme.outline.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final silhouette = view == BodyView.front ? _frontSilhouettePath() : _backSilhouettePath();
    canvas.drawPath(silhouette, baseFill);
    canvas.drawPath(silhouette, outline);

    final selectedPaint = Paint()
      ..color = theme.colorScheme.primary.withOpacity(0.85)
      ..style = PaintingStyle.fill;
    final unselectedPaint = Paint()
      ..color = theme.colorScheme.primary.withOpacity(0.35)
      ..style = PaintingStyle.fill;

    for (final region in regions.where((r) => r.view == view)) {
      final path = region.buildPath();
      final isSelected = selectedRegions.contains(region.id);
      canvas.drawPath(path, isSelected ? selectedPaint : unselectedPaint);
      canvas.drawPath(path, outline);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BodyDiagramPainter oldDelegate) {
    return oldDelegate.view != view ||
        oldDelegate.selectedRegions != selectedRegions ||
        oldDelegate.theme.colorScheme != theme.colorScheme;
  }
}

Path _frontSilhouettePath() {
  final path = Path();
  path.moveTo(_centerX, 8);
  path.arcToPoint(
    Offset(_centerX - 14, 30),
    radius: const Radius.circular(20),
    clockwise: true,
  );
  path.quadraticBezierTo(_centerX - 22, 42, _centerX - 18, 50);
  path.lineTo(32, 70);
  path.quadraticBezierTo(20, 100, 28, 130);
  path.lineTo(26, 180);
  path.quadraticBezierTo(22, 240, 32, 260);
  path.lineTo(36, 300);
  path.lineTo(48, 300);
  path.quadraticBezierTo(52, 270, 54, 238);
  path.lineTo(66, 238);
  path.quadraticBezierTo(68, 270, 72, 300);
  path.lineTo(84, 300);
  path.lineTo(88, 260);
  path.quadraticBezierTo(98, 240, 94, 180);
  path.lineTo(92, 130);
  path.quadraticBezierTo(100, 100, 88, 70);
  path.lineTo(_centerX + 18, 50);
  path.quadraticBezierTo(_centerX + 22, 42, _centerX + 14, 30);
  path.arcToPoint(
    Offset(_centerX, 8),
    radius: const Radius.circular(20),
    clockwise: true,
  );
  path.close();
  return path;
}

Path _backSilhouettePath() {
  final path = Path();
  path.moveTo(_centerX, 8);
  path.arcToPoint(
    Offset(_centerX - 16, 32),
    radius: const Radius.circular(22),
    clockwise: true,
  );
  path.quadraticBezierTo(_centerX - 24, 42, _centerX - 20, 52);
  path.lineTo(30, 74);
  path.quadraticBezierTo(18, 100, 26, 132);
  path.lineTo(24, 182);
  path.quadraticBezierTo(18, 230, 30, 258);
  path.lineTo(34, 300);
  path.lineTo(46, 300);
  path.quadraticBezierTo(50, 272, 52, 242);
  path.lineTo(68, 242);
  path.quadraticBezierTo(70, 272, 74, 300);
  path.lineTo(86, 300);
  path.lineTo(90, 258);
  path.quadraticBezierTo(102, 230, 96, 182);
  path.lineTo(94, 132);
  path.quadraticBezierTo(102, 100, 90, 74);
  path.lineTo(_centerX + 20, 52);
  path.quadraticBezierTo(_centerX + 24, 42, _centerX + 16, 32);
  path.arcToPoint(
    Offset(_centerX, 8),
    radius: const Radius.circular(22),
    clockwise: true,
  );
  path.close();
  return path;
}

Path _mirrorPath(Path original) {
  final matrix = Float64List.fromList([
    -1, 0, 0, 0,
    0, 1, 0, 0,
    0, 0, 1, 0,
    2 * _centerX, 0, 0, 1,
  ]);
  return original.transform(matrix);
}

Path _roundedRect(double left, double top, double width, double height, [double radius = 6]) {
  return Path()
    ..addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, width, height),
      Radius.circular(radius),
    ));
}

Path _frontTrapezius() {
  final path = Path();
  path.moveTo(_centerX - 18, 52);
  path.lineTo(_centerX + 18, 52);
  path.lineTo(_centerX + 10, 72);
  path.lineTo(_centerX - 10, 72);
  path.close();
  return path;
}

Path _frontDeltoidLeft() {
  final path = Path();
  path.moveTo(34, 62);
  path.lineTo(26, 78);
  path.quadraticBezierTo(22, 94, 30, 104);
  path.lineTo(42, 86);
  path.close();
  return path;
}

Path _frontPectoralLeft() {
  final path = Path();
  path.moveTo(36, 86);
  path.lineTo(54, 82);
  path.lineTo(54, 118);
  path.lineTo(34, 122);
  path.quadraticBezierTo(28, 108, 32, 96);
  path.close();
  return path;
}

Path _frontSerratusLeft() {
  final path = Path();
  path.moveTo(40, 118);
  path.lineTo(34, 128);
  path.lineTo(40, 140);
  path.lineTo(48, 132);
  path.close();
  return path;
}

Path _frontObliqueLeft() {
  final path = Path();
  path.moveTo(36, 124);
  path.lineTo(30, 150);
  path.lineTo(36, 180);
  path.lineTo(44, 170);
  path.close();
  return path;
}

Path _frontBicepsLeft() {
  final path = Path();
  path.moveTo(30, 104);
  path.lineTo(20, 118);
  path.lineTo(24, 150);
  path.lineTo(34, 140);
  path.close();
  return path;
}

Path _frontForearmLeft() {
  final path = Path();
  path.moveTo(24, 150);
  path.lineTo(18, 176);
  path.lineTo(24, 206);
  path.lineTo(34, 188);
  path.close();
  return path;
}

Path _frontQuadricepsLeft() {
  return _roundedRect(40, 182, 16, 54, 6);
}

Path _frontSartoriusLeft() {
  final path = Path();
  path.moveTo(40, 182);
  path.lineTo(34, 190);
  path.lineTo(38, 228);
  path.lineTo(44, 220);
  path.close();
  return path;
}

Path _frontTibialisLeft() {
  return _roundedRect(44, 236, 12, 44, 5);
}

Path _frontSoleusLeft() {
  return _roundedRect(44, 280, 12, 16, 4);
}

Path _frontAbdominals() {
  return _roundedRect(_centerX - 16, 118, 32, 74, 8);
}

Path _backTrapezius() {
  final path = Path();
  path.moveTo(_centerX - 24, 52);
  path.lineTo(_centerX + 24, 52);
  path.lineTo(_centerX + 8, 84);
  path.lineTo(_centerX - 8, 84);
  path.close();
  return path;
}

Path _backDeltoidLeft() {
  final path = Path();
  path.moveTo(32, 68);
  path.lineTo(22, 84);
  path.lineTo(28, 110);
  path.lineTo(40, 90);
  path.close();
  return path;
}

Path _backInfraspinatusLeft() {
  final path = Path();
  path.moveTo(36, 90);
  path.lineTo(28, 118);
  path.lineTo(36, 138);
  path.lineTo(46, 114);
  path.close();
  return path;
}

Path _backTricepsLeft() {
  final path = Path();
  path.moveTo(28, 110);
  path.lineTo(18, 134);
  path.lineTo(24, 166);
  path.lineTo(34, 146);
  path.close();
  return path;
}

Path _backForearmLeft() {
  final path = Path();
  path.moveTo(24, 166);
  path.lineTo(18, 194);
  path.lineTo(26, 220);
  path.lineTo(34, 194);
  path.close();
  return path;
}

Path _backLatLeft() {
  final path = Path();
  path.moveTo(40, 114);
  path.lineTo(30, 150);
  path.lineTo(40, 186);
  path.lineTo(52, 150);
  path.close();
  return path;
}

Path _backGluteLeft() {
  final path = Path();
  path.moveTo(40, 186);
  path.quadraticBezierTo(34, 210, 38, 232);
  path.lineTo(52, 232);
  path.quadraticBezierTo(54, 206, 50, 186);
  path.close();
  return path;
}

Path _backHamstringLeft() {
  return _roundedRect(42, 232, 14, 46, 6);
}

Path _backCalfLeft() {
  final path = Path();
  path.moveTo(44, 278);
  path.lineTo(40, 246);
  path.lineTo(50, 246);
  path.lineTo(56, 278);
  path.close();
  return path;
}

Path _backSoleusLeft() {
  return _roundedRect(46, 278, 10, 18, 4);
}

final List<BodyRegion> _regions = [
  BodyRegion(
    id: 'front_trapezius',
    label: 'Trapezius',
    view: BodyView.front,
    buildPath: _frontTrapezius,
  ),
  BodyRegion(
    id: 'front_deltoid_left',
    label: 'Deltoid (L)',
    view: BodyView.front,
    buildPath: _frontDeltoidLeft,
  ),
  BodyRegion(
    id: 'front_deltoid_right',
    label: 'Deltoid (R)',
    view: BodyView.front,
    buildPath: () => _mirrorPath(_frontDeltoidLeft()),
  ),
  BodyRegion(
    id: 'front_pectoralis_left',
    label: 'Pectoralis major (L)',
    view: BodyView.front,
    buildPath: _frontPectoralLeft,
  ),
  BodyRegion(
    id: 'front_pectoralis_right',
    label: 'Pectoralis major (R)',
    view: BodyView.front,
    buildPath: () => _mirrorPath(_frontPectoralLeft()),
  ),
  BodyRegion(
    id: 'front_serratus_left',
    label: 'Serratus anterior (L)',
    view: BodyView.front,
    buildPath: _frontSerratusLeft,
  ),
  BodyRegion(
    id: 'front_serratus_right',
    label: 'Serratus anterior (R)',
    view: BodyView.front,
    buildPath: () => _mirrorPath(_frontSerratusLeft()),
  ),
  BodyRegion(
    id: 'front_oblique_left',
    label: 'External oblique (L)',
    view: BodyView.front,
    buildPath: _frontObliqueLeft,
  ),
  BodyRegion(
    id: 'front_oblique_right',
    label: 'External oblique (R)',
    view: BodyView.front,
    buildPath: () => _mirrorPath(_frontObliqueLeft()),
  ),
  BodyRegion(
    id: 'front_biceps_left',
    label: 'Biceps (L)',
    view: BodyView.front,
    buildPath: _frontBicepsLeft,
  ),
  BodyRegion(
    id: 'front_biceps_right',
    label: 'Biceps (R)',
    view: BodyView.front,
    buildPath: () => _mirrorPath(_frontBicepsLeft()),
  ),
  BodyRegion(
    id: 'front_forearm_left',
    label: 'Forearm flexors (L)',
    view: BodyView.front,
    buildPath: _frontForearmLeft,
  ),
  BodyRegion(
    id: 'front_forearm_right',
    label: 'Forearm flexors (R)',
    view: BodyView.front,
    buildPath: () => _mirrorPath(_frontForearmLeft()),
  ),
  BodyRegion(
    id: 'front_quadriceps_left',
    label: 'Quadriceps (L)',
    view: BodyView.front,
    buildPath: _frontQuadricepsLeft,
  ),
  BodyRegion(
    id: 'front_quadriceps_right',
    label: 'Quadriceps (R)',
    view: BodyView.front,
    buildPath: () => _mirrorPath(_frontQuadricepsLeft()),
  ),
  BodyRegion(
    id: 'front_sartorius_left',
    label: 'Sartorius (L)',
    view: BodyView.front,
    buildPath: _frontSartoriusLeft,
  ),
  BodyRegion(
    id: 'front_sartorius_right',
    label: 'Sartorius (R)',
    view: BodyView.front,
    buildPath: () => _mirrorPath(_frontSartoriusLeft()),
  ),
  BodyRegion(
    id: 'front_tibialis_left',
    label: 'Tibialis anterior (L)',
    view: BodyView.front,
    buildPath: _frontTibialisLeft,
  ),
  BodyRegion(
    id: 'front_tibialis_right',
    label: 'Tibialis anterior (R)',
    view: BodyView.front,
    buildPath: () => _mirrorPath(_frontTibialisLeft()),
  ),
  BodyRegion(
    id: 'front_soleus_left',
    label: 'Soleus (L)',
    view: BodyView.front,
    buildPath: _frontSoleusLeft,
  ),
  BodyRegion(
    id: 'front_soleus_right',
    label: 'Soleus (R)',
    view: BodyView.front,
    buildPath: () => _mirrorPath(_frontSoleusLeft()),
  ),
  BodyRegion(
    id: 'front_abdominals',
    label: 'Abdominals',
    view: BodyView.front,
    buildPath: _frontAbdominals,
  ),
  BodyRegion(
    id: 'back_trapezius',
    label: 'Trapezius',
    view: BodyView.back,
    buildPath: _backTrapezius,
  ),
  BodyRegion(
    id: 'back_deltoid_left',
    label: 'Deltoid (L)',
    view: BodyView.back,
    buildPath: _backDeltoidLeft,
  ),
  BodyRegion(
    id: 'back_deltoid_right',
    label: 'Deltoid (R)',
    view: BodyView.back,
    buildPath: () => _mirrorPath(_backDeltoidLeft()),
  ),
  BodyRegion(
    id: 'back_infraspinatus_left',
    label: 'Infraspinatus & Teres major (L)',
    view: BodyView.back,
    buildPath: _backInfraspinatusLeft,
  ),
  BodyRegion(
    id: 'back_infraspinatus_right',
    label: 'Infraspinatus & Teres major (R)',
    view: BodyView.back,
    buildPath: () => _mirrorPath(_backInfraspinatusLeft()),
  ),
  BodyRegion(
    id: 'back_triceps_left',
    label: 'Triceps (L)',
    view: BodyView.back,
    buildPath: _backTricepsLeft,
  ),
  BodyRegion(
    id: 'back_triceps_right',
    label: 'Triceps (R)',
    view: BodyView.back,
    buildPath: () => _mirrorPath(_backTricepsLeft()),
  ),
  BodyRegion(
    id: 'back_forearm_left',
    label: 'Forearm extensors (L)',
    view: BodyView.back,
    buildPath: _backForearmLeft,
  ),
  BodyRegion(
    id: 'back_forearm_right',
    label: 'Forearm extensors (R)',
    view: BodyView.back,
    buildPath: () => _mirrorPath(_backForearmLeft()),
  ),
  BodyRegion(
    id: 'back_lat_left',
    label: 'Latissimus dorsi (L)',
    view: BodyView.back,
    buildPath: _backLatLeft,
  ),
  BodyRegion(
    id: 'back_lat_right',
    label: 'Latissimus dorsi (R)',
    view: BodyView.back,
    buildPath: () => _mirrorPath(_backLatLeft()),
  ),
  BodyRegion(
    id: 'back_glute_left',
    label: 'Gluteus (L)',
    view: BodyView.back,
    buildPath: _backGluteLeft,
  ),
  BodyRegion(
    id: 'back_glute_right',
    label: 'Gluteus (R)',
    view: BodyView.back,
    buildPath: () => _mirrorPath(_backGluteLeft()),
  ),
  BodyRegion(
    id: 'back_hamstring_left',
    label: 'Hamstrings (L)',
    view: BodyView.back,
    buildPath: _backHamstringLeft,
  ),
  BodyRegion(
    id: 'back_hamstring_right',
    label: 'Hamstrings (R)',
    view: BodyView.back,
    buildPath: () => _mirrorPath(_backHamstringLeft()),
  ),
  BodyRegion(
    id: 'back_calf_left',
    label: 'Gastrocnemius (L)',
    view: BodyView.back,
    buildPath: _backCalfLeft,
  ),
  BodyRegion(
    id: 'back_calf_right',
    label: 'Gastrocnemius (R)',
    view: BodyView.back,
    buildPath: () => _mirrorPath(_backCalfLeft()),
  ),
  BodyRegion(
    id: 'back_soleus_left',
    label: 'Soleus (L)',
    view: BodyView.back,
    buildPath: _backSoleusLeft,
  ),
  BodyRegion(
    id: 'back_soleus_right',
    label: 'Soleus (R)',
    view: BodyView.back,
    buildPath: () => _mirrorPath(_backSoleusLeft()),
  ),
];

List<BodyRegion> get selectableBodyRegions => List.unmodifiable(_regions);
