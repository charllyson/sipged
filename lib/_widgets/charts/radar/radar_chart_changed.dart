// lib/_widgets/charts/radar/radar_chart_changed.dart
import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sipged/_utils/formats/sipged_format_money.dart';

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

  void _clearHover() {
    setState(() {
      _hoverSeries = null;
      _hoverAxis = null;
      _hoverPos = null;
      _hoverValue = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Gradient cardGradient = isDark
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

    final hasMismatch =
    widget.datasets.any((s) => s.values.length != widget.labels.length);

    final bool showShimmer =
        widget.labels.isEmpty || widget.datasets.isEmpty || hasMismatch;

    // ==========================
    // CASO: SHIMMER
    // ==========================
    if (showShimmer) {
      return SizedBox(
        width: widget.larguraCard,
        height: widget.alturaCard,
        child: BasicCard(
          isDark: isDark,
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          gradient: cardGradient,
          enableShadow: true,
          child: Center(
            child: RadarChartShimmer(
              isDark: isDark,
              altura: 275,
              largura: widget.larguraGrafico,
              legendItems: widget.useExternalLegend ? widget.datasets.length : 0,
              axes: 10,
              rings: 10,
            ),
          ),
        ),
      );
    }

    // ==========================
    // CASO: GRÁFICO COM DADOS
    // ==========================

    return SizedBox(
      width: widget.larguraCard,
      height: widget.alturaCard,
      child: BasicCard(
        isDark: isDark,
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        gradient: cardGradient,
        enableShadow: true,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxW = widget.larguraGrafico ?? constraints.maxWidth;
            final maxH = constraints.maxHeight.isFinite ? constraints.maxHeight : 300.0;

            // ====== LEGENDA (medição real aproximada) ======
            final legendItemMinWidth = 120.0;
            final legendCols = math.max(1, (maxW / legendItemMinWidth).floor());
            final legendRows =
            widget.useExternalLegend ? (widget.datasets.length / legendCols).ceil() : 0;
            final legendRowHeight = 24.0;
            final legendReservedHeight = widget.useExternalLegend
                ? (legendRows * legendRowHeight) + (legendRows > 0 ? 8.0 : 0.0)
                : 0.0;

            // ====== ÁREA ÚTIL DO GRÁFICO ======
            final usableH = (maxH - legendReservedHeight).clamp(120.0, maxH);
            final side = math.min(maxW, usableH);

            // ====== FONT & OFFSET ======
            final labelCount = widget.labels.length.clamp(3, 24);
            final baseFont = (side / 30).clamp(9, 14).toDouble();
            final fontSize = (baseFont - (labelCount > 10 ? 1.0 : 0.0)).clamp(8, 14).toDouble();

            final titleOffset = side >= 420
                ? 0.20
                : side >= 340
                ? 0.18
                : 0.16;

            Color seriesColor(int i) {
              final custom = widget.coresPersonalizadas;
              if (custom != null && custom.isNotEmpty) {
                return custom[i % custom.length];
              }
              return widget.datasets[i].color;
            }

            Widget buildLegend() {
              if (!widget.useExternalLegend) return const SizedBox.shrink();

              return Wrap(
                spacing: 12,
                runSpacing: 8,
                children: List.generate(widget.datasets.length, (i) {
                  final s = widget.datasets[i];
                  final c = seriesColor(i);
                  final isOn = _hoverSeries == null || _hoverSeries == i;

                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        color: c.withValues(alpha: isOn ? 1 : .4),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        s.name,
                        style: TextStyle(
                          fontSize: 12,
                          color: isOn
                              ? (isDark ? Colors.white : Colors.black)
                              : (isDark ? Colors.white.withValues(alpha:.5) : Colors.black.withValues(alpha:.5)),
                        ),
                      ),
                    ],
                  );
                }),
              );
            }

            final chart = RadarChart(
              RadarChartData(
                radarShape: RadarShape.polygon,
                tickCount: widget.tickCount,
                titlePositionPercentageOffset: titleOffset,
                getTitle: (index, angle) => RadarChartTitle(text: widget.labels[index]),
                titleTextStyle: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: fontSize),
                radarBackgroundColor: Colors.transparent,
                radarBorderData: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1.2,
                ),
                gridBorderData: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.7),
                  width: 1,
                ),
                ticksTextStyle: const TextStyle(
                  color: Colors.transparent,
                  fontSize: 0,
                  height: 0,
                ),
                tickBorderData: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.35),
                  width: 0.8,
                ),
                dataSets: [
                  for (int i = 0; i < widget.datasets.length; i++)
                    RadarDataSet(
                      fillColor: seriesColor(i).withValues(alpha: 0.18),
                      borderColor: seriesColor(i),
                      borderWidth: (_hoverSeries == i) ? 3.2 : 2.0,
                      entryRadius: (_hoverSeries == i) ? 3.6 : 2.4,
                      dataEntries: widget.datasets[i].values
                          .map((v) => RadarEntry(value: v.toDouble()))
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

                    Offset? lp;
                    try {
                      lp = (event as dynamic).localPosition as Offset?;
                    } catch (_) {
                      lp = null;
                    }

                    setState(() {
                      _hoverSeries = spot.touchedDataSetIndex;
                      _hoverAxis = spot.touchedRadarEntryIndex;
                      _hoverPos = lp;
                      _hoverValue = spot.touchedRadarEntry.value;
                    });

                    if (widget.onEntryTap != null) {
                      final isTap = event.runtimeType.toString().contains('FlTap');
                      if (isTap && _hoverAxis != null && _hoverSeries != null && _hoverValue != null) {
                        widget.onEntryTap!(
                          axisIndex: _hoverAxis!,
                          seriesIndex: _hoverSeries!,
                          value: _hoverValue!,
                        );
                      }
                    }
                  },
                ),
              ),
            );

            final tooltip = (_hoverSeries != null && _hoverAxis != null && _hoverPos != null)
                ? Positioned(
              left: _hoverPos!.dx + 12,
              top: _hoverPos!.dy + 12,
              child: Material(
                elevation: 2,
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: DefaultTextStyle(
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.datasets[_hoverSeries!].name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(widget.labels[_hoverAxis!]),
                        // ✅ novo: compacto padronizado
                        Text(SipGedFormatMoney.brlCompact(_hoverValue ?? 0)),
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
                      child: buildLegend(),
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
