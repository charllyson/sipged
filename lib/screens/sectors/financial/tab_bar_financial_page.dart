import 'package:flutter/material.dart';

import 'package:siged/_blocs/process/contracts/contract_bloc.dart';
import 'package:siged/_blocs/process/contracts/contract_data.dart';

import 'package:siged/_widgets/menu/tab/tab_changed_widget.dart';
import 'package:siged/screens/sectors/financial/payments/report/payment_report_page.dart';
import 'package:siged/screens/sectors/financial/payments/adjustment/payments_adjustment_page.dart';
import 'package:siged/screens/sectors/financial/payments/revision/payments_revision_page.dart';

class TabBarFinancialPage extends StatelessWidget {
  final ContractData? contractData;
  final ContractBloc? contractsBloc;
  final int initialTabIndex;

  const TabBarFinancialPage({
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
        // 1) Boletim (pagamentos de medições) → pode abrir sem ID
        ContractTabDescriptor(
          label: 'Boletim',
          requireSavedContract: false,
          builder: (c) => PaymentsReportPage(contractData: c),
        ),

        // 2) Apostilamentos → exige contrato salvo
        ContractTabDescriptor(
          label: 'Apostilamentos',
          requireSavedContract: true,
          builder: (c) => PaymentsAdjustmentPage(contractData: c!),
        ),

        // 3) Revisões → exige contrato salvo
        ContractTabDescriptor(
          label: 'Revisões',
          requireSavedContract: true,
          builder: (c) => PaymentsRevisionPage(contractData: c!),
        ),
      ],
    );
  }
}
