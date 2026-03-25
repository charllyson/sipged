import 'dart:math' as math;
import 'dart:ui';

import 'package:latlong2/latlong.dart';
import 'dxf_model.dart';

/// Interface que projeta ponto do MODELO (x,y) → WGS84 (lat,lon).
abstract class DxfProjector {
  LatLng project(double x, double y);
}

/// Projeção identidade (útil para testes).
class IdentityProjector implements DxfProjector {
  @override
  LatLng project(double x, double y) => LatLng(y, x);
}

/// Projeção UTM simples (zona fixa). Use sul=true abaixo do Equador.
class UtmProjector implements DxfProjector {
  final int zone;
  final bool southHemisphere;
  UtmProjector({required this.zone, this.southHemisphere = true});

  // Conversão UTM→WGS84 mínima (boa o bastante para sobrepor no mapa).
  // Se você já usa alguma lib GIS, pode trocar por ela.
  @override
  LatLng project(double x, double y) {
    // x = Easting, y = Northing
    const a = 6378137.0; // WGS84
    const e = 0.081819190842622;
    final e1sq = 0.00673949674228;
    final k0 = 0.9996;

    final xAdj = x - 500000.0;
    final yAdj = southHemisphere ? y - 10000000.0 : y;

    final m = yAdj / k0;
    final mu = m / (a * (1.0 - (e * e) / 4.0 - 3 * (e * e * e * e) / 64.0 - 5 * (e * e * e * e * e * e) / 256.0));

    final phi1Rad = mu
        + (3 * e / 2 - 27 * e * e * e / 32) * sin2(mu)
        + (21 * e * e / 16 - 55 * e * e * e * e / 32) * sin4(mu)
        + (151 * e * e * e / 96) * sin6(mu);
    final n1 = a / (mathSqrt(1 - (e * e) * (mathSin(phi1Rad) * mathSin(phi1Rad))));
    final t1 = mathTan(phi1Rad) * mathTan(phi1Rad);
    final c1 = e1sq * (mathCos(phi1Rad) * mathCos(phi1Rad));
    final r1 = a * (1 - e * e) / mathPow(1 - (e * e) * (mathSin(phi1Rad) * mathSin(phi1Rad)), 1.5);
    final d = xAdj / (n1 * k0);

    final lat = phi1Rad -
        (n1 * mathTan(phi1Rad) / r1) *
            (d * d / 2 -
                (5 + 3 * t1 + 10 * c1 - 4 * c1 * c1 - 9 * e1sq) * mathPow(d, 4) / 24 +
                (61 + 90 * t1 + 298 * c1 + 45 * t1 * t1 - 252 * e1sq - 3 * c1 * c1) * mathPow(d, 6) / 720);
    final lon = (d -
        (1 + 2 * t1 + c1) * mathPow(d, 3) / 6 +
        (5 - 2 * c1 + 28 * t1 - 3 * c1 * c1 + 8 * e1sq + 24 * t1 * t1) * mathPow(d, 5) / 120) /
        mathCos(phi1Rad);

    final lonDeg = lon * 180 / mathPi + (zone * 6 - 183);
    final latDeg = lat * 180 / mathPi;
    return LatLng(latDeg, lonDeg);
  }

  // helpers
  double sin2(double x) => (mathSin(2 * x));
  double sin4(double x) => (mathSin(4 * x));
  double sin6(double x) => (mathSin(6 * x));
  double mathSin(double x) => math.sin(x);
  double mathCos(double x) => math.cos(x);
  double mathTan(double x) => math.tan(x);
  double mathSqrt(double x) => math.sqrt(x);
  double mathPow(double x, double p) => math.pow(x, p).toDouble();
  double get mathPi => math.pi;
}

/// Projector afim com dois pontos de controle (rotação+escala uniforme).
class AffineProjector2pt implements DxfProjector {
  final double a, b, c, d, tx, ty; // [a b tx; c d ty]
  const AffineProjector2pt({required this.a, required this.b, required this.c, required this.d, required this.tx, required this.ty});

