// lib/_blocs/modules/actives/railway/active_railways_style.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

class RailwayLaneStyle {
  const RailwayLaneStyle({
    required this.color,
    this.defaultColor,
    required this.strokeWidth,
    this.dx = 0.0,
    this.isDotted = false,
  });

  final Color color;
  final Color? defaultColor;
  final double strokeWidth;
  final double dx;
  final bool isDotted;
}

class ActiveRailwaysStyle extends ChangeNotifier {
  /// Status esperado:
  /// 'OP'    -> Em operação
  /// 'OBRA'  -> Em obras
  /// 'PLAN'  -> Planejada
  /// 'INAT'  -> Inativa
  /// default -> OUTRO
  static List<RailwayLaneStyle> styleLane(String? status, double zoom) {
    final code = status?.toUpperCase().trim();

    double normalStroke() {
      return (1.0 * math.pow(2, 5 - zoom)).clamp(1.5, 4.0).toDouble();
    }

    switch (code) {
      case 'OP':
        return [
          RailwayLaneStyle(
            color: colorForStatus('OP'),
            defaultColor: colorForStatus('OP'),
            strokeWidth: normalStroke(),
            dx: 0,
            isDotted: false,
          ),
        ];

      case 'OBRA':
        return [
          RailwayLaneStyle(
            color: colorForStatus('OBRA'),
            defaultColor: colorForStatus('OBRA'),
            strokeWidth: normalStroke(),
            dx: 0,
            isDotted: false,
          ),
        ];

      case 'PLAN':
        return [
          RailwayLaneStyle(
            color: colorForStatus('PLAN'),
            defaultColor: colorForStatus('PLAN'),
            strokeWidth: normalStroke(),
            dx: 0,
            isDotted: true,
          ),
        ];

      case 'INAT':
        return [
          RailwayLaneStyle(
            color: colorForStatus('INAT'),
            defaultColor: colorForStatus('INAT'),
            strokeWidth: normalStroke(),
            dx: 0,
            isDotted: false,
          ),
        ];

      default:
        return [
          RailwayLaneStyle(
            color: colorForStatus('OUTRO'),
            defaultColor: colorForStatus('OUTRO'),
            strokeWidth: (5.0 * math.pow(2, 1 - zoom))
                .clamp(1.0, 10.0)
                .toDouble(),
            dx: 0,
            isDotted: false,
          ),
        ];
    }
  }

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