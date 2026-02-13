import 'package:flutter/material.dart';
import 'package:sipged/_utils/formats/sipged_format_money.dart';
import 'pie_chart_changed.dart'; // para usar o enum ValueFormatType

class PieChartLegend extends StatelessWidget {
  final List<String> labels;
  final List<double> values;
  final double total;
  final List<Color> cores;
  final int? touchedIndex;
  final ValueChanged<int?>? onLegendTap;
  final ValueFormatType valueFormatType;

  const PieChartLegend({
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
    return Row(
      children: List.generate(labels.length, (i) {
        final value = values[i];
        final pct = total == 0 ? 0.0 : value / total * 100;

        return InkWell(
          onTap: () => onLegendTap?.call(touchedIndex == i ? null : i),
          child: Container(
            margin: const EdgeInsets.only(right: 10, bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: (touchedIndex == i) ? cores[i].withValues(alpha: 0.12) : null,
              border: Border.all(color: cores[i].withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 10, height: 10, color: cores[i]),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(labels[i], style: const TextStyle(fontSize: 12)),
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
