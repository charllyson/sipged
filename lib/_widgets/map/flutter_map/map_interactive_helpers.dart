import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:sipged/_widgets/map/markers/marker_changed_data.dart';
import 'package:sipged/_widgets/map/polygon/polygon_changed_data.dart';
import 'package:sipged/_widgets/map/polylines/polyline_changed_data.dart';

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

  bool contains(LatLng p) {
    return p.latitude >= minLat &&
        p.latitude <= maxLat &&
        p.longitude >= minLng &&
        p.longitude <= maxLng;
  }

  static _BBox fromPoints(List<LatLng> pts) {
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

    return _BBox(
      minLat: minLat,
      maxLat: maxLat,
      minLng: minLng,
      maxLng: maxLng,
    );
  }
}

/// Helper puro, sem BuildContext.
/// Centraliza parsing, bbox e utilitários geométricos.
class MapInteractiveHelpers {
  final String Function(String) norm;

  MapInteractiveHelpers({required this.norm});

  final Map<String, _BBox> _bboxByRegionNorm = <String, _BBox>{};

  Set<String> toNormSet(List<String>? lst) {
    if (lst == null || lst.isEmpty) return <String>{};
    return lst.map(norm).toSet();
  }

  bool sameSet(Set<String> a, Set<String> b) {
    return a.length == b.length && a.containsAll(b);
  }

  // =========================================================
  // CACHE DE BBOX DOS POLÍGONOS
  // =========================================================

  void rebuildPolygonBBoxes({required List<PolygonChangedData> regionalPolys}) {
    _bboxByRegionNorm.clear();

    for (final reg in regionalPolys) {
      final pts = reg.polygon.points;
      if (pts.isEmpty) continue;
      _bboxByRegionNorm[norm(reg.title)] = _BBox.fromPoints(pts);
    }
  }

  void rebuildPolygonBBoxesIfNeeded({
    required List<PolygonChangedData> oldPolys,
    required List<PolygonChangedData> newPolys,
  }) {
    final shouldRebuild =
        oldPolys.length != newPolys.length || !identical(oldPolys, newPolys);

    if (!shouldRebuild) return;
    rebuildPolygonBBoxes(regionalPolys: newPolys);
  }

  bool containsInBBox(String regionKeyNorm, LatLng p) {
    final bbox = _bboxByRegionNorm[regionKeyNorm];
    if (bbox == null) return true;
    return bbox.contains(p);
  }

  // =========================================================
  // GEOMETRIAS / CENTRO INICIAL
  // =========================================================

