// lib/screens/sectors/traffic/accidents/accidents_selector_dates_section.dart
import 'package:flutter/material.dart';
import 'package:siged/_widgets/dates/selector/selectorDates.dart';
import '../../../../_blocs/sectors/transit/accidents/accidents_data.dart';

class AccidentsSelectorDatesSection extends StatelessWidget {
  final List<AccidentsData> allAccidents;
  final int? initialYear;
  final int? initialMonth;
  final ValueChanged<AccidentsSelectorDatesResult> onSelectionChanged;

  const AccidentsSelectorDatesSection({
    super.key,
    required this.allAccidents,
    this.initialYear,
    this.initialMonth,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SelectorDates<AccidentsData>(
      items: allAccidents,
      getDate: (item) => item.date,
      initialYear: initialYear,
      initialMonth: initialMonth,

      // NÃO deixa o selector aplicar filtro sozinho no init.
      autoSelectInitial: false,

      onSelectionChanged: ({
        List<AccidentsData>? filteredItems,
        int? selectedYear,
        int? selectedMonth,
        int? selectedDay,
      }) {
        onSelectionChanged(
          AccidentsSelectorDatesResult(
            filteredItems: filteredItems ?? [],
            selectedYear: selectedYear,
            selectedMonth: selectedMonth,
          ),
        );
      },
    );
  }
}

class AccidentsSelectorDatesResult {
  final List<AccidentsData> filteredItems;
  final int? selectedYear;
  final int? selectedMonth;

  AccidentsSelectorDatesResult({
    required this.filteredItems,
    required this.selectedYear,
    required this.selectedMonth,
  });
}
