// lib/_widgets/charts/linear_bar/horizontal_bar_chart_bars.dart
import 'package:flutter/material.dart';
import 'package:siged/_widgets/charts/linear_bar/horizontal_bar_chart.dart';

import 'package:siged/_widgets/charts/linear_bar/range_overlay_config.dart';
import 'package:siged/_widgets/charts/linear_bar/slice_hatch_config.dart';

import 'types.dart';

class HorizontalStackedBarsBars extends StatelessWidget {
  /// Label de cada linha (ex: região, empresa etc.)
  final List<String> labels;

  /// Valores de cada linha.
  final List<List<double>> values;

  /// Labels das fatias (compartilhadas entre todas as linhas).
  final List<String>? groupLegendLabels;

  /// Cores base das fatias (na mesma ordem das posições de `values[i]`).
  final List<Color> colors;

  /// Máximo global (soma dos slices por linha) para normalizar os flex.
  final double globalMax;

  /// Altura da barra (sem contar labels acima).
  final double barHeight;

  /// Largura reservada para o texto da esquerda (nome da região / obra).
  final double labelWidth;

  /// Espaço horizontal entre o texto da esquerda e o início da barra.
  final double gapLabelToBar;

  /// Onde os labels das fatias serão exibidos (acima, dentro ou nenhum).
  final LabelLocation sliceLabelLocation;

  /// Tema atual (dark / light) afeta cores de fundo/seleção.
  final bool isDark;

  /// Índice da linha selecionada (controle externo, opcional).
  final int? selectedRowIndex;

  /// Índice da fatia selecionada dentro da linha (controle externo, opcional).
  final int? selectedSliceIndex;

  /// True se o pai controla a seleção (via props/callback).
  final bool isExternalControlled;

  /// Chamado quando estiver em modo de seleção interna.
  final void Function(int rowIndex, int sliceIndex)? onInternalToggleSelection;

  /// Callback do pai para clique na fatia.
  final void Function(
      int rowIndex,
      int sliceIndex,
      String rowLabel,
      String? sliceLabel,
      )? onSliceTapExternal;

  // ============================================================
  // ✅ Configuração opcional de hatch POR FATIA
  // ============================================================
  final SliceHatchConfig? hatch;

  // ============================================================
  // ✅ Overlay opcional de faixa (start/end) com tracejado
  // ============================================================
  final RangeOverlayConfig? rangeOverlay;

  const HorizontalStackedBarsBars({
    super.key,
    required this.labels,
    required this.values,
    required this.colors,
    required this.globalMax,
    required this.barHeight,
    required this.labelWidth,
    required this.gapLabelToBar,
    required this.sliceLabelLocation,
    required this.isDark,
    required this.selectedRowIndex,
    required this.selectedSliceIndex,
    required this.isExternalControlled,
    this.groupLegendLabels,
    this.onInternalToggleSelection,
    this.onSliceTapExternal,
    this.hatch,
    this.rangeOverlay,
  });

  /// Converte o valor absoluto da fatia em `flex` proporcional ao [globalMax].
  int _flexFromValue(double v) {
    if (globalMax <= 0 || v <= 0) return 1;
    final fraction = (v / globalMax).clamp(0.0, 1.0);
    final flex = (fraction * 10000).round();
    return flex <= 0 ? 1 : flex;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(labels.length, (rowIndex) {
        return HorizontalChartBar(
          rowIndex: rowIndex,
          label: labels[rowIndex],
          values: values[rowIndex],
          colors: colors,
          globalMax: globalMax,
          barHeight: barHeight,
          labelWidth: labelWidth,
          gapLabelToBar: gapLabelToBar,
          sliceLabelLocation: sliceLabelLocation,
          isDark: isDark,
          groupLegendLabels: groupLegendLabels,
          selectedRowIndex: selectedRowIndex,
          selectedSliceIndex: selectedSliceIndex,
          isExternalControlled: isExternalControlled,
          flexFromValue: _flexFromValue,
          onInternalToggleSelection: onInternalToggleSelection,
          onSliceTapExternal: onSliceTapExternal,
          hatch: hatch,
          rangeOverlay: rangeOverlay,
        );
      }),
    );
  }
}
