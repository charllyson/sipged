import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';

import 'package:sipged/_utils/formatters/sipged_format_money.dart';
import 'package:sipged/_widgets/cards/basic/basic_card.dart';
import 'package:sipged/_widgets/charts/gauges/gauge_chart_metrics.dart';
import 'package:sipged/_widgets/charts/gauges/gauge_chart_shimmer.dart';

enum GaugeTextMode {
  explicit,
  percent,
  number,
  money,
}

enum GaugeLegendValueMode {
  percent,
  value,
  percentAndValue,
}

class GaugeChartSeries {
  final String id;
  final String label;

  /// Percentual da série.
  ///
  /// Deve ser informado entre 0.0 e 1.0.
  final double? percent;

  /// Valor absoluto da série.
  ///
  /// Exemplo: valor medido, valor pago, quantidade etc.
  final double? value;

  final Color? color;
  final Color? trackColor;

  /// Largura opcional da linha desta série.
  final double? lineWidth;

  const GaugeChartSeries({
    required this.id,
    required this.label,
    required this.percent,
    this.value,
    this.color,
    this.trackColor,
    this.lineWidth,
  });
}

class GaugeChartChange extends StatelessWidget {
  final double? centerLabel;
  final String? headerLabel;
  final String? footerLabel;

  final double? widthGraphic;
  final double? heightGraphic;

  /// Lista de séries para desenhar múltiplos círculos.
  ///
  /// Exemplo:
  /// - Série 1: Medições
  /// - Série 2: Pagamentos
  ///
  /// Quando vazia ou null, o widget usa o comportamento antigo com centerLabel.
  final List<GaugeChartSeries>? series;

  /// Define qual série será usada para montar o texto central quando
  /// showSeriesValuesInside for false.
  ///
  /// Se null, usa a primeira série da lista.
  final String? centerSeriesId;

  /// Mostra legenda das séries abaixo do gráfico.
  final bool showLegend;

  /// Mostra um resumo das séries dentro do círculo.
  ///
  /// Quando true e houver mais de uma série, o centro mostra uma pequena lista:
  /// Medições 72,0%
  /// Pagamentos 48,0%
  final bool showSeriesValuesInside;

  /// Multiplicador do tamanho dos textos internos quando usar séries.
  final double seriesCenterTextScale;

  /// Define como a legenda das séries será exibida.
  final GaugeLegendValueMode legendValueMode;

  /// Define se valores monetários da legenda devem ser compactados.
  final bool compactLegendValue;

  /// Controla explicitamente o estado de carregamento.
  ///
  /// Quando true, exibe o shimmer mesmo que existam valores preenchidos.
  final bool isLoading;

  /// Quando true, compacta valores grandes no centro do gauge.
  final bool compactCenterValue;

  /// Multiplicador global da espessura dos círculos.
  final double strokeScale;

  /// Cor do progresso do gauge.
  ///
  /// No modo antigo, controla a cor do círculo único.
  /// No modo com series, é usado apenas como fallback.
  final Color? progressColor;

  /// Cor da trilha interna do gauge.
  ///
  /// Mantido com esse nome para não quebrar chamadas existentes.
  final Color? backgroundColor;

  /// Cor do card.
  ///
  /// Segue o mesmo padrão do BarChartChanged.
  final Color colorCard;

  final double? radius;
  final double? centerFontSize;
  final double? footerFontSize;

