import 'package:flutter/material.dart';
import 'package:sipged/_widgets/dates/selector/selectorDates.dart';
import 'package:sipged/_blocs/modules/contracts/measurement/report/report_measurement_data.dart';

class MeasurementSelectorDatesSection extends StatefulWidget {
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
  State<MeasurementSelectorDatesSection> createState() =>
      _MeasurementSelectorDatesSectionState();
}

class _MeasurementSelectorDatesSectionState
    extends State<MeasurementSelectorDatesSection> {
  late int? _effectiveInitialYear;
  late int? _effectiveInitialMonth;

  @override
  void initState() {
    super.initState();
    // Decide o ano/mês apenas uma vez no início
    _effectiveInitialYear  = widget.initialYear ?? DateTime.now().year;
    _effectiveInitialMonth = widget.initialMonth;
  }

  @override
  void didUpdateWidget(covariant MeasurementSelectorDatesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Se o pai passar explicitamente novos iniciais (não-nulos), respeite
    if (widget.initialYear != null && widget.initialYear != oldWidget.initialYear) {
      _effectiveInitialYear = widget.initialYear;
    }
    if (widget.initialMonth != null && widget.initialMonth != oldWidget.initialMonth) {
      _effectiveInitialMonth = widget.initialMonth;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SelectorDates<ReportMeasurementData>(
      items: widget.allMeasurements,
      getDate: (item) => item.date,
      initialYear: _effectiveInitialYear,
      initialMonth: _effectiveInitialMonth,
      // (opcional) flags de ordenação – já são default
      sortByDate: true,
      sortDescending: false,
      onSelectionChanged: ({
        required List<ReportMeasurementData> filteredItems,
        int? selectedYear,
        int? selectedMonth,
        int? selectedDay,
      }) {
        widget.onSelectionChanged(
          SelectorDatesFilterResult(
            filteredItems: filteredItems,
            selectedYear: selectedYear,
            selectedMonth: selectedMonth,
          ),
        );
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
