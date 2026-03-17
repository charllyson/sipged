import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';

import 'package:sipged/_utils/formats/sipged_format_money.dart';
import 'package:sipged/_widgets/cards/basic/basic_card.dart';
import 'package:sipged/_widgets/charts/gauges/gauge_chart_metrics.dart';
import 'package:sipged/_widgets/charts/gauges/gauge_chart_shimmer.dart';

enum GaugeTextMode { explicit, percent, number, money }

class GaugeChartChange extends StatelessWidget {
  final double? centerLabel;
  final String? headerLabel;
  final String? footerLabel;

  final double? widthGraphic;
  final double? heightGraphic;

  final Color? progressColor;
  final Color? backgroundColor;

  final double? radius;
  final double? centerFontSize;
  final double? footerFontSize;

  final List<double>? values;

  final GaugeTextMode? centerMode;
  final GaugeTextMode? headerMode;
  final GaugeTextMode? footerMode;

  const GaugeChartChange({
    super.key,
    this.centerLabel,
    this.headerLabel,
    this.footerLabel,
    this.widthGraphic,
    this.heightGraphic,
    this.progressColor,
    this.backgroundColor,
    this.radius,
    this.centerFontSize,
    this.footerFontSize,
    this.values,
    this.centerMode,
    this.headerMode,
    this.footerMode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bool noData =
        (centerLabel == null) && (values == null || values!.isEmpty);

    final double resolvedHeight = heightGraphic ?? 255.0;
    final double resolvedWidth = widthGraphic ?? 260.0;

    final clampedPercent = (centerLabel ?? 0).clamp(0.0, 1.0);
    final double valuesSum =
    (values ?? const <double>[]).fold<double>(0.0, (a, b) => a + b);

    final GaugeTextMode headerM = headerMode ?? GaugeTextMode.explicit;
    final GaugeTextMode centerM = centerMode ?? GaugeTextMode.percent;
    final GaugeTextMode footerM =
    ((footerMode ?? GaugeTextMode.explicit) == GaugeTextMode.explicit &&
        (footerLabel == null || footerLabel!.isEmpty))
        ? GaugeTextMode.money
        : (footerMode ?? GaugeTextMode.explicit);

    final String headerText = _formatByMode(
      mode: headerM,
      percent: clampedPercent,
      sum: valuesSum,
      explicit: headerLabel ?? '',
    );

    final String centerText = _formatByMode(
      mode: centerM,
      percent: clampedPercent,
      sum: valuesSum,
      explicit: '${(clampedPercent * 100).toStringAsFixed(2)}%',
    );

    final String footerText = _formatByMode(
      mode: footerM,
      percent: clampedPercent,
      sum: valuesSum,
      explicit: footerLabel ?? '',
    );

    final String tooltipText = footerM == GaugeTextMode.money
        ? SipGedFormatMoney.doubleToText(valuesSum)
        : valuesSum.toStringAsFixed(0);

    return SizedBox(
      width: resolvedWidth,
      height: resolvedHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double maxWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : resolvedWidth;

          final double maxHeight = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : resolvedHeight;

          final metrics = GaugeChartMetrics.resolve(
            maxWidth: maxWidth,
            maxHeight: maxHeight,
            customRadius: radius,
            customCenterFontSize: centerFontSize,
            customFooterFontSize: footerFontSize,
            centerText: centerText,
            footerText: footerText,
            headerText: headerText,
          );

          if (noData) {
            return BasicCard(
              isDark: isDark,
              width: double.infinity,
              padding: metrics.cardPadding,
              child: SizedBox.expand(
                child: GaugeCircularPercentShimmer(
                  width: maxWidth,
                  height: maxHeight,
                  customRadius: radius,
                ),
              ),
            );
          }

          return BasicCard(
            isDark: isDark,
            width: double.infinity,
            padding: metrics.cardPadding,
            child: SizedBox.expand(
              child: Tooltip(
                message: tooltipText,
                child: Center(
                  child: CircularPercentIndicator(
                    radius: metrics.radius,
                    lineWidth: metrics.lineWidth,
                    animation: true,
                    percent: clampedPercent,
                    circularStrokeCap: CircularStrokeCap.round,
                    progressColor:
                    progressColor ?? _getProgressColor(clampedPercent),
                    backgroundColor:
                    backgroundColor ?? Colors.grey.shade300,
                    header: headerText.trim().isEmpty
                        ? null
                        : Padding(
                      padding:
                      EdgeInsets.only(bottom: metrics.headerSpacing),
                      child: Text(
                        headerText,
                        style: TextStyle(
                          fontSize: metrics.headerFontSize,
                          fontWeight: FontWeight.w600,
                          height: 1.0,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    center: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: metrics.innerTextBoxSize,
                        ),
                        child: Text(
                          centerText,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.visible,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: metrics.centerFontSize,
                            height: 1.0,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    footer: footerText.trim().isEmpty
                        ? null
                        : Padding(
                      padding:
                      EdgeInsets.only(top: metrics.footerSpacing),
                      child: Text(
                        footerText,
                        style: TextStyle(
                          fontSize: metrics.footerFontSize,
                          height: 1.0,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
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
        return SipGedFormatMoney.doubleToText(sum);
    }
  }

  Color _getProgressColor(double percent) {
    if (percent <= 0.2) {
      return Colors.green;
    } else if (percent <= 0.4) {
      return Colors.blue.shade600;
    } else if (percent <= 0.6) {
      return Colors.yellow.shade800;
    } else if (percent <= 0.8) {
      return Colors.orange.shade800;
    } else {
      return Colors.red;
    }
  }
}