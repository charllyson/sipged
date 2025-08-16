import 'package:flutter/material.dart';

import '../../../../_datas/sectors/transit/accidents/accidents_data.dart';
import '../../../../_widgets/selectorDates/selectorDates.dart';
import '../../../../_widgets/selectorDates/selector_dates_shimmer.dart';

class AccidentsSelectorSection extends StatefulWidget {
  final List<AccidentsData> allData;
  final void Function(List<AccidentsData> filtered, int? year, int? month) onFilterChanged;

  const AccidentsSelectorSection({
    super.key,
    required this.allData,
    required this.onFilterChanged,
  });

  @override
  State<AccidentsSelectorSection> createState() => _AccidentsSelectorSectionState();
}

class _AccidentsSelectorSectionState extends State<AccidentsSelectorSection> {
  final selectedYearNotifier = ValueNotifier<int?>(DateTime.now().year);
  final selectedMonthNotifier = ValueNotifier<int?>(null);

  @override
  Widget build(BuildContext context) {
    if (widget.allData.isEmpty) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            SizedBox(width: 12),
            SelectorDatesShimmer(),
            SizedBox(width: 12),
            SelectorDatesShimmer(),
          ],
        ),
      );
    }

    final allAccidents = widget.allData;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SelectorDates<AccidentsData>(
        items: allAccidents,
        getDate: (item) => item.date,
        initialYear: selectedYearNotifier.value,
        initialMonth: selectedMonthNotifier.value,
        onSelectionChanged: ({
          List<AccidentsData>? filteredItems,
          int? selectedYear,
          int? selectedMonth,
        }) {
          selectedYearNotifier.value = selectedYear;
          selectedMonthNotifier.value = selectedMonth;

          final filtered = (filteredItems ?? [])
            ..sort((a, b) => (b.date ?? DateTime(1900)).compareTo(a.date ?? DateTime(1900)));

          widget.onFilterChanged(filtered, selectedYear, selectedMonth);
        },
      ),
    );
  }
}


