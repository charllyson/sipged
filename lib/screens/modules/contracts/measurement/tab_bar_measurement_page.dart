import 'package:flutter/material.dart';

import 'package:sipged/_blocs/modules/contracts/_process/process_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';

import 'package:sipged/_widgets/menu/tab/tab_changed_widget.dart';
import 'package:sipged/screens/modules/contracts/measurement/report/report_measurement_page.dart';
import 'package:sipged/screens/modules/contracts/measurement/adjustment/adjustment_measurement_page.dart';
import 'package:sipged/screens/modules/contracts/measurement/revision/revision_measurement_page.dart';

class TabBarMeasurementPage extends StatelessWidget {
  final ProcessData? contractData;
  final ProcessCubit? contractsCubit;
  final int initialTabIndex;

  const TabBarMeasurementPage({
    super.key,
    this.contractData,
    this.contractsCubit,
    this.initialTabIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return TabChanged(
      contractData: contractData,
      contractsCubit: contractsCubit,
      initialTabIndex: initialTabIndex,
      tabs: [
        ContractTabDescriptor(
          label: 'Boletim',
          requireSavedContract: false,
          builder: (c) => ReportMeasurement(contractData: c!),
        ),
        ContractTabDescriptor(
          label: 'Reajustamento',
          requireSavedContract: true,
          builder: (c) => AdjustmentMeasurement(contractData: c!),
        ),
        ContractTabDescriptor(
          label: 'Revisões',
          requireSavedContract: true,
          builder: (c) => RevisionMeasurement(contractData: c!),
        ),
      ],
    );
  }
}