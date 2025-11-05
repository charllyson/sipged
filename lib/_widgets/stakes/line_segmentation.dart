// lib/_widgets/stakes/line_segmentation.dart
import 'dart:math' as math;
import 'package:flutter/material.dart'; // Color
import 'package:flutter/widgets.dart';
import 'package:latlong2/latlong.dart';

import 'package:siged/_widgets/map/markers/tagged_marker.dart';
import 'package:siged/_widgets/map/polylines/tappable_changed_polyline.dart';

final Distance _distTool = const Distance();
const double _earthRadius = 6378137.0; // WebMercator

double _bearing(LatLng a, LatLng b) {
  final lat1 = a.latitude * math.pi / 180.0;
  final lat2 = b.latitude * math.pi / 180.0;
  final dLon = (b.longitude - a.longitude) * math.pi / 180.0;
  final y = math.sin(dLon) * math.cos(lat2);
  final x = math.cos(lat1) * math.sin(lat2) -
      math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
  return math.atan2(y, x);
}

LatLng _offsetByMeters(LatLng p, double distanceMeters, double bearingRad) {
  final lat = p.latitude * math.pi / 180.0;
  final lon = p.longitude * math.pi / 180.0;
  final dDivR = distanceMeters / _earthRadius;

  final newLat = math.asin(math.sin(lat) * math.cos(dDivR) +
      math.cos(lat) * math.sin(dDivR) * math.cos(bearingRad));
  final newLon = lon +
      math.atan2(math.sin(bearingRad) * math.sin(dDivR) * math.cos(lat),
          math.cos(dDivR) - math.sin(lat) * math.sin(newLat));

  return LatLng(newLat * 180.0 / math.pi, newLon * 180.0 / math.pi);
}

double _meanLat(List<LatLng> pts) =>
    pts.isEmpty ? 0.0 : pts.map((e) => e.latitude).reduce((a, b) => a + b) / pts.length;

double _metersPerPixelAt(double latitude, double zoom) {
  const earthRadius = 6378137.0;
  final latRad = latitude * math.pi / 180.0;
  return (math.cos(latRad) * 2 * math.pi * earthRadius) /
      (256 * math.pow(2.0, zoom));
}

double dynamicStakeGapPx({
  required List<LatLng> axis,
  required double zoom,
  double stepMeters = 20.0,
  double bubbleWidthPx = 34.0,
  double marginPx = 8.0,
}) {
  if (axis.isEmpty) return 120;
  final mpp = _metersPerPixelAt(axis.first.latitude, zoom);
  final stepPx = stepMeters / mpp;
  final need = bubbleWidthPx + marginPx;
  return (stepPx >= need) ? 0.0 : need;
}

double _normalizePi(double a) {
  while (a <= -math.pi) a += 2 * math.pi;
  while (a > math.pi) a -= 2 * math.pi;
  return a;
}

Offset _latLngToWorldPixel(LatLng p, double zoom) {
  const tile = 256.0;
  final scale = tile * math.pow(2.0, zoom);
  final x = (p.longitude + 180.0) / 360.0 * scale;
  final s = math.sin(p.latitude * math.pi / 180.0);
  final y = (0.5 - math.log((1 + s) / (1 - s)) / (4 * math.pi)) * scale;
  return Offset(x, y);
}

class _Sample {
  final LatLng p;
  final double bearing;
  _Sample(this.p, this.bearing);
}

/// Amostra o eixo a cada `stepMeters` e inclui a estaca 0.
List<_Sample> _sampleAlong(List<LatLng> axis, double stepMeters) {
  if (axis.length < 2) return const <_Sample>[];
  final out = <_Sample>[];
  double acc = 0;
  var curr = axis.first;
  double target = stepMeters;

  for (var i = 1; i < axis.length; i++) {
    final next = axis[i];
    final segLen = _distTool.distance(curr, next);
    final segBearing = _bearing(curr, next);

    while (acc + segLen >= target) {
      final remain = target - acc;
      final t = remain / segLen;
      final lat = curr.latitude + (next.latitude - curr.latitude) * t;
      final lon = curr.longitude + (next.longitude - curr.longitude) * t;
      out.add(_Sample(LatLng(lat, lon), segBearing));
      target += stepMeters;
    }

    acc += segLen;
    curr = next;
  }

  out.insert(0, _Sample(axis.first, _bearing(axis[0], axis[1])));
  return out;
}

