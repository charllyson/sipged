import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'pie_chart_shimmer_widget.dart';
import 'pie_chart_legend.dart';

import 'package:sipged/_widgets/cards/basic/basic_card.dart';

enum ValueFormatType { monetary, decimal, integer }

class PieChartChanged extends StatefulWidget {
  final void Function(int?)? onTouch;
  final int? selectedIndex;
  final double? larguraGrafico;
  final double? larguraCard;
  final double? alturaCard;
  final bool showPercentageOutside;
  final double minPercentForLabel;
  final bool useExternalLegend;
  final List<Color>? coresPersonalizadas;
  final void Function(String? label)? onTapLabel;
  final String? selectedLabel;

  /// Labels das fatias
  final List<String> labels;

  /// Valores TOTAIS de cada fatia (usados para o desenho/percentual)
  final List<double> values;

  /// Valores FILTRADOS de cada fatia (para opacidade)
  final List<double>? filteredValues;

  final ValueFormatType valueFormatType;
  final Color? colorCard;

  /// Altura do gráfico (área do Pie). Default: 200.
  final double? chartHeight;

  /// Raio base das fatias (não destacadas). Default: 42.
  final double? sliceRadius;

  /// Raio quando a fatia está destacada. Default: [sliceRadius] + 6 ou 48.
  final double? sliceRadiusHighlighted;

  /// Raio do furo central do donut. Default: 40.
  final double? centerSpaceRadius;

  /// Espaço entre fatias. Default: 2.
  final double? sectionsSpace;

  /// Offset quando o título é desenhado fora (>= 1). Default: 1.6.
  final double? titleOutsideOffset;

  const PieChartChanged({
    super.key,
    this.onTouch,
    this.selectedIndex,
    this.onTapLabel,
    this.selectedLabel,
    this.larguraGrafico,
    this.larguraCard,
    this.alturaCard,
    this.showPercentageOutside = false,
    this.minPercentForLabel = 6.0,
    this.useExternalLegend = true,
    this.coresPersonalizadas,
    this.valueFormatType = ValueFormatType.monetary,
    required this.labels,
    required this.values,
    this.filteredValues,
    this.colorCard = Colors.white,
    this.chartHeight,
    this.sliceRadius,
    this.sliceRadiusHighlighted,
    this.centerSpaceRadius,
    this.sectionsSpace,
    this.titleOutsideOffset,
  });

  @override
  State<PieChartChanged> createState() => _PieChartChangedState();
}

class _PieChartChangedState extends State<PieChartChanged> {
  late List<Color> cores;
  int? touchedIndex;

  // Defaults centralizados
  double get _sliceRadiusBaseRaw => widget.sliceRadius ?? 42.0;
  double get _sliceRadiusHiRaw =>
      widget.sliceRadiusHighlighted ??
          (widget.sliceRadius != null ? widget.sliceRadius! + 6.0 : 48.0);
  double get _centerSpaceRadiusRaw => widget.centerSpaceRadius ?? 40.0;
  double get _sectionsSpace => widget.sectionsSpace ?? 2.0;
  double get _titleOutsideOffset => widget.titleOutsideOffset ?? 1.6;
  double get _chartHeight => widget.chartHeight ?? 200.0;

  @override
  void initState() {
    super.initState();
    _ensureColors(widget.values.length);
  }

