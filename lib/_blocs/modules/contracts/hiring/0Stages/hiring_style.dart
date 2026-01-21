import 'package:flutter/material.dart';

/// Cores baseadas em um status (fundo, borda, título/texto).
class StatusColors {
  final Color background;
  final Color border;
  final Color title;

  const StatusColors({
    required this.background,
    required this.border,
    required this.title,
  });
}

class HiringStyle {
  /// 🔹 Cores para status das certidões (FGTS, INSS, Fazenda etc.)
  static StatusColors certidaoColorsForStatus(
      String status,
      ThemeData theme,
      ) {
    // fallback neutro
    Color bg = theme.colorScheme.surfaceVariant.withOpacity(0.3);
    Color border = theme.dividerColor;
    Color title = theme.colorScheme.onSurface;

    switch (status) {
      case 'Válida':
        bg = Colors.green.shade50;
        border = Colors.green.shade400;
        title = Colors.green.shade800;
        break;
      case 'Vencida':
        bg = Colors.red.shade50;
        border = Colors.red.shade400;
        title = Colors.red.shade800;
        break;
      case 'Em atualização':
        bg = Colors.orange.shade50;
        border = Colors.orange.shade400;
        title = Colors.orange.shade800;
        break;
      case 'Dispensada':
        bg = Colors.blueGrey.shade50;
        border = Colors.blueGrey.shade300;
        title = Colors.blueGrey.shade800;
        break;
      case 'Não se aplica':
        bg = Colors.grey.shade100;
        border = Colors.grey.shade400;
        title = Colors.grey.shade800;
        break;
      default:
      // mantém o neutro
        break;
    }

    return StatusColors(background: bg, border: border, title: title);
  }

  /// 🔹 Cores para status do checklist jurídico
  /// (Conforme, Parcial, Não conforme, N/A)
  static StatusColors checklistColorsForStatus(
      String status,
      ThemeData theme,
      ) {
    // fallback neutro
    Color bg = theme.colorScheme.surfaceVariant.withOpacity(0.3);
    Color border = theme.dividerColor;
    Color title = theme.colorScheme.onSurface;

    switch (status) {
      case 'Conforme':
        bg = Colors.green.shade50;
        border = Colors.green.shade400;
        title = Colors.green.shade800;
        break;
      case 'Parcial':
        bg = Colors.orange.shade50;
        border = Colors.orange.shade400;
        title = Colors.orange.shade800;
        break;
      case 'Não conforme':
        bg = Colors.red.shade50;
        border = Colors.red.shade400;
        title = Colors.red.shade800;
        break;
      case 'N/A':
        bg = Colors.grey.shade100;
        border = Colors.grey.shade400;
        title = Colors.grey.shade700;
        break;
      default:
      // neutro
        break;
    }

    return StatusColors(background: bg, border: border, title: title);
  }
}
