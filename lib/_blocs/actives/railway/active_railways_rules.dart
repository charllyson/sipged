import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

class ActiveRailwaysRules {
  // Códigos canônicos de status (ajuste conforme seu catálogo)
  // Baseado no exemplo: "Em Operação" etc.
  static const List<String> statusOrder = <String>[
    'OP',     // Em Operação
    'OBRA',   // Em Obras
    'PLAN',   // Planejada
    'INAT',   // Inativa / Desativada
    'OUTRO',
  ];

  static String labelForStatus(String code) {
    switch (code) {
      case 'OP':   return 'Em operação';
      case 'OBRA': return 'Em obras';
      case 'PLAN': return 'Planejada';
      case 'INAT': return 'Inativa';
      default:     return 'Outro';
    }
  }

  static String statusCodeOf(String? raw) {
    final r = (raw ?? '').toUpperCase();
    if (r.contains('OPERA')) return 'OP';
    if (r.contains('OBRA'))  return 'OBRA';
    if (r.contains('PLAN'))  return 'PLAN';
    if (r.contains('INAT') || r.contains('DESAT')) return 'INAT';
    return 'OUTRO';
  }

  // ======== Região (canonização igual às rodovias) ========
  static String stripDiacritics(String s) {
    const map = {
      'Á':'A','À':'A','Â':'A','Ã':'A','Ä':'A',
      'É':'E','È':'E','Ê':'E','Ë':'E',
      'Í':'I','Ì':'I','Î':'I','Ï':'I',
      'Ó':'O','Ò':'O','Ô':'O','Õ':'O','Ö':'O',
      'Ú':'U','Ù':'U','Û':'U','Ü':'U',
      'Ç':'C',
    };
    final b = StringBuffer();
    for (final r in s.runes) {
      final ch = String.fromCharCode(r);
      b.write(map[ch] ?? ch);
    }
    return b.toString();
  }

  static String _norm(String? s) {
    if (s == null) return '';
    var t = s.toUpperCase().trim();
    t = t.replaceAll(RegExp(r'\s+'), ' ');
    t = stripDiacritics(t);
    return t;
  }

  static String canonRegion(String? s, List<String> regionLabels) {
    final n = _norm(s);
    if (n.isEmpty) return n;

    for (final label in regionLabels) {
      final ln = _norm(label);
      if (n == ln) return ln;
    }
    if (n.contains('MUNDAU')) return _norm('VALE DO MUNDAÚ');
    if (n.contains('PARAIBA')) return _norm('VALE DO PARAÍBA');
    return n;
  }

  // ======== Geometria ========
  static double getStrokeByZoom(double base, double zoom) {
    final fator = (zoom / 10).clamp(0.6, 2.5);
    final ajustado = base * fator;
    return ajustado.clamp(0.1, 12.0);
  }

  static List<LatLng> deslocarPontos(
      List<LatLng> pts, {
        double? deslocamentoOrtogonal,
        double dx = 0,
        double dy = 0,
      }) {
    if (deslocamentoOrtogonal == null) {
      return pts.map((p) => LatLng(p.latitude + dy, p.longitude + dx)).toList();
    }
    return _deslocarOrtogonalSuavizado(pts, deslocamentoOrtogonal);
  }

  static List<LatLng> _deslocarOrtogonalSuavizado(List<LatLng> pontos, double dx) {
    if (pontos.length < 2) return pontos;
    final out = <LatLng>[];
    for (int i = 0; i < pontos.length; i++) {
      late double vx, vy;
      if (i == 0) {
        vx = pontos[1].latitude - pontos[0].latitude;
        vy = pontos[1].longitude - pontos[0].longitude;
      } else if (i == pontos.length - 1) {
        vx = pontos[i].latitude - pontos[i - 1].latitude;
        vy = pontos[i].longitude - pontos[i - 1].longitude;
      } else {
        final vx1 = pontos[i].latitude - pontos[i - 1].latitude;
        final vy1 = pontos[i].longitude - pontos[i - 1].longitude;
        final vx2 = pontos[i + 1].latitude - pontos[i].latitude;
        final vy2 = pontos[i + 1].longitude - pontos[i].longitude;
        vx = (vx1 + vx2) / 2;
        vy = (vy1 + vy2) / 2;
      }
      final len = math.sqrt(vx * vx + vy * vy);
      if (len == 0) {
        out.add(pontos[i]);
        continue;
      }
      final nx = -vy / len;
      final ny =  vx / len;
      out.add(LatLng(pontos[i].latitude + nx * dx, pontos[i].longitude + ny * dx));
    }
    return out;
  }
}
