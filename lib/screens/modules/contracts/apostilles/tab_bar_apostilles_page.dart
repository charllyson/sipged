import 'package:flutter/material.dart';

import 'package:sipged/_blocs/modules/contracts/_process/process_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';
import 'package:sipged/_widgets/menu/tab/tab_changed_widget.dart';
import 'package:sipged/screens/modules/contracts/apostilles/apostilles_page.dart';

class TabBarApostillesPage extends StatelessWidget {
  const TabBarApostillesPage({
    super.key,
    this.contractData,
    this.contractsCubit,
    this.initialTabIndex = 0,
  });

  final ProcessData? contractData;
  final ProcessCubit? contractsCubit;
  final int initialTabIndex;

  @override
  Widget build(BuildContext context) {
    return TabChanged(
      contractData: contractData,
      contractsCubit: contractsCubit,
      initialTabIndex: initialTabIndex,
      tabs: [
        ContractTabDescriptor(
          label: 'Apostilamentos',
          requireSavedContract: true,
          builder: (c) {
            final contract = c!;

            return ApostillesPage(
              key: ValueKey(contract.id),
              contractData: contract,
            );
          },
        ),
      ],
    );
  }
}