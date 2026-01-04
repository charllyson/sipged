// lib/screens/process/hiring/physical_financial/tab_bar_additive_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_blocs/_process/process_bloc.dart';
import 'package:siged/_blocs/_process/process_data.dart';

import 'package:siged/_blocs/sectors/operation/road/schedule_road_cubit.dart';
import 'package:siged/_blocs/sectors/operation/road/schedule_road_repository.dart';

import 'package:siged/_widgets/menu/tab/tab_changed_widget.dart';
import 'package:siged/_widgets/schedule/physical_financial/schedule_physical_financial_widget.dart';

// 👉 usar a AdditivePage do módulo contracts/additives
import 'package:siged/screens/process/additive/additive_page.dart';

class TabBarAdditivePage extends StatelessWidget {
  final ProcessData? contractData;
  final ProcessBloc? contractsBloc;
  final int initialTabIndex;

  const TabBarAdditivePage({
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
          label: 'Aditivos',
          requireSavedContract: true,
          builder: (c) {
            return AdditivePage(
              key: ValueKey(c?.id),
              contractData: c!,
            );
          },
        ),
        ContractTabDescriptor(
          label: 'Cronograma',
          requireSavedContract: true,
          builder: (c) => BlocProvider<ScheduleRoadCubit>(
            create: (_) => ScheduleRoadCubit(
              repository: ScheduleRoadRepository(),
            )..warmup(
              contractId: c.id!,
              initialServiceKey: 'geral',
            ),
            child: SchedulePhysicalFinancialWidget(
              contractData: c!,
              chronogramMode: true,
            ),
          ),
        ),
      ],
    );
  }
}
