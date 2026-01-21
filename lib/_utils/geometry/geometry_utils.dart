// lib/_services/geometry/geometry_utils.dart
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:archive/archive.dart';
import 'package:flutter_map/flutter_map.dart' show MapCamera;
import 'package:latlong2/latlong.dart';

/// ---------------- modelos ----------------
enum GeometryType { line, polygon }

class Geom {
  final GeometryType type;
  final List<LatLng> points;
  const Geom._(this.type, this.points);
  factory Geom.line(List<LatLng> pts) => Geom._(GeometryType.line, pts);
  factory Geom.polygon(List<LatLng> pts) => Geom._(GeometryType.polygon, pts);
}

/// Cell usado no algoritmo de polylabel
class GeometryCell {
  final double x, y, h, d;
  double get max => d + h * math.sqrt2;
  GeometryCell(this.x, this.y, this.h, this.d);
}

/// =====================================================================================
///  DETECÇÃO E PARSE DE ARQUIVOS (GeoJSON / KML / KMZ)
/// =====================================================================================
class GeometryParsers {
  static String detectKind(String fileName, String? contentType, Uint8List bytes) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.kml')) return 'kml';
    if (lower.endsWith('.kmz')) return 'kmz';
    if (lower.endsWith('.geojson') || lower.endsWith('.json')) return 'geojson';

    final ct = (contentType ?? '').toLowerCase();
    if (ct.contains('kml')) return 'kml';
    if (ct.contains('kmz') || ct.contains('zip')) return 'kmz';
    if (ct.contains('geo+json') || ct.contains('json')) return 'geojson';

    // Assinatura ZIP
    if (bytes.length >= 2 && bytes[0] == 0x50 && bytes[1] == 0x4B) return 'kmz';

    // Heurística textual
    final head = utf8.decode(bytes.take(64).toList(), allowMalformed: true).toLowerCase();
    if (head.contains('<kml')) return 'kml';
    if (head.trimLeft().startsWith('{')) return 'geojson';

