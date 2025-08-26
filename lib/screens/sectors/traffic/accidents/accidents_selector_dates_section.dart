import 'package:flutter/material.dart';
import 'package:sisged/_widgets/selectorDates/selectorDates.dart';
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
      getDate: (item) => item.date, // DateTime? em AccidentsData
      initialYear: initialYear,
      initialMonth: initialMonth,
      onSelectionChanged: ({
        List<AccidentsData>? filteredItems,
        int? selectedYear,
        int? selectedMonth,
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
