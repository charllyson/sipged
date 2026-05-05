import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/_process/process_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';

import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_road_cubit.dart';
import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_road_repository.dart';

import 'package:sipged/_widgets/menu/tab/tab_changed_widget.dart';
import 'package:sipged/screens/modules/operation/phys_fin/physfin_widget.dart';
import 'package:sipged/screens/modules/contracts/additive/additive_page.dart';

class TabBarAdditivePage extends StatelessWidget {
  const TabBarAdditivePage({
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
          label: 'Aditivos',
          requireSavedContract: true,
          builder: (c) {
            final contract = c!;

            return AdditivePage(
              key: ValueKey(contract.id),
              contractData: contract,
            );
          },
        ),
        ContractTabDescriptor(
          label: 'Cronograma',
          requireSavedContract: true,
          builder: (c) {
            final contract = c!;

            return BlocProvider<ScheduleRoadCubit>(
              create: (_) => ScheduleRoadCubit(
                repository: ScheduleRoadRepository(),
              )..warmup(
                contractId: contract.id!,
                initialServiceKey: 'geral',
              ),
              child: PhysFinWidget(
                contractData: contract,
                chronogramMode: true,
              ),
            );
          },
        ),
      ],
    );
  }
}