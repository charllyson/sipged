// lib/_blocs/modules/actives/railway/active_railways_style.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sipged/_widgets/map/polylines/polyline_changed_data.dart';

class ActiveRailwaysStyle extends ChangeNotifier {
  /// status esperado (código canônico):
  /// 'OP'   -> Em operação
  /// 'OBRA' -> Em obras
  /// 'PLAN' -> Planejada
  /// 'INAT' -> Inativa
  /// default -> 'OUTRO'
  static List<PolylineChangedData> styleLane(String? status, double zoom) {
    switch (status?.toUpperCase()) {
      case 'OP':
        return [
          PolylineChangedData(
            points: const [],
            tag: null,
            color: colorForStatus('OP'),
            defaultColor: colorForStatus('OP'),
            strokeWidth:
            (1.0 * math.pow(2, 5 - zoom)).clamp(1.5, 4.0).toDouble(),
            dx: 0,
            isDotted: false,
            hitTestable: false,
          ),
        ];

      case 'OBRA':
        return [
          PolylineChangedData(
            points: const [],
            tag: null,
            color: colorForStatus('OBRA'),
            defaultColor: colorForStatus('OBRA'),
            strokeWidth:
            (1.0 * math.pow(2, 5 - zoom)).clamp(1.5, 4.0).toDouble(),
            dx: 0,
            isDotted: false,
            hitTestable: false,
          ),
        ];

      case 'PLAN':
        return [
          PolylineChangedData(
            points: const [],
            tag: null,
            color: colorForStatus('PLAN'),
            defaultColor: colorForStatus('PLAN'),
            strokeWidth:
            (1.0 * math.pow(2, 5 - zoom)).clamp(1.5, 4.0).toDouble(),
            dx: 0,
            isDotted: false,
            hitTestable: false,
          ),
        ];

      case 'INAT':
        return [
          PolylineChangedData(
            points: const [],
            tag: null,
            color: colorForStatus('INAT'),
            defaultColor: colorForStatus('INAT'),
            strokeWidth:
            (1.0 * math.pow(2, 5 - zoom)).clamp(1.5, 4.0).toDouble(),
            dx: 0,
            isDotted: false,
            hitTestable: false,
          ),
        ];

      default:
        return [
          PolylineChangedData(
            points: const [],
            tag: null,
            color: colorForStatus('OUTRO'),
            defaultColor: colorForStatus('OUTRO'),
            strokeWidth:
            (5.0 * math.pow(2, 1 - zoom)).clamp(1.0, 10.0).toDouble(),
            dx: 0,
            isDotted: false,
            hitTestable: false,
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
        return Colors.brown.shade500;
    }
  }
}