  bool hasAnyGeometry({
    List<LatLng>? initialGeometryPoints,
    List<PolygonChangedData>? polygons,
    List<PolylineChangedData>? polylines,
    List<MarkerChangedData<dynamic>>? taggedMarkers,
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
    List<PolygonChangedData>? polygons,
    List<PolylineChangedData>? polylines,
    List<MarkerChangedData<dynamic>>? taggedMarkers,
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

    return LatLng(
      (minLat + maxLat) / 2.0,
      (minLng + maxLng) / 2.0,
    );
  }

  List<LatLng> collectAllGeometryPoints({
    List<LatLng>? initialGeometryPoints,
    List<PolygonChangedData>? polygons,
    List<PolylineChangedData>? polylines,
    List<MarkerChangedData<dynamic>>? taggedMarkers,
    List<Marker>? extraMarkers,
  }) {
    // Caso já venha uma lista preparada externamente, usa ela direto.
    if (initialGeometryPoints != null && initialGeometryPoints.isNotEmpty) {
      return List<LatLng>.from(initialGeometryPoints);
    }

    final pts = <LatLng>[];

    final regs = polygons ?? const <PolygonChangedData>[];
    for (final reg in regs) {
      pts.addAll(reg.polygon.points);
    }

    final lines = polylines ?? const <PolylineChangedData>[];
    for (final line in lines) {
      pts.addAll(line.points);
    }

    final tagged = taggedMarkers ?? const <MarkerChangedData<dynamic>>[];
    for (final m in tagged) {
      pts.add(m.point);
    }

    final extras = extraMarkers ?? const <Marker>[];
    for (final m in extras) {
      pts.add(m.point);
    }

    return pts;
  }

  // =========================================================
  // HIT-TEST DE POLÍGONO
  // =========================================================

  /// Ray casting.
  /// Aqui usamos latitude como "x" e longitude como "y" para manter
  /// consistência com a estrutura anterior.
  bool pointInPolygon(LatLng p, List<LatLng> pts) {
    if (pts.length < 3) return false;

    bool inside = false;

    for (int i = 0, j = pts.length - 1; i < pts.length; j = i++) {
      final xi = pts[i].latitude;
      final yi = pts[i].longitude;
      final xj = pts[j].latitude;
      final yj = pts[j].longitude;

      final intersects = ((yi > p.longitude) != (yj > p.longitude)) &&
          (p.latitude < (xj - xi) * (p.longitude - yi) / ((yj - yi) + 0.0) + xi);

      if (intersects) inside = !inside;
    }

    return inside;
  }

  // =========================================================
  // PROPERTIES
  // =========================================================

  String? getProp(PolygonChangedData reg, String keyWanted) {
    final wanted = norm(keyWanted);
    final props = reg.properties;

    if (props is! List<Map<String, dynamic>>) return null;

    for (final m in props) {
      for (final e in m.entries) {
        if (norm(e.key) == wanted) {
          final v = e.value;
          if (v is String && v.trim().isNotEmpty) {
            return v.trim();
          }
        }
      }
    }

    return null;
  }

  // =========================================================
  // PARSE DE LAT/LNG
  // =========================================================

  LatLng? parseLatLng(String s) {
    final input = s.trim();
    if (input.isEmpty) return null;

    // Ex: -9.65, -36.7
    final reA = RegExp(r'(-?\d{1,3}(?:\.\d+)?)\s*[,;\s]\s*(-?\d{1,3}(?:\.\d+)?)');
    final mA = reA.firstMatch(input);
    if (mA != null) {
      final lat = double.tryParse(mA.group(1)!);
      final lng = double.tryParse(mA.group(2)!);
      if (lat != null && lng != null && _isValidLatLng(lat, lng)) {
        return LatLng(lat, lng);
      }
    }

    // Ex: S 9.65 O 36.7 | N 10 E 20 | S10 W20
    final reB = RegExp(
      r'(?:(N|S)\s*)?(\d{1,3}(?:\.\d+)?)\D+(?:(E|W|L|O)\s*)?(\d{1,3}(?:\.\d+)?)',
      caseSensitive: false,
    );
    final mB = reB.firstMatch(input);
    if (mB != null) {
      final ns = (mB.group(1) ?? '').toUpperCase();
      final ew = (mB.group(3) ?? '').toUpperCase();
      final latVal = double.tryParse(mB.group(2)!);
      final lngVal = double.tryParse(mB.group(4)!);

      if (latVal != null && lngVal != null) {
        var lat = latVal;
        var lng = lngVal;

        if (ns == 'S') lat = -lat.abs();

        // O = Oeste -> negativo
        // W = West  -> negativo
        // L = Leste -> positivo
        // E = East  -> positivo
        if (ew == 'W' || ew == 'O') lng = -lng.abs();
        if (ew == 'L' || ew == 'E') lng = lng.abs();

        if (_isValidLatLng(lat, lng)) {
          return LatLng(lat, lng);
        }
      }
    }

    // Ex: lat=-9.65 lng=-36.7
    final reC = RegExp(
      r'lat[:=]\s*(-?\d+(?:\.\d+)?)\D+lon[g]?[:=]\s*(-?\d+(?:\.\d+)?)',
      caseSensitive: false,
    );
    final mC = reC.firstMatch(input);
    if (mC != null) {
      final lat = double.tryParse(mC.group(1)!);
      final lng = double.tryParse(mC.group(2)!);
      if (lat != null && lng != null && _isValidLatLng(lat, lng)) {
        return LatLng(lat, lng);
      }
    }

    return null;
  }

  bool _isValidLatLng(double lat, double lng) {
    return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
  }
}