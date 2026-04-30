import 'dart:math' as math;

import 'package:latlong2/latlong.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/feature_data.dart';

class MapHitTest {
  MapHitTest._();

  static const Distance _distance = Distance();

  static final Expando<_FeatureHitEntryCache> _entryCache =
  Expando<_FeatureHitEntryCache>('map_hit_entry_cache');

  static List<FeatureHitEntry> buildHitEntries({
    required List<String> orderedActiveLayerIds,
    required Map<String, List<FeatureData>> featuresByLayer,
  }) {
    final entries = <FeatureHitEntry>[];

    for (final layerId in orderedActiveLayerIds.reversed) {
      final layerFeatures = featuresByLayer[layerId];
      if (layerFeatures == null || layerFeatures.isEmpty) continue;

      for (final feature in layerFeatures.reversed) {
        entries.add(_entryForFeature(feature));
      }
    }

    return entries;
  }

  static FeatureHitEntry _entryForFeature(FeatureData feature) {
    final signature = _featureGeometrySignature(feature);
    final cached = _entryCache[feature];

    if (cached != null && cached.signature == signature) {
      return cached.entry;
    }

    final entry = FeatureHitEntry(
      feature: feature,
      markerBounds: _computeMarkerBounds(feature.markerPoints),
      lineBounds: _computeBoundsForLineParts(feature.lineParts),
      polygonBounds: _computeBoundsForRings(feature.polygonRings),
    );

    _entryCache[feature] = _FeatureHitEntryCache(
      signature: signature,
      entry: entry,
    );

    return entry;
  }

  static int _featureGeometrySignature(FeatureData feature) {
    LatLng? firstMarker;
    LatLng? lastMarker;

    if (feature.markerPoints.isNotEmpty) {
      firstMarker = feature.markerPoints.first;
      lastMarker = feature.markerPoints.last;
    }

    LatLng? firstLinePoint;
    LatLng? lastLinePoint;

    if (feature.lineParts.isNotEmpty && feature.lineParts.first.isNotEmpty) {
      firstLinePoint = feature.lineParts.first.first;

      final lastPart = feature.lineParts.last;
      if (lastPart.isNotEmpty) {
        lastLinePoint = lastPart.last;
      }
    }

    LatLng? firstPolygonPoint;
    LatLng? lastPolygonPoint;

    if (feature.polygonRings.isNotEmpty &&
        feature.polygonRings.first.isNotEmpty) {
      firstPolygonPoint = feature.polygonRings.first.first;

      final lastRing = feature.polygonRings.last;
      if (lastRing.isNotEmpty) {
        lastPolygonPoint = lastRing.last;
      }
    }

    return Object.hashAll([
      feature.selectionKey,
      feature.geometryType,
      feature.markerPoints.length,
      feature.lineParts.length,
      feature.polygonRings.length,
      firstMarker?.latitude.toStringAsFixed(6),
      firstMarker?.longitude.toStringAsFixed(6),
      lastMarker?.latitude.toStringAsFixed(6),
      lastMarker?.longitude.toStringAsFixed(6),
      firstLinePoint?.latitude.toStringAsFixed(6),
      firstLinePoint?.longitude.toStringAsFixed(6),
      lastLinePoint?.latitude.toStringAsFixed(6),
      lastLinePoint?.longitude.toStringAsFixed(6),
      firstPolygonPoint?.latitude.toStringAsFixed(6),
      firstPolygonPoint?.longitude.toStringAsFixed(6),
      lastPolygonPoint?.latitude.toStringAsFixed(6),
      lastPolygonPoint?.longitude.toStringAsFixed(6),
    ]);
  }

  static FeatureData? findFeatureAt({
    required LatLng tap,
    required double zoom,
    required List<FeatureHitEntry> entries,
  }) {
    for (final entry in entries) {
      if (_hitMarker(entry, tap, zoom)) return entry.feature;
      if (_hitLine(entry, tap, zoom)) return entry.feature;
      if (_hitPolygon(entry, tap, zoom)) return entry.feature;
    }

    return null;
  }

