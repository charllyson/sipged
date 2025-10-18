// ============================================================================
// lib/_blocs/actives/roads/active_road_rules.dart
// ============================================================================
import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

/// Regras de estilo e geometria para rodovias
class ActiveRoadsRules {
  // ===========================================================================
  // Rótulos
  // ===========================================================================
  static String getStatusSurface(String status) {
    switch (status.trim().toUpperCase()) {
      case 'DUP': return 'DUPLICADA';
      case 'EOD': return 'EM OBRA DE DUPLICAÇÃO';
      case 'PAV': return 'PAVIMENTADA';
      case 'EOP': return 'EM OBRAS DE PAVIMENTAÇÃO';
      case 'IMP': return 'IMPLANTADA';
      case 'EOI': return 'EM OBRAS DE IMPLANTAÇÃO';
      case 'LEN': return 'LEITO NATURAL';
      case 'PLA': return 'PLANEJADA';
      default:    return 'OUTRO';
    }
  }

  // ===========================================================================
  // LÓGICA DA LEGENDA (tipo de linha)
  // ===========================================================================
  /// DUP/EOD = duas pistas; PAV/EOP = uma pista
  static bool isDupla(String? code) {
    final c = (code ?? '').toUpperCase().trim();
    return c == 'DUP' || c == 'EOD';
  }

  /// EOD/EOP = tracejada; DUP/PAV = contínua
  static bool isTracejada(String? code) {
    final c = (code ?? '').toUpperCase().trim();
    return c == 'EOD' || c == 'EOP';
  }

  // ===========================================================================
  // ESCALAS COM O ZOOM
  // ===========================================================================
  /// largura (px) de uma pista
  static double laneWidthForZoom(double zoom) {
    final w = 1.15 * math.pow(1.36, zoom - 8);     // ~1.2(z8) → ~2.6(z12) → ~5.2(z16)
    return w.clamp(1.0, 6.2).toDouble();
  }

  /// separação (px) entre as duas pistas
  static double laneSeparationPxForZoom(double zoom) {
    final s = 0.95 * math.pow(1.58, zoom - 10);    // ~1.7(z10) → ~4.4(z13) → ~11.6(z16)
    return s.clamp(1.6, 12.5).toDouble();
  }

  /// quantos graus valem 1 px nesse centro/zoom (aprox.)
  static double degreesPerPixel(double latitude, double zoom) {
    final mpp = 156543.03392 * math.cos(latitude * math.pi / 180.0) / math.pow(2.0, zoom);
    return mpp / 111_320.0;
  }

  // ===========================================================================
  // OFFSET PARALELO (sem "dobras")
  // ===========================================================================
  /// Desloca uma polyline **paralelamente** `deslocamentoOrtogonal` graus (lado esquerdo negativo).
  /// Usa junções com limite de mitra e opcional densificação para curvas discretizadas.
  static List<LatLng> deslocarPontos(
      List<LatLng> pts, {
        required double deslocamentoOrtogonal, // em graus!
        double miterLimit = 3.0,
        double densifyIfSegmentMeters = 0,
      }) {
    if (pts.length < 2 || deslocamentoOrtogonal.abs() < 1e-12) return pts;

    // Conversão LatLng <-> metros (plano local)
    final latMean = pts.map((p) => p.latitude).reduce((a, b) => a + b) / pts.length;
    final cosLat = math.cos(latMean * math.pi / 180.0);
    const mPerDegLat = 111_320.0;
    final mPerDegLng = 111_320.0 * cosLat;

    List<_P> toM(List<LatLng> s) =>
        s.map((p) => _P(p.longitude * mPerDegLng, p.latitude * mPerDegLat)).toList();
    List<LatLng> toLL(List<_P> s) =>
        s.map((p) => LatLng(p.y / mPerDegLat, p.x / mPerDegLng)).toList();

    // densify opcional
    List<_P> densify(List<_P> src, double maxSegMeters) {
      if (maxSegMeters <= 0) return src;
      final out = <_P>[];
      for (int i = 0; i < src.length - 1; i++) {
        final a = src[i], b = src[i + 1];
        out.add(a);
        final dx = b.x - a.x, dy = b.y - a.y;
        final len = math.sqrt(dx * dx + dy * dy);
        final nSteps = (len / maxSegMeters).floor();
        if (nSteps > 1) {
          for (int k = 1; k < nSteps; k++) {
            final t = k / nSteps;
            out.add(_P(a.x + dx * t, a.y + dy * t));
          }
        }
      }
      out.add(src.last);
      return out;
    }

    // graus -> metros
    final dMeters = deslocamentoOrtogonal * mPerDegLat;

    var m = toM(pts);
    if (densifyIfSegmentMeters > 0) m = densify(m, densifyIfSegmentMeters);

    // normais por segmento
    final segNormals = <_P>[];
    for (int i = 0; i < m.length - 1; i++) {
      final a = m[i], b = m[i + 1];
      final vx = b.x - a.x, vy = b.y - a.y;
      final len = math.sqrt(vx * vx + vy * vy);
      if (len < 1e-12) {
        segNormals.add(const _P(0, 0));
      } else {
        segNormals.add(_P(-vy / len, vx / len)); // 90° esq
      }
    }

    // offset ponto a ponto com mitra
    final out = <_P>[];
    for (int i = 0; i < m.length; i++) {
      late _P off;
      if (i == 0) {
        final n = segNormals[0];
        off = _P(n.x * dMeters, n.y * dMeters);
      } else if (i == m.length - 1) {
        final n = segNormals[segNormals.length - 1];
        off = _P(n.x * dMeters, n.y * dMeters);
      } else {
        final n1 = segNormals[i - 1];
        final n2 = segNormals[i];
        var tx = n1.x + n2.x, ty = n1.y + n2.y;
        var tlen = math.sqrt(tx * tx + ty * ty);
        if (tlen < 1e-9) {
          tx = n2.x; ty = n2.y; tlen = 1.0;
        }
        tx /= tlen; ty /= tlen;
        final dot = tx * n1.x + ty * n1.y;      // cos(theta/2)
        final gain = (dot.abs() < 1e-3) ? miterLimit : (1.0 / dot).abs();
        final k = math.min(gain, miterLimit);
        off = _P(tx * dMeters * k, ty * dMeters * k);
      }
      out.add(_P(m[i].x + off.x, m[i].y + off.y));
    }

    return toLL(out);
  }
}

class _P {
  final double x, y;
  const _P(this.x, this.y);
}