  factory AffineProjector2pt.fromTwoPoints({
    required double x0, required double y0, required double lon0, required double lat0,
    required double x1, required double y1, required double lon1, required double lat1,
  }) {
    final dx = x1 - x0, dy = y1 - y0;
    final dLon = lon1 - lon0, dLat = lat1 - lat0;
    final denom = (dx*dx + dy*dy);
    if (denom == 0) {
      return AffineProjector2pt(a: 0, b: 0, c: 0, d: 0, tx: lon0, ty: lat0);
    }
    final sCos = (dx * dLon + dy * dLat) / denom;
    final sSin = (dx * dLat - dy * dLon) / denom;
    final a =  sCos, b = -sSin, c = sSin, d = sCos;
    final tx = lon0 - (a * x0 + b * y0);
    final ty = lat0 - (c * x0 + d * y0);
    return AffineProjector2pt(a: a, b: b, c: c, d: d, tx: tx, ty: ty);
  }

  @override
  LatLng project(double x, double y) {
    final lon = a * x + b * y + tx;
    final lat = c * x + d * y + ty;
    return LatLng(lat, lon);
  }
}

class DxfToGeo {
  /// Converte ENTIDADES do DXF em sequências de LatLng (para PolylineLayer).
  static List<List<LatLng>> toPolylines({
    required DxfModel model,
    required DxfProjector projector,
    int arcSampling = 24, // pontos por arco (mínimo)
  }) {
    final out = <List<LatLng>>[];

    // LINE
    for (final l in model.lines) {
      out.add([projector.project(l.a.dx, l.a.dy), projector.project(l.b.dx, l.b.dy)]);
    }

    // (LW)POLYLINE
    for (final pl in model.polylines) {
      final seq = <LatLng>[];
      for (final p in pl.points) {
        seq.add(projector.project(p.dx, p.dy));
      }
      if (pl.closed && seq.length > 1) seq.add(seq.first);
      out.add(seq);
    }

    // CIRCLE (amostra)
    for (final c in model.circles) {
      final n = mathMax(arcSampling, (c.r / 2).round());
      final seq = <LatLng>[];
      for (int i = 0; i <= n; i++) {
        final t = 2 * math.pi * (i / n);
        final pt = c.center + Offset.fromDirection(t, c.r);
        seq.add(projector.project(pt.dx, pt.dy));
      }
      out.add(seq);
    }

    // ARC (amostra)
    for (final a in model.arcs) {
      final sweep = (a.sweepRadians).abs();
      final n = mathMax(arcSampling, (a.r * sweep / 5).round());
      final seq = <LatLng>[];
      for (int i = 0; i <= n; i++) {
        final t = a.startRadians + a.sweepRadians * (i / n);
        final pt = a.center + Offset.fromDirection(t, a.r);
        seq.add(projector.project(pt.dx, pt.dy));
      }
      out.add(seq);
    }

    return out;
  }

  // helpers
  static int mathMax(int a, int b) => (a > b) ? a : b;
}

/// Heurística simples:
/// - Se as coordenadas parecem UTM/EPSG:326xx, peça zona (parâmetro/setting)
/// - Se são “pequenas” (planta), devolve Identity (ou use AffineProjector2pt)
DxfProjector autoDetectProjector(DxfModel model, {int? utmZone, bool southHemisphere = true}) {
  final bb = model.bounds();
  final minX = bb.left, minY = bb.top, maxX = bb.right, maxY = bb.bottom;

  final avgX = (minX + maxX) / 2;
  final avgY = (minY + maxY) / 2;

  // Faixas típicas UTM (Easting/Northing em metros)
  final looksLikeUTM = (avgX > 100000 && avgX < 900000) && (avgY > 0 && avgY < 10000000);

  if (looksLikeUTM && utmZone != null) {
    return UtmProjector(zone: utmZone, southHemisphere: southHemisphere);
  }

  // fallback identidade (útil para teste) — para plantas, prefira AffineProjector2pt
  return IdentityProjector();
}
