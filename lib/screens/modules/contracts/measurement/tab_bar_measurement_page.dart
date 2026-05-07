import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/_process/process_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_repository.dart';

import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_road_cubit.dart';
import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_road_repository.dart';

import 'package:sipged/_widgets/menu/tab/tab_changed_widget.dart';

import 'package:sipged/screens/modules/contracts/measurement/report/report_executed_page.dart';
import 'package:sipged/screens/modules/contracts/measurement/adjustment/adjustment_measurement_page.dart';
import 'package:sipged/screens/modules/contracts/measurement/revision/revision_measurement_page.dart';

import 'package:sipged/screens/modules/operation/phys_fin/physfin_widget.dart';

class TabBarMeasurementPage extends StatefulWidget {
  const TabBarMeasurementPage({
    super.key,
    this.contractData,
    this.contractsCubit,
    this.initialTabIndex = 0,
  });

  final ProcessData? contractData;
  final ProcessCubit? contractsCubit;
  final int initialTabIndex;

  @override
  State<TabBarMeasurementPage> createState() => _TabBarMeasurementPageState();
}

class _TabBarMeasurementPageState extends State<TabBarMeasurementPage> {
  final DfdRepository _dfdRepository = DfdRepository();

  DfdData? _dfdData;

  String get _contractId => widget.contractData?.id?.trim() ?? '';

  String? get _textBanner {
    final descricaoObjeto = _dfdData?.descricaoObjeto?.trim();

    if (descricaoObjeto != null && descricaoObjeto.isNotEmpty) {
      return descricaoObjeto;
    }

    if (_contractId.isNotEmpty) {
      return 'Contrato $_contractId';
    }

    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadDfdDisplayData();
  }

  @override
  void didUpdateWidget(covariant TabBarMeasurementPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldId = oldWidget.contractData?.id?.trim() ?? '';
    final newId = widget.contractData?.id?.trim() ?? '';

    if (oldId != newId) {
      _dfdData = null;
      _loadDfdDisplayData();
    }
  }

  Future<void> _loadDfdDisplayData() async {
    final contractId = _contractId;

    if (contractId.isEmpty) return;

    try {
      final dfd = await _dfdRepository.readDataForContract(contractId);

      if (!mounted) return;

      setState(() {
        _dfdData = dfd;
      });
    } catch (e, stack) {
      debugPrint('Falha ao carregar DFD no TabBarMeasurementPage: $e');
      debugPrintStack(stackTrace: stack);
    }
  }

  String _buildContractNumber(ProcessData contract) {
    final processoAdministrativo = _dfdData?.processoAdministrativo?.trim();

    if (processoAdministrativo != null && processoAdministrativo.isNotEmpty) {
      return 'Processo nº $processoAdministrativo';
    }

    final contractId = contract.id?.trim() ?? '';

    if (contractId.isNotEmpty) {
      return 'Contrato $contractId';
    }

    return '';
  }

  Widget _buildChronogramTab(ProcessData contract) {
    final contractId = contract.id?.trim();

    if (contractId == null || contractId.isEmpty) {
      return const Center(
        child: Text(
          'Salve o contrato antes de acessar o cronograma.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return BlocProvider<ScheduleRoadCubit>(
      key: ValueKey('measurement-chronogram-$contractId'),
      create: (_) => ScheduleRoadCubit(
        repository: ScheduleRoadRepository(),
      )..warmup(
        contractId: contractId,
        initialServiceKey: 'geral',
      ),
      child: PhysFinWidget(
        contractData: contract,
        chronogramMode: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TabChanged(
      contractData: widget.contractData,
      contractsCubit: widget.contractsCubit,
      initialTabIndex: widget.initialTabIndex,
      textBanner: _textBanner,
      contractNumberBuilder: _buildContractNumber,
      tabs: [
        ContractTabDescriptor(
          label: 'Boletim',
          requireSavedContract: false,
          builder: (c) => ReportExecutedPage(
            contractData: c!,
          ),
        ),
        ContractTabDescriptor(
          label: 'Reajustamento',
          requireSavedContract: true,
          builder: (c) => AdjustmentMeasurement(
            contractData: c!,
          ),
        ),
        ContractTabDescriptor(
          label: 'Revisões',
          requireSavedContract: true,
          builder: (c) => RevisionMeasurement(
            contractData: c!,
          ),
        ),
        ContractTabDescriptor(
          label: 'Cronograma',
          requireSavedContract: true,
          builder: (c) {
            final contract = c!;

            return _buildChronogramTab(contract);
          },
        ),
      ],
    );
  }
}