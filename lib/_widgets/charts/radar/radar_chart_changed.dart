import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:sipged/_utils/formatters/sipged_format_money.dart';

import 'package:sipged/_widgets/charts/radar/radar_chart_shimmer.dart';
import 'package:sipged/_widgets/charts/radar/radar_series_data.dart';
import 'package:sipged/_widgets/cards/basic/basic_card.dart';

class RadarChartChanged extends StatefulWidget {
  final List<String> labels;
  final List<RadarSeriesData> datasets;

  final int tickCount;
  final bool minAtCenter;

  final double? larguraGrafico;
  final double? larguraCard;
  final double? alturaCard;

  final bool useExternalLegend;
  final List<Color>? coresPersonalizadas;

  final void Function({
  required int axisIndex,
  required int seriesIndex,
  required double value,
  })? onEntryTap;

  const RadarChartChanged({
    super.key,
    required this.labels,
    required this.datasets,
    this.tickCount = 5,
    this.minAtCenter = false,
    this.larguraGrafico,
    this.larguraCard = 420,
    this.alturaCard,
    this.useExternalLegend = true,
    this.coresPersonalizadas,
    this.onEntryTap,
  });

  @override
  State<RadarChartChanged> createState() => _RadarChartChangedState();
}

class _RadarChartChangedState extends State<RadarChartChanged> {
  int? _hoverSeries;
  int? _hoverAxis;
  Offset? _hoverPos;
  double? _hoverValue;

  static const double _defaultCardHeight = 295.0;
  static const Color _cardBackgroundColor = Colors.white;

  void _clearHover() {
    if (!mounted) return;

    setState(() {
      _hoverSeries = null;
      _hoverAxis = null;
      _hoverPos = null;
      _hoverValue = null;
    });
  }

  Color _seriesColor(int index) {
    final custom = widget.coresPersonalizadas;

    if (custom != null && custom.isNotEmpty) {
      return custom[index % custom.length];
    }

    return widget.datasets[index].color;
  }

