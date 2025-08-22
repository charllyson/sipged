import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'pie_chart_shimmer_widget.dart';
import 'pie_chart_legend.dart';

enum ValueFormatType {
  monetary,
  decimal,
  integer,
}

class PieChartChanged extends StatefulWidget {
  final void Function(int?)? onTouch;
  final int? selectedIndex;
  final double? larguraGrafico;
  final double? larguraCard;
  final bool showPercentageOutside;
  final double minPercentForLabel;
  final bool useExternalLegend;
  final List<Color>? coresPersonalizadas;
  final void Function(String? label)? onTapLabel;
  final String? selectedLabel;
  final List<String> labels;
  final List<double> values;
  final ValueFormatType valueFormatType; // 👈 novo parâmetro

  const PieChartChanged({
    super.key,
    this.onTouch,
    this.selectedIndex,
    this.onTapLabel,
    this.selectedLabel,
    this.larguraGrafico,
    this.larguraCard,
    this.showPercentageOutside = false,
    this.minPercentForLabel = 6.0,
    this.useExternalLegend = true,
    this.coresPersonalizadas,
    this.valueFormatType = ValueFormatType.monetary, // 👈 default
    required this.labels,
    required this.values,
  });

  @override
  State<PieChartChanged> createState() => _PieChartChangedState();
}

class _PieChartChangedState extends State<PieChartChanged> {
  late List<Color> cores;
  int? touchedIndex;

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
    if (widget.labels.isEmpty ||
        widget.values.isEmpty ||
        widget.labels.length != widget.values.length) {
      return const PieChartShimmerWidget();
    }
    if (cores.length != widget.values.length) {
      _ensureColors(widget.values.length);
    }

    final safeSelectedIndex = (widget.selectedIndex != null &&
        widget.selectedIndex! >= 0 &&
        widget.selectedIndex! < widget.values.length)
        ? widget.selectedIndex
        : null;

    final total = widget.values.fold<double>(0, (sum, e) => sum + e);
    if (total == 0) return const PieChartShimmerWidget();

    final chart = SizedBox(
      height: 200,
      width: widget.larguraGrafico ?? double.infinity,
      child: PieChart(
        PieChartData(
          startDegreeOffset: -90,
          centerSpaceRadius: 40,
          sectionsSpace: 2,
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

            final percentual = (value / total) * 100;
            final showInside = percentual >= widget.minPercentForLabel;
            final titleText = showInside
                ? (widget.showPercentageOutside
                ? '${percentual.toStringAsFixed(1)}%'
                : '${percentual.toStringAsFixed(0)}%')
                : '';

            return PieChartSectionData(
              color: cores[i],
              value: value,
              title: titleText,
              radius: isHighlighted ? 48 : 42,
              titlePositionPercentageOffset:
              widget.showPercentageOutside ? 1.6 : 0.65,
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

    final double legendWidthTarget =
        widget.larguraGrafico ?? widget.larguraCard ?? double.infinity;

    final Widget legendWidget = widget.useExternalLegend
        ? SizedBox(
      width: legendWidthTarget,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: PieChartLegend(
          labels: widget.labels,
          values: widget.values,
          total: total,
          cores: cores,
          touchedIndex: touchedIndex,
          valueFormatType: widget.valueFormatType, // 👈 passa o tipo
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
      ),
    )
        : const SizedBox.shrink();

    return SizedBox(
      width: widget.larguraCard,
      child: Card(
        color: Colors.white,
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              chart,
              if (widget.useExternalLegend) ...[
                const SizedBox(height: 12),
                legendWidget,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
