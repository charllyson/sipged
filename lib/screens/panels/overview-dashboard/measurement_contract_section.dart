import 'package:flutter/material.dart';
import 'package:sipged/_widgets/charts/lines/line_chart_changed.dart';
import 'package:sipged/_blocs/modules/contracts/measurement/report/report_measurement_data.dart';

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
    final dates = filteredMeasurements
        .map((m) => m.date)
        .whereType<DateTime>()
        .toList();

    final values =
    filteredMeasurements.map((m) => (m.value ?? 0.0)).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: LineChartChanged(
        alturaGrafico: 300,

        // 🔷 SECTION TITLE (agora ativado)
        headerTitle: 'Evolução das Mediçōes',
        headerSubtitle: 'Valores acumulados por data',
        headerIcon: Icons.show_chart_rounded,

        // eixo X (dd/MM já configurado no chart)
        dateLabels: dates,
        labels: const [],

        values: values,
        selectedIndex: selectedIndex,
        onPointTap: (index) => onPointTap?.call(index),
      ),
    );
  }
}