  Widget _buildLegend({
    required bool isDark,
  }) {
    if (!widget.useExternalLegend) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: List.generate(widget.datasets.length, (index) {
        final series = widget.datasets[index];
        final color = _seriesColor(index);
        final bool isActive = _hoverSeries == null || _hoverSeries == index;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color.withValues(alpha: isActive ? 1.0 : 0.40),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              series.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                height: 1.0,
                color: isActive
                    ? Colors.black87
                    : Colors.black.withValues(alpha: 0.45),
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bool hasMismatch = widget.datasets.any(
          (series) => series.values.length != widget.labels.length,
    );

    final bool showShimmer =
        widget.labels.isEmpty || widget.datasets.isEmpty || hasMismatch;

    final double resolvedCardWidth = widget.larguraCard ?? 420.0;
    final double resolvedCardHeight = widget.alturaCard ?? _defaultCardHeight;

    if (showShimmer) {
      return SizedBox(
        width: resolvedCardWidth,
        height: resolvedCardHeight,
        child: BasicCard(
          isDark: isDark,
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.all(12),
          backgroundColor: _cardBackgroundColor,
          gradient: null,
          enableShadow: true,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double maxW = widget.larguraGrafico ??
                  (constraints.maxWidth.isFinite
                      ? constraints.maxWidth
                      : resolvedCardWidth);

              final double maxH = constraints.maxHeight.isFinite
                  ? constraints.maxHeight
                  : resolvedCardHeight;

              final double side = math.min(maxW, maxH).clamp(120.0, 275.0);

              return Center(
                child: RadarChartShimmer(
                  isDark: false,
                  altura: side,
                  largura: side,
                  legendItems:
                  widget.useExternalLegend ? widget.datasets.length : 0,
                  axes: widget.labels.isNotEmpty
                      ? widget.labels.length.clamp(3, 24)
                      : 10,
                  rings: 6,
                ),
              );
            },
          ),
        ),
      );
    }

    return SizedBox(
      width: resolvedCardWidth,
      height: resolvedCardHeight,
      child: BasicCard(
        isDark: isDark,
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(12),
        backgroundColor: _cardBackgroundColor,
        gradient: null,
        enableShadow: true,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double maxW = widget.larguraGrafico ??
                (constraints.maxWidth.isFinite
                    ? constraints.maxWidth
                    : resolvedCardWidth);

            final double maxH = constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : resolvedCardHeight;

            final double legendItemMinWidth = 120.0;
            final int legendCols = math.max(
              1,
              (maxW / legendItemMinWidth).floor(),
            );

            final int legendRows = widget.useExternalLegend
                ? (widget.datasets.length / legendCols).ceil()
                : 0;

            final double legendRowHeight = 24.0;

            final double legendReservedHeight = widget.useExternalLegend
                ? (legendRows * legendRowHeight) +
                (legendRows > 0 ? 8.0 : 0.0)
                : 0.0;

            final double usableH = (maxH - legendReservedHeight).clamp(
              120.0,
              maxH,
            );

            final double side = math.min(maxW, usableH);

            final int labelCount = widget.labels.length.clamp(3, 24);
            final double baseFont = (side / 30).clamp(9.0, 14.0);
            final double fontSize =
            (baseFont - (labelCount > 10 ? 1.0 : 0.0)).clamp(8.0, 14.0);

            final double titleOffset = side >= 420
                ? 0.20
                : side >= 340
                ? 0.18
                : 0.16;

            final chart = RadarChart(
              RadarChartData(
                radarShape: RadarShape.polygon,
                tickCount: widget.tickCount,
                titlePositionPercentageOffset: titleOffset,
                getTitle: (index, angle) {
                  return RadarChartTitle(
                    text: widget.labels[index],
                  );
                },
                titleTextStyle: theme.textTheme.bodySmall?.copyWith(
                  fontSize: fontSize,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                  height: 1.0,
                ),
                radarBackgroundColor: Colors.transparent,
                radarBorderData: BorderSide(
                  color: Colors.black.withValues(alpha: 0.16),
                  width: 1.2,
                ),
                gridBorderData: BorderSide(
                  color: Colors.black.withValues(alpha: 0.12),
                  width: 1,
                ),
                ticksTextStyle: const TextStyle(
                  color: Colors.transparent,
                  fontSize: 0,
                  height: 0,
                ),
                tickBorderData: BorderSide(
                  color: Colors.black.withValues(alpha: 0.08),
                  width: 0.8,
                ),
                dataSets: [
                  for (int i = 0; i < widget.datasets.length; i++)
                    RadarDataSet(
                      fillColor: _seriesColor(i).withValues(alpha: 0.18),
                      borderColor: _seriesColor(i),
                      borderWidth: _hoverSeries == i ? 3.2 : 2.0,
                      entryRadius: _hoverSeries == i ? 3.6 : 2.4,
                      dataEntries: widget.datasets[i].values
                          .map(
                            (value) => RadarEntry(
                          value: value.toDouble(),
                        ),
                      )
                          .toList(),
                    ),
                ],
                radarTouchData: RadarTouchData(
                  enabled: true,
                  touchCallback: (event, response) {
                    final spot = response?.touchedSpot;

                    if (spot == null) {
                      _clearHover();
                      return;
                    }

                    Offset? localPosition;

                    try {
                      localPosition = (event as dynamic).localPosition as Offset?;
                    } catch (_) {
                      localPosition = null;
                    }

                    if (!mounted) return;

                    setState(() {
                      _hoverSeries = spot.touchedDataSetIndex;
                      _hoverAxis = spot.touchedRadarEntryIndex;
                      _hoverPos = localPosition;
                      _hoverValue = spot.touchedRadarEntry.value;
                    });

                    if (widget.onEntryTap == null) return;

                    final bool isTap =
                    event.runtimeType.toString().contains('FlTap');

                    if (isTap &&
                        _hoverAxis != null &&
                        _hoverSeries != null &&
                        _hoverValue != null) {
                      widget.onEntryTap!(
                        axisIndex: _hoverAxis!,
                        seriesIndex: _hoverSeries!,
                        value: _hoverValue!,
                      );
                    }
                  },
                ),
              ),
            );

            final tooltip =
            _hoverSeries != null && _hoverAxis != null && _hoverPos != null
                ? Positioned(
              left: _hoverPos!.dx + 12,
              top: _hoverPos!.dy + 12,
              child: Material(
                elevation: 2,
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: DefaultTextStyle(
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      height: 1.15,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.datasets[_hoverSeries!].name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(widget.labels[_hoverAxis!]),
                        Text(
                          SipGedFormatMoney.brlCompact(
                            _hoverValue ?? 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
                : const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Center(
                    child: SizedBox(
                      width: side,
                      height: side,
                      child: MouseRegion(
                        onExit: (_) => _clearHover(),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned.fill(child: chart),
                            tooltip,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (widget.useExternalLegend) const SizedBox(height: 8),
                if (widget.useExternalLegend)
                  SizedBox(
                    height: legendReservedHeight,
                    child: SingleChildScrollView(
                      primary: false,
                      child: _buildLegend(isDark: isDark),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}