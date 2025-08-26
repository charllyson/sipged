import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../_widgets/roads/active_road_class.dart';

class ActiveRoadsStyle extends ChangeNotifier {
  static List<ActiveRoadClass> styleQGISParaStatus(String? status, double zoom) {
    switch (status?.toUpperCase()) {
      case 'DUP': // DUPLICADA
        return
          [
            ActiveRoadClass(cor: Colors.green.shade600, width: (3.0 * math.pow(2, 13 - zoom)).clamp(2.5, 8.0).toDouble()),
            ActiveRoadClass(cor: Colors.green.shade200, width:  (2.0 * math.pow(2, 13 - zoom)).clamp(1.5, 4.0).toDouble()),
          ];
      case 'EOD': // EM OBRA DE DUPLICAÇÃO
        return
          [
            ActiveRoadClass(cor: Colors.green.shade600, width: (3.0 * math.pow(2, 13 - zoom)).clamp(2.5, 8.0).toDouble()),
            ActiveRoadClass(cor: Colors.white, width:  (2.0 * math.pow(2, 13 - zoom)).clamp(1.5, 4.0).toDouble()),
          ];
      case 'PAV': // PAVIMENTADA
        return
          [
            ActiveRoadClass(cor: Colors.green.shade600, width: (3.0 * math.pow(2, 10 - zoom)).clamp(2.5, 6.0).toDouble()),
            ActiveRoadClass(cor: Colors.green.shade200, width:  (2.0 * math.pow(2, 10 - zoom)).clamp(1.5, 4.0).toDouble()),
          ];
      case 'EOP': // EM OBRAS DE PAVIMENTAÇÃO
        return
          [
            ActiveRoadClass(cor: Colors.green.shade600, width: (3.0 * math.pow(2, 10 - zoom)).clamp(2.5, 6.0).toDouble()),
            ActiveRoadClass(cor: Colors.white, width:  (2.0 * math.pow(2, 10 - zoom)).clamp(1.5, 4.0).toDouble()),
          ];
      case 'IMP': //IMPLANTADA
        return
          [
            ActiveRoadClass(cor: Colors.white, width: (3.0 * math.pow(2, 13 - zoom)).clamp(2.5, 6.0).toDouble()),
            ActiveRoadClass(cor: Colors.green, width:  (2.0 * math.pow(2, 13 - zoom)).clamp(1.5, 4.0).toDouble()),
          ];
      case 'EOI': // EM OBRAS DE IMPLANTAÇÃO
        return
          [
            ActiveRoadClass(cor: Colors.white, width: (3.0 * math.pow(2, 13 - zoom)).clamp(2.5, 6.0).toDouble()),
            ActiveRoadClass(cor: Colors.green, width:  (2.0 * math.pow(2, 13 - zoom)).clamp(1.5, 4.0).toDouble()),
          ];
      case 'PLA': // PLANEJADA
        return
          [
            ActiveRoadClass(cor: Colors.blue, width: (3.0 * math.pow(2, 13 - zoom)).clamp(2.5, 6.0).toDouble()),
            ActiveRoadClass(cor: Colors.white, width:  (2.0 * math.pow(2, 13 - zoom)).clamp(1.5, 4.0).toDouble()),
          ];
      case 'LEN': // LEITO NATURAL
        return
          [
            ActiveRoadClass(cor: Colors.blue, width: (3.0 * math.pow(2, 8 - zoom)).clamp(2.5, 6.0).toDouble()),
          ];
      default:
        return [
          ActiveRoadClass(cor: Colors.grey.shade600, width: (5.0 * math.pow(2, 1 - zoom)).clamp(1, 10.0).toDouble()),
        ];
    }
  }
}
