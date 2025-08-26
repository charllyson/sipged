import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

class ActiveRoadsRules{

  static String getStatusSurface(String status) {
    switch (status) {
      case 'DUP':
        return 'DUPLICADA';
      case 'EOD':
        return 'EM OBRA DE DUPLICAÇÃO';
      case 'PAV':
        return 'PAVIMENTADA';
      case 'EOP':
        return 'EM OBRAS DE PAVIMENTAÇÃO';
      case 'IMP':
        return 'IMPLANTADA';
      case 'EOI':
        return 'EM OBRAS DE IMPLANTAÇÃO';
      case 'LEN':
        return 'LEITO NATURAL';
      case 'PLA':
        return 'PLANEJADA';
      default:
        return 'OUTRO';
    }
  }

  /// Ajusta a largura da linha com base no zoom do mapa
  static double getStrokeByZoom(double larguraBase, double zoom) {
    // Aumenta mais agressivamente com zoom
    final fator = (zoom / 10).clamp(0.6, 2.5); // valor calibrado
    final ajustado = larguraBase * fator;
    return ajustado.clamp(0.1, 12.0);
  }

  /// Aplica deslocamento simples ou ortogonal nos pontos
  static List<LatLng> deslocarPontos(
      List<LatLng> pontos, {
        double dx = 0,
        double dy = 0,
        double? deslocamentoOrtogonal,
      }) {
    if (deslocamentoOrtogonal != null) {
      return _deslocarOrtogonalSuavizado(pontos, deslocamentoOrtogonal);
    }

    return pontos
        .map((p) => LatLng(p.latitude + dy, p.longitude + dx))
        .toList();
  }

  /// Desloca os pontos ortogonalmente à direção da linha
  static List<LatLng> _deslocarOrtogonalSuavizado(List<LatLng> pontos, double dx) {
    if (pontos.length < 2) return pontos;

    final deslocados = <LatLng>[];

    for (int i = 0; i < pontos.length; i++) {
      late double dxFinal, dyFinal;

      if (i == 0) {
        // Primeiro ponto: usa vetor entre p0 e p1
        dxFinal = pontos[1].latitude - pontos[0].latitude;
        dyFinal = pontos[1].longitude - pontos[0].longitude;
      } else if (i == pontos.length - 1) {
        // Último ponto: usa vetor entre penúltimo e último
        dxFinal = pontos[i].latitude - pontos[i - 1].latitude;
        dyFinal = pontos[i].longitude - pontos[i - 1].longitude;
      } else {
        // Ponto intermediário: média dos vetores antes e depois
        final dx1 = pontos[i].latitude - pontos[i - 1].latitude;
        final dy1 = pontos[i].longitude - pontos[i - 1].longitude;
        final dx2 = pontos[i + 1].latitude - pontos[i].latitude;
        final dy2 = pontos[i + 1].longitude - pontos[i].longitude;

        dxFinal = (dx1 + dx2) / 2;
        dyFinal = (dy1 + dy2) / 2;
      }

      // Normaliza vetor
      final length = math.sqrt(dxFinal * dxFinal + dyFinal * dyFinal);
      if (length == 0) {
        deslocados.add(pontos[i]);
        continue;
      }

      final nx = -dyFinal / length; // vetor ortogonal normalizado (inverte e gira)
      final ny = dxFinal / length;

      // Aplica deslocamento
      final novoPonto = LatLng(
        pontos[i].latitude + nx * dx,
        pontos[i].longitude + ny * dx,
      );

      deslocados.add(novoPonto);
    }

    return deslocados;
  }


  /// Largura simbólica usada em outros componentes para legendas
  static double getWidthByStatus(String? status) {
    switch (status?.trim().toUpperCase()) {
      case 'DUP':
      case 'EOD':
      case 'PAV':
      case 'EOP':
        return 3.0;

      case 'IMP':
      case 'EOI':
        return 2.0;

      case 'LEN':
      case 'PLA':
        return 1.0;

      default:
        return 2.0;
    }
  }
}