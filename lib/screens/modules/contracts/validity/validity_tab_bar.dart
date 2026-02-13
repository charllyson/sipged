// ==============================
// lib/screens/contracts/validity/validity_tab_bar_page.dart
// ==============================
import 'package:flutter/material.dart';

import 'package:sipged/_blocs/modules/contracts/_process/process_bloc.dart';
import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';
import 'package:sipged/_widgets/menu/tab/tab_changed_widget.dart';
import 'package:sipged/screens/modules/contracts/validity/validity_page.dart';

class ValidityTabBarPage extends StatelessWidget {
  final ProcessData? contractData;
  final ProcessBloc? contractsBloc;
  final int initialTabIndex;

  const ValidityTabBarPage({
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
          label: 'Vigências',
          requireSavedContract: true,
          builder: (c) => ValidityPage(
            key: ValueKey(c?.id),
            contractData: c!,
          ),
        ),
      ],
    );
  }
}
