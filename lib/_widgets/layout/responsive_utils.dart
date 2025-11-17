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

  double? minWidthSmallScreen,
  double minItemWidth = 220.0,
  bool forceItemsPerLineOnSmall = false,
}) {
  final width = containerWidth ?? MediaQuery.of(context).size.width;

  final effectiveMargin = containerWidth == null ? margin : 0.0;

  if (!forceItemsPerLineOnSmall && width < 600) {
    final single = width - (effectiveMargin * 2) - extraPadding;
    if (minWidthSmallScreen != null) {
      return single.clamp(minWidthSmallScreen, double.infinity) as double;
    }
    return single;
  }

  final totalMargins = effectiveMargin * 2;
  final availableBase = width
      - totalMargins
      - extraPadding
      - reservedWidth
      - spaceBetweenReserved;

  int cols = itemsPerLine.clamp(1, 12);
  while (cols > 1) {
    final totalSpacing = spacing * (cols - 1);
    final available = availableBase - totalSpacing;
    final w = available / cols;
    if (w >= minItemWidth) {
      return w;
    }
    cols--;
  }

  final totalSpacing = spacing * (1 - 1); // 0
  final available = availableBase - totalSpacing;
  return available;
}

/// Helper centralizado para calcular largura dos inputs
double inputWidth({
  required BuildContext context,
  required BoxConstraints inner,
  required int perLine,
  double minItemWidth = 220,

  // 🔹 overrides opcionais (casos especiais)
  double? spacing,
  double? margin,
  double? extraPadding,
  double? reservedWidth,
  double? spaceBetweenReserved,
  double? minWidthSmallScreen,
  bool? forceItemsPerLineOnSmall,
}) {
  return responsiveInputWidth(
    context: context,
    itemsPerLine: perLine,
    containerWidth: inner.maxWidth,
    spacing: spacing ?? 12,
    margin: margin ?? 12,         // ignorado quando containerWidth != null
    extraPadding: extraPadding ?? 0,
    reservedWidth: reservedWidth ?? 0,
    spaceBetweenReserved: spaceBetweenReserved ?? 0,
    minItemWidth: minItemWidth,
    minWidthSmallScreen: minWidthSmallScreen ?? 280,
    forceItemsPerLineOnSmall: forceItemsPerLineOnSmall ?? true,
  );
}

double inputWidthPerLine({
  required BuildContext context,
  required BoxConstraints inner,
  required int perLine,
  double minItemWidth = 260,
}) {
  return inputWidth(
    context: context,
    inner: inner,
    perLine: perLine,
    minItemWidth: minItemWidth,
  );
}

// ===== atalhos padrão (sem override) =====

double inputW1(BuildContext context, BoxConstraints inner) {
  return inputWidth(
    context: context,
    inner: inner,
    perLine: 1,
    minItemWidth: 400,
  );
}

double inputW2(BuildContext context, BoxConstraints inner) {
  return inputWidth(
    context: context,
    inner: inner,
    perLine: 2,
    minItemWidth: 260,
  );
}

double inputW3(BuildContext context, BoxConstraints inner) {
  return inputWidth(
    context: context,
    inner: inner,
    perLine: 3,
    minItemWidth: 260,
  );
}

double inputW4(BuildContext context, BoxConstraints inner) {
  return inputWidth(
    context: context,
    inner: inner,
    perLine: 4,
    minItemWidth: 260,
  );
}

double inputW5(BuildContext context, BoxConstraints inner) {
  return inputWidth(
    context: context,
    inner: inner,
    perLine: 5,
    minItemWidth: 260,
  );
}

double inputW6(BuildContext context, BoxConstraints inner) {
  return inputWidth(
    context: context,
    inner: inner,
    perLine: 6,
    minItemWidth: 260,
  );
}

double inputW7(BuildContext context, BoxConstraints inner) {
  return inputWidth(
    context: context,
    inner: inner,
    perLine: 7,
    minItemWidth: 200,
  );
}
