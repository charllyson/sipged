import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sisgeo/_datas/measurement/measurement_data.dart';
import 'package:sisgeo/_datas/apostilles/apostilles_data.dart';
import 'package:sisgeo/_datas/additive/additive_data.dart';
import 'package:sisgeo/_widgets/formats/format_field.dart';

class PieChartSample extends StatefulWidget {
  final List<MeasurementData>? measurements;
  final List<ApostillesData>? apostilles;
  final List<AdditiveData>? additives;
  final void Function(int?)? onTouch;
  final int? selectedIndex;
  final double? larguraGrafico;

  const PieChartSample({
    super.key,
    this.measurements,
    this.apostilles,
    this.additives,
    this.onTouch,
    this.selectedIndex,
    this.larguraGrafico,
  });

  @override
  State<PieChartSample> createState() => _PieChartSampleState();
}

class _PieChartSampleState extends State<PieChartSample> {
  late final List<Color> cores;
  int? touchedIndex;

  @override
  void initState() {
    super.initState();
    final totalItens = (widget.apostilles?.length ??
        widget.measurements?.length ??
        widget.additives?.length) ?? 0;

    final random = Random();
    cores = List.generate(
      totalItens,
          (_) => Color.fromARGB(
        255,
        random.nextInt(200) + 30,
        random.nextInt(200) + 30,
        random.nextInt(200) + 30,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isApostille = widget.apostilles != null && widget.apostilles!.isNotEmpty;
    final bool isMeasurement = widget.measurements != null && widget.measurements!.isNotEmpty;
    final bool isAdditive = widget.additives != null && widget.additives!.isNotEmpty;

    final dataList = isApostille
        ? widget.apostilles!
        : isMeasurement
        ? widget.measurements!
        : widget.additives;

    if (dataList == null || dataList.isEmpty) {
      return _semDados('Sem dados');
    }

    final total = dataList.fold<double>(0, (sum, e) {
      if (isApostille) return sum + ((e as ApostillesData).apostillevalue ?? 0);
      if (isMeasurement) return sum + ((e as MeasurementData).measurementinitialvalue ?? 0);
      return sum + ((e as AdditiveData).additivevalue ?? 0);
    });

    if (total == 0) {
      return _semDados('Apenas aditivos de prazo');
    }

    return Card(
      color: Colors.white,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: RepaintBoundary(
          child: SizedBox(
            height: 210,
            width: widget.larguraGrafico ?? 220,
            child: PieChart(
              PieChartData(
                centerSpaceRadius: 40,
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    if (event is FlTapUpEvent && response?.touchedSection != null) {
                      setState(() {
                        touchedIndex = response!.touchedSection!.touchedSectionIndex;
                        widget.onTouch?.call(touchedIndex);
                      });
                    }
                  },
                ),
                sections: List.generate(dataList.length, (index) {
                  final isTouched = index == (widget.selectedIndex ?? touchedIndex);

                  double value = 0;
                  int? order;
                  String formattedValue = '';

                  if (isApostille) {
                    final item = dataList[index] as ApostillesData;
                    value = item.apostillevalue ?? 0;
                    order = item.apostilleorder;
                  } else if (isMeasurement) {
                    final item = dataList[index] as MeasurementData;
                    value = item.measurementinitialvalue ?? 0;
                    order = item.measurementorder;
                  } else if (isAdditive) {
                    final item = dataList[index] as AdditiveData;
                    value = item.additivevalue ?? 0;
                    order = item.additiveorder;
                  }

                  final percentual = (value / total) * 100;
                  formattedValue = priceToString(value);

                  return PieChartSectionData(
                    color: cores[index],
                    value: value,
                    title: isTouched
                        ? '$order\n${percentual.toStringAsFixed(1)}%\n$formattedValue'
                        : '$order',
                    radius: 40,
                    titlePositionPercentageOffset: isTouched ? 1.6 : 1.4,
                    titleStyle: TextStyle(
                      color: isTouched ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isTouched ? 11 : 9,
                      height: isTouched ? 1.2 : 1.0,
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _semDados(String texto) {
    return Card(
      color: Colors.white,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          height: 210,
          width: widget.larguraGrafico ?? 220,
          child: Center(child: Text(texto)),
        ),
      ),
    );
  }
}