    return 'unknown';
  }

  static Future<List<Geom>> parseGeometries(
      String name,
      Uint8List bytes,
      String kind,
      ) async {
    switch (kind) {
      case 'kml':
        return _parseKml(utf8.decode(bytes, allowMalformed: true));
      case 'kmz':
        return _parseKmz(bytes);
      case 'geojson':
        return _parseGeoJson(utf8.decode(bytes, allowMalformed: true));
      default:
        return const [];
    }
  }

  static List<Geom> _parseGeoJson(String text) {
    final data = json.decode(text) as Map<String, dynamic>;
    final List<Geom> out = [];

    void addLine(List coords) {
      final pts = <LatLng>[];
      for (final c in coords) {
        if (c is List && c.length >= 2) {
          pts.add(LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()));
        }
      }
      if (pts.length >= 2) out.add(Geom.line(pts));
    }

    void addPoly(List coords) {
      if (coords.isEmpty) return;
      final ring = coords.first as List; // outer
      final pts = <LatLng>[];
      for (final c in ring) {
        if (c is List && c.length >= 2) {
          pts.add(LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()));
        }
      }
      if (pts.length >= 3) out.add(Geom.polygon(pts));
    }

    void parseGeom(Map<String, dynamic> g) {
      final type = (g['type'] ?? '').toString();
      final coords = g['coordinates'];
      if (type == 'LineString' && coords is List) {
        addLine(coords);
      } else if (type == 'MultiLineString' && coords is List) {
        for (final ls in coords) {
          if (ls is List) addLine(ls);
        }
      } else if (type == 'Polygon' && coords is List) {
        addPoly(coords);
      } else if (type == 'MultiPolygon' && coords is List) {
        for (final pg in coords) {
          if (pg is List) addPoly(pg);
        }
      }
    }

    final type = (data['type'] ?? '').toString();
    if (type == 'FeatureCollection' && data['features'] is List) {
      for (final f in (data['features'] as List)) {
        if (f is Map<String, dynamic>) {
          final g = f['geometry'] as Map<String, dynamic>?;
          if (g != null) parseGeom(g);
        }
      }
    } else if (type == 'Feature' && data['geometry'] is Map<String, dynamic>) {
      parseGeom(data['geometry'] as Map<String, dynamic>);
    } else if (data['type'] is String && data['coordinates'] != null) {
      parseGeom(data);
    }
    return out;
  }

  static List<LatLng> _coordsToLatLng(String coordsTxt) {
    final pts = <LatLng>[];
    final tokens = coordsTxt
        .split(RegExp(r'\s+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty);
    for (final t in tokens) {
      final p = t.split(',');
      if (p.length >= 2) {
        final lon = double.tryParse(p[0]);
        final lat = double.tryParse(p[1]);
        if (lat != null && lon != null) pts.add(LatLng(lat, lon));
      }
    }
    return pts;
  }

  static List<Geom> _parseKml(String xml) {
    final List<Geom> out = [];

    Iterable<List<LatLng>> extractLines() sync* {
      final reg = RegExp(
        r'<LineString[^>]*>.*?<coordinates>(.*?)</coordinates>.*?</LineString>',
        dotAll: true,
        caseSensitive: false,
      );
      for (final m in reg.allMatches(xml)) {
        final pts = _coordsToLatLng(m.group(1) ?? '');
        if (pts.length >= 2) yield pts;
      }
    }

    Iterable<List<LatLng>> extractPolys() sync* {
      final reg = RegExp(
        r'<Polygon[^>]*>.*?<outerBoundaryIs>.*?<coordinates>(.*?)</coordinates>.*?</outerBoundaryIs>.*?</Polygon>',
        dotAll: true,
        caseSensitive: false,
      );
      for (final m in reg.allMatches(xml)) {
        final pts = _coordsToLatLng(m.group(1) ?? '');
        if (pts.length >= 3) yield pts;
      }
    }

    for (final ls in extractLines()) {
      out.add(Geom.line(ls));
    }
    for (final pg in extractPolys()) {
      out.add(Geom.polygon(pg));
    }
    return out;
  }

  static Future<List<Geom>> _parseKmz(Uint8List bytes) async {
    final archive = ZipDecoder().decodeBytes(bytes, verify: true);
    for (final f in archive.files) {
      if (f.isFile && f.name.toLowerCase().endsWith('.kml')) {
        final content = utf8.decode(f.content as List<int>, allowMalformed: true);
        return _parseKml(content);
      }
    }
    return const [];
  }
}

/// =====================================================================================
///  POLYLABEL (polo de inacessibilidade) + utilidades geométricas
/// =====================================================================================
class Polylabel {
  static double _hypot(double a, double b) => math.sqrt(a * a + b * b);

  static double _pointToSegDist(
      double x,
      double y,
      double x1,
      double y1,
      double x2,
      double y2,
      ) {
    final dx = x2 - x1, dy = y2 - y1;
    if (dx == 0 && dy == 0) return _hypot(x - x1, y - y1);
    var t = ((x - x1) * dx + (y - y1) * dy) / (dx * dx + dy * dy);
    t = (t.clamp(0.0, 1.0));
    final px = x1 + t * dx;
    final py = y1 + t * dy;
    return _hypot(x - px, y - py);
  }

  static double _pointToPolygonDist(double x, double y, List<LatLng> poly) {
    bool inside = false;
    double minDist = double.infinity;
    for (int i = 0, j = poly.length - 1; i < poly.length; j = i++) {
      final xi = poly[i].longitude, yi = poly[i].latitude;
      final xj = poly[j].longitude, yj = poly[j].latitude;

      final intersect = ((yi > y) != (yj > y)) &&
          (x < (xj - xi) * (y - yi) / ((yj - yi) == 0 ? 1e-12 : (yj - yi)) + xi);
      if (intersect) inside = !inside;

      final dist = _pointToSegDist(x, y, xi, yi, xj, yj);
      if (dist < minDist) minDist = dist;
    }
    return (inside ? 1 : -1) * minDist;
  }

  static ({double minX, double minY, double maxX, double maxY}) bbox(List<LatLng> poly) {
    double minX = double.infinity, minY = double.infinity;
    double maxX = -double.infinity, maxY = -double.infinity;
    for (final p in poly) {
      final x = p.longitude, y = p.latitude;
      if (x < minX) minX = x;
      if (y < minY) minY = y;
      if (x > maxX) maxX = x;
      if (y > maxY) maxY = y;
    }
    return (minX: minX, minY: minY, maxX: maxX, maxY: maxY);
  }

  static LatLng compute(List<LatLng> polygon, {double precision = 1e-6}) {
    final b = bbox(polygon);
    final double w = b.maxX - b.minX, h = b.maxY - b.minY;
    final double cellSize = math.min(w, h);
    if (cellSize == 0) return polygon.first;
    final double h2 = cellSize / 2;

    GeometryCell bestCell = GeometryCell(
      (b.minX + b.maxX) / 2,
      (b.minY + b.maxY) / 2,
      0,
      _pointToPolygonDist(
        (b.minX + b.maxX) / 2,
        (b.minY + b.maxY) / 2,
        polygon,
      ),
    );

    GeometryCell? best;
    final List<GeometryCell> queue = [];
    for (double x = b.minX; x < b.maxX; x += cellSize) {
      for (double y = b.minY; y < b.maxY; y += cellSize) {
        final c = GeometryCell(
          x + h2,
          y + h2,
          h2,
          _pointToPolygonDist(x + h2, y + h2, polygon),
        );
        queue.add(c);
        if (best == null || c.d > best.d) best = c;
      }
    }
    if (best != null && best.d > bestCell.d) bestCell = best;

    queue.sort((a, b) => b.max.compareTo(a.max));
    final double tolerance = precision;

    while (queue.isNotEmpty) {
      final cell = queue.removeAt(0);
      if (cell.d > bestCell.d) bestCell = cell;
      if (cell.max - bestCell.d <= tolerance) continue;

      final h2c = cell.h / 2;
      for (final dx in [-h2c, h2c]) {
        for (final dy in [-h2c, h2c]) {
          final c = GeometryCell(
            cell.x + dx,
            cell.y + dy,
            h2c,
            _pointToPolygonDist(cell.x + dx, cell.y + dy, polygon),
          );
          queue.add(c);
        }
      }
      queue.sort((a, b) => b.max.compareTo(a.max));
    }
    return LatLng(bestCell.y, bestCell.x);
  }
}

/// =====================================================================================
///  LABEL POINTS (centroid, bbox, polylabel) + Ponto na tela (WebMercator)
/// =====================================================================================

enum LabelPointStrategy { centroid, bboxCenter, polylabel }

List<LatLng> _closeRing(List<LatLng> ring) {
  if (ring.isEmpty) return ring;
  return (ring.first == ring.last) ? ring : [...ring, ring.first];
}

/// Centro do bbox
LatLng bboxCenter(List<LatLng> ring) {
  if (ring.isEmpty) return const LatLng(0, 0);
  double minLat = ring.first.latitude, maxLat = ring.first.latitude;
  double minLng = ring.first.longitude, maxLng = ring.first.longitude;
  for (final p in ring) {
    if (p.latitude < minLat) minLat = p.latitude;
    if (p.latitude > maxLat) maxLat = p.latitude;
    if (p.longitude < minLng) minLng = p.longitude;
    if (p.longitude > maxLng) maxLng = p.longitude;
  }
  return LatLng((minLat + maxLat) / 2.0, (minLng + maxLng) / 2.0);
}

/// Centróide geométrico (Shoelace)
LatLng centroidOfPolygon(List<LatLng> ring) {
  final pts = _closeRing(ring);
  if (pts.length < 4) return bboxCenter(ring);

  double area2 = 0.0; // 2 * área
  double cx = 0.0;
  double cy = 0.0;

  for (var i = 0; i < pts.length - 1; i++) {
    final x0 = pts[i].longitude, y0 = pts[i].latitude;
    final x1 = pts[i + 1].longitude, y1 = pts[i + 1].latitude;
    final cross = x0 * y1 - x1 * y0;
    area2 += cross;
    cx += (x0 + x1) * cross;
    cy += (y0 + y1) * cross;
  }

  if (area2.abs() < 1e-12) return bboxCenter(ring);
  final a6 = area2 * 3.0; // 6 * área = 3 * (2*área)
  return LatLng(cy / a6, cx / a6);
}

/// Ray casting
bool pointInPolygon(LatLng p, List<LatLng> ring) {
  final pts = _closeRing(ring);
  bool inside = false;
  for (int i = 0, j = pts.length - 1; i < pts.length; j = i++) {
    final xi = pts[i].longitude, yi = pts[i].latitude;
    final xj = pts[j].longitude, yj = pts[j].latitude;

    final intersect = ((yi > p.latitude) != (yj > p.latitude)) &&
        (p.longitude <
            (xj - xi) * (p.latitude - yi) /
                (((yj - yi) == 0) ? 1e-12 : (yj - yi)) +
                xi);
    if (intersect) inside = !inside;
  }
  return inside;
}

/// Ponto de rótulo unificado
LatLng labelPointForPolygon(
    List<LatLng> ring, {
      LabelPointStrategy strategy = LabelPointStrategy.centroid,
      bool ensureInside = true,
      double polylabelPrecision = 1e-6,
    }) {
  LatLng p;
  switch (strategy) {
    case LabelPointStrategy.bboxCenter:
      p = bboxCenter(ring);
      break;
    case LabelPointStrategy.polylabel:
      p = Polylabel.compute(_closeRing(ring), precision: polylabelPrecision);
      break;
    case LabelPointStrategy.centroid:
      p = centroidOfPolygon(ring);
      break;
  }

  if (ensureInside && !pointInPolygon(p, ring)) {
    p = Polylabel.compute(_closeRing(ring), precision: polylabelPrecision);
  }
  return p;
}

/// -------------------- Web Mercator: LatLng -> Offset de tela --------------------
class MapMath {
  static ({double x, double y}) mercatorProject(LatLng ll, double zoom) {
    const double tileSize = 256.0;
    final double scale = tileSize * math.pow(2.0, zoom).toDouble();
    final double x = (ll.longitude + 180.0) / 360.0 * scale;
    final double sinLat = math.sin(ll.latitude * math.pi / 180.0);
    final double y =
        (0.5 - math.log((1 + sinLat) / (1 - sinLat)) / (4 * math.pi)) * scale;
    return (x: x, y: y);
  }

  static Offset latLngToScreen(MapCamera cam, LatLng target) {
    final size = cam.nonRotatedSize;
    final zoom = cam.zoom;
    final center = cam.center;
    final c = mercatorProject(center, zoom);
    final p = mercatorProject(target, zoom);
    final originX = c.x - size.width / 2.0;
    final originY = c.y - size.height / 2.0;
    final screenX = p.x - originX;
    final screenY = p.y - originY;
    return Offset(screenX, screenY);
  }
}
