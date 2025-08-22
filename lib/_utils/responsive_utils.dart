// lib/_utils/responsive_utils.dart
import 'package:flutter/material.dart';

double responsiveInputWidth({
  required BuildContext context,
  required int itemsPerLine,

  /// Se você estiver dentro de um LayoutBuilder, passe `constraints.maxWidth`
  /// para ter a largura REAL disponível do container pai.
  double? containerWidth,

  double spacing = 12.0,              // Espaço entre campos na mesma linha
  double margin = 12.0,               // Margem lateral do container
  double extraPadding = 0.0,          // Padding interno extra (se houver)
  double reservedWidth = 0.0,         // Largura de elementos fixos (ex: ícone PDF)
  double spaceBetweenReserved = 0.0,  // Espaço entre fixos e inputs
  double? minWidthSmallScreen,        // Largura mínima para telas muito pequenas

  /// NOVO: quando true, mantém `itemsPerLine` mesmo em telas < 600px
  bool forceItemsPerLineOnSmall = false,
}) {
  final width = containerWidth ?? MediaQuery.of(context).size.width;

  // Quebra para 1 por linha em telas muito pequenas (a menos que seja forçado)
  if (!forceItemsPerLineOnSmall && width < 600) {
    final single = width - margin - 32; // 32 ~ padding interno típico da tela
    if (minWidthSmallScreen != null) {
      return single.clamp(minWidthSmallScreen, double.infinity);
    }
    return single;
  }

  final totalSpacing = spacing * (itemsPerLine - 1);
  final totalMargins = margin * 2;
  final available = width
      - totalSpacing
      - totalMargins
      - extraPadding
      - reservedWidth
      - spaceBetweenReserved;

  return available / itemsPerLine;
}
