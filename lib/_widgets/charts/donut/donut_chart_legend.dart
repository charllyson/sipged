import 'package:flutter/material.dart';
import 'package:sipged/_utils/formats/sipged_format_money.dart';
import 'donut_chart_changed.dart';

class DonutChartLegend extends StatelessWidget {
  final List<String> labels;
  final List<double> values;
  final double total;
  final List<Color> cores;
  final int? touchedIndex;
  final ValueChanged<int?>? onLegendTap;
  final ValueFormatType valueFormatType;

  final double chipHeight;
  final double chipMinWidth;
  final double labelFontSize;
  final double valueFontSize;
  final double spacing;

  const DonutChartLegend({
    super.key,
    required this.labels,
    required this.values,
    required this.total,
    required this.cores,
    required this.touchedIndex,
    this.onLegendTap,
    this.valueFormatType = ValueFormatType.monetary,
    this.chipHeight = 44,
    this.chipMinWidth = 130,
    this.labelFontSize = 12,
    this.valueFontSize = 12,
    this.spacing = 10,
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

    return Row(
      children: List.generate(labels.length, (i) {
        final value = values[i];
        final pct = total == 0 ? 0.0 : value / total * 100;
        final selected = touchedIndex == i;

        return InkWell(
          onTap: () => onLegendTap?.call(selected ? null : i),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: BoxConstraints(minWidth: chipMinWidth),
            height: chipHeight,
            margin: EdgeInsets.only(right: i == labels.length - 1 ? 0 : spacing),
            padding: EdgeInsets.symmetric(
              horizontal: chipHeight * 0.22,
              vertical: chipHeight * 0.14,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: selected ? cores[i].withValues(alpha: 0.12) : null,
              border: Border.all(
                color: cores[i].withValues(alpha: selected ? 0.55 : 0.35),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: (chipHeight * 0.22).clamp(8.0, 11.0),
                  height: (chipHeight * 0.22).clamp(8.0, 11.0),
                  decoration: BoxDecoration(
                    color: cores[i],
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: (chipHeight * 0.16).clamp(6.0, 9.0)),
                Flexible(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        labels[i],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontSize: labelFontSize,
                          fontWeight: FontWeight.w800,
                          height: 1.0,
                        ),
                      ),
                      SizedBox(height: (chipHeight * 0.06).clamp(1.0, 3.0)),
                      Text(
                        '${_formatValue(value)} • ${pct.toStringAsFixed(1)}%',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: valueFontSize,
                          height: 1.0,
                        ),
                      ),
                    ],
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