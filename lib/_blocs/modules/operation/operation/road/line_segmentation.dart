import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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

LatLng _offsetByMeters(
    LatLng p,
    double distanceMeters,
    double bearingRad,
    ) {
  final lat = p.latitude * math.pi / 180.0;
  final lon = p.longitude * math.pi / 180.0;
  final dDivR = distanceMeters / _earthRadius;

  final newLat = math.asin(
    math.sin(lat) * math.cos(dDivR) +
        math.cos(lat) * math.sin(dDivR) * math.cos(bearingRad),
  );

  final newLon = lon +
      math.atan2(
        math.sin(bearingRad) * math.sin(dDivR) * math.cos(lat),
        math.cos(dDivR) - math.sin(lat) * math.sin(newLat),
      );

  return LatLng(
    newLat * 180.0 / math.pi,
    newLon * 180.0 / math.pi,
  );
}

double _metersPerPixelAt(
    double latitude,
    double zoom,
    ) {
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

  return stepPx >= need ? 0.0 : need;
}

double _normalizePi(double a) {
  while (a <= -math.pi) {
    a += 2 * math.pi;
  }

  while (a > math.pi) {
    a -= 2 * math.pi;
  }

  return a;
}

Offset _latLngToWorldPixel(
    LatLng p,
    double zoom,
    ) {
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

  const _Sample(
      this.p,
      this.bearing,
      );
}

/// Amostra o eixo a cada `stepMeters` e inclui a estaca 0.
List<_Sample> _sampleAlong(
    List<LatLng> axis,
    double stepMeters,
    ) {
  if (axis.length < 2) return const <_Sample>[];

  final out = <_Sample>[];

  double acc = 0.0;
  var curr = axis.first;
  double target = stepMeters;

  for (var i = 1; i < axis.length; i++) {
    final next = axis[i];
    final segLen = _distTool.distance(curr, next);
    final segBearing = _bearing(curr, next);

    if (segLen <= 0) {
      curr = next;
      continue;
    }

    while (acc + segLen >= target) {
      final remain = target - acc;
      final t = remain / segLen;

      final lat = curr.latitude + (next.latitude - curr.latitude) * t;
      final lon = curr.longitude + (next.longitude - curr.longitude) * t;

      out.add(
        _Sample(
          LatLng(lat, lon),
          segBearing,
        ),
      );

      target += stepMeters;
    }

    acc += segLen;
    curr = next;
  }

  out.insert(
    0,
    _Sample(
      axis.first,
      _bearing(axis[0], axis[1]),
    ),
  );

  return out;
}

/// Dados auxiliares da estaca.
///
/// Não é MarkerData. É apenas um payload opcional para montar o widget visual.
class StakeMarkerPayload {
  final int idx;
  final String label;
  final double normalAngle;
  final double tickPx;
  final LatLng point;

  const StakeMarkerPayload({
    required this.idx,
    required this.label,
    required this.normalAngle,
    required this.tickPx,
    required this.point,
  });

  Map<String, dynamic> toMap() {
    return {
      'idx': idx,
      'label': label,
      'normalAngle': normalAngle,
      'tickPx': tickPx,
      'latitude': point.latitude,
      'longitude': point.longitude,
    };
  }
}

