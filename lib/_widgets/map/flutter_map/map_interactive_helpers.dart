// lib/_widgets/map/flutter_map/map_interactive_helpers.dart
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';

import 'package:sipged/_widgets/map/markers/tagged_marker.dart';
import 'package:sipged/_widgets/map/polygon/polygon_changed.dart';
import 'package:sipged/_widgets/map/polylines/tappable_changed_polyline.dart';

class _BBox {
  final double minLat;
  final double maxLat;
  final double minLng;
  final double maxLng;

  const _BBox({
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
  });

  bool contains(LatLng p) =>
      p.latitude >= minLat &&
          p.latitude <= maxLat &&
          p.longitude >= minLng &&
          p.longitude <= maxLng;

  static _BBox fromPoints(List<LatLng> pts) {
    double minLat = pts.first.latitude;
    double maxLat = pts.first.latitude;
    double minLng = pts.first.longitude;
    double maxLng = pts.first.longitude;

    for (final p in pts) {
      final lat = p.latitude;
      final lng = p.longitude;
      if (lat < minLat) minLat = lat;
      if (lat > maxLat) maxLat = lat;
      if (lng < minLng) minLng = lng;
      if (lng > maxLng) maxLng = lng;
    }

    return _BBox(minLat: minLat, maxLat: maxLat, minLng: minLng, maxLng: maxLng);
  }
}

/// Helper “puro” (sem BuildContext), focado em performance/manutenção.
/// Mantém caches (bbox) e parsing (lat/lng).
class MapInteractiveHelpers {
  final String Function(String) norm;

  MapInteractiveHelpers({required this.norm});

  // Cache de bbox por polígono (acelera hit-test)
  final Map<String, _BBox> _bboxByRegionNorm = <String, _BBox>{};

  Set<String> toNormSet(List<String>? lst) =>
      lst == null ? <String>{} : lst.map(norm).toSet();

  bool sameSet(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);

  // -----------------------
  // BBOX CACHE
  // -----------------------
  void rebuildPolygonBBoxes({required List<PolygonChanged> regionalPolys}) {
    _bboxByRegionNorm.clear();
    for (final reg in regionalPolys) {
      final pts = reg.polygon.points;
      if (pts.isEmpty) continue;
      final keyNorm = norm(reg.title);
      _bboxByRegionNorm[keyNorm] = _BBox.fromPoints(pts);
    }
  }

  void rebuildPolygonBBoxesIfNeeded({
    required List<PolygonChanged> oldPolys,
    required List<PolygonChanged> newPolys,
  }) {
    // heurística simples e segura
    final shouldRebuild = (oldPolys.length != newPolys.length) || !identical(oldPolys, newPolys);
    if (!shouldRebuild) return;
    rebuildPolygonBBoxes(regionalPolys: newPolys);
  }

  bool containsInBBox(String regionKeyNorm, LatLng p) {
    final bbox = _bboxByRegionNorm[regionKeyNorm];
    if (bbox == null) return true; // sem bbox → não bloqueia
    return bbox.contains(p);
  }

  // -----------------------
  // GEOMETRY: center
  // -----------------------
  bool hasAnyGeometry({
    List<LatLng>? initialGeometryPoints,
    List<PolygonChanged>? polygons,
    List<TappableChangedPolyline>? polylines,
    List<TaggedChangedMarker<dynamic>>? taggedMarkers,
    List<Marker>? extraMarkers,
  }) {
    return collectAllGeometryPoints(
      initialGeometryPoints: initialGeometryPoints,
      polygons: polygons,
      polylines: polylines,
      taggedMarkers: taggedMarkers,
      extraMarkers: extraMarkers,
    ).isNotEmpty;
  }

  LatLng? computeInitialCenterFromGeometries({
    List<LatLng>? initialGeometryPoints,
    List<PolygonChanged>? polygons,
    List<TappableChangedPolyline>? polylines,
    List<TaggedChangedMarker<dynamic>>? taggedMarkers,
    List<Marker>? extraMarkers,
  }) {
    final pts = collectAllGeometryPoints(
      initialGeometryPoints: initialGeometryPoints,
      polygons: polygons,
      polylines: polylines,
      taggedMarkers: taggedMarkers,
      extraMarkers: extraMarkers,
    );
    if (pts.isEmpty) return null;

    double minLat = pts.first.latitude;
    double maxLat = pts.first.latitude;
    double minLng = pts.first.longitude;
    double maxLng = pts.first.longitude;

    for (final p in pts) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    return LatLng((minLat + maxLat) / 2.0, (minLng + maxLng) / 2.0);
  }

