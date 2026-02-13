import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:sipged/_blocs/modules/financial/budget/budget_data.dart';
import 'package:sipged/_blocs/modules/financial/empenhos/empenho_data.dart';

import 'package:sipged/_widgets/charts/legend/chart_legend.dart';
import 'package:sipged/_widgets/charts/linear_bar/horizontal_bar_chart_changed.dart';
import 'package:sipged/_widgets/charts/linear_bar/types.dart';

class EmpenhoSlicesRow extends StatefulWidget {
  final NumberFormat currency;

  /// Orçamento (para mapear cor por fundingSourceLabel)
  final List<BudgetData> budgets;

  /// Empenhos do recorte atual (contrato ou geral)
  final List<EmpenhoData> empenhos;

  const EmpenhoSlicesRow({
    super.key,
    required this.currency,
    required this.budgets,
    required this.empenhos,
  });

  @override
  State<EmpenhoSlicesRow> createState() => _EmpenhoSlicesRowState();
}

class _EmpenhoSlicesRowState extends State<EmpenhoSlicesRow> {
  /// seleção global (aplica em todos os blocos de demanda)
  int? _selectedSliceIndex;

  void _toggleSlice(int slice) {
    setState(() {
      _selectedSliceIndex = (_selectedSliceIndex == slice) ? null : slice;
    });
  }

  // =========================================================
  // PALETA CONSISTENTE: fundingSourceLabel -> Color
  // =========================================================
  List<Color> _buildPalette(int n) {
    if (n <= 0) return const <Color>[];
    return List<Color>.generate(n, (i) {
      final hue = (360.0 * (i / max(1, n))) % 360.0;
      return HSLColor.fromAHSL(1.0, hue, 0.62, 0.52).toColor();
    });
  }

  List<String> _fundingSourceOrder() {
    // 1) tenta ordenar por orçamento (maior valor primeiro)
    final Map<String, double> byBudget = {};
    for (final b in widget.budgets) {
      final k = (b.fundingSourceLabel ?? '').trim();
      if (k.isEmpty) continue;
      byBudget[k] = (byBudget[k] ?? 0) + b.amount;
    }

    if (byBudget.isNotEmpty) {
      final entries = byBudget.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      return entries.map((e) => e.key).toList();
    }

    // 2) fallback: pelas fontes presentes nos empenhos
    final set = <String>{};
    for (final e in widget.empenhos) {
      final k = e.fundingSourceLabel.trim();
      if (k.isNotEmpty) set.add(k);
    }
    final list = set.toList()..sort();
    return list;
  }

  Map<String, Color> _buildFundingSourceColorMap(List<String> sources) {
    final colors = _buildPalette(sources.length);
    final Map<String, Color> map = {};
    for (int i = 0; i < sources.length; i++) {
      map[sources[i]] = colors[i];
    }
    return map;
  }

  // =========================================================
  // AGREGAÇÃO: DEMANDA -> (FONTE -> VALOR)
  // =========================================================
  Map<String, Map<String, double>> _empenhosByDemandBySource() {
    final Map<String, Map<String, double>> out = {};

    for (final e in widget.empenhos) {
      final demand = e.demandLabel.trim().isNotEmpty ? e.demandLabel.trim() : 'Sem demanda';
      final source = e.fundingSourceLabel.trim().isNotEmpty ? e.fundingSourceLabel.trim() : 'Sem fonte';

      out.putIfAbsent(demand, () => <String, double>{});
      out[demand]![source] = (out[demand]![source] ?? 0) + e.empenhadoTotal;
    }

    // ordenação por total desc (demanda maior primeiro)
    final entries = out.entries.toList()
      ..sort((a, b) {
        final at = a.value.values.fold<double>(0, (s, v) => s + v);
        final bt = b.value.values.fold<double>(0, (s, v) => s + v);
        final r = bt.compareTo(at);
        if (r != 0) return r;
        return a.key.toLowerCase().compareTo(b.key.toLowerCase());
      });

    return {for (final e in entries) e.key: e.value};
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (widget.empenhos.isEmpty) {
      return const Text("Nenhum empenho cadastrado.");
    }

    // fontes globais (para manter mesma cor por fonte)
    final globalSources = _fundingSourceOrder();
    final sourceColorMap = _buildFundingSourceColorMap(globalSources);

    final grouped = _empenhosByDemandBySource();
    if (grouped.isEmpty) {
      return const Text("Nenhuma demanda encontrada nos empenhos.");
    }

    const double kCardHeight = 70.0;
    const double kLegendWidth = 420.0;

    final isMobile = MediaQuery.of(context).size.width < 600;

    final blocks = <Widget>[];

    for (final entry in grouped.entries) {
      final demandLabel = entry.key;
      final bySource = entry.value;

      // ----------------------------
      // 1) alinha valores na ordem global
      // 2) filtra fontes com valor <= 0
      // ----------------------------
      final filteredLabels = <String>[];
      final filteredValues = <double>[];
      final filteredColors = <Color>[];

      for (final src in globalSources) {
        final v = (bySource[src] ?? 0.0);
        if (v <= 0) continue; // ✅ não exibir fontes zeradas
        filteredLabels.add(src);
        filteredValues.add(v);
        filteredColors.add(sourceColorMap[src]!);
      }

      // Se ainda assim não tiver nada, pula a demanda
      if (filteredValues.isEmpty) continue;

      // Se existia seleção, mas agora o index está fora (porque filtrou),
      // melhor limpar para evitar seleção quebrada.
      final int? safeSelectedSliceIndex = (_selectedSliceIndex != null &&
          _selectedSliceIndex! >= 0 &&
          _selectedSliceIndex! < filteredLabels.length)
          ? _selectedSliceIndex
          : null;

      final legendWidget = ChartLegend(
        widthCard: isMobile ? double.infinity : kLegendWidth,
        heightCard: kCardHeight,
        isSmall: false,
        compact: false,
        labels: <String>["DEMANDA: $demandLabel"],
        values: <List<double>>[filteredValues],
        groupLegendLabels: filteredLabels,
        colors: filteredColors,
        valueType: ValueType.money,
        isDark: isDark,
        selectedRowIndex: safeSelectedSliceIndex == null ? null : 0,
        selectedSliceIndex: safeSelectedSliceIndex,
        onLegendTap: (row, slice, rowLabel, sliceLabel) => _toggleSlice(slice),
      );

      final barWidget = HorizontalBarChanged(
        label: "EMPENHOS POR FONTE (DEMANDA)",
        values: filteredValues,
        groupLegendLabels: filteredLabels,
        sliceColors: filteredColors,
        barHeight: 20,
        labelWidth: 0,
        gapLabelToBar: 12,
        sliceLabelLocation: LabelLocation.none,
        showSliceLabelsOnBar: false,
        cardHeight: kCardHeight,
        selectedRowIndex: safeSelectedSliceIndex == null ? null : 0,
        selectedSliceIndex: safeSelectedSliceIndex,
        onSliceTap: (row, slice, rowLabel, sliceLabel) => _toggleSlice(slice),
      );

      Widget line;
      if (isMobile) {
        line = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            legendWidget,
            const SizedBox(height: 8),
            barWidget,
          ],
        );
      } else {
        line = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            legendWidget,
            const SizedBox(width: 12),
            Expanded(child: barWidget),
          ],
        );
      }

      blocks.add(line);
      blocks.add(const SizedBox(height: 12));
    }

    if (blocks.isNotEmpty) {
      blocks.removeLast();
    }

    if (blocks.isEmpty) {
      return const Text("Nenhuma demanda possui valores de empenho > 0 por fonte.");
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks,
    );
  }
}
