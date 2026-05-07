import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/_process/process_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_repository.dart';

import 'package:sipged/_blocs/modules/financial/budget/budget_cubit.dart';
import 'package:sipged/_blocs/modules/financial/empenhos/empenho_cubit.dart';

import 'package:sipged/_widgets/menu/tab/tab_changed_widget.dart';

import 'package:sipged/screens/modules/financial/budget/budget_page.dart';
import 'package:sipged/screens/modules/financial/empenhos/empenho_page.dart';

class TabBarFinancialPage extends StatefulWidget {
  const TabBarFinancialPage({
    super.key,
    this.contractData,
    this.contractsCubit,
    this.initialTabIndex = 0,
  });

  final ProcessData? contractData;
  final ProcessCubit? contractsCubit;
  final int initialTabIndex;

  @override
  State<TabBarFinancialPage> createState() => _TabBarFinancialPageState();
}

class _TabBarFinancialPageState extends State<TabBarFinancialPage> {
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
  void didUpdateWidget(covariant TabBarFinancialPage oldWidget) {
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
      debugPrint('Falha ao carregar DFD no TabBarFinancialPage: $e');
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

  Widget _buildBudgetTab(ProcessData contract) {
    final contractId = contract.id?.trim() ?? '';

    return BlocProvider<BudgetCubit>(
      key: ValueKey('financial-budget-$contractId'),
      create: (_) => BudgetCubit(),
      child: BudgetPage(
        contractData: contract,
      ),
    );
  }

  Widget _buildEmpenhoTab(ProcessData contract) {
    final contractId = contract.id?.trim() ?? '';

    return BlocProvider<EmpenhoCubit>(
      key: ValueKey('financial-empenho-$contractId'),
      create: (_) => EmpenhoCubit(),
      child: EmpenhoPage(
        contractData: contract,
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
          label: 'Orçamento',
          requireSavedContract: true,
          builder: (c) => _buildBudgetTab(c!),
        ),
        ContractTabDescriptor(
          label: 'Empenhos',
          requireSavedContract: true,
          builder: (c) => _buildEmpenhoTab(c!),
        ),
      ],
    );
  }
}