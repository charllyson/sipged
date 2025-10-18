import 'package:flutter/cupertino.dart';

double responsiveInputWidth({
  required BuildContext context,
  required int itemsPerLine,

  double? containerWidth,
  double spacing = 12.0,
  double margin = 12.0,
  double extraPadding = 0.0,
  double reservedWidth = 0.0,
  double spaceBetweenReserved = 0.0,

  // usado antes só p/ telas muito pequenas; mantém
  double? minWidthSmallScreen,

  /// 🔹 NOVO: largura mínima desejada por item em QUALQUER tela
  /// (bom para cards como SummaryExpandableCard).
  double minItemWidth = 220.0,

  /// Se true, mantém `itemsPerLine` mesmo <600px (como já existia)
  bool forceItemsPerLineOnSmall = false,
}) {
  final width = containerWidth ?? MediaQuery.of(context).size.width;

  // Quebra para 1 por linha em telas muito pequenas (a menos que seja forçado)
  if (!forceItemsPerLineOnSmall && width < 600) {
    final single = width - margin - 32; // 32 ~ padding típico
    if (minWidthSmallScreen != null) {
      return single.clamp(minWidthSmallScreen, double.infinity);
    }
    return single;
  }

  final totalMargins = margin * 2;
  final availableBase = width
      - totalMargins
      - extraPadding
      - reservedWidth
      - spaceBetweenReserved;

  // Começa com o desejado e vai reduzindo até caber a largura mínima
  int cols = itemsPerLine.clamp(1, 12);
  while (cols > 1) {
    final totalSpacing = spacing * (cols - 1);
    final available = availableBase - totalSpacing;
    final w = available / cols;
    if (w >= minItemWidth) {
      return w; // atende a largura mínima => usa `cols` atual
    }
    cols--;
  }

  // Se sobrou 1 coluna, calcule com ela
  final totalSpacing = spacing * (1 - 1); // 0
  final available = availableBase - totalSpacing;
  return available; // 1 por linha
}
