import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// ---- Geo/math helpers (reutilizável) ----
class SipGedGeoMath {
  const SipGedGeoMath._();

  static double degToRad(double deg) => deg * math.pi / 180.0;
  static double radToDeg(double rad) => rad * 180.0 / math.pi;

  /// cos em graus (muito usado em geo)
  static double cosDeg(double deg) => math.cos(degToRad(deg));

  /// Meters-per-pixel aproximado (WebMercator)
  /// Equatorial m/px at zoom 0 ~= 156543.03392
  static double metersPerPixel(double latitude, double zoom) {
    return 156543.03392 * cosDeg(latitude) / math.pow(2.0, zoom);
  }

  /// Ângulo (em graus) no vértice B formado por A-B-C (aprox. plano local).
  static double angleDeg(LatLng a, LatLng b, LatLng c) {
    final v1x = a.latitude - b.latitude;
    final v1y = a.longitude - b.longitude;
    final v2x = c.latitude - b.latitude;
    final v2y = c.longitude - b.longitude;

    final dot = v1x * v2x + v1y * v2y;
    final n1 = math.sqrt(v1x * v1x + v1y * v1y);
    final n2 = math.sqrt(v2x * v2x + v2y * v2y);
    if (n1 == 0 || n2 == 0) return 180.0;

    final cosT = (dot / (n1 * n2)).clamp(-1.0, 1.0);
    return math.acos(cosT) * 180.0 / math.pi;
  }

  /// Distância entre dois pontos (metros)
  static double distanceMeters(LatLng a, LatLng b) => const Distance()(a, b);

  /// Distância do ponto P ao segmento AB em metros.
  /// Usa Distance() do latlong2 para medir em metros, mas projeta o ponto no segmento em coordenadas (lat/lng).
  static double pointToSegmentDistanceMeters(LatLng p, LatLng a, LatLng b) {
    final dist = const Distance();
    final ap = dist(a, p);
    final ab = dist(a, b);
    if (ab == 0) return ap;

    final denom = ((b.latitude - a.latitude) * (b.latitude - a.latitude)) +
        ((b.longitude - a.longitude) * (b.longitude - a.longitude));
    if (denom == 0) return ap;

    final t = (((p.latitude - a.latitude) * (b.latitude - a.latitude)) +
        ((p.longitude - a.longitude) * (b.longitude - a.longitude))) /
        denom;

    if (t <= 0) return ap;
    if (t >= 1) return dist(p, b);

    final proj = LatLng(
      a.latitude + (b.latitude - a.latitude) * t,
      a.longitude + (b.longitude - a.longitude) * t,
    );
    return dist(p, proj);
  }

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
