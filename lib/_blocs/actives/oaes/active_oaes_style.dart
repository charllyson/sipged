import 'package:flutter/material.dart';

class OaesDataStyle {
  /// Mapa 0..5 -> cores
  static Color getColorByNota(double nota) {
    if (nota == 0) return Colors.green.shade700;  // Restaurada
    if (nota == 1) return Colors.red.shade900;    // Crítica
    if (nota == 2) return Colors.orange.shade900; // Problemática
    if (nota == 3) return Colors.yellow.shade800; // Potencialmente problemática
    if (nota == 4) return Colors.purple.shade400; // Sem problemas sérios
    if (nota == 5) return Colors.blue.shade700;   // Sem problemas
    return Colors.grey.shade400;                  // Sem nota
  }

  /// Label semântico por nota
  static String getLabelByNota(int nota) {
    switch (nota) {
      case 0:
        return 'Restaurada';
      case 1:
        return 'Crítica';
      case 2:
        return 'Problemática';
      case 3:
        return 'Potencialmente problemática';
      case 4:
        return 'Sem problemas sérios';
      case 5:
        return 'Sem problemas';
      default:
        return 'Sem nota';
    }
  }

  /// Versão segura (aceita null, clamp 0..5)
  static Color colorForScore(num? score) {
    if (score == null) return Colors.grey.shade400;
    final s = score.toDouble();
    if (s.isNaN) return Colors.grey.shade400;
    final c = s.clamp(0, 5).toDouble();
    return getColorByNota(c);
  }

  /// Lista de cores paralela aos scores
  static List<Color> colorsFromScores(List<num?> scores) =>
      scores.map(colorForScore).toList(growable: false);
}
