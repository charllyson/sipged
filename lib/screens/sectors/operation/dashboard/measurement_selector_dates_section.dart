import 'package:flutter/material.dart';
import 'package:sisged/_widgets/selectorDates/selectorDates.dart';

import 'package:sisged/_datas/documents/measurement/reports/report_measurement_data.dart';

class MeasurementSelectorDatesSection extends StatelessWidget {
  final List<ReportMeasurementData> allMeasurements;
  final int? initialYear;
  final int? initialMonth;
  final ValueChanged<SelectorDatesFilterResult> onSelectionChanged;

  const MeasurementSelectorDatesSection({
    super.key,
    required this.allMeasurements,
    this.initialYear,
    this.initialMonth,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SelectorDates<ReportMeasurementData>(
      items: allMeasurements,
      getDate: (item) => item.dateReportMeasurement,
      initialYear: initialYear,
      initialMonth: initialMonth,
      onSelectionChanged: ({
        List<ReportMeasurementData>? filteredItems,
        int? selectedYear,
        int? selectedMonth,
      }) {
        onSelectionChanged(SelectorDatesFilterResult(
          filteredItems: filteredItems ?? [],
          selectedYear: selectedYear,
          selectedMonth: selectedMonth,
        ));
      },
    );
  }
}

class SelectorDatesFilterResult {
  final List<ReportMeasurementData> filteredItems;
  final int? selectedYear;
  final int? selectedMonth;

  SelectorDatesFilterResult({
    required this.filteredItems,
    required this.selectedYear,
    required this.selectedMonth,
  });
}