  List<LatLng> collectAllGeometryPoints({
    List<LatLng>? initialGeometryPoints,
    List<PolygonChanged>? polygons,
    List<TappableChangedPolyline>? polylines,
    List<TaggedChangedMarker<dynamic>>? taggedMarkers,
    List<Marker>? extraMarkers,
  }) {
    if (initialGeometryPoints != null && initialGeometryPoints.isNotEmpty) {
      return List<LatLng>.from(initialGeometryPoints);
    }

    final pts = <LatLng>[];

    // 1) Polígonos
    final regs = polygons ?? const <PolygonChanged>[];
    for (final reg in regs) {
      pts.addAll(reg.polygon.points);
    }

    // 2) Polylines
    final lines = polylines;
    if (lines != null && lines.isNotEmpty) {
      for (final line in lines) {
        pts.addAll(line.points);
      }
    }

    // 3) Tagged markers
    final tagged = taggedMarkers;
    if (tagged != null && tagged.isNotEmpty) {
      for (final m in tagged) {
        pts.add(m.point);
      }
    }

    // 4) extra markers
    final extras = extraMarkers;
    if (extras != null && extras.isNotEmpty) {
      for (final m in extras) {
        pts.add(m.point);
      }
    }

    return pts;
  }

  // -----------------------
  // Hit-test: polygon
  // -----------------------
  bool pointInPolygon(LatLng p, List<LatLng> pts) {
    bool inside = false;
    for (int i = 0, j = pts.length - 1; i < pts.length; j = i++) {
      final xi = pts[i].latitude, yi = pts[i].longitude;
      final xj = pts[j].latitude, yj = pts[j].longitude;

      final intersect = ((yi > p.longitude) != (yj > p.longitude)) &&
          (p.latitude < (xj - xi) * (p.longitude - yi) / (yj - yi + 0.0) + xi);

      if (intersect) inside = !inside;
    }
    return inside;
  }

  // -----------------------
  // Properties helper
  // -----------------------
  String? getProp(PolygonChanged reg, String keyWanted) {
    final wanted = norm(keyWanted);
    final props = reg.properties;
    if (props is! List<Map<String, dynamic>>) return null;

    for (final m in props) {
      for (final e in m.entries) {
        if (norm(e.key) == wanted) {
          final v = e.value;
          if (v is String && v.trim().isNotEmpty) return v.trim();
        }
      }
    }
    return null;
  }

  // -----------------------
  // Parse lat/lng
  // -----------------------
  LatLng? parseLatLng(String s) {
    final reA =
    RegExp(r'(-?\d{1,3}(?:\.\d+)?)\s*[,;\s]\s*(-?\d{1,3}(?:\.\d+)?)');
    final mA = reA.firstMatch(s);
    if (mA != null) {
      final lat = double.tryParse(mA.group(1)!);
      final lng = double.tryParse(mA.group(2)!);
      if (lat != null && lng != null && _isValidLatLng(lat, lng)) {
        return LatLng(lat, lng);
      }
    }

    final reB = RegExp(
      r'(?:(N|S)\s*)?(\d{1,3}(?:\.\d+)?)\D+(?:(E|W|L|O)\s*)?(\d{1,3}(?:\.\d+)?)',
      caseSensitive: false,
    );
    final mB = reB.firstMatch(s);
    if (mB != null) {
      final ns = (mB.group(1) ?? '').toUpperCase();
      final ew = (mB.group(3) ?? '').toUpperCase();
      final latVal = double.tryParse(mB.group(2)!);
      final lngVal = double.tryParse(mB.group(4)!);
      if (latVal != null && lngVal != null) {
        var lat = latVal;
        var lng = lngVal;
        if (ns == 'S') lat = -lat.abs();
        if (ew == 'W' || ew == 'O' || ew == 'L') lng = -lng.abs();
        if (_isValidLatLng(lat, lng)) return LatLng(lat, lng);
      }
    }

    final reC = RegExp(
      r'lat[:=]\s*(-?\d+(?:\.\d+)?)\D+lon[g]?[:=]\s*(-?\d+(?:\.\d+)?)',
      caseSensitive: false,
    );
    final mC = reC.firstMatch(s);
    if (mC != null) {
      final lat = double.tryParse(mC.group(1)!);
      final lng = double.tryParse(mC.group(2)!);
      if (lat != null && lng != null && _isValidLatLng(lat, lng)) {
        return LatLng(lat, lng);
      }
    }
    return null;
  }

  bool _isValidLatLng(double lat, double lng) =>
      lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
}
