import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:siged/_blocs/modules/financial/budget/budget_data.dart';
import 'package:siged/_widgets/charts/legend/chart_legend.dart';
import 'package:siged/_widgets/charts/linear_bar/horizontal_bar_chart_changed.dart';
import 'package:siged/_widgets/charts/linear_bar/types.dart';

class BudgetSlicesRow extends StatefulWidget {
  final NumberFormat currency;
  final List<BudgetData> budgets;

  const BudgetSlicesRow({
    super.key,
    required this.currency,
    required this.budgets,
  });

  @override
  State<BudgetSlicesRow> createState() => _BudgetSlicesRowState();
}

class _BudgetSlicesRowState extends State<BudgetSlicesRow> {
  int? _selectedSliceIndex;

  void _toggleSlice(int slice) {
    setState(() {
      _selectedSliceIndex = (_selectedSliceIndex == slice) ? null : slice;
    });
  }

  List<Color> _buildPalette(int n) {
    if (n <= 0) return const <Color>[];
    return List<Color>.generate(n, (i) {
      final hue = (360.0 * (i / max(1, n))) % 360.0;
      return HSLColor.fromAHSL(1.0, hue, 0.62, 0.52).toColor();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // ✅ Orçamento por Fonte (BudgetData.fundingSourceLabel)
    final Map<String, double> byFonte = {};
    for (final b in widget.budgets) {
      final k = (b.fundingSourceLabel ?? '').trim();
      if (k.isEmpty) continue;
      byFonte[k] = (byFonte[k] ?? 0) + b.amount;
    }

    final entries = byFonte.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final sliceLabels = entries.map((e) => e.key).toList();
    final values = entries.map((e) => e.value).toList();

    if (sliceLabels.isEmpty) {
      return const Text("Nenhum orçamento com Fonte de recurso definido.");
    }

    final sliceColors = _buildPalette(sliceLabels.length);

    const double kCardHeight = 200.0;
    const double kLegendWidth = 420.0;

    final isMobile = MediaQuery.of(context).size.width < 600;

    final legendWidget = ChartLegend(
      widthCard: isMobile ? double.infinity : kLegendWidth,
      heightCard: kCardHeight,
      isSmall: false,
      labels: const <String>["DISTRIBUIÇÃO DO ORÇAMENTO POR FONTES"],
      values: <List<double>>[values],
      groupLegendLabels: sliceLabels,
      colors: sliceColors,
      valueType: ValueType.money,
      isDark: isDark,
      selectedRowIndex: _selectedSliceIndex == null ? null : 0,
      selectedSliceIndex: _selectedSliceIndex,
      onLegendTap: (row, slice, rowLabel, sliceLabel) => _toggleSlice(slice),
    );

    final barWidget = HorizontalBarChanged(
      label: "ORÇAMENTO POR FONTE DE RECURSO",
      values: values,
      groupLegendLabels: sliceLabels,
      barHeight: 150,
      labelWidth: 0,
      gapLabelToBar: 12,
      sliceLabelLocation: LabelLocation.none,
      showSliceLabelsOnBar: false,
      cardHeight: kCardHeight,
      selectedRowIndex: _selectedSliceIndex == null ? null : 0,
      selectedSliceIndex: _selectedSliceIndex,
      sliceColors: sliceColors,
      onSliceTap: (row, slice, rowLabel, sliceLabel) => _toggleSlice(slice),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          legendWidget,
          const SizedBox(height: 8),
          barWidget,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        legendWidget,
        const SizedBox(width: 12),
        Expanded(child: barWidget),
      ],
    );
  }
}
