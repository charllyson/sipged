// lib/_utils/geometry/sipged_poly_simplify.dart
import 'package:latlong2/latlong.dart';

import 'package:sipged/_utils/geometry/sipged_geo_math.dart';
import 'package:sipged/_utils/geometry/sipged_lru_cache.dart';

typedef MetersPerPixelFn = double Function(double latitude, double zoom);

/// Simplificação de polylines:
/// - DP (Douglas-Peucker) com preservação por ângulo
/// - Split de segmentos longos (anti-“quadrado”)
/// - Cache LRU para uso em mapa (zoom-driven)
class SipGedPolyline {
  SipGedPolyline({
    int maxCacheEntries = 120,
    MetersPerPixelFn? metersPerPixelFn,
  })  : _cache = SipGedLruCache<String, List<LatLng>>(maxEntries: maxCacheEntries),
        _metersPerPixelFn = metersPerPixelFn;

  final SipGedLruCache<String, List<LatLng>> _cache;
  final MetersPerPixelFn? _metersPerPixelFn;

  /// Se você não quiser passar metersPerPixelFn em cada chamada,
  /// injete no construtor e use `simplifyAdaptive(...)` sem o parâmetro.
  SipGedPolyline withMetersPerPixel(MetersPerPixelFn fn) =>
      SipGedPolyline(maxCacheEntries: _cache.maxEntries, metersPerPixelFn: fn);

  void clearCache() => _cache.clear();

  // ===========================================================================
  // API 1: ADAPTATIVO (zoom + cache)
  // ===========================================================================

  List<LatLng> simplifyAdaptive(
      List<LatLng> pts, {
        required double zoom,
        required double tolerancePxFar,
        required double tolerancePxMid,
        required double minAngleDeg,
        required double maxSegmentMeters,
        MetersPerPixelFn? metersPerPixelFn,
      }) {
    if (pts.length < 3) return pts;

    final fn = metersPerPixelFn ?? _metersPerPixelFn;
    if (fn == null) {
      throw ArgumentError(
        'metersPerPixelFn é obrigatório. Passe no construtor ou no método simplifyAdaptive.',
      );
    }

    final tolPx = (zoom < 9)
        ? tolerancePxFar
        : (zoom < 12 ? tolerancePxMid : 0.0);

    final avgLat = pts.fold<double>(0.0, (s, p) => s + p.latitude) / pts.length;
    final tolM = tolPx * fn(avgLat, zoom);

    final bucket = (zoom * 10).floor();
    final h = _lightPointsHash(pts);
    final key = '$bucket|$tolM|$minAngleDeg|$maxSegmentMeters|$h';

    final cached = _cache.get(key);
    if (cached != null) return cached;

    final refined = simplifyPipeline(
      pts,
      toleranceMeters: tolM,
      minAngleDeg: minAngleDeg,
      maxSegmentMeters: maxSegmentMeters,
    );

    _cache.put(key, refined);
    return refined;
  }

  // ===========================================================================
  // API 2: PIPELINE (sem zoom; opcionalmente sem cache)
  // ===========================================================================

  /// Pipeline: DP + preservação de ângulo + split de segmentos longos
  static List<LatLng> simplifyPipeline(
      List<LatLng> pts, {
        required double toleranceMeters,
        required double minAngleDeg,
        required double maxSegmentMeters,
      }) {
    if (pts.length < 3) return pts;

    final base = _dpWithAngle(
      pts,
      toleranceMeters: toleranceMeters,
      minAngleDeg: minAngleDeg,
    );

    return _splitLongSegments(base, maxSegmentMeters);
  }

  // ===========================================================================
  // Internals (core DP + angle)
  // ===========================================================================

  static String _lightPointsHash(List<LatLng> pts) {
    double sx = 0, sy = 0;
    for (final p in pts) {
      sx += p.latitude;
      sy += p.longitude;
    }
    return '${pts.length}:${sx.toStringAsFixed(6)}:${sy.toStringAsFixed(6)}';
  }

  static void _dpRec(
      List<LatLng> pts,
      int i,
      int j, {
        required double toleranceMeters,
        required double minAngleDeg,
        required Set<int> keep,
      }) {
    if (j <= i + 1) return;

    // preserva vértices fortes
    for (int k = i + 1; k < j; k++) {
      if (k <= 0 || k >= pts.length - 1) continue;
      final ang = SipGedGeoMath.angleDeg(pts[k - 1], pts[k], pts[k + 1]);
      if (ang <= minAngleDeg) keep.add(k);
    }

    double maxD = -1;
    int idx = -1;

    for (int k = i + 1; k < j; k++) {
      if (keep.contains(k)) continue;
      final d = SipGedGeoMath.pointToSegmentDistanceMeters(pts[k], pts[i], pts[j]);
      if (d > maxD) {
        maxD = d;
        idx = k;
      }
    }

    if (maxD > toleranceMeters && idx != -1) {
      _dpRec(
        pts,
        i,
        idx,
        toleranceMeters: toleranceMeters,
        minAngleDeg: minAngleDeg,
        keep: keep,
      );
      _dpRec(
        pts,
        idx,
        j,
        toleranceMeters: toleranceMeters,
        minAngleDeg: minAngleDeg,
        keep: keep,
      );
    } else {
      keep.add(i);
      keep.add(j);
    }
  }

  static List<LatLng> _dpWithAngle(
      List<LatLng> pts, {
        required double toleranceMeters,
        required double minAngleDeg,
      }) {
    if (toleranceMeters <= 0) return pts;

    final keep = <int>{0, pts.length - 1};
    _dpRec(
      pts,
      0,
      pts.length - 1,
      toleranceMeters: toleranceMeters,
      minAngleDeg: minAngleDeg,
      keep: keep,
    );

    final sorted = keep.toList()..sort();
    return [for (final idx in sorted) pts[idx]];
  }

  static List<LatLng> _splitLongSegments(List<LatLng> pts, double maxSegM) {
    if (maxSegM <= 0 || pts.length < 2) return pts;

    final out = <LatLng>[];
    for (int i = 0; i < pts.length - 1; i++) {
      final a = pts[i], b = pts[i + 1];
      out.add(a);

      final d = SipGedGeoMath.distanceMeters(a, b);
      if (d > maxSegM) {
        final n = (d / maxSegM).floor();
        for (int k = 1; k <= n; k++) {
          final t = k / (n + 1);
          out.add(LatLng(
            a.latitude + (b.latitude - a.latitude) * t,
            a.longitude + (b.longitude - a.longitude) * t,
          ));
        }
      }
    }
    out.add(pts.last);
    return out;
  }
}
