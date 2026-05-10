import 'package:flutter/material.dart';

import 'package:sipged/_blocs/modules/transit/infractions/infractions_data.dart';
import 'package:sipged/_widgets/DataTime/selector/selector_dates.dart';

class InfractionsSelectorDatesSection extends StatelessWidget {
  final List<InfractionsData> allInfractions;
  final int? initialYear;
  final int? initialMonth;
  final ValueChanged<InfractionsSelectorDatesResult> onSelectionChanged;

  const InfractionsSelectorDatesSection({
    super.key,
    required this.allInfractions,
    this.initialYear,
    this.initialMonth,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SelectorDates<InfractionsData>(
      items: allInfractions,
      getDate: (item) => item.dateInfraction,
      initialYear: initialYear,
      initialMonth: initialMonth,
      onSelectionChanged: ({
        List<InfractionsData>? filteredItems,
        int? selectedYear,
        int? selectedMonth,
        int? selectedDay,
      }) {
        onSelectionChanged(
          InfractionsSelectorDatesResult(
            filteredItems: filteredItems ?? const <InfractionsData>[],
            selectedYear: selectedYear,
            selectedMonth: selectedMonth,
          ),
        );
      },
    );
  }
}

class InfractionsSelectorDatesResult {
  final List<InfractionsData> filteredItems;
  final int? selectedYear;
  final int? selectedMonth;

  const InfractionsSelectorDatesResult({
    required this.filteredItems,
    required this.selectedYear,
    required this.selectedMonth,
  });
}