/// ===== Estacas (upright) com anti-colisão =====
List<TaggedChangedMarker<Map<String, dynamic>>> buildStakeMarkersUprightWithTickRight({
  required List<LatLng> axis,
  double stepMeters = 20.0,
  double offsetRightMeters = 6.0, // (reservado p/ futuros estilos)
  required double zoom,
  double minLabelPixelGap = 100,
}) {
  if (axis.length < 2) return const [];

  final samples = _sampleAlong(axis, stepMeters);
  if (samples.isEmpty) return const [];

  final out = <TaggedChangedMarker<Map<String, dynamic>>>[];

  Offset? lastPx;
  for (var i = 0; i < samples.length; i++) {
    final s = samples[i];
    final nAngle = _normalizePi(s.bearing + math.pi / 2);

    final anchor = s.p;

    if (minLabelPixelGap > 0) {
      final currPx = _latLngToWorldPixel(anchor, zoom);
      if (lastPx != null) {
        final d = (currPx - lastPx!).distance;
        if (d < minLabelPixelGap) continue;
      }
      lastPx = currPx;
    }

    out.add(TaggedChangedMarker<Map<String, dynamic>>(
      point: anchor,
      properties: {'idx': i, 'label': '$i', 'normalAngle': nAngle, 'tickPx': 12.0},
      data: <String, dynamic>{},
    ));
  }

  return out;
}

// ======================================================
// 🔹 Segmentação do eixo e helpers de paralelas
// ======================================================

class SegmentedAxis {
  /// segmento i vai de stake i a stake i+1
  final List<List<LatLng>> segments;
  /// posições exatas das estacas
  final List<LatLng> stakePositions;
  SegmentedAxis(this.segments, this.stakePositions);
}

LatLng _interpolateByMeters(LatLng a, LatLng b, double distanceFromA) {
  final segLen = _distTool.distance(a, b);
  if (segLen <= 0) return a;
  final t = (distanceFromA / segLen).clamp(0.0, 1.0);
  final lat = a.latitude + (b.latitude - a.latitude) * t;
  final lon = a.longitude + (b.longitude - a.longitude) * t;
  return LatLng(lat, lon);
}

SegmentedAxis splitAxisByFixedStep({
  required List<LatLng> axis,
  double stepMeters = 20.0,
}) {
  if (axis.length < 2) return SegmentedAxis(const <List<LatLng>>[], const <LatLng>[]);

  final samples = _sampleAlong(axis, stepMeters);
  if (samples.isEmpty) return SegmentedAxis(const <List<LatLng>>[], const <LatLng>[]);

  final stakePositions = samples.map((s) => s.p).toList();
  final segments = <List<LatLng>>[];

  var curr = axis.first;
  var segStart = curr;
  var axisIdx = 1;

  void _advanceUntil(LatLng target) {
    final currTarget = target;
    final currSeg = <LatLng>[];
    currSeg.add(segStart);

    while (true) {
      if (axisIdx >= axis.length) {
        if (currSeg.last != curr) currSeg.add(curr);
        segments.add(currSeg);
        return;
      }

      final next = axis[axisIdx];
      final segLen = _distTool.distance(curr, next);

      final toTarget = _distTool.distance(segStart, currTarget);
      final toCurr   = _distTool.distance(segStart, curr);
      final along    = toTarget - toCurr;

      if (along <= segLen + 1e-6) {
        final cutPoint = _interpolateByMeters(curr, next, along);
        if (currSeg.last != cutPoint) currSeg.add(cutPoint);
        segments.add(currSeg);

        segStart = cutPoint;
        curr = cutPoint;
        return;
      } else {
        if (currSeg.last != next) currSeg.add(next);
        curr = next;
        axisIdx++;
      }
    }
  }

  for (var i = 1; i < stakePositions.length; i++) {
    _advanceUntil(stakePositions[i]);
  }

  // rabicho final
  final lastStake = stakePositions.last;
  final totalEnd  = axis.last;
  final tailLen   = _distTool.distance(lastStake, totalEnd);
  if (tailLen > 1.0) {
    final tail = <LatLng>[lastStake];
    var tailIdx = axisIdx;
    while (tailIdx < axis.length) {
      final next = axis[tailIdx];
      if (tail.last != next) tail.add(next);
      tailIdx++;
    }
    if (tail.length >= 2) segments.add(tail);
  }

  return SegmentedAxis(segments, stakePositions);
}

