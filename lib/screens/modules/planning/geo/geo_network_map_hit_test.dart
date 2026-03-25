import 'dart:math' as math;

import 'package:latlong2/latlong.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/geo_feature_data.dart';

class GeoNetworkMapHitTest {
  GeoNetworkMapHitTest._();

  static const Distance _distance = Distance();

  static List<FeatureHitEntry> buildHitEntries({
    required List<String> orderedActiveLayerIds,
    required Map<String, List<GeoFeatureData>> featuresByLayer,
  }) {
    final entries = <FeatureHitEntry>[];

    for (final layerId in orderedActiveLayerIds.reversed) {
      final layerFeatures = featuresByLayer[layerId];
      if (layerFeatures == null || layerFeatures.isEmpty) continue;

      for (final feature in layerFeatures) {
        entries.add(
          FeatureHitEntry(
            feature: feature,
            markerBounds: _computeMarkerBounds(feature.markerPoints),
            lineBounds: _computeBoundsForLineParts(feature.lineParts),
            polygonBounds: _computeBoundsForRings(feature.polygonRings),
          ),
        );
      }
    }

    return entries;
  }

  static GeoFeatureData? findFeatureAt({
    required LatLng tap,
    required double zoom,
    required List<FeatureHitEntry> entries,
  }) {
    for (final entry in entries) {
      if (_hitMarker(entry, tap, zoom)) return entry.feature;
      if (_hitLine(entry, tap, zoom)) return entry.feature;
      if (_hitPolygon(entry, tap)) return entry.feature;
    }

    return null;
  }

  static bool _hitMarker(FeatureHitEntry entry, LatLng tap, double zoom) {
    final toleranceMeters = zoom >= 14 ? 20.0 : zoom >= 10 ? 60.0 : 120.0;

    if (!_boundsMayContain(
      entry.markerBounds,
      tap,
      toleranceMeters,
    )) {
      return false;
    }

    for (final p in entry.feature.markerPoints) {
      if (_distance.as(LengthUnit.Meter, tap, p) <= toleranceMeters) {
        return true;
      }
    }
    return false;
  }

  static bool _hitLine(FeatureHitEntry entry, LatLng tap, double zoom) {
    final toleranceMeters = zoom >= 14 ? 25.0 : zoom >= 10 ? 80.0 : 200.0;

    if (!_boundsMayContain(entry.lineBounds, tap, toleranceMeters)) {
      return false;
    }

    for (final line in entry.feature.lineParts) {
      for (int i = 0; i < line.length - 1; i++) {
        final a = line[i];
        final b = line[i + 1];

        if (!_segmentBoundsMayContain(a, b, tap, toleranceMeters)) {
          continue;
        }

        final da = _distance.as(LengthUnit.Meter, tap, a);
        final db = _distance.as(LengthUnit.Meter, tap, b);
        final seg = _distance.as(LengthUnit.Meter, a, b);

        if (seg <= 0) continue;

        if ((da + db - seg).abs() <= toleranceMeters) {
          return true;
        }
      }
    }

    return false;
  }

  static bool _hitPolygon(FeatureHitEntry entry, LatLng tap) {
    if (entry.polygonBounds != null && !entry.polygonBounds!.contains(tap)) {
      return false;
    }

    for (final ring in entry.feature.polygonRings) {
      final ringBounds = _computeBoundsForPoints(ring);
      if (ringBounds != null && !ringBounds.contains(tap)) continue;

      if (_pointInPolygon(tap, ring)) return true;
    }
    return false;
  }

  static bool _boundsMayContain(
      LatLngBoundsLite? bounds,
      LatLng tap,
      double toleranceMeters,
      ) {
    if (bounds == null) return false;
    return bounds.expandMeters(tap.latitude, toleranceMeters).contains(tap);
  }

