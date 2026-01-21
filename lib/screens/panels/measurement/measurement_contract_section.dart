import 'package:flutter/material.dart';
import 'package:siged/_widgets/charts/lines/line_chart_changed.dart';
import 'package:siged/_utils/formats/format_field.dart';
import 'package:siged/_blocs/modules/contracts/measurement/report/report_measurement_data.dart';

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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        margin: const EdgeInsets.only(left: 12),
        child: LineChartChanged(
          alturaGrafico: 300,
          labels: filteredMeasurements.map((m) => dayAndMonthToString(m.date!)).toList(),
          values: filteredMeasurements.map((m) => m.value ?? 0.0).toList(),
          selectedIndex: selectedIndex,
          onPointTap: (index) {
            onPointTap?.call(index);
          },
        ),
      ),
    );
  }
}

