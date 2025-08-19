import 'package:flutter/material.dart';

class OaesDataStyle{
  static Color getColorByNota(double nota) {
    if (nota == 0) return Colors.green.shade700;
    if (nota == 1) return Colors.red.shade900;
    if (nota == 2) return Colors.orange.shade900;
    if (nota == 3) return Colors.yellow.shade800;
    if (nota == 4) return Colors.purple.shade400;
    if (nota == 5) return Colors.blue.shade700;
    return Colors.grey.shade400;
  }
}