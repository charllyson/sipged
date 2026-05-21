import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/contract/contract_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_repository.dart';

import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_linear_cubit.dart';
import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_linear_repository.dart';
import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_linear_services_data.dart';

import 'package:sipged/_blocs/system/permission/permission_cubit.dart';
import 'package:sipged/_blocs/system/permission/permission_state.dart';

import 'package:sipged/_widgets/menu/tab/tab_changed_widget.dart';
import 'package:sipged/_widgets/menu/tab/contract_tab_descriptor.dart';

import 'package:sipged/screens/modules/contracts/measurement/physics_finance/physfin_widget.dart';
import 'package:sipged/screens/modules/contracts/additive/additive_page.dart';

class TabBarAdditivePage extends StatefulWidget {
  const TabBarAdditivePage({
    super.key,
    this.contractData,
    this.contractsCubit,
    this.initialTabIndex = 0,
  });

  final ContractData? contractData;
  final ContractCubit? contractsCubit;
  final int initialTabIndex;

  @override
  State<TabBarAdditivePage> createState() => _TabBarAdditivePageState();
}

class _TabBarAdditivePageState extends State<TabBarAdditivePage> {
  late String _activeTenantId;
  late DfdRepository _dfdRepository;

  DfdData? _dfdData;
  bool _loadingDfd = true;

  String get _contractId => widget.contractData?.id?.trim() ?? '';

  double get _extensaoDfdMetros {
    return ((_dfdData?.extensaoKm ?? 0.0).toDouble()) * 1000.0;
  }

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

    _loadDfdData();
  }

  @override
  void didUpdateWidget(covariant TabBarAdditivePage oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldId = oldWidget.contractData?.id?.trim() ?? '';
    final newId = widget.contractData?.id?.trim() ?? '';

    if (oldId != newId) {
      setState(() {
        _dfdData = null;
        _loadingDfd = true;
      });

      _loadDfdData();
    }
  }

  String _resolveRequiredTenantId(PermissionState permissionState) {
    final tenantId = permissionState.activeTenantId?.trim();

    if (tenantId == null || tenantId.isEmpty) {
      throw ArgumentError(
        'tenantId é obrigatório para TabBarAdditivePage.',
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
      _loadingDfd = true;
    });

    _loadDfdData();
  }

  Future<void> _loadDfdData() async {
    final contractId = _contractId;

    if (contractId.isEmpty) {
      if (!mounted) return;

      setState(() {
        _dfdData = null;
        _loadingDfd = false;
      });

      return;
    }

    try {
      final dfd = await _dfdRepository.readDataForContract(contractId);

      if (!mounted) return;

      setState(() {
        _dfdData = dfd;
        _loadingDfd = false;
      });
    } catch (e, stack) {
      debugPrint('Falha ao carregar DFD no TabBarAdditivePage: $e');
      debugPrintStack(stackTrace: stack);

      if (!mounted) return;

      setState(() {
        _dfdData = null;
        _loadingDfd = false;
      });
    }
  }

  Widget _buildAdditiveTab(ContractData contract) {
    return AdditivePage(
      key: ValueKey<String>('additive_${contract.id ?? ""}'),
      contractData: contract,
    );
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

    if (_loadingDfd) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return BlocProvider<ScheduleLinearCubit>(
      key: ValueKey<String>(
        'additive-chronogram-$_activeTenantId-$contractId-${_dfdData?.extensaoKm ?? 0}',
      ),
      create: (_) {
        return ScheduleLinearCubit(
          repository: ScheduleLinearRepository(
            tenantId: _activeTenantId,
          ),
          tenantId: _activeTenantId,
        )..warmup(
          contractId: contractId,
          extensaoDfdMetros: _extensaoDfdMetros,
          initialServiceKey: ScheduleLinearServicesData.geralKey,
          summarySubjectContract: _textBanner,
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
        tabs: [
          ContractTabDescriptor(
            label: 'Aditivos',
            requireSavedContract: true,
            builder: (contract) {
              return _buildAdditiveTab(contract!);
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