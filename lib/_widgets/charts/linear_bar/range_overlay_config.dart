// lib/_widgets/charts/linear_bar/range_overlay_config.dart
import 'package:flutter/material.dart';
import 'package:sipged/_widgets/charts/linear_bar/types.dart';

/// ============================================================
/// ✅ Overlay de faixa com start/end + linhas tracejadas
/// - startValue/endValue são mapeados para a largura do bar
/// - por padrão, o "máximo" usado no mapeamento é `maxValue`
///   (se null => usa globalMax do gráfico)
/// - `overlayOverflow` controla quanto “vaza” para fora da barra
/// ============================================================
class RangeOverlayConfig {
  final double startValue;
  final double endValue;

  /// Se null, usa o globalMax do gráfico.
  final double? maxValue;

  /// Cor do preenchimento (faixa).
  final Color fillColor;

  /// Cor da linha tracejada.
  final Color dashedLineColor;

  /// Espessura da linha tracejada.
  final double dashedStrokeWidth;

  /// Comprimento do traço.
  final double dashWidth;

  /// Espaço entre traços.
  final double dashGap;

  /// Mostrar os textos (start/end) no overlay.
  final bool showLabels;

  /// ✅ Tipo do valor (money/unit/percent/custom)
  final ValueType valueType;

  /// ✅ Formatter custom (usado quando valueType == custom, ou quando você quiser forçar)
  final StackedValueFormatter? customFormatter;

  /// ✅ Precisão para unit/percent
  final int fractionDigits;

  /// ✅ Sufixo para unit (ex.: "km", "m²")
  final String unitSuffix;

  /// Estilo do texto.
  final TextStyle? labelStyle;

  /// Padding interno para posicionar labels.
  final EdgeInsets labelPadding;

  /// ✅ Quanto o overlay deve “vazar” para cima e para baixo (px).
  final double overlayOverflow;

  const RangeOverlayConfig({
    required this.startValue,
    required this.endValue,
    this.maxValue,
    this.fillColor = const Color(0x33FFFFFF),
    this.dashedLineColor = const Color(0xCCFFFFFF),
    this.dashedStrokeWidth = 1.5,
    this.dashWidth = 6.0,
    this.dashGap = 4.0,
    this.showLabels = true,
    this.valueType = ValueType.unit,
    this.customFormatter,
    this.fractionDigits = 2,
    this.unitSuffix = '',
    this.labelStyle,
    this.labelPadding = const EdgeInsets.symmetric(horizontal: 6),
    this.overlayOverflow = 10.0,
  });

  bool get isValid => endValue > startValue;

  /// ✅ Formatter único do overlay (centralizado)
  String format(double v) => formatStackedValue(
    v,
    type: valueType,
    custom: customFormatter,
    fractionDigits: fractionDigits,
    unitSuffix: unitSuffix,
  );
}
