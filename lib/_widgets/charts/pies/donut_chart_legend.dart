// lib/_widgets/charts/donut/donut_chart_legend.dart
import 'package:flutter/material.dart';
import 'package:sipged/_utils/formats/sipged_format_money.dart';
import 'donut_chart_changed.dart'; // ValueFormatType

class DonutChartLegend extends StatelessWidget {
  final List<String> labels;
  final List<double> values;
  final double total;
  final List<Color> cores;
  final int? touchedIndex;
  final ValueChanged<int?>? onLegendTap;
  final ValueFormatType valueFormatType;

  const DonutChartLegend({
    super.key,
    required this.labels,
    required this.values,
    required this.total,
    required this.cores,
    required this.touchedIndex,
    this.onLegendTap,
    this.valueFormatType = ValueFormatType.monetary,
  });

  String _formatValue(double value) {
    switch (valueFormatType) {
      case ValueFormatType.monetary:
        return SipGedFormatMoney.doubleToText(value);
      case ValueFormatType.decimal:
        return value.toStringAsFixed(2);
      case ValueFormatType.integer:
        return value.toInt().toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ estilo "chips" (bom para bottom/horizontal)
    return Row(
      children: List.generate(labels.length, (i) {
        final value = values[i];
        final pct = total == 0 ? 0.0 : value / total * 100;

        final bool selected = touchedIndex == i;

        return InkWell(
          onTap: () => onLegendTap?.call(selected ? null : i),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            margin: const EdgeInsets.only(right: 10, bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: selected ? cores[i].withValues(alpha: 0.12) : null,
              border: Border.all(color: cores[i].withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: cores[i],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      labels[i],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${_formatValue(value)} • ${pct.toStringAsFixed(1)}%',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

/// ✅ Versão em LISTA (boa para lateral/right)
class DonutChartLegendList extends StatelessWidget {
  final List<String> labels;
  final List<double> values;
  final double total;
  final List<Color> cores;
  final int? touchedIndex;
  final ValueChanged<int?>? onLegendTap;
  final ValueFormatType valueFormatType;

  const DonutChartLegendList({
    super.key,
    required this.labels,
    required this.values,
    required this.total,
    required this.cores,
    required this.touchedIndex,
    this.onLegendTap,
    this.valueFormatType = ValueFormatType.monetary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: List.generate(labels.length, (i) {
        final value = values[i];
        final pct = total == 0 ? 0.0 : value / total * 100;
        final selected = touchedIndex == i;

        return InkWell(
          onTap: () => onLegendTap?.call(selected ? null : i),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: selected
                  ? cores[i].withValues(alpha: 0.10)
                  : (theme.brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.03)),
              border: Border.all(
                color: selected
                    ? cores[i].withValues(alpha: 0.55)
                    : cores[i].withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: cores[i],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    labels[i],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${pct.toStringAsFixed(0)}%',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
