import 'package:flutter/material.dart';

import 'package:siged/_blocs/modules/contracts/_process/process_bloc.dart';
import 'package:siged/_blocs/modules/contracts/_process/process_data.dart';
import 'package:siged/_widgets/menu/tab/tab_changed_widget.dart';

// ✅ usar a ApostillesPage do módulo contracts/apostilles
import 'package:siged/screens/modules/contracts/apostilles/apostilles_page.dart';

class TabBarApostillesPage extends StatelessWidget {
  final ProcessData? contractData;
  final ProcessBloc? contractsBloc;
  final int initialTabIndex;

  const TabBarApostillesPage({
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
        ContractTabDescriptor(
          label: 'Apostilamentos',
          requireSavedContract: true,
          builder: (c) => ApostillesPage(
            key: ValueKey(c?.id),
            contractData: c!,
          ),
        ),
      ],
    );
  }
}
