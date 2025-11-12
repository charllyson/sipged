import 'package:flutter/material.dart';
import 'package:siged/_blocs/_process/process_bloc.dart';
import 'package:siged/_blocs/_process/process_data.dart';
import 'package:siged/_widgets/menu/tab/tab_changed_widget.dart';
import 'package:siged/screens/process/validity/validity_page.dart';

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
        // As demais exigem ID salvo
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