  /// Lista de valores usada no comportamento antigo.
  ///
  /// Quando usar `series`, prefira informar o valor em `GaugeChartSeries.value`.
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
    this.series,
    this.centerSeriesId,
    this.showLegend = true,
    this.showSeriesValuesInside = true,
    this.seriesCenterTextScale = 1.18,
    this.legendValueMode = GaugeLegendValueMode.percent,
    this.compactLegendValue = false,
    this.isLoading = false,
    this.compactCenterValue = true,
    this.strokeScale = 1.35,
    this.progressColor,
    this.backgroundColor,
    this.colorCard = Colors.white,
    this.radius,
    this.centerFontSize,
    this.footerFontSize,
    this.values,
    this.centerMode,
    this.headerMode,
    this.footerMode,
  });

  static const double _defaultCardWidth = 260.0;
  static const double _defaultCardHeight = 295.0;

  static const List<Color> _defaultSeriesColors = <Color>[
    Color(0xFF2563EB),
    Color(0xFF16A34A),
    Color(0xFFF97316),
    Color(0xFF9333EA),
    Color(0xFFDC2626),
    Color(0xFF0891B2),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final Color textColor = isDark ? Colors.white : Colors.black87;

    final Color resolvedCardBackgroundColor = isDark
        ? colorCard == Colors.white
        ? const Color(0xFF1E1E1E)
        : colorCard
        : colorCard;

    final Color resolvedTrackColor = backgroundColor ??
        (isDark ? Colors.white.withValues(alpha: 0.16) : Colors.grey.shade300);

    final List<GaugeChartSeries> effectiveSeries = _effectiveSeries(
      fallbackTrackColor: resolvedTrackColor,
    );

    final bool usingSeries = series != null && series!.isNotEmpty;
    final bool hasValues = values != null && values!.isNotEmpty;

    final bool hasAnySeriesData = effectiveSeries.any((item) {
      return item.percent != null || item.value != null;
    });

    final bool shouldShowShimmer = isLoading ||
        (usingSeries
            ? !hasAnySeriesData
            : (centerLabel == null && !hasValues));

    final double resolvedWidth = widthGraphic ?? _defaultCardWidth;
    final double resolvedHeight = heightGraphic ?? _defaultCardHeight;

    final double legacyPercent = (centerLabel ?? 0.0).clamp(0.0, 1.0);

    final double legacyValuesSum = (values ?? const <double>[])
        .fold<double>(0.0, (previous, value) => previous + value);

    final GaugeChartSeries? centerSeries = _resolveCenterSeries(
      effectiveSeries,
    );

    final double activePercent = usingSeries
        ? ((centerSeries?.percent ?? 0.0).clamp(0.0, 1.0))
        : legacyPercent;

    final double activeValue = usingSeries
        ? (centerSeries?.value ?? 0.0)
        : legacyValuesSum;

    final double sumValue = usingSeries
        ? effectiveSeries.fold<double>(
      0.0,
          (previous, item) => previous + (item.value ?? 0.0),
    )
        : legacyValuesSum;

    final GaugeTextMode headerM = headerMode ?? GaugeTextMode.explicit;
    final GaugeTextMode centerM = centerMode ?? GaugeTextMode.percent;

    final GaugeTextMode footerM =
    ((footerMode ?? GaugeTextMode.explicit) == GaugeTextMode.explicit &&
        (footerLabel == null || footerLabel!.trim().isEmpty))
        ? GaugeTextMode.money
        : (footerMode ?? GaugeTextMode.explicit);

    final String headerText = _formatByMode(
      mode: headerM,
      percent: activePercent,
      value: activeValue,
      sum: sumValue,
      explicit: headerLabel ?? '',
      compact: false,
      preferValue: usingSeries,
    );

    final String centerText = _formatByMode(
      mode: centerM,
      percent: activePercent,
      value: activeValue,
      sum: sumValue,
      explicit: '${(activePercent * 100).toStringAsFixed(2)}%',
      compact: compactCenterValue,
      preferValue: usingSeries,
    );

    final String footerText = _formatByMode(
      mode: footerM,
      percent: activePercent,
      value: activeValue,
      sum: sumValue,
      explicit: footerLabel ?? '',
      compact: false,
      preferValue: false,
    );

    final String tooltipText = _buildTooltipText(
      usingSeries: usingSeries,
      series: effectiveSeries,
      footerMode: footerM,
      valuesSum: sumValue,
      hasValues: hasValues || hasAnySeriesData,
      percent: activePercent,
      footerText: footerText,
    );

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

          if (shouldShowShimmer) {
            return BasicCard(
              isDark: isDark,
              width: double.infinity,
              height: double.infinity,
              padding: metrics.cardPadding,
              backgroundColor: resolvedCardBackgroundColor,
              gradient: null,
              enableShadow: true,
              child: SizedBox.expand(
                child: GaugeCircularPercentShimmer(
                  width: maxWidth,
                  height: maxHeight,
                  customRadius: radius,
                  hasHeader: headerText.trim().isNotEmpty,
                  hasFooter: footerText.trim().isNotEmpty || showLegend,
                ),
              ),
            );
          }

          if (usingSeries) {
            return _buildSeriesGauge(
              isDark: isDark,
              textColor: textColor,
              backgroundColor: resolvedCardBackgroundColor,
              metrics: metrics,
              series: effectiveSeries,
              headerText: headerText,
              centerText: centerText,
              footerText: footerText,
              tooltipText: tooltipText,
              centerMode: centerM,
            );
          }

          return _buildSingleGauge(
            isDark: isDark,
            textColor: textColor,
            backgroundColor: resolvedCardBackgroundColor,
            trackColor: resolvedTrackColor,
            metrics: metrics,
            percent: legacyPercent,
            headerText: headerText,
            centerText: centerText,
            footerText: footerText,
            tooltipText: tooltipText,
          );
        },
      ),
    );
  }

  Widget _buildSingleGauge({
    required bool isDark,
    required Color textColor,
    required Color backgroundColor,
    required Color trackColor,
    required GaugeChartMetrics metrics,
    required double percent,
    required String headerText,
    required String centerText,
    required String footerText,
    required String tooltipText,
  }) {
    final double resolvedLineWidth = (metrics.lineWidth * strokeScale).clamp(
      9.0,
      26.0,
    );

    final double safeCenterBoxSize = ((metrics.radius * 2) -
        (resolvedLineWidth * 2) -
        12.0)
        .clamp(24.0, 140.0);

    return BasicCard(
      isDark: isDark,
      width: double.infinity,
      height: double.infinity,
      padding: metrics.cardPadding,
      backgroundColor: backgroundColor,
      gradient: null,
      enableShadow: true,
      child: SizedBox.expand(
        child: Tooltip(
          message: tooltipText,
          child: Center(
            child: CircularPercentIndicator(
              radius: metrics.radius,
              lineWidth: resolvedLineWidth,
              animation: true,
              percent: percent,
              circularStrokeCap: CircularStrokeCap.round,
              progressColor: progressColor ?? _getProgressColor(percent),
              backgroundColor: trackColor,
              header: headerText.trim().isEmpty
                  ? null
                  : Padding(
                padding: EdgeInsets.only(
                  bottom: metrics.headerSpacing,
                ),
                child: Text(
                  headerText,
                  style: TextStyle(
                    fontSize: metrics.headerFontSize,
                    fontWeight: FontWeight.w600,
                    height: 1.0,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              center: SizedBox(
                width: safeCenterBoxSize,
                height: safeCenterBoxSize,
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.center,
                    child: Text(
                      centerText,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.visible,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: metrics.centerFontSize,
                        height: 1.0,
                        color: textColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              footer: footerText.trim().isEmpty
                  ? null
                  : Padding(
                padding: EdgeInsets.only(
                  top: metrics.footerSpacing,
                ),
                child: Text(
                  footerText,
                  style: TextStyle(
                    fontSize: metrics.footerFontSize,
                    height: 1.0,
                    color: textColor.withValues(alpha: 0.86),
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
  }

  Widget _buildSeriesGauge({
    required bool isDark,
    required Color textColor,
    required Color backgroundColor,
    required GaugeChartMetrics metrics,
    required List<GaugeChartSeries> series,
    required String headerText,
    required String centerText,
    required String footerText,
    required String tooltipText,
    required GaugeTextMode centerMode,
  }) {
    final int seriesCount = series.length;

    final double outerRadius = metrics.radius;

    final double defaultLineWidth = (metrics.lineWidth * strokeScale).clamp(
      9.0,
      24.0,
    );

    final double ringGap = seriesCount <= 2 ? 7.0 : 5.0;

    final List<_GaugeRingMetrics> rings = <_GaugeRingMetrics>[];

    for (int index = 0; index < seriesCount; index++) {
      final GaugeChartSeries item = series[index];

      final double lineWidth = (item.lineWidth ?? defaultLineWidth).clamp(
        7.0,
        28.0,
      );

      final double currentRadius = outerRadius - (index * (lineWidth + ringGap));

      if (currentRadius <= 24.0) {
        continue;
      }

      rings.add(
        _GaugeRingMetrics(
          series: item,
          radius: currentRadius,
          lineWidth: lineWidth,
        ),
      );
    }

    final double innerMostRadius =
    rings.isEmpty ? outerRadius : rings.last.radius;

    final double innerMostLineWidth =
    rings.isEmpty ? defaultLineWidth : rings.last.lineWidth;

    final double safeCenterBoxSize = ((innerMostRadius * 2) -
        (innerMostLineWidth * 2) -
        12.0)
        .clamp(36.0, 150.0);

    final bool hasHeader = headerText.trim().isNotEmpty;
    final bool hasFooter = footerText.trim().isNotEmpty;
    final bool hasLegend = showLegend && series.length > 1;

    final bool shouldShowSeriesCenter =
        showSeriesValuesInside && series.length > 1;

    return BasicCard(
      isDark: isDark,
      width: double.infinity,
      height: double.infinity,
      padding: metrics.cardPadding,
      backgroundColor: backgroundColor,
      gradient: null,
      enableShadow: true,
      child: Tooltip(
        message: tooltipText,
        child: SizedBox.expand(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (hasHeader)
                Padding(
                  padding: EdgeInsets.only(
                    bottom: metrics.headerSpacing,
                  ),
                  child: Text(
                    headerText,
                    style: TextStyle(
                      fontSize: metrics.headerFontSize,
                      fontWeight: FontWeight.w600,
                      height: 1.0,
                      color: textColor,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              Flexible(
                fit: FlexFit.loose,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SizedBox(
                    width: outerRadius * 2,
                    height: outerRadius * 2,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        for (final ring in rings)
                          CircularPercentIndicator(
                            radius: ring.radius,
                            lineWidth: ring.lineWidth,
                            animation: true,
                            percent: (ring.series.percent ?? 0.0).clamp(
                              0.0,
                              1.0,
                            ),
                            circularStrokeCap: CircularStrokeCap.round,
                            progressColor: ring.series.color ??
                                progressColor ??
                                _getProgressColor(
                                  (ring.series.percent ?? 0.0).clamp(0.0, 1.0),
                                ),
                            backgroundColor: ring.series.trackColor ??
                                backgroundColor.withValues(alpha: 0.12),
                          ),
                        SizedBox(
                          width: safeCenterBoxSize,
                          height: safeCenterBoxSize,
                          child: Center(
                            child: shouldShowSeriesCenter
                                ? _GaugeCenterSeriesSummary(
                              series: series,
                              textColor: textColor,
                              centerMode: centerMode,
                              compactCenterValue: compactCenterValue,
                              textScale: seriesCenterTextScale,
                              formatMoney: _formatCompactMoney,
                              formatNumber: _formatCompactNumber,
                            )
                                : FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.center,
                              child: Text(
                                centerText,
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.visible,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: metrics.centerFontSize,
                                  height: 1.0,
                                  color: textColor,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (hasFooter)
                Padding(
                  padding: EdgeInsets.only(
                    top: metrics.footerSpacing,
                  ),
                  child: Text(
                    footerText,
                    style: TextStyle(
                      fontSize: metrics.footerFontSize,
                      height: 1.0,
                      color: textColor.withValues(alpha: 0.86),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (hasLegend)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 6,
                    children: [
                      for (int index = 0; index < series.length; index++)
                        _GaugeLegendItem(
                          color: series[index].color ??
                              _defaultSeriesColors[
                              index % _defaultSeriesColors.length],
                          label: series[index].label,
                          percent: series[index].percent,
                          value: series[index].value,
                          textColor: textColor,
                          legendValueMode: legendValueMode,
                          compactLegendValue: compactLegendValue,
                          formatCompactMoney: _formatCompactMoney,
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<GaugeChartSeries> _effectiveSeries({
    required Color fallbackTrackColor,
  }) {
    if (series != null && series!.isNotEmpty) {
      return List<GaugeChartSeries>.generate(series!.length, (index) {
        final GaugeChartSeries item = series![index];

        return GaugeChartSeries(
          id: item.id,
          label: item.label,
          percent: item.percent,
          value: item.value,
          color: item.color ??
              _defaultSeriesColors[index % _defaultSeriesColors.length],
          trackColor: item.trackColor ?? fallbackTrackColor,
          lineWidth: item.lineWidth,
        );
      });
    }

    return <GaugeChartSeries>[
      GaugeChartSeries(
        id: 'default',
        label: headerLabel ?? 'Indicador',
        percent: centerLabel,
        value: (values ?? const <double>[]).fold<double>(
          0.0,
              (previous, value) => previous + value,
        ),
        color: progressColor,
        trackColor: fallbackTrackColor,
      ),
    ];
  }

  GaugeChartSeries? _resolveCenterSeries(List<GaugeChartSeries> items) {
    if (items.isEmpty) {
      return null;
    }

    final String? id = centerSeriesId?.trim();

    if (id == null || id.isEmpty) {
      return items.first;
    }

    for (final item in items) {
      if (item.id == id) {
        return item;
      }
    }

    return items.first;
  }

  String _formatByMode({
    required GaugeTextMode mode,
    required double percent,
    required double value,
    required double sum,
    required String explicit,
    required bool compact,
    required bool preferValue,
  }) {
    final double baseValue = preferValue ? value : sum;

    switch (mode) {
      case GaugeTextMode.explicit:
        return explicit;

      case GaugeTextMode.percent:
        return '${(percent * 100).toStringAsFixed(2)}%';

      case GaugeTextMode.number:
        if (compact) {
          return _formatCompactNumber(baseValue);
        }

        return baseValue.toStringAsFixed(0);

      case GaugeTextMode.money:
        if (compact) {
          return _formatCompactMoney(baseValue);
        }

        return SipGedFormatMoney.doubleToText(baseValue);
    }
  }

  String _buildTooltipText({
    required bool usingSeries,
    required List<GaugeChartSeries> series,
    required GaugeTextMode footerMode,
    required double valuesSum,
    required bool hasValues,
    required double percent,
    required String footerText,
  }) {
    if (usingSeries && series.isNotEmpty) {
      return series.map((item) {
        final String percentText =
            '${((item.percent ?? 0.0).clamp(0.0, 1.0) * 100).toStringAsFixed(2)}%';

        final String valueText = item.value == null
            ? ''
            : ' | ${SipGedFormatMoney.doubleToText(item.value!)}';

        return '${item.label}: $percentText$valueText';
      }).join('\n');
    }

    if (footerText.trim().isNotEmpty) {
      return footerText;
    }

    if (hasValues) {
      if (footerMode == GaugeTextMode.money) {
        return SipGedFormatMoney.doubleToText(valuesSum);
      }

      if (footerMode == GaugeTextMode.number) {
        return valuesSum.toStringAsFixed(0);
      }
    }

    return '${(percent * 100).toStringAsFixed(2)}%';
  }

  String _formatCompactMoney(double value) {
    final double absValue = value.abs();
    final String signal = value < 0 ? '-' : '';

    if (absValue >= 1000000000) {
      return '${signal}R\$ ${_compactDecimal(absValue / 1000000000)} bi';
    }

    if (absValue >= 1000000) {
      return '${signal}R\$ ${_compactDecimal(absValue / 1000000)} mi';
    }

    if (absValue >= 1000) {
      return '${signal}R\$ ${_compactDecimal(absValue / 1000)} mil';
    }

    return SipGedFormatMoney.doubleToText(value);
  }

  String _formatCompactNumber(double value) {
    final double absValue = value.abs();
    final String signal = value < 0 ? '-' : '';

    if (absValue >= 1000000000) {
      return '$signal${_compactDecimal(absValue / 1000000000)} bi';
    }

    if (absValue >= 1000000) {
      return '$signal${_compactDecimal(absValue / 1000000)} mi';
    }

    if (absValue >= 1000) {
      return '$signal${_compactDecimal(absValue / 1000)} mil';
    }

    return value.toStringAsFixed(0);
  }

  String _compactDecimal(double value) {
    if (value >= 100) {
      return value.toStringAsFixed(0).replaceAll('.', ',');
    }

    if (value >= 10) {
      return value.toStringAsFixed(1).replaceAll('.', ',');
    }

    return value.toStringAsFixed(2).replaceAll('.', ',');
  }

  Color _getProgressColor(double percent) {
    if (percent <= 0.2) {
      return Colors.green;
    }

    if (percent <= 0.4) {
      return Colors.blue.shade600;
    }

    if (percent <= 0.6) {
      return Colors.yellow.shade800;
    }

    if (percent <= 0.8) {
      return Colors.orange.shade800;
    }

    return Colors.red;
  }
}

class _GaugeRingMetrics {
  final GaugeChartSeries series;
  final double radius;
  final double lineWidth;

  const _GaugeRingMetrics({
    required this.series,
    required this.radius,
    required this.lineWidth,
  });
}

class _GaugeCenterSeriesSummary extends StatelessWidget {
  const _GaugeCenterSeriesSummary({
    required this.series,
    required this.textColor,
    required this.centerMode,
    required this.compactCenterValue,
    required this.textScale,
    required this.formatMoney,
    required this.formatNumber,
  });

  final List<GaugeChartSeries> series;
  final Color textColor;
  final GaugeTextMode centerMode;
  final bool compactCenterValue;
  final double textScale;
  final String Function(double value) formatMoney;
  final String Function(double value) formatNumber;

  @override
  Widget build(BuildContext context) {
    final List<GaugeChartSeries> visibleSeries = series.take(2).toList();
    final double safeScale = textScale.clamp(0.85, 1.45).toDouble();

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int index = 0; index < visibleSeries.length; index++) ...[
            _GaugeCenterSeriesItem(
              series: visibleSeries[index],
              textColor: textColor,
              centerMode: centerMode,
              compactCenterValue: compactCenterValue,
              textScale: safeScale,
              formatMoney: formatMoney,
              formatNumber: formatNumber,
            ),
            if (index != visibleSeries.length - 1)
              Padding(
                padding: EdgeInsets.symmetric(
                  vertical: 4 * safeScale,
                ),
                child: Container(
                  width: 42 * safeScale,
                  height: 1,
                  color: textColor.withValues(alpha: 0.10),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _GaugeCenterSeriesItem extends StatelessWidget {
  const _GaugeCenterSeriesItem({
    required this.series,
    required this.textColor,
    required this.centerMode,
    required this.compactCenterValue,
    required this.textScale,
    required this.formatMoney,
    required this.formatNumber,
  });

  final GaugeChartSeries series;
  final Color textColor;
  final GaugeTextMode centerMode;
  final bool compactCenterValue;
  final double textScale;
  final String Function(double value) formatMoney;
  final String Function(double value) formatNumber;

  @override
  Widget build(BuildContext context) {
    final Color dotColor = series.color ?? Colors.blueGrey;
    final double safeScale = textScale.clamp(0.85, 1.45).toDouble();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7.5 * safeScale,
              height: 7.5 * safeScale,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 4 * safeScale),
            Text(
              series.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9.8 * safeScale,
                height: 1.0,
                color: textColor.withValues(alpha: 0.72),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        SizedBox(height: 3.5 * safeScale),
        Text(
          _resolveValueText(),
          maxLines: 1,
          overflow: TextOverflow.visible,
          style: TextStyle(
            fontSize: 15.8 * safeScale,
            height: 1.0,
            color: textColor,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  String _resolveValueText() {
    final double percent = (series.percent ?? 0.0).clamp(0.0, 1.0);
    final double value = series.value ?? 0.0;

    switch (centerMode) {
      case GaugeTextMode.explicit:
      case GaugeTextMode.percent:
        return '${(percent * 100).toStringAsFixed(1)}%';

      case GaugeTextMode.money:
        if (compactCenterValue) {
          return formatMoney(value);
        }

        return SipGedFormatMoney.doubleToText(value);

      case GaugeTextMode.number:
        if (compactCenterValue) {
          return formatNumber(value);
        }

        return value.toStringAsFixed(0);
    }
  }
}

class _GaugeLegendItem extends StatelessWidget {
  const _GaugeLegendItem({
    required this.color,
    required this.label,
    required this.percent,
    required this.value,
    required this.textColor,
    required this.legendValueMode,
    required this.compactLegendValue,
    required this.formatCompactMoney,
  });

  final Color color;
  final String label;
  final double? percent;
  final double? value;
  final Color textColor;
  final GaugeLegendValueMode legendValueMode;
  final bool compactLegendValue;
  final String Function(double value) formatCompactMoney;

  @override
  Widget build(BuildContext context) {
    final double safePercent = (percent ?? 0.0).clamp(0.0, 1.0);
    final double safeValue = value ?? 0.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          _legendText(
            label: label,
            percent: safePercent,
            value: safeValue,
          ),
          style: TextStyle(
            fontSize: 11.0,
            height: 1.0,
            color: textColor.withValues(alpha: 0.82),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _legendText({
    required String label,
    required double percent,
    required double value,
  }) {
    final percentText = '${(percent * 100).toStringAsFixed(1)}%';

    final valueText = compactLegendValue
        ? formatCompactMoney(value)
        : SipGedFormatMoney.doubleToText(value);

    switch (legendValueMode) {
      case GaugeLegendValueMode.percent:
        return '$label: $percentText';

      case GaugeLegendValueMode.value:
        return '$label: $valueText';

      case GaugeLegendValueMode.percentAndValue:
        return '$label: $percentText · $valueText';
    }
  }
}