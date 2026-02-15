// lib/_blocs/modules/actives/railway/active_railways_style.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sipged/_widgets/map/polylines/polyline_changed_class.dart';

class ActiveRailwaysStyle extends ChangeNotifier {
  /// status esperado (código canônico):
  /// 'OP' (Em operação), 'OBRA' (Em obras), 'PLAN' (Planejada), 'INAT' (Inativa), default -> 'OUTRO'
  static List<PolylineClass> styleLane(String? status, double zoom) {
    switch (status?.toUpperCase()) {
      case 'OP': // EM OPERAÇÃO
        return [
          PolylineClass(
            cor: colorForStatus('OP'),
            width:
            (1.0 * math.pow(2, 5 - zoom)).clamp(1.5, 4.0).toDouble(),
          ),
        ];

      case 'OBRA': // EM OBRAS
        return [
          PolylineClass(
            cor: colorForStatus('OBRA'),
            width:
            (1.0 * math.pow(2, 5 - zoom)).clamp(1.5, 4.0).toDouble(),
          ),
        ];

      case 'PLAN': // PLANEJADA
        return [
          PolylineClass(
            cor: colorForStatus('PLAN'),
            width:
            (1.0 * math.pow(2, 5 - zoom)).clamp(1.5, 4.0).toDouble(),
          ),
        ];

      case 'INAT': // INATIVA / DESATIVADA
        return [
          PolylineClass(
            cor: colorForStatus('INAT'),
            width:
            (1.0 * math.pow(2, 5 - zoom)).clamp(1.5, 4.0).toDouble(),
          ),
        ];

      default: // OUTROS
        return [
          PolylineClass(
            cor: colorForStatus('OUTRO'),
            width:
            (5.0 * math.pow(2, 1 - zoom)).clamp(1.0, 10.0).toDouble(),
          ),
        ];
    }
  }

  // Paleta VISÍVEL (evita branco nas camadas superiores)
  static Color colorForStatus(String code) {
    switch (code.toUpperCase()) {
      case 'OP':
        return Colors.black;
      case 'OBRA':
        return Colors.orange.shade600;
      case 'PLAN':
        return Colors.blue.shade400;
      case 'INAT':
        return Colors.grey.shade600;
      default:
        return Colors.brown.shade500; // OUTRO
    }
  }
}