  static bool _segmentBoundsMayContain(
      LatLng a,
      LatLng b,
      LatLng tap,
      double toleranceMeters,
      ) {
    final bounds = LatLngBoundsLite(
      minLat: math.min(a.latitude, b.latitude),
      maxLat: math.max(a.latitude, b.latitude),
      minLng: math.min(a.longitude, b.longitude),
      maxLng: math.max(a.longitude, b.longitude),
    );

    return bounds.expandMeters(tap.latitude, toleranceMeters).contains(tap);
  }

  static bool _pointInPolygon(LatLng point, List<LatLng> polygon) {
    if (polygon.length < 3) return false;

    bool inside = false;
    int j = polygon.length - 1;

    for (int i = 0; i < polygon.length; i++) {
      final xi = polygon[i].longitude;
      final yi = polygon[i].latitude;
      final xj = polygon[j].longitude;
      final yj = polygon[j].latitude;

      final intersect = ((yi > point.latitude) != (yj > point.latitude)) &&
          (point.longitude <
              (xj - xi) * (point.latitude - yi) /
                  ((yj - yi) == 0 ? 0.0000001 : (yj - yi)) +
                  xi);

      if (intersect) inside = !inside;
      j = i;
    }

    return inside;
  }

  static LatLngBoundsLite? _computeMarkerBounds(List<LatLng> points) {
    if (points.isEmpty) return null;
    return _computeBoundsForPoints(points);
  }

  static LatLngBoundsLite? _computeBoundsForLineParts(List<List<LatLng>> parts) {
    LatLngBoundsLite? out;

    for (final part in parts) {
      final bounds = _computeBoundsForPoints(part);
      if (bounds == null) continue;
      out = out == null ? bounds : out.expandToInclude(bounds);
    }

    return out;
  }

  static LatLngBoundsLite? _computeBoundsForRings(List<List<LatLng>> rings) {
    LatLngBoundsLite? out;

    for (final ring in rings) {
      final bounds = _computeBoundsForPoints(ring);
      if (bounds == null) continue;
      out = out == null ? bounds : out.expandToInclude(bounds);
    }

    return out;
  }

  static LatLngBoundsLite? _computeBoundsForPoints(List<LatLng> points) {
    if (points.isEmpty) return null;

    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;

    for (var i = 1; i < points.length; i++) {
      final p = points[i];
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    return LatLngBoundsLite(
      minLat: minLat,
      maxLat: maxLat,
      minLng: minLng,
      maxLng: maxLng,
    );
  }
}

class FeatureHitEntry {
  final GeoFeatureData feature;
  final LatLngBoundsLite? markerBounds;
  final LatLngBoundsLite? lineBounds;
  final LatLngBoundsLite? polygonBounds;

  const FeatureHitEntry({
    required this.feature,
    required this.markerBounds,
    required this.lineBounds,
    required this.polygonBounds,
  });
}

class LatLngBoundsLite {
  final double minLat;
  final double maxLat;
  final double minLng;
  final double maxLng;

  const LatLngBoundsLite({
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
  });

  bool contains(LatLng point) {
    return point.latitude >= minLat &&
        point.latitude <= maxLat &&
        point.longitude >= minLng &&
        point.longitude <= maxLng;
  }

  LatLngBoundsLite expandToInclude(LatLngBoundsLite other) {
    return LatLngBoundsLite(
      minLat: math.min(minLat, other.minLat),
      maxLat: math.max(maxLat, other.maxLat),
      minLng: math.min(minLng, other.minLng),
      maxLng: math.max(maxLng, other.maxLng),
    );
  }

  LatLngBoundsLite expandMeters(double referenceLat, double meters) {
    final latDelta = meters / 111320.0;
    final cosLat = math.cos(referenceLat * math.pi / 180).abs();
    final lngDelta = meters / (111320.0 * (cosLat < 0.0001 ? 0.0001 : cosLat));

    return LatLngBoundsLite(
      minLat: minLat - latDelta,
      maxLat: maxLat + latDelta,
      minLng: minLng - lngDelta,
      maxLng: maxLng + lngDelta,
    );
  }
}