import 'package:flutter/material.dart';
import '../../../../../_blocs/system/system_bloc.dart';
import '../../../../../_widgets/charts/line_chart_changed.dart';
import '../../../../../_widgets/formats/format_field.dart';
import '../../../../_datas/documents/measurement/reports/report_measurement_data.dart';

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (filteredMeasurements.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Nenhuma medição encontrada para o filtro selecionado.'),
          )
        else
          Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
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
          ),
      ],
    );
  }
}

