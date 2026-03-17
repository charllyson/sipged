import 'package:flutter/material.dart';
import 'package:sipged/_utils/formats/sipged_format_money.dart';
import 'package:sipged/_widgets/charts/donut/donut_chart_changed.dart';

class DonutChartLegendList extends StatelessWidget {
  final List<String> labels;
  final List<double> values;
  final double total;
  final List<Color> cores;
  final int? touchedIndex;
  final ValueChanged<int?>? onLegendTap;
  final ValueFormatType valueFormatType;

  final double itemHeight;
  final double labelFontSize;
  final double percentFontSize;
  final double spacing;

  const DonutChartLegendList({
    super.key,
    required this.labels,
    required this.values,
    required this.total,
    required this.cores,
    required this.touchedIndex,
    this.onLegendTap,
    this.valueFormatType = ValueFormatType.monetary,
    this.itemHeight = 44,
    this.labelFontSize = 12,
    this.percentFontSize = 12,
    this.spacing = 8,
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
            height: itemHeight,
            margin: EdgeInsets.only(bottom: i == labels.length - 1 ? 0 : spacing),
            padding: EdgeInsets.symmetric(
              horizontal: itemHeight * 0.26,
              vertical: itemHeight * 0.18,
            ),
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
                  width: (itemHeight * 0.22).clamp(8.0, 11.0),
                  height: (itemHeight * 0.22).clamp(8.0, 11.0),
                  decoration: BoxDecoration(
                    color: cores[i],
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: (itemHeight * 0.20).clamp(8.0, 10.0)),
                Expanded(
                  child: Text(
                    labels[i],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: labelFontSize,
                      height: 1.0,
                    ),
                  ),
                ),
                SizedBox(width: (itemHeight * 0.20).clamp(8.0, 10.0)),
                Flexible(
                  child: Text(
                    '${_formatValue(value)} • ${pct.toStringAsFixed(0)}%',
                    maxLines: 1,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: percentFontSize,
                      height: 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}