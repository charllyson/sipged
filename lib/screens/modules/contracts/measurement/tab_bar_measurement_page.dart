// lib/screens/modules/contracts/measurement/tab_bar_measurement_page.dart
// ajuste o caminho conforme onde esse arquivo está no seu projeto

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/contract/contract_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_repository.dart';

import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_road_cubit.dart';
import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_road_repository.dart';

import 'package:sipged/_blocs/system/permission/permission_cubit.dart';
import 'package:sipged/_blocs/system/permission/permission_state.dart';

import 'package:sipged/_widgets/menu/tab/tab_changed_widget.dart';

import 'package:sipged/screens/modules/contracts/measurement/report/report_executed_page.dart';
import 'package:sipged/screens/modules/contracts/measurement/adjustment/adjustment_measurement_page.dart';
import 'package:sipged/screens/modules/contracts/measurement/revision/revision_measurement_page.dart';

import 'package:sipged/screens/modules/contracts/measurement/cronograma/physfin_widget.dart';

class TabBarMeasurementPage extends StatefulWidget {
  const TabBarMeasurementPage({
    super.key,
    this.contractData,
    this.contractsCubit,
    this.initialTabIndex = 0,
  });

  final ContractData? contractData;
  final ContractCubit? contractsCubit;
  final int initialTabIndex;

  @override
  State<TabBarMeasurementPage> createState() => _TabBarMeasurementPageState();
}

class _TabBarMeasurementPageState extends State<TabBarMeasurementPage> {
  late String _activeTenantId;
  late DfdRepository _dfdRepository;

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

    _activeTenantId = _resolveRequiredTenantId(
      context.read<PermissionCubit>().state,
    );

    _dfdRepository = DfdRepository(
      tenantId: _activeTenantId,
    );

    _loadDfdDisplayData();
  }

  @override
  void didUpdateWidget(covariant TabBarMeasurementPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldId = oldWidget.contractData?.id?.trim() ?? '';
    final newId = widget.contractData?.id?.trim() ?? '';

    if (oldId != newId) {
      setState(() {
        _dfdData = null;
      });

      _loadDfdDisplayData();
    }
  }

  String _resolveRequiredTenantId(PermissionState permissionState) {
    final tenantId = permissionState.activeTenantId?.trim();

    if (tenantId == null || tenantId.isEmpty) {
      throw ArgumentError(
        'tenantId é obrigatório para TabBarMeasurementPage.',
      );
    }

    return tenantId;
  }

  void _handlePermissionStateChanged(PermissionState permissionState) {
    final nextTenantId = _resolveRequiredTenantId(permissionState);

    if (nextTenantId == _activeTenantId) return;

    setState(() {
      _activeTenantId = nextTenantId;
      _dfdRepository = DfdRepository(
        tenantId: _activeTenantId,
      );
      _dfdData = null;
    });

    _loadDfdDisplayData();
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

  String _buildContractNumber(ContractData contract) {
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

  Widget _buildChronogramTab(ContractData contract) {
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
      key: ValueKey<String>(
        'measurement-chronogram-$_activeTenantId-$contractId',
      ),
      create: (_) {
        return ScheduleRoadCubit(
          repository: ScheduleRoadRepository(
            tenantId: _activeTenantId,
          ),
          tenantId: _activeTenantId,
        )..warmup(
          contractId: contractId,
          initialServiceKey: 'geral',
        );
      },
      child: PhysFinWidget(
        contractData: contract,
        chronogramMode: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PermissionCubit, PermissionState>(
      listenWhen: (previous, current) {
        return previous.activeTenantId != current.activeTenantId;
      },
      listener: (context, permissionState) {
        _handlePermissionStateChanged(permissionState);
      },
      child: TabChanged(
        contractData: widget.contractData,
        contractsCubit: widget.contractsCubit,
        initialTabIndex: widget.initialTabIndex,
        textBanner: _textBanner,
        contractNumberBuilder: _buildContractNumber,
        tabs: [
          ContractTabDescriptor(
            label: 'Boletim',
            requireSavedContract: false,
            builder: (contract) {
              return ReportExecutedPage(
                contractData: contract!,
              );
            },
          ),
          ContractTabDescriptor(
            label: 'Reajustamento',
            requireSavedContract: true,
            builder: (contract) {
              return AdjustmentMeasurement(
                contractData: contract!,
              );
            },
          ),
          ContractTabDescriptor(
            label: 'Revisões',
            requireSavedContract: true,
            builder: (contract) {
              return RevisionMeasurement(
                contractData: contract!,
              );
            },
          ),
          ContractTabDescriptor(
            label: 'Cronograma',
            requireSavedContract: true,
            builder: (contract) {
              return _buildChronogramTab(contract!);
            },
          ),
        ],
      ),
    );
  }
}