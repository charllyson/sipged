import 'package:flutter/material.dart';

import 'package:sipged/_blocs/modules/contracts/contract/contract_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';
import 'package:sipged/_widgets/menu/tab/tab_changed_widget.dart';
import 'package:sipged/screens/modules/contracts/validity/validity_page.dart';

class ValidityTabBarPage extends StatelessWidget {
  final ContractData? contractData;
  final ContractCubit? contractsCubit;
  final int initialTabIndex;

  const ValidityTabBarPage({
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