import 'package:flutter/material.dart';
import 'package:sisged/_blocs/system/info/system_bloc.dart';
import 'package:sisged/_widgets/charts/lines/line_chart_changed.dart';
import 'package:sisged/_utils/formats/format_field.dart';
import 'package:sisged/_blocs/documents/measurement/report/report_measurement_data.dart';

class MeasurementContractSection extends StatelessWidget {
  final List<ReportMeasurementData> filteredMeasurements;
  final int? selectedIndex;
  final void Function(int index)? onPointTap;

  const MeasurementContractSection({
    super.key,
    required this.filteredMeasurements,
    required this.selectedIndex,
    this.onPointTap,
  });

  @override
  Widget build(BuildContext context) {
    final systemBloc = SystemBloc();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        margin: const EdgeInsets.only(left: 12),
        child: LineChartChanged(
          larguraGrafico: systemBloc.calcularLarguraDinamica(filteredMeasurements.length),
          alturaGrafico: 300,
          labels: filteredMeasurements.map((m) => dayAndMonthToString(m.dateReportMeasurement!)).toList(),
          values: filteredMeasurements.map((m) => m.valueReportMeasurement ?? 0.0).toList(),
          selectedIndex: selectedIndex,
          onPointTap: (index) {
            onPointTap?.call(index);
          },
        ),
      ),
    );
  }
}

