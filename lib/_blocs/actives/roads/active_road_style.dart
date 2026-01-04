import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../_widgets/map/polylines/active_road_class.dart';

/// ---------------------------------------------------------------------------
/// ESTILOS DAS RODOVIAS (PERFORMANCE OTIMIZADA)
/// ---------------------------------------------------------------------------
class ActiveRoadsStyle extends ChangeNotifier {
  /// calcula largura com cache simples (evita recalcular pow muitas vezes)
  static double _lane(double zoom, double base, double min, double max) {
    final v = (base * math.pow(2, (13 - zoom))).toDouble();
    if (v < min) return min;
    if (v > max) return max;
    return v;
  }

  static List<PolylineClass> styleLane(String? status, double zoom) {
    final w1 = _lane(zoom, 3.0, 2.5, 8.0);
    final w2 = _lane(zoom, 2.0, 1.5, 4.0);

    Color surfColor = colorForSurface(status?.toUpperCase() ?? '');

    switch (status?.toUpperCase()) {
      case 'DUP':
      case 'EOD':
      case 'PAV':
      case 'EOP':
      case 'IMP':
      case 'EOI':
      case 'PLA':
      case 'LEN':
        return [
          PolylineClass(cor: Colors.white, width: w1),
          PolylineClass(cor: surfColor, width: w2),
        ];
      default:
        final d = (5.0 * math.pow(2, 1 - zoom))
            .clamp(1.0, 10.0)
            .toDouble();
        return [
          PolylineClass(
            cor: colorForSurface(''),
            width: d,
          ),
        ];
    }
  }

  // Paleta VISÍVEL para o Pie (evita branco)
  static Color colorForSurface(String code) {
    switch (code) {
      case 'DUP': return Colors.green.shade600;
      case 'EOD': return Colors.green.shade300;
      case 'PAV': return Colors.blue.shade600;
      case 'EOP': return Colors.blue.shade300;
      case 'IMP': return Colors.brown.shade600;
      case 'EOI': return Colors.brown.shade300;
      case 'PLA': return Colors.orange.shade300;
      case 'LEN': return Colors.red.shade300;
      default: return Colors.grey.shade600;
    }
  }
}