/// Central (20 m)
List<TappableChangedPolyline> buildSegmentPolylines({
  required SegmentedAxis segmented,
  Color Function(int idx)? colorForIndex,
  double strokeWidth = 5.0,
}) {
  final out = <TappableChangedPolyline>[];
  final segs = segmented.segments;

  Color _defaultColor(int i) =>
      (i % 2 == 0) ? const Color(0xFF1565C0) : const Color(0xFF42A5F5);

  for (var i = 0; i < segs.length; i++) {
    final seg = segs[i];
    if (seg.length < 2) continue;

    final baseColor = (colorForIndex ?? _defaultColor).call(i);

    out.add(TappableChangedPolyline(
      points: seg,
      tag: 'segC:$i',
      color: baseColor,
      defaultColor: baseColor,
      strokeWidth: strokeWidth,
      isDotted: false,
      hitTestable: true,
    ));
  }
  return out;
}

/// Desloca uma lista de pontos seguindo a normal local ponto-a-ponto.
List<LatLng> _offsetPolylineByNormal(List<LatLng> pts, double offsetMeters, {required bool right}) {
  if (pts.length < 2) return pts;
  final out = <LatLng>[];

  for (int k = 0; k < pts.length; k++) {
    late double brg;
    if (k == 0) {
      brg = _bearing(pts[k], pts[k + 1]);
    } else if (k == pts.length - 1) {
      brg = _bearing(pts[k - 1], pts[k]);
    } else {
      final b1 = _bearing(pts[k - 1], pts[k]);
      final b2 = _bearing(pts[k], pts[k + 1]);
      var x = math.cos(b1) + math.cos(b2);
      var y = math.sin(b1) + math.sin(b2);
      brg = math.atan2(y, x);
    }

    final rightNormal = _normalizePi(brg + math.pi / 2);
    final leftNormal  = _normalizePi(rightNormal + math.pi);
    final use = right ? rightNormal : leftNormal;
    out.add(_offsetByMeters(pts[k], offsetMeters.abs(), use));
  }

  return out;
}

/// Paralelas segmentadas, alinhadas índice-a-índice à central.
List<TappableChangedPolyline> buildParallelSegmentPolylines({
  required SegmentedAxis segmented,
  double offsetMeters = 3.5,
  bool buildRight = true,
  bool buildLeft  = true,
  Color Function(int idx)? colorForIndex,
  double strokeWidth = 4.0,
  bool hitTestable = true,
  String sidePrefixRight = 'segR',
  String sidePrefixLeft  = 'segL',
}) {
  final out = <TappableChangedPolyline>[];
  final segs = segmented.segments;

  Color _defaultColor(int i) =>
      (i % 2 == 0) ? const Color(0xFF1565C0) : const Color(0xFF42A5F5);

  for (var i = 0; i < segs.length; i++) {
    final seg = segs[i];
    if (seg.length < 2) continue;
    final baseColor = (colorForIndex ?? _defaultColor).call(i);

    if (buildRight) {
      final rPts = _offsetPolylineByNormal(seg, offsetMeters, right: true);
      if (rPts.length >= 2) {
        out.add(TappableChangedPolyline(
          points: rPts,
          tag: '$sidePrefixRight:$i',
          color: baseColor,
          defaultColor: baseColor,
          strokeWidth: strokeWidth,
          isDotted: false,
          hitTestable: hitTestable,
        ));
      }
    }

    if (buildLeft) {
      final lPts = _offsetPolylineByNormal(seg, offsetMeters, right: false);
      if (lPts.length >= 2) {
        out.add(TappableChangedPolyline(
          points: lPts,
          tag: '$sidePrefixLeft:$i',
          color: baseColor,
          defaultColor: baseColor,
          strokeWidth: strokeWidth,
          isDotted: false,
          hitTestable: hitTestable,
        ));
      }
    }
  }

  return out;
}

// ======================================================
// 🔹 EXTENSÃO: Helpers de deslocamento por segmento (direita/esquerda)
// ======================================================
extension SegmentedAxisHelpers on SegmentedAxis {
  /// Número total de segmentos (entre estacas)
  int get segmentCount => segments.length;

  /// Segmento deslocado para a direita em relação ao eixo central
  List<LatLng> offsetSegmentRight(int idx, double offsetMeters) {
    if (idx < 0 || idx >= segments.length) return const [];
    return _offsetPolylineByNormal(segments[idx], offsetMeters, right: true);
  }

  /// Segmento deslocado para a esquerda em relação ao eixo central
  List<LatLng> offsetSegmentLeft(int idx, double offsetMeters) {
    if (idx < 0 || idx >= segments.length) return const [];
    return _offsetPolylineByNormal(segments[idx], offsetMeters, right: false);
  }
}
