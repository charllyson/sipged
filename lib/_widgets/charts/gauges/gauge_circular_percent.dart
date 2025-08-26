import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:sisged/_utils/formats/format_field.dart';

enum GaugeTextMode { explicit, percent, number, money }

class GaugeCircularPercent extends StatelessWidget {
  final double? centerTitle;         // de 0 a 1
  final String? headerTitle;           // usado quando headerMode == explicit
  final String? footerTitle;        // usado quando footerMode == explicit

  final double? larguraGrafico;
  final Color? progressColor;
  final Color? backgroundColor;
  final double? radius;
  final double? centerFontSize;
  final double? footerFontSize;

  /// Lista com os valores (ex.: contagem/soma) para number/money
  final List<double>? values;

  /// Compat: se true e footerMode não for definido, footer vira money
  final bool? financial;

  /// Formatação independente
  final GaugeTextMode? centerMode; // default: percent
  final GaugeTextMode? headerMode; // default: explicit
  final GaugeTextMode? footerMode; // default: explicit

  const GaugeCircularPercent({
    super.key,
    this.centerTitle,
    this.headerTitle,
    this.footerTitle,
    this.larguraGrafico,
    this.progressColor,
    this.backgroundColor,
    this.radius,
    this.centerFontSize,
    this.footerFontSize,
    this.values,
    this.financial,
    this.centerMode,
    this.headerMode,
    this.footerMode,
  });

  @override
  Widget build(BuildContext context) {
    final clampedPercent = (centerTitle ?? 0).clamp(0.0, 1.0);
    final double valuesSum = (values ?? const <double>[]).fold<double>(0.0, (a, b) => a + b);

    final GaugeTextMode headerM = headerMode ?? GaugeTextMode.explicit;
    final GaugeTextMode centerM = centerMode ?? GaugeTextMode.percent;
    final GaugeTextMode footerM = (financial == true &&
        (footerMode ?? GaugeTextMode.explicit) == GaugeTextMode.explicit &&
        (this.footerTitle == null || this.footerTitle!.isEmpty))
        ? GaugeTextMode.money
        : (footerMode ?? GaugeTextMode.explicit);

    final String headerTitle = _formatByMode(
      mode: headerM,
      percent: clampedPercent,
      sum: valuesSum,
      explicit: this.headerTitle ?? '',
    );

    final String centerText = _formatByMode(
      mode: centerM,
      percent: clampedPercent,
      sum: valuesSum,
      explicit: '${(clampedPercent * 100).toStringAsFixed(2)}%',
    );

    final String footerTitle = _formatByMode(
      mode: footerM,
      percent: clampedPercent,
      sum: valuesSum,
      explicit: this.footerTitle ?? '',
    );

    final String tooltipText =
    (financial == true || footerM == GaugeTextMode.money)
        ? '${priceToString(valuesSum)}'
        : '$valuesSum';

    return Card(
      color: Colors.white,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: RepaintBoundary(
          child: SizedBox(
            height: 255,
            width: larguraGrafico ?? double.infinity,
            child: Tooltip(
              message: tooltipText,
              child: CircularPercentIndicator(
                radius: radius ?? 60.0,
                lineWidth: 20.0,
                animation: true,
                percent: clampedPercent,
                center: Text(
                  centerText,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: centerFontSize ?? 20.0,
                  ),
                  textAlign: TextAlign.center,
                ),
                header: Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    headerTitle,
                    style: const TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
                footer: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    footerTitle,
                    style: TextStyle(fontSize: footerFontSize ?? 14.0),
                    textAlign: TextAlign.center,
                  ),
                ),
                circularStrokeCap: CircularStrokeCap.round,
                progressColor:
                progressColor ?? _getProgressColor(clampedPercent),
                backgroundColor: backgroundColor ?? Colors.grey.shade300,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatByMode({
    required GaugeTextMode mode,
    required double percent,
    required double sum,
    required String explicit,
  }) {
    switch (mode) {
      case GaugeTextMode.explicit:
        return explicit;
      case GaugeTextMode.percent:
        return '${(percent * 100).toStringAsFixed(2)}%';
      case GaugeTextMode.number:
        return sum.toStringAsFixed(0);
      case GaugeTextMode.money:
        return priceToString(sum);
    }
  }

  Color _getProgressColor(double percent) {
    if (percent <= 0.2) {
      return Colors.green;
    } else if (percent <= 0.4 && percent > 0.2) {
      return Colors.blue.shade600;
    } else if (percent <= 0.6 && percent > 0.4) {
      return Colors.yellow.shade800;
    } else if (percent <= 0.8 && percent > 0.6) {
      return Colors.orange.shade800;
    } else {
      return Colors.red;
    }
  }
}
