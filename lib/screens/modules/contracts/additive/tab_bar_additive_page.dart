import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/_process/process_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';

import 'package:sipged/_blocs/modules/operation/operation/road/schedule_road_cubit.dart';
import 'package:sipged/_blocs/modules/operation/operation/road/schedule_road_repository.dart';

import 'package:sipged/_widgets/menu/tab/tab_changed_widget.dart';
import 'package:sipged/screens/modules/operation/schedule/financial/schedule_physical_financial_widget.dart';
import 'package:sipged/screens/modules/contracts/additive/additive_page.dart';

class TabBarAdditivePage extends StatelessWidget {
  final ProcessData? contractData;
  final ProcessCubit? contractsCubit;
  final int initialTabIndex;

  const TabBarAdditivePage({
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