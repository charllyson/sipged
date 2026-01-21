import 'package:flutter/material.dart';

import 'package:siged/_blocs/modules/contracts/_process/process_bloc.dart';
import 'package:siged/_blocs/modules/contracts/_process/process_data.dart';

import 'package:siged/_widgets/menu/tab/tab_changed_widget.dart';
import 'package:siged/screens/modules/contracts/measurement/report/report_measurement_page.dart';
import 'package:siged/screens/modules/contracts/measurement/adjustment/adjustment_measurement_page.dart';
import 'package:siged/screens/modules/contracts/measurement/revision/revision_measurement_page.dart';

class TabBarMeasurementPage extends StatelessWidget {
  final ProcessData? contractData;
  final ProcessBloc? contractsBloc;
  final int initialTabIndex;

  const TabBarMeasurementPage({
    super.key,
    this.contractData,
    this.contractsBloc,
    this.initialTabIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return TabChangedWidget(
      contractData: contractData,
      contractsBloc: contractsBloc,
      initialTabIndex: initialTabIndex,
      tabs: [
        // 1) Boletim → liberado mesmo sem ID
        ContractTabDescriptor(
          label: 'Boletim',
          requireSavedContract: false,
          builder: (c) => ReportMeasurement(contractData: c!),
        ),
        // 2) Reajustamento → exige contrato salvo
        ContractTabDescriptor(
          label: 'Reajustamento',
          requireSavedContract: true,
          builder: (c) => AdjustmentMeasurement(contractData: c!),
        ),
        // 3) Revisões → exige contrato salvo
        ContractTabDescriptor(
          label: 'Revisões',
          requireSavedContract: true,
          builder: (c) => RevisionMeasurement(contractData: c!),
        ),
      ],
    );
  }
}
