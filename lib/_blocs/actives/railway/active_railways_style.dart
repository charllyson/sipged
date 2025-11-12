import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../_widgets/map/active_road_class.dart';

class ActiveRailwaysStyle extends ChangeNotifier {
  /// status esperado (código canônico):
  /// 'OP' (Em operação), 'OBRA' (Em obras), 'PLAN' (Planejada), 'INAT' (Inativa), default -> 'OUTRO'
  static List<ActiveRoadClass> styleLane(String? status, double zoom) {
    switch (status?.toUpperCase()) {
      case 'OP': // EM OPERAÇÃO
        return [
          ActiveRoadClass(
            cor: colorForStatus('OP'),
            width: (1.0 * math.pow(2, 5 - zoom)).clamp(1.5, 4.0).toDouble(),
          ),
        ];

      case 'OBRA': // EM OBRAS
        return [
          ActiveRoadClass(
            cor: colorForStatus('OBRA'),
            width: (1.0 * math.pow(2, 5 - zoom)).clamp(1.5, 4.0).toDouble(),
          ),
        ];

      case 'PLAN': // PLANEJADA
        return [
          ActiveRoadClass(
            cor: colorForStatus('PLAN'),
            width: (1.0 * math.pow(2, 5 - zoom)).clamp(1.5, 4.0).toDouble(),
          ),
        ];

      case 'INAT': // INATIVA / DESATIVADA
        return [
          ActiveRoadClass(
            cor: colorForStatus('INAT'),
            width: (1.0 * math.pow(2, 5 - zoom)).clamp(1.5, 4.0).toDouble(),
          ),
        ];

      default: // OUTROS
        return [
          ActiveRoadClass(
            cor: colorForStatus('OUTRO'),
            width: (5.0 * math.pow(2, 1 - zoom)).clamp(1.0, 10.0).toDouble(),
          ),
        ];
    }
  }

  // Paleta VISÍVEL (evita branco nas camadas superiores)
  static Color colorForStatus(String code) {
    switch (code.toUpperCase()) {
      case 'OP':   return Colors.black;
      case 'OBRA': return Colors.orange.shade600;
      case 'PLAN': return Colors.blue.shade400;
      case 'INAT': return Colors.grey.shade600;
      default:     return Colors.brown.shade500; // OUTRO
    }
  }
}
