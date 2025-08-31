import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

class RailwayTies {
  RailwayTies._();

  static double _distM(LatLng a, LatLng b) => const Distance()(a, b);

  static LatLng _offsetMeters(
      LatLng p, {
        required double dx,
        required double dy,
      }) {
    const mPerDeg = 111320.0;
    final latRad = p.latitude * math.pi / 180.0;
    final dLat = dy / mPerDeg;
    final dLng = dx / (mPerDeg * math.cos(latRad).clamp(0.2, 1.0));
    return LatLng(p.latitude + dLat, p.longitude + dLng);
  }

  static LatLng _interpolateAlong(LatLng a, LatLng b, double tMetersFromA) {
    final total = _distM(a, b);
    if (total <= 0) return a;
    final f = (tMetersFromA / total).clamp(0.0, 1.0);
    return LatLng(
      a.latitude + (b.latitude - a.latitude) * f,
      a.longitude + (b.longitude - a.longitude) * f,
    );
  }

  static ({double nx, double ny}) _unitNormalMeters(LatLng a, LatLng b) {
    final dy = _distM(a, LatLng(b.latitude, a.longitude));
    final dx = _distM(LatLng(a.latitude, b.longitude), b);
    final sx = (b.longitude >= a.longitude) ? 1.0 : -1.0;
    final sy = (b.latitude  >= a.latitude ) ? 1.0 : -1.0;
    final vx = dx * sx, vy = dy * sy;
    final len = math.sqrt(vx * vx + vy * vy);
    if (len == 0) return (nx: 0, ny: 0);
    return (nx: -vy / len, ny: vx / len); // +90°
  }

  /// Metros por pixel na latitude [lat] em zoom WebMercator [zoom]
  static double metersPerPixel(double lat, double zoom) {
    final cosLat = math.cos(lat * math.pi / 180.0).abs().clamp(0.2, 1.0);
    return 156543.03392 * cosLat / math.pow(2.0, zoom);
  }

  /// Dormentes com parâmetros em **pixels** (convertidos para metros pelo zoom)
  static List<List<LatLng>> generateTiesPx(
      List<LatLng> polyline,
      double zoom, {
        double spacingPx = 10,
        double lengthPx = 10,
      }) {
    if (polyline.length < 2) return const [];
    final avgLat =
        polyline.fold<double>(0, (s, p) => s + p.latitude) / polyline.length;
    final mpp = metersPerPixel(avgLat, zoom);
    return generateTiesMeters(
      polyline,
      spacingMeters: spacingPx * mpp,
      lengthMeters: lengthPx * mpp,
    );
  }

  /// Dormentes com parâmetros em **metros**
  static List<List<LatLng>> generateTiesMeters(
      List<LatLng> polyline, {
        required double spacingMeters,
        required double lengthMeters,
      }) {
    if (polyline.length < 2 || spacingMeters <= 0 || lengthMeters <= 0) {
      return const [];
    }

    final edges = <({LatLng a, LatLng b, double len})>[];
    for (var i = 0; i < polyline.length - 1; i++) {
      final a = polyline[i], b = polyline[i + 1];
      final len = _distM(a, b);
      if (len > 0.01) edges.add((a: a, b: b, len: len));
    }
    if (edges.isEmpty) return const [];

    final ties = <List<LatLng>>[];
    double carry = 0.0;

    for (final e in edges) {
      double walked = 0.0;

      if (carry > 0 && carry < spacingMeters) {
        if (e.len >= carry) {
          final c = _interpolateAlong(e.a, e.b, carry);
          final n = _unitNormalMeters(e.a, e.b);
          final half = lengthMeters / 2.0;
          ties.add([
            _offsetMeters(c, dx: -n.nx * half, dy: -n.ny * half),
            _offsetMeters(c, dx:  n.nx * half, dy:  n.ny * half),
          ]);
          walked = carry;
          carry = 0.0;
        } else {
          carry -= e.len;
          continue;
        }
      }

      while (walked + spacingMeters <= e.len + 1e-6) {
        walked += spacingMeters;
        final c = _interpolateAlong(e.a, e.b, walked);
        final n = _unitNormalMeters(e.a, e.b);
        final half = lengthMeters / 2.0;
        ties.add([
          _offsetMeters(c, dx: -n.nx * half, dy: -n.ny * half),
          _offsetMeters(c, dx:  n.nx * half, dy:  n.ny * half),
        ]);
      }

      carry = spacingMeters - (e.len - walked);
      if (carry >= spacingMeters || carry < 0) carry = 0.0;
    }

    return ties;
  }

  /// Curva de métricas vs. zoom (valores em px)
  static ({
  double spacingPx,
  double lengthPx,
  double tieStrokePx,
  double railStrokePx,
  double outlinePx,
  double tieHaloPx,          // 🔹 NOVO: halo nos dormentes
  bool showTies,
  double simplifyTolerancePx,
  }) metricsForZoom(double z) {
    double lerp(double a, double b, double t) => a + (b - a) * t.clamp(0.0, 1.0);

    // --- Longe (5..10): sem dormentes
    final tFar = ((z - 5.0) / (10.0 - 5.0)).clamp(0.0, 1.0);
    final outlineFar   = lerp(1.2, 2.2, tFar);
    final railFar      = lerp(2.6, 3.2, tFar);
    final simplifyFar  = lerp(8.0, 6.0, tFar);

    // --- Intermediário (10..12): dormentes LITE **mais visíveis**
    final tLite = ((z - 10.0) / (12.0 - 10.0)).clamp(0.0, 1.0);
    final spacingLite  = lerp(28.0, 16.0, tLite); // antes 40→22
    final lengthLite   = lerp(12.0, 18.0, tLite); // antes 6→10
    final tieLite      = lerp( 1.8,  2.6, tLite); // antes 1.2→1.8
    final railLite     = lerp( 3.0,  3.6, tLite);
    final outlineLite  = lerp( 0.6,  0.2, tLite);
    final tieHaloLite  = lerp( 1.2,  0.8, tLite); // 🔹 branco sob o dormente

    // --- Perto (12..20): dormentes FULL
    final tNear = ((z - 12.0) / (20.0 - 12.0)).clamp(0.0, 1.0);
    final spacingNear = lerp(18.0, 7.0,  tNear);
    final lengthNear  = lerp(16.0, 20.0, tNear);
    final tieNear     = lerp( 2.2, 3.0,  tNear);
    final railNear    = lerp( 3.2, 4.5,  tNear);

    if (z < 7.0) {
      return (
      spacingPx: 9999,
      lengthPx: 0,
      tieStrokePx: 0,
      railStrokePx: railFar,
      outlinePx: outlineFar,
      tieHaloPx: 0.0,
      showTies: false,
      simplifyTolerancePx: simplifyFar,
      );
    } else if (z < 7.0) {
      // LITE (agora bem perceptível)
      return (
      spacingPx: spacingLite,
      lengthPx:  lengthLite,
      tieStrokePx: tieLite,
      railStrokePx: railLite,
      outlinePx: outlineLite,
      tieHaloPx: tieHaloLite,          // 🔹 halo ativo
      showTies: true,
      simplifyTolerancePx: 2,
      );
    } else {
      // FULL
      return (
      spacingPx: spacingNear,
      lengthPx:  lengthNear,
      tieStrokePx: tieNear,
      railStrokePx: railNear,
      outlinePx: 0.0,
      tieHaloPx: 0.0,
      showTies: true,
      simplifyTolerancePx: 0.0,
      );
    }
  }


}
