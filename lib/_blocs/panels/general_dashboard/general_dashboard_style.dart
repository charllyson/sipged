import 'package:flutter/material.dart';

class GeneralDashboardStyle {

  static List<(String, String)> statusMenu = [
    ('🚜 Contratos em andamento', 'EM ANDAMENTO'),
    ('⏳ Contratos a iniciar', 'A INICIAR'),
    ('✅ Contratos concluídos', 'CONCLUÍDO'),
    ('🔧 Demandas em projeto', 'EM PROJETO'),
    ('🚫 Contratos paralisadas', 'PARALISADO'),
    ('❌ Contratos canceladas', 'CANCELADO'),
  ];

  static Color getColorByStatus(String status) {
    switch (status) {
      case 'EM ANDAMENTO':
        return Colors.amber.shade700;
      case 'A INICIAR':
        return Colors.blue.shade300;
      case 'CONCLUÍDO':
        return Colors.green;
      case 'EM PROJETO':
        return Colors.orange.shade700;
      case 'PARALISADO':
        return Colors.red.shade700;
      case 'CANCELADO':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }

  static IconData iconStatus(String status) {
    switch (status) {
      case 'EM ANDAMENTO':
        return Icons.work;
      case 'A INICIAR':
        return Icons.add_box;
      case 'CONCLUÍDO':
        return Icons.check_circle;
      case 'EM PROJETO':
        return Icons.build;
      case 'PARALISADO':
        return Icons.pause;
      case 'CANCELADO':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }
  static List<Color> statusColorsList = [
    Colors.yellow.shade700,
    Colors.blue.shade300,
    Colors.green,
    Colors.orange.shade700,
    Colors.red.shade700,
    Colors.grey,
  ];

  static Map<String, Color> regionsColors = {
    'SERTÃO': Colors.red.withValues(alpha: 0.2),
    'AGRESTE': Colors.blue.withValues(alpha: 0.2),
    'NORTE': Colors.purple.withValues(alpha: 0.2),
    'SUL': Colors.teal.withValues(alpha: 0.2),
    'VALE DO MUNDAÚ': Colors.orange.withValues(alpha: 0.2),
    'VALE DO PARAÍBA': Colors.brown.withValues(alpha: 0.2),
    'METROPOLITANA': Colors.pink.withValues(alpha: 0.2),
  };

  static Map<String, Color> statusColors = {
    'EM ANDAMENTO': Colors.yellow.shade800,
    'A INICIAR': Colors.blue.shade400,
    'CONCLUÍDO': Colors.green,
    'EM PROJETO': Colors.orange.shade800,
    'PARALISADO': Colors.red.shade800,
    'CANCELADO': Colors.grey,
  };

  // Paleta básica para gráficos e destaques
  static const Color kPrimary = Color(0xFF1976D2);  // azul
  static const Color kWarning = Color(0xFFFFA000);  // âmbar
  static const Color kSuccess = Color(0xFF2E7D32);  // verde



}