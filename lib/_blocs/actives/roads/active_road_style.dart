import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../_widgets/roads/active_road_class.dart';

class ActiveRoadsStyle extends ChangeNotifier {
  static List<ActiveRoadClass> styleLane(String? status, double zoom) {
    switch (status?.toUpperCase()) {
      case 'DUP': // DUPLICADA
        return
          [
            ActiveRoadClass(cor: Colors.white, width: (3.0 * math.pow(2, 13 - zoom)).clamp(2.5, 8.0).toDouble()),
            ActiveRoadClass(cor: colorForSurface('DUP'), width:  (2.0 * math.pow(2, 13 - zoom)).clamp(1.5, 4.0).toDouble()),
          ];
      case 'EOD': // EM OBRA DE DUPLICAÇÃO
        return
          [
            ActiveRoadClass(cor: Colors.white, width: (3.0 * math.pow(2, 13 - zoom)).clamp(2.5, 8.0).toDouble()),
            ActiveRoadClass(cor: colorForSurface('EOD'), width:  (2.0 * math.pow(2, 13 - zoom)).clamp(1.5, 4.0).toDouble()),
          ];
      case 'PAV': // PAVIMENTADA
        return
          [
            ActiveRoadClass(cor: Colors.white, width: (3.0 * math.pow(2, 13 - zoom)).clamp(2.5, 8.0).toDouble()),
            ActiveRoadClass(cor: colorForSurface('PAV'), width:  (2.0 * math.pow(2, 13 - zoom)).clamp(1.5, 4.0).toDouble()),
          ];
      case 'EOP': // EM OBRAS DE PAVIMENTAÇÃO
        return
          [
            ActiveRoadClass(cor: Colors.white, width: (3.0 * math.pow(2, 13 - zoom)).clamp(2.5, 8.0).toDouble()),
            ActiveRoadClass(cor: colorForSurface('EOP'), width:  (2.0 * math.pow(2, 13 - zoom)).clamp(1.5, 4.0).toDouble()),
          ];
      case 'IMP': //IMPLANTADA
        return
          [
            ActiveRoadClass(cor: Colors.white, width: (3.0 * math.pow(2, 13 - zoom)).clamp(2.5, 8.0).toDouble()),
            ActiveRoadClass(cor: colorForSurface('IMP'), width:  (2.0 * math.pow(2, 13 - zoom)).clamp(1.5, 4.0).toDouble()),
          ];
      case 'EOI': // EM OBRAS DE IMPLANTAÇÃO
        return
          [
            ActiveRoadClass(cor: Colors.white, width: (3.0 * math.pow(2, 13 - zoom)).clamp(2.5, 8.0).toDouble()),
            ActiveRoadClass(cor: colorForSurface('EOI'), width:  (2.0 * math.pow(2, 13 - zoom)).clamp(1.5, 4.0).toDouble()),
          ];
      case 'PLA': // PLANEJADA
        return
          [
            ActiveRoadClass(cor: Colors.white, width: (3.0 * math.pow(2, 13 - zoom)).clamp(2.5, 8.0).toDouble()),
            ActiveRoadClass(cor: colorForSurface('PLA'), width:  (2.0 * math.pow(2, 13 - zoom)).clamp(1.5, 4.0).toDouble()),
          ];
      case 'LEN': // LEITO NATURAL
        return
          [
            ActiveRoadClass(cor: Colors.white, width: (3.0 * math.pow(2, 13 - zoom)).clamp(2.5, 8.0).toDouble()),
            ActiveRoadClass(cor: colorForSurface('LEN'), width:  (2.0 * math.pow(2, 13 - zoom)).clamp(1.5, 4.0).toDouble()),
          ];
      default:
        return [
          ActiveRoadClass(cor: colorForSurface(''), width: (5.0 * math.pow(2, 1 - zoom)).clamp(1, 10.0).toDouble()),
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
      default:    return Colors.grey.shade600;
    }
  }
}