Widget _defaultStakeMarkerChild(
    BuildContext context,
    StakeMarkerPayload payload,
    ) {
  const double size = 34.0;

  return SizedBox(
    width: 44,
    height: 44,
    child: Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Transform.rotate(
          angle: payload.normalAngle,
          child: Container(
            width: payload.tickPx,
            height: 2,
            margin: EdgeInsets.only(left: payload.tickPx),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
        Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.25),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            payload.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Estacas upright com anti-colisão.
///
/// Retorna Marker nativo do flutter_map.
List<Marker> buildStakeMarkersUprightWithTickRight({
  required BuildContext context,
  required List<LatLng> axis,
  double stepMeters = 20.0,
  double offsetRightMeters = 6.0,
  required double zoom,
  double minLabelPixelGap = 100,
  double width = 44,
  double height = 44,
  Alignment alignment = Alignment.center,
  bool rotate = false,
  Widget Function(BuildContext context, StakeMarkerPayload payload)? childBuilder,
}) {
  if (axis.length < 2) return const [];

  final samples = _sampleAlong(axis, stepMeters);
  if (samples.isEmpty) return const [];

  final out = <Marker>[];

  Offset? lastPx;

  for (var i = 0; i < samples.length; i++) {
    final s = samples[i];

    final nAngle = _normalizePi(s.bearing + math.pi / 2);
    final anchor = s.p;

    if (minLabelPixelGap > 0) {
      final currPx = _latLngToWorldPixel(anchor, zoom);

      if (lastPx != null) {
        final d = (currPx - lastPx).distance;
        if (d < minLabelPixelGap) continue;
      }

      lastPx = currPx;
    }

    final payload = StakeMarkerPayload(
      idx: i,
      label: '$i',
      normalAngle: nAngle,
      tickPx: 12.0,
      point: anchor,
    );

    out.add(
      Marker(
        point: anchor,
        width: width,
        height: height,
        alignment: alignment,
        rotate: rotate,
        child: childBuilder?.call(context, payload) ??
            _defaultStakeMarkerChild(context, payload),
      ),
    );
  }

  return out;
}

// ======================================================
// Segmentação do eixo e helpers de paralelas
// ======================================================

class SegmentedAxis {
  /// Segmento i vai de stake i a stake i+1.
  final List<List<LatLng>> segments;

  /// Posições exatas das estacas.
  final List<LatLng> stakePositions;

  const SegmentedAxis(
      this.segments,
      this.stakePositions,
      );

  bool get isEmpty => segments.isEmpty;

  bool get isNotEmpty => segments.isNotEmpty;
}

LatLng _interpolateByMeters(
    LatLng a,
    LatLng b,
    double distanceFromA,
    ) {
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
  if (axis.length < 2) {
    return const SegmentedAxis(
      <List<LatLng>>[],
      <LatLng>[],
    );
  }

  final samples = _sampleAlong(axis, stepMeters);

  if (samples.isEmpty) {
    return const SegmentedAxis(
      <List<LatLng>>[],
      <LatLng>[],
    );
  }

  final stakePositions = samples.map((s) => s.p).toList(growable: false);
  final segments = <List<LatLng>>[];

  var curr = axis.first;
  var segStart = curr;
  var axisIdx = 1;

  void advanceUntil(LatLng target) {
    final currTarget = target;
    final currSeg = <LatLng>[segStart];

    while (true) {
      if (axisIdx >= axis.length) {
        if (currSeg.last != curr) currSeg.add(curr);
        if (currSeg.length >= 2) segments.add(currSeg);
        return;
      }

      final next = axis[axisIdx];
      final segLen = _distTool.distance(curr, next);

      if (segLen <= 0) {
        curr = next;
        axisIdx++;
        continue;
      }

      final toTarget = _distTool.distance(segStart, currTarget);
      final toCurr = _distTool.distance(segStart, curr);
      final along = toTarget - toCurr;

      if (along <= segLen + 1e-6) {
        final cutPoint = _interpolateByMeters(curr, next, along);

        if (currSeg.last != cutPoint) currSeg.add(cutPoint);
        if (currSeg.length >= 2) segments.add(currSeg);

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
    advanceUntil(stakePositions[i]);
  }

  final lastStake = stakePositions.last;
  final totalEnd = axis.last;
  final tailLen = _distTool.distance(lastStake, totalEnd);

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

  return SegmentedAxis(
    segments,
    stakePositions,
  );
}

Color _defaultSegmentColor(int i) {
  return i.isEven ? const Color(0xFF1565C0) : const Color(0xFF42A5F5);
}

/// Central.
///
/// Agora retorna `Polyline<Object>` nativa do flutter_map.
/// O antigo `tag` agora fica em `hitValue`.
List<Polyline<Object>> buildSegmentPolylines({
  required SegmentedAxis segmented,
  Color Function(int idx)? colorForIndex,
  double strokeWidth = 5.0,
  bool hitTestable = true,
  String tagPrefix = 'segC',
}) {
  final out = <Polyline<Object>>[];
  final segs = segmented.segments;

  for (var i = 0; i < segs.length; i++) {
    final seg = segs[i];

    if (seg.length < 2) continue;

    final baseColor = (colorForIndex ?? _defaultSegmentColor).call(i);

    out.add(
      Polyline<Object>(
        points: seg,
        color: baseColor,
        strokeWidth: strokeWidth,
        hitValue: '$tagPrefix:$i',
      ),
    );
  }

  return out;
}

/// Desloca uma lista de pontos seguindo a normal local ponto-a-ponto.
List<LatLng> _offsetPolylineByNormal(
    List<LatLng> pts,
    double offsetMeters, {
      required bool right,
    }) {
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

      final x = math.cos(b1) + math.cos(b2);
      final y = math.sin(b1) + math.sin(b2);

      brg = math.atan2(y, x);
    }

    final rightNormal = _normalizePi(brg + math.pi / 2);
    final leftNormal = _normalizePi(rightNormal + math.pi);
    final use = right ? rightNormal : leftNormal;

    out.add(
      _offsetByMeters(
        pts[k],
        offsetMeters.abs(),
        use,
      ),
    );
  }

  return out;
}

/// Paralelas segmentadas, alinhadas índice-a-índice à central.
///
/// Agora retorna `Polyline<Object>` nativa do flutter_map.
/// Os antigos `tag`s agora ficam em `hitValue`.
List<Polyline<Object>> buildParallelSegmentPolylines({
  required SegmentedAxis segmented,
  double offsetMeters = 3.5,
  bool buildRight = true,
  bool buildLeft = true,
  Color Function(int idx)? colorForIndex,
  double strokeWidth = 4.0,
  bool hitTestable = true,
  String sidePrefixRight = 'segR',
  String sidePrefixLeft = 'segL',
}) {
  final out = <Polyline<Object>>[];
  final segs = segmented.segments;

  for (var i = 0; i < segs.length; i++) {
    final seg = segs[i];

    if (seg.length < 2) continue;

    final baseColor = (colorForIndex ?? _defaultSegmentColor).call(i);

    if (buildRight) {
      final rPts = _offsetPolylineByNormal(
        seg,
        offsetMeters,
        right: true,
      );

      if (rPts.length >= 2) {
        out.add(
          Polyline<Object>(
            points: rPts,
            color: baseColor,
            strokeWidth: strokeWidth,
            hitValue: '$sidePrefixRight:$i',
          ),
        );
      }
    }

    if (buildLeft) {
      final lPts = _offsetPolylineByNormal(
        seg,
        offsetMeters,
        right: false,
      );

      if (lPts.length >= 2) {
        out.add(
          Polyline<Object>(
            points: lPts,
            color: baseColor,
            strokeWidth: strokeWidth,
            hitValue: '$sidePrefixLeft:$i',
          ),
        );
      }
    }
  }

  return out;
}

// ======================================================
// EXTENSÃO: Helpers de deslocamento por segmento
// ======================================================

extension SegmentedAxisHelpers on SegmentedAxis {
  int get segmentCount => segments.length;

  List<LatLng> offsetSegmentRight(
      int idx,
      double offsetMeters,
      ) {
    if (idx < 0 || idx >= segments.length) return const [];

    return _offsetPolylineByNormal(
      segments[idx],
      offsetMeters,
      right: true,
    );
  }

  List<LatLng> offsetSegmentLeft(
      int idx,
      double offsetMeters,
      ) {
    if (idx < 0 || idx >= segments.length) return const [];

    return _offsetPolylineByNormal(
      segments[idx],
      offsetMeters,
      right: false,
    );
  }
}