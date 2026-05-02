import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/_process/process_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';

import 'package:sipged/_blocs/modules/operation/operation/road/schedule_road_cubit.dart';
import 'package:sipged/_blocs/modules/operation/operation/road/schedule_road_repository.dart';

import 'package:sipged/_widgets/menu/tab/tab_changed_widget.dart';
import 'package:sipged/screens/modules/operation/schedule/financial/physfin_widget.dart';
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

  String _buildContractNumber(ProcessData contract) {
    final number = contract.displayNumber.trim();

    if (number.isEmpty) return '';

    if ((contract.contractNumber ?? '').trim().isNotEmpty) {
      return 'Contrato nº $number';
    }

    if ((contract.processNumber ?? '').trim().isNotEmpty) {
      return 'Processo nº $number';
    }

    return number;
  }

  @override
  Widget build(BuildContext context) {
    return TabChanged(
      contractData: contractData,
      contractsCubit: contractsCubit,
      initialTabIndex: initialTabIndex,
      textBanner: contractData?.summarySubjectContract,
      contractNumberBuilder: _buildContractNumber,
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