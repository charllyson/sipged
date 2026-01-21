// lib/screens/modules/actives/railways/network/multi_line_simplifier.dart
import 'dart:collection';
import 'dart:math' as math;
import 'package:latlong2/latlong.dart';
import '../../screens/modules/actives/railways/network/railway_ties.dart';

class MultiLineSimplifier {
  MultiLineSimplifier._();

  // ---- LRU cache por faixa de zoom (bucket = floor(zoom*10)) ----
  static const int _maxEntries = 120;
  static final _cache = LinkedHashMap<String, List<LatLng>>();

  static String _key(List<LatLng> pts, int zoomBucket, double tolM, double angleDeg, double maxSegM) {
    // hash leve dos pontos
    double sx = 0, sy = 0;
    for (final p in pts) { sx += p.latitude; sy += p.longitude; }
    final h = '${pts.length}:${sx.toStringAsFixed(6)}:${sy.toStringAsFixed(6)}';
    return '$zoomBucket|$tolM|$angleDeg|$maxSegM|$h';
  }

  // Público: simplificação adaptativa + cache
  static List<LatLng> simplifyAdaptive(
      List<LatLng> pts, {
        required double zoom,
        required double tolerancePxFar,   // ex.: 4.5..6 px
        required double tolerancePxMid,   // ex.: 3..4 px
        required double minAngleDeg,      // ex.: 16..22 deg
        required double maxSegmentMeters, // ex.: 80..140 m
      }) {
    if (pts.length < 3) return pts;

    // tolerância por zoom (em px)
    final tolPx = (zoom < 9)
        ? tolerancePxFar
        : (zoom < 12 ? tolerancePxMid : 0.0);

    // px -> metros
    final avgLat = pts.fold<double>(0, (s, p) => s + p.latitude) / pts.length;
    final mpp = RailwayTies.metersPerPixel(avgLat, zoom);
    final tolM = tolPx * mpp;

    final bucket = (zoom * 10).floor();
    final key = _key(pts, bucket, tolM, minAngleDeg, maxSegmentMeters);
    final cached = _cache[key];
    if (cached != null) return cached;

    // 1) Douglas–Peucker com preservação de ângulo
    final base = _dpWithAngle(pts, tolM, minAngleDeg);

    // 2) Anti-“quadrado”: divide trechos muito longos
    final refined = _splitLongSegments(base, maxSegmentMeters);

    // LRU pequeno
    _cache[key] = refined;
    if (_cache.length > _maxEntries) {
      _cache.remove(_cache.keys.first);
    }
    return refined;
  }

  // ---------- helpers ----------
  static double _angleDeg(LatLng a, LatLng b, LatLng c) {
    final v1x = a.latitude - b.latitude;
    final v1y = a.longitude - b.longitude;
    final v2x = c.latitude - b.latitude;
    final v2y = c.longitude - b.longitude;
    final dot = v1x * v2x + v1y * v2y;
    final n1 = math.sqrt(v1x * v1x + v1y * v1y);
    final n2 = math.sqrt(v2x * v2x + v2y * v2y);
    if (n1 == 0 || n2 == 0) return 180;
    final cosT = (dot / (n1 * n2)).clamp(-1.0, 1.0);
    return math.acos(cosT) * 180.0 / math.pi;
  }

  static double _pointSegDistM(LatLng p, LatLng a, LatLng b) {
    final dist = const Distance();
    final ap = dist(a, p);
    final ab = dist(a, b);
    if (ab == 0) return ap;
    // projeção paramétrica (aprox. plano local)
    final t = (((p.latitude - a.latitude) * (b.latitude - a.latitude)) +
        ((p.longitude - a.longitude) * (b.longitude - a.longitude))) /
        (((b.latitude - a.latitude) * (b.latitude - a.latitude)) +
            ((b.longitude - a.longitude) * (b.longitude - a.longitude)));
    if (t <= 0) return ap;
    if (t >= 1) return dist(p, b);
    final proj = LatLng(
      a.latitude + (b.latitude - a.latitude) * t,
      a.longitude + (b.longitude - a.longitude) * t,
    );
    return dist(p, proj);
  }

  static void _dpRec(
      List<LatLng> pts,
      int i,
      int j,
      double tolM,
      double minAngleDeg,
      Set<int> keep,
      ) {
    if (j <= i + 1) return;

    // preserva vértices fortes
    for (int k = i + 1; k < j; k++) {
      final ang = _angleDeg(pts[k - 1], pts[k], pts[k + 1]);
      if (ang <= minAngleDeg) keep.add(k);
    }

    double maxD = -1;
    int idx = -1;
    for (var k = i + 1; k < j; k++) {
      // se já é “curva” forte, pula da avaliação
      if (keep.contains(k)) continue;
      final d = _pointSegDistM(pts[k], pts[i], pts[j]);
      if (d > maxD) {
        maxD = d;
        idx = k;
      }
    }

    if (maxD > tolM && idx != -1) {
      _dpRec(pts, i, idx, tolM, minAngleDeg, keep);
      _dpRec(pts, idx, j, tolM, minAngleDeg, keep);
    } else {
      keep.add(i);
      keep.add(j);
    }
  }

  static List<LatLng> _dpWithAngle(List<LatLng> pts, double tolM, double minAngleDeg) {
    if (tolM <= 0) return pts;
    final keep = <int>{0, pts.length - 1};
    _dpRec(pts, 0, pts.length - 1, tolM, minAngleDeg, keep);
    final sorted = keep.toList()..sort();
    return [for (final i in sorted) pts[i]];
  }

  static List<LatLng> _splitLongSegments(List<LatLng> pts, double maxSegM) {
    if (maxSegM <= 0) return pts;
    final dist = const Distance();
    final out = <LatLng>[];
    for (int i = 0; i < pts.length - 1; i++) {
      final a = pts[i], b = pts[i + 1];
      out.add(a);
      final d = dist(a, b);
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