  @override
  void didUpdateWidget(covariant PieChartChanged oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.values.length != oldWidget.values.length ||
        (widget.coresPersonalizadas?.length ?? 0) !=
            (oldWidget.coresPersonalizadas?.length ?? 0)) {
      _ensureColors(widget.values.length);
      if (touchedIndex != null && touchedIndex! >= widget.values.length) {
        touchedIndex = null;
      }
    }
  }

  void _ensureColors(int length) {
    if (length <= 0) {
      cores = const [];
      return;
    }
    if (widget.coresPersonalizadas != null &&
        widget.coresPersonalizadas!.length >= length) {
      cores = widget.coresPersonalizadas!;
      return;
    }
    final rnd = Random();
    cores = List.generate(
      length,
          (_) => Color.fromARGB(
        255,
        rnd.nextInt(200) + 30,
        rnd.nextInt(200) + 30,
        rnd.nextInt(200) + 30,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Gradiente padrão igual aos outros cards
    final Gradient gradient = isDark
        ? const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF101018),
        Color(0xFF171924),
      ],
    )
        : const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white,
        Color(0xFFF5F7FB),
      ],
    );

    final bool hasBasicsInvalid = widget.labels.isEmpty ||
        widget.values.isEmpty ||
        widget.labels.length != widget.values.length;

    final total = widget.values.fold<double>(0, (sum, e) => sum + e);
    final bool totalZero = total == 0;

    final bool showShimmer = hasBasicsInvalid || totalZero;

    // ==========
    // SHIMMER
    // ==========
    if (showShimmer) {
      final chartWidth = widget.larguraGrafico ?? 260;

      final Widget legendShimmer = widget.useExternalLegend
          ? SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const SizedBox(width: 8),
            PieChartLegendShimmerWidget(
              isDark: isDark,
              itemCount: 5,
              height: 44,
              // largura aproximada dos “chips” da legenda
              itemMinWidth: 130,
              spacing: 10,
            ),
          ],
        ),
      )
          : const SizedBox.shrink();

      return SizedBox(
        width: widget.larguraCard,
        height: widget.alturaCard,
        child: BasicCard(
          isDark: isDark,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          gradient: gradient,
          enableShadow: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: PieChartShimmerWidget(
                  isDark: isDark,
                  largura: chartWidth,
                  altura: _chartHeight, // IMPORTANT: igual ao chart real
                ),
              ),
              const SizedBox(height: 12), // IMPORTANT: igual ao layout real
              if (widget.useExternalLegend) legendShimmer,
            ],
          ),
        ),
      );
    }

    // ======================
    // GRÁFICO COM DADOS
    // ======================
    if (cores.length != widget.values.length) {
      _ensureColors(widget.values.length);
    }

    final safeSelectedIndex = (widget.selectedIndex != null &&
        widget.selectedIndex! >= 0 &&
        widget.selectedIndex! < widget.values.length)
        ? widget.selectedIndex
        : null;

    // Flags para série filtrada
    final bool hasFilteredSeries =
        widget.filteredValues != null && widget.filteredValues!.isNotEmpty;
    final bool hasAnyFilteredValue =
        hasFilteredSeries && widget.filteredValues!.any((v) => v > 0);

    // ----- Segurança contra overflow: ajuste de raios por altura disponível -----
    final double maxOuter = (_chartHeight / 2) - 12.0; // 12px de folga

    double baseSlice = _sliceRadiusBaseRaw.clamp(0.0, maxOuter);
    double hiSlice = _sliceRadiusHiRaw.clamp(baseSlice, maxOuter);

    if (widget.showPercentageOutside) {
      baseSlice = (baseSlice * 0.92).clamp(0.0, maxOuter);
      hiSlice = (hiSlice * 0.92).clamp(baseSlice, maxOuter);
    }

    final double centerSpaceRadius = _centerSpaceRadiusRaw.clamp(
      0.0,
      (baseSlice - 10.0).clamp(0.0, baseSlice),
    );

    final chart = SizedBox(
      height: _chartHeight,
      width: widget.larguraGrafico ?? double.infinity,
      child: PieChart(
        PieChartData(
          startDegreeOffset: -90,
          centerSpaceRadius: centerSpaceRadius,
          sectionsSpace: _sectionsSpace,
          pieTouchData: PieTouchData(
            touchCallback: (event, response) {
              if (event is! FlTapUpEvent) return;
              final touched = response?.touchedSection;
              if (touched == null) {
                setState(() => touchedIndex = null);
                widget.onTouch?.call(null);
                widget.onTapLabel?.call(null);
                return;
              }
              final index = touched.touchedSectionIndex;
              if (index < 0 || index >= widget.labels.length) return;
              final label = widget.labels[index];
              setState(() {
                if (touchedIndex == index) {
                  touchedIndex = null;
                  widget.onTouch?.call(null);
                  widget.onTapLabel?.call(null);
                } else {
                  touchedIndex = index;
                  widget.onTouch?.call(index);
                  widget.onTapLabel?.call(label);
                }
              });
            },
          ),
          sections: List.generate(widget.values.length, (i) {
            final value = widget.values[i];
            final label = widget.labels[i];

            final isSelectedProp =
                (safeSelectedIndex != null && i == safeSelectedIndex) ||
                    (widget.selectedLabel != null &&
                        label.toUpperCase() ==
                            widget.selectedLabel!.toUpperCase());

            final isTouchedLocal = (touchedIndex == i);
            final isHighlighted = isSelectedProp || isTouchedLocal;

            double filteredValue;
            if (widget.filteredValues != null &&
                i < widget.filteredValues!.length) {
              filteredValue = widget.filteredValues![i];
            } else {
              filteredValue = value;
            }

            final bool hasSomeFilter = hasFilteredSeries && hasAnyFilteredValue;
            final bool isInFilter = filteredValue > 0.0;

            final percentual = (value / total) * 100;
            final showInside = percentual >= widget.minPercentForLabel;

            final titleText = showInside
                ? (widget.showPercentageOutside
                ? '${percentual.toStringAsFixed(1)}%'
                : '${percentual.toStringAsFixed(0)}%')
                : '';

            final Color baseColor = cores[i];

            Color color;
            if (value == 0) {
              color = baseColor.withValues(alpha: 0.15);
            } else if (isHighlighted) {
              color = baseColor;
            } else if (hasSomeFilter && !isInFilter) {
              color = baseColor.withValues(alpha: 0.30);
            } else if (hasSomeFilter && isInFilter) {
              color = baseColor.withValues(alpha: 0.85);
            } else {
              color = baseColor;
            }

            return PieChartSectionData(
              color: color,
              value: value,
              title: titleText,
              radius: isHighlighted ? hiSlice : baseSlice,
              titlePositionPercentageOffset:
              widget.showPercentageOutside ? _titleOutsideOffset : 0.65,
              titleStyle: TextStyle(
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w600,
                fontSize: isHighlighted ? 12 : 10,
                height: 1.0,
              ),
            );
          }),
        ),
      ),
    );

    final Widget legendWidget = widget.useExternalLegend
        ? SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          const SizedBox(width: 8),
          PieChartLegend(
            labels: widget.labels,
            values: widget.values,
            total: total,
            cores: cores,
            touchedIndex: touchedIndex,
            valueFormatType: widget.valueFormatType,
            onLegendTap: (index) {
              setState(() => touchedIndex = index);
              if (index == null) {
                widget.onTouch?.call(null);
                widget.onTapLabel?.call(null);
              } else {
                widget.onTouch?.call(index);
                widget.onTapLabel?.call(widget.labels[index]);
              }
            },
          ),
        ],
      ),
    )
        : const SizedBox.shrink();

    return SizedBox(
      width: widget.larguraCard,
      height: widget.alturaCard,
      child: BasicCard(
        isDark: isDark,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        gradient: gradient,
        enableShadow: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            chart,
            const SizedBox(height: 12),
            if (widget.useExternalLegend) legendWidget,
          ],
        ),
      ),
    );
  }
}
