import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

@immutable
class PolylineChangedData {
  final List<LatLng> points;
  final dynamic tag;

  final Color color;
  final Color? defaultColor;
  final double strokeWidth;
  final double dx;
  final bool isDotted;
  final bool hitTestable;

  /// Quando [isDotted] for true, permite controlar se o padrão será
  /// pontilhado curto ou tracejado customizado.
  final bool useDashedPattern;

  /// Comprimento visual do traço.
  final double dashSegmentLength;

  /// Espaço entre os traços.
  final double dashGapLength;

  /// Como o padrão deve se ajustar ao comprimento da polyline.
  final PatternFit patternFit;

  PolylineChangedData({
    required this.points,
    required this.tag,
    required this.color,
    required this.strokeWidth,
    this.defaultColor,
    this.dx = 0,
    this.isDotted = false,
    this.hitTestable = true,
    this.useDashedPattern = true,
    this.dashSegmentLength = 12,
    this.dashGapLength = 8,
    this.patternFit = PatternFit.scaleUp,
  });

  bool get isEmpty => points.isEmpty;

  bool get hasRenderableGeometry => points.length >= 2;

  late final LatLngBounds geographicBounds = _computeGeographicBounds();

  LatLngBounds _computeGeographicBounds() {
    if (points.isEmpty) {
      return LatLngBounds(
        const LatLng(0, 0),
        const LatLng(0, 0),
      );
    }

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    return LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );
  }

  bool isVisibleInMapBounds(LatLngBounds visibleBounds) {
    return geographicBounds.isOverlapping(visibleBounds);
  }

  List<Offset> projectToScreen(MapCamera camera) {
    if (points.isEmpty) return const [];

    return points
        .map((p) => camera.latLngToScreenOffset(p))
        .toList(growable: false);
  }

  PolylineScreenBBox? buildScreenBBox(MapCamera camera) {
    if (points.isEmpty) return null;

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final latLng in points) {
      final p = camera.latLngToScreenOffset(latLng);

      if (p.dx < minX) minX = p.dx;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dy > maxY) maxY = p.dy;
    }

    return PolylineScreenBBox(
      minX: minX,
      minY: minY,
      maxX: maxX,
      maxY: maxY,
    );
  }

  StrokePattern _buildStrokePattern() {
    if (!isDotted) {
      return const StrokePattern.solid();
    }

    if (!useDashedPattern) {
      return const StrokePattern.dotted();
    }

    final dash = math.max(1, dashSegmentLength).toDouble();
    final gap = math.max(1, dashGapLength).toDouble();

    return StrokePattern.dashed(
      segments: <double>[dash, gap],
      patternFit: patternFit,
    );
  }

  Polyline buildFlutterPolyline({
    Color? overrideColor,
    double? overrideStrokeWidth,
  }) {
    return Polyline(
      points: points,
      color: overrideColor ?? color,
      strokeWidth: overrideStrokeWidth ?? strokeWidth,
      pattern: _buildStrokePattern(),
    );
  }

  double? hitDistance({
    required Offset tapPosition,
    required List<Offset> projectedOffsets,
    required double tolerance,
    PolylineScreenBBox? screenBBox,
  }) {
    if (!hitTestable) return null;
    if (projectedOffsets.length < 2) return null;

    final effectiveTolerance = math.max(
      tolerance,
      (strokeWidth * 0.5) + 4.0,
    );

    final bbox = screenBBox;
    if (bbox != null && !bbox.contains(tapPosition, effectiveTolerance)) {
      return null;
    }

    double? bestDistance;

    for (int i = 0; i < projectedOffsets.length - 1; i++) {
      final a = projectedOffsets[i];
      final b = projectedOffsets[i + 1];

      final dist = _pointToSegmentDistance(tapPosition, a, b);
      if (dist > effectiveTolerance) continue;

      final inside = _isProjectionInsideSegment(tapPosition, a, b);
      if (!inside) continue;

      if (bestDistance == null || dist < bestDistance) {
        bestDistance = dist;
      }
    }

    return bestDistance;
  }

  static double _pointToSegmentDistance(
      Offset p,
      Offset a,
      Offset b,
      ) {
    final vx = b.dx - a.dx;
    final vy = b.dy - a.dy;

    final wx = p.dx - a.dx;
    final wy = p.dy - a.dy;

    final c1 = wx * vx + wy * vy;

    if (c1 <= 0) return _distance(p, a);

    final c2 = vx * vx + vy * vy;

    if (c2 <= c1) return _distance(p, b);

    final t = c1 / c2;

    final proj = Offset(
      a.dx + t * vx,
      a.dy + t * vy,
    );

    return _distance(p, proj);
  }

  static bool _isProjectionInsideSegment(
      Offset p,
      Offset a,
      Offset b,
      ) {
    final vx = b.dx - a.dx;
    final vy = b.dy - a.dy;

    final wx = p.dx - a.dx;
    final wy = p.dy - a.dy;

    final c1 = wx * vx + wy * vy;
    if (c1 <= 0) return false;

    final c2 = vx * vx + vy * vy;
    if (c2 <= c1) return false;

    return true;
  }

  static double _distance(Offset p, Offset q) {
    final dx = p.dx - q.dx;
    final dy = p.dy - q.dy;
    return math.sqrt(dx * dx + dy * dy);
  }

  PolylineChangedData copyWith({
    List<LatLng>? points,
    dynamic tag,
    Color? color,
    Color? defaultColor,
    double? strokeWidth,
    double? dx,
    bool? isDotted,
    bool? hitTestable,
    bool? useDashedPattern,
    double? dashSegmentLength,
    double? dashGapLength,
    PatternFit? patternFit,
  }) {
    return PolylineChangedData(
      points: points ?? this.points,
      tag: tag ?? this.tag,
      color: color ?? this.color,
      defaultColor: defaultColor ?? this.defaultColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      dx: dx ?? this.dx,
      isDotted: isDotted ?? this.isDotted,
      hitTestable: hitTestable ?? this.hitTestable,
      useDashedPattern: useDashedPattern ?? this.useDashedPattern,
      dashSegmentLength: dashSegmentLength ?? this.dashSegmentLength,
      dashGapLength: dashGapLength ?? this.dashGapLength,
      patternFit: patternFit ?? this.patternFit,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PolylineChangedData &&
        other.tag == tag &&
        other.color == color &&
        other.defaultColor == defaultColor &&
        other.strokeWidth == strokeWidth &&
        other.dx == dx &&
        other.isDotted == isDotted &&
        other.hitTestable == hitTestable &&
        other.useDashedPattern == useDashedPattern &&
        other.dashSegmentLength == dashSegmentLength &&
        other.dashGapLength == dashGapLength &&
        other.patternFit == patternFit &&
        _listEquals(other.points, points);
  }

  @override
  int get hashCode => Object.hash(
    tag,
    color,
    defaultColor,
    strokeWidth,
    dx,
    isDotted,
    hitTestable,
    useDashedPattern,
    dashSegmentLength,
    dashGapLength,
    patternFit,
    Object.hashAll(
      points.map((p) => Object.hash(p.latitude, p.longitude)),
    ),
  );

  static bool _listEquals(List<LatLng> a, List<LatLng> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;

    for (int i = 0; i < a.length; i++) {
      final pa = a[i];
      final pb = b[i];

      if (pa.latitude != pb.latitude || pa.longitude != pb.longitude) {
        return false;
      }
    }

    return true;
  }
}

@immutable
class PolylineScreenBBox {
  final double minX;
  final double minY;
  final double maxX;
  final double maxY;

  const PolylineScreenBBox({
    required this.minX,
    required this.minY,
    required this.maxX,
    required this.maxY,
  });

  bool contains(Offset p, double tolerance) {
    return p.dx >= (minX - tolerance) &&
        p.dx <= (maxX + tolerance) &&
        p.dy >= (minY - tolerance) &&
        p.dy <= (maxY + tolerance);
  }
}