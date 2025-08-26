import 'package:flutter/material.dart';
import 'package:sisged/_widgets/selectorDates/selectorDates.dart';
import '../../../../_blocs/sectors/transit/infractions/infractions_data.dart';

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
      getDate: (item) => item.dateInfraction, // DateTime? em InfractionsData
      initialYear: initialYear,
      initialMonth: initialMonth,
      onSelectionChanged: ({
        List<InfractionsData>? filteredItems,
        int? selectedYear,
        int? selectedMonth,
      }) {
        onSelectionChanged(
          InfractionsSelectorDatesResult(
            filteredItems: filteredItems ?? [],
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

  InfractionsSelectorDatesResult({
    required this.filteredItems,
    required this.selectedYear,
    required this.selectedMonth,
  });
}