  static bool _hitMarker(
      FeatureHitEntry entry,
      LatLng tap,
      double zoom,
      ) {
    final toleranceMeters = _pixelToleranceToMeters(
      latitude: tap.latitude,
      zoom: zoom,
      pixels: _markerTolerancePixels(zoom),
      minMeters: 18,
      maxMeters: 9000,
    );

    if (!_boundsMayContain(entry.markerBounds, tap, toleranceMeters)) {
      return false;
    }

    for (final point in entry.feature.markerPoints) {
      final d = _distance.as(
        LengthUnit.Meter,
        tap,
        point,
      );

      if (d <= toleranceMeters) {
        return true;
      }
    }

    return false;
  }

  static bool _hitLine(
      FeatureHitEntry entry,
      LatLng tap,
      double zoom,
      ) {
    final toleranceMeters = _pixelToleranceToMeters(
      latitude: tap.latitude,
      zoom: zoom,
      pixels: _lineTolerancePixels(zoom),
      minMeters: 20,
      maxMeters: 12000,
    );

    if (!_boundsMayContain(entry.lineBounds, tap, toleranceMeters)) {
      return false;
    }

    for (final line in entry.feature.lineParts) {
      if (line.length < 2) continue;

      for (int i = 0; i < line.length - 1; i++) {
        final a = line[i];
        final b = line[i + 1];

        if (!_segmentBoundsMayContain(a, b, tap, toleranceMeters)) {
          continue;
        }

        final d = _distancePointToSegmentMeters(
          point: tap,
          a: a,
          b: b,
        );

        if (d <= toleranceMeters) {
          return true;
        }
      }
    }

    return false;
  }

  static bool _hitPolygon(
      FeatureHitEntry entry,
      LatLng tap,
      double zoom,
      ) {
    final toleranceMeters = _pixelToleranceToMeters(
      latitude: tap.latitude,
      zoom: zoom,
      pixels: _polygonTolerancePixels(zoom),
      minMeters: 12,
      maxMeters: 10000,
    );

    if (!_boundsMayContain(entry.polygonBounds, tap, toleranceMeters)) {
      return false;
    }

    for (final ring in entry.feature.polygonRings) {
      if (ring.length < 3) continue;

      final ringBounds = _computeBoundsForPoints(ring);

      if (ringBounds != null &&
          !ringBounds.expandMeters(tap.latitude, toleranceMeters).contains(tap)) {
        continue;
      }

      if (_pointInPolygon(tap, ring)) {
        return true;
      }

      if (_pointNearRing(
        tap: tap,
        ring: ring,
        toleranceMeters: toleranceMeters,
      )) {
        return true;
      }
    }

    return false;
  }

  static double _markerTolerancePixels(double zoom) {
    if (zoom < 7) return 22;
    if (zoom < 10) return 20;
    if (zoom < 13) return 18;
    return 16;
  }

  static double _lineTolerancePixels(double zoom) {
    if (zoom < 7) return 18;
    if (zoom < 10) return 16;
    if (zoom < 13) return 14;
    return 12;
  }

  static double _polygonTolerancePixels(double zoom) {
    if (zoom < 7) return 14;
    if (zoom < 10) return 12;
    if (zoom < 13) return 10;
    return 8;
  }

  static double _pixelToleranceToMeters({
    required double latitude,
    required double zoom,
    required double pixels,
    required double minMeters,
    required double maxMeters,
  }) {
    final metersPerPixel = _metersPerPixel(
      latitude: latitude,
      zoom: zoom,
    );

    return (metersPerPixel * pixels).clamp(
      minMeters,
      maxMeters,
    );
  }

  static double _metersPerPixel({
    required double latitude,
    required double zoom,
  }) {
    final latRad = latitude * math.pi / 180.0;
    final cosLat = math.cos(latRad).abs().clamp(0.0001, 1.0);

    return (156543.03392804097 * cosLat) / math.pow(2.0, zoom);
  }

  static bool _pointNearRing({
    required LatLng tap,
    required List<LatLng> ring,
    required double toleranceMeters,
  }) {
    if (ring.length < 2) return false;

    for (int i = 0; i < ring.length; i++) {
      final a = ring[i];
      final b = ring[(i + 1) % ring.length];

      if (!_segmentBoundsMayContain(a, b, tap, toleranceMeters)) {
        continue;
      }

      final d = _distancePointToSegmentMeters(
        point: tap,
        a: a,
        b: b,
      );

      if (d <= toleranceMeters) {
        return true;
      }
    }

    return false;
  }

  static double _distancePointToSegmentMeters({
    required LatLng point,
    required LatLng a,
    required LatLng b,
  }) {
    final ap = _distance.as(LengthUnit.Meter, a, point);
    final bp = _distance.as(LengthUnit.Meter, b, point);
    final ab = _distance.as(LengthUnit.Meter, a, b);

    if (ab <= 0) return ap;

    final s = (ap + bp + ab) / 2.0;
    final areaSquared = s * (s - ap) * (s - bp) * (s - ab);

    if (areaSquared <= 0) {
      return math.min(ap, bp);
    }

    final area = math.sqrt(areaSquared);
    final height = (2.0 * area) / ab;

    final projectionInside =
        (ap * ap + ab * ab >= bp * bp) &&
            (bp * bp + ab * ab >= ap * ap);

    if (!projectionInside) {
      return math.min(ap, bp);
    }

    return height;
  }

  static bool _boundsMayContain(
      LatLngBoundsLite? bounds,
      LatLng tap,
      double toleranceMeters,
      ) {
    if (bounds == null) return false;

    return bounds
        .expandMeters(
      tap.latitude,
      toleranceMeters,
    )
        .contains(tap);
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

    return bounds
        .expandMeters(
      tap.latitude,
      toleranceMeters,
    )
        .contains(tap);
  }

  static bool _pointInPolygon(
      LatLng point,
      List<LatLng> polygon,
      ) {
    if (polygon.length < 3) return false;

    var inside = false;
    var j = polygon.length - 1;

    for (var i = 0; i < polygon.length; i++) {
      final xi = polygon[i].longitude;
      final yi = polygon[i].latitude;
      final xj = polygon[j].longitude;
      final yj = polygon[j].latitude;

      final denominator = (yj - yi).abs() < 0.0000001
          ? 0.0000001
          : yj - yi;

      final intersect =
          ((yi > point.latitude) != (yj > point.latitude)) &&
              (point.longitude <
                  ((xj - xi) * (point.latitude - yi) / denominator) + xi);

      if (intersect) {
        inside = !inside;
      }

      j = i;
    }

    return inside;
  }

  static LatLngBoundsLite? _computeMarkerBounds(List<LatLng> points) {
    if (points.isEmpty) return null;

    return _computeBoundsForPoints(points);
  }

  static LatLngBoundsLite? _computeBoundsForLineParts(
      List<List<LatLng>> parts,
      ) {
    LatLngBoundsLite? out;

    for (final part in parts) {
      final bounds = _computeBoundsForPoints(part);
      if (bounds == null) continue;

      out = out == null ? bounds : out.expandToInclude(bounds);
    }

    return out;
  }

  static LatLngBoundsLite? _computeBoundsForRings(
      List<List<LatLng>> rings,
      ) {
    LatLngBoundsLite? out;

    for (final ring in rings) {
      final bounds = _computeBoundsForPoints(ring);
      if (bounds == null) continue;

      out = out == null ? bounds : out.expandToInclude(bounds);
    }

    return out;
  }

  static LatLngBoundsLite? _computeBoundsForPoints(
      List<LatLng> points,
      ) {
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
  final FeatureData feature;
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

class _FeatureHitEntryCache {
  final int signature;
  final FeatureHitEntry entry;

  const _FeatureHitEntryCache({
    required this.signature,
    required this.entry,
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

  LatLngBoundsLite expandMeters(
      double referenceLat,
      double meters,
      ) {
    final latDelta = meters / 111320.0;

    final cosLat = math.cos(referenceLat * math.pi / 180).abs();
    final safeCosLat = cosLat < 0.0001 ? 0.0001 : cosLat;

    final lngDelta = meters / (111320.0 * safeCosLat);

    return LatLngBoundsLite(
      minLat: minLat - latDelta,
      maxLat: maxLat + latDelta,
      minLng: minLng - lngDelta,
      maxLng: maxLng + lngDelta,
    );
  }
}