// lib/screens/modules/planning/land/land_tabs.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/contract/contract_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';

import 'package:sipged/_blocs/modules/operation/schedule/expropriation/expropriation_cubit.dart';
import 'package:sipged/_blocs/modules/operation/schedule/expropriation/expropriation_repository.dart';

import 'package:sipged/_blocs/system/permission/permission_cubit.dart';
import 'package:sipged/_blocs/system/permission/permission_state.dart';

import 'package:sipged/_widgets/menu/tab/tab_changed_widget.dart';
import 'package:sipged/_widgets/menu/footBar/foot_bar.dart';
import 'package:sipged/_widgets/texts/section_text_name.dart';

import 'package:sipged/screens/modules/operation/expropriation/land_map.dart';
import 'package:sipged/screens/modules/operation/expropriation/land_property.dart';
import 'package:sipged/screens/modules/operation/expropriation/land_table.dart';
import 'package:sipged/_widgets/menu/tab/contract_tab_descriptor.dart';

class LandTabs extends StatefulWidget {
  final ContractData? contractData;
  final ContractCubit? contractsCubit;
  final int initialTabIndex;

  const LandTabs({
    super.key,
    this.contractData,
    this.contractsCubit,
    this.initialTabIndex = 0,
  });

  @override
  State<LandTabs> createState() => _LandTabsState();
}

class _LandTabsState extends State<LandTabs> {
  late ContractData? _contractData;
  String? _selectedPropertyId;

  String get _contractId => _contractData?.id?.trim() ?? '';

  @override
  void initState() {
    super.initState();
    _contractData = widget.contractData;
  }

  @override
  void didUpdateWidget(covariant LandTabs oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldContractId = oldWidget.contractData?.id?.trim() ?? '';
    final newContractId = widget.contractData?.id?.trim() ?? '';

    if (oldContractId != newContractId) {
      setState(() {
        _contractData = widget.contractData;
        _selectedPropertyId = null;
      });
    }
  }

  String? _normalizeId(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  String? _tenantIdFromState(PermissionState state) {
    final tenantId = state.activeTenantId?.trim();
    if (tenantId == null || tenantId.isEmpty) return null;
    return tenantId;
  }

  void _handlePropertySelected(String? propertyId) {
    setState(() {
      _selectedPropertyId = _normalizeId(propertyId);
    });
  }

  Widget _buildPlaceholder(String text) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        const FootBar(),
      ],
    );
  }


  Widget _buildPropertyTable({
    required String tenantId,
  }) {
    return LandTable(
      contractId: _contractId,
      selectedPropertyId: _selectedPropertyId,
      onPropertySelected: _handlePropertySelected,
    );
  }

  Widget _buildScrollableTab({
    required String tenantId,
    required String formTitle,
    required Widget form,
    String tableTitle = 'Imóveis cadastrados no sistema',
    bool showTable = true,
  }) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionTitle(text: formTitle),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: form,
                ),
                if (showTable) ...[
                  SectionTitle(text: tableTitle),
                  _buildPropertyTable(tenantId: tenantId),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        const FootBar(),
      ],
    );
  }

  Widget _buildMapTab() {
    final contractData = _contractData;

    if (contractData == null || _contractId.isEmpty) {
      return _buildPlaceholder(
        'Salve ou selecione um contrato para visualizar o mapa de imóveis.',
      );
    }

    return LandMap(
      contractData: contractData,
    );
  }

  Widget _buildPropertyTab({
    required String tenantId,
  }) {
    if (_contractId.isEmpty) {
      return _buildPlaceholder(
        'Salve ou selecione um contrato para cadastrar imóveis.',
      );
    }

    return BlocProvider<ExpropriationCubit>(
      key: ValueKey<String>(
        'land-property-$tenantId-$_contractId-${_selectedPropertyId ?? 'new'}',
      ),
      create: (_) => ExpropriationCubit(
        repository: ExpropriationRepository(
          tenantId: tenantId,
        ),
      ),
      child: _buildScrollableTab(
        tenantId: tenantId,
        formTitle: 'Cadastrar imóvel no sistema',
        form: LandProperty(
          contractId: _contractId,
          propertyId: _selectedPropertyId,
          onSavedPropertyId: _handlePropertySelected,
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PermissionCubit, PermissionState>(
      buildWhen: (previous, current) {
        return previous.activeTenantId != current.activeTenantId ||
            previous.current != current.current;
      },
      builder: (context, permissionState) {
        final tenantId = _tenantIdFromState(permissionState);

        if (tenantId == null) {
          return _buildPlaceholder(
            'Selecione uma empresa/tenant ativo para acessar a desapropriação.',
          );
        }

        return TabChanged(
          contractData: _contractData,
          contractsCubit: widget.contractsCubit,
          initialTabIndex: widget.initialTabIndex,
          tabs: [
            ContractTabDescriptor(
              label: 'Mapa',
              requireSavedContract: true,
              builder: (_) => _buildMapTab(),
            ),
            ContractTabDescriptor(
              label: 'Imóvel',
              requireSavedContract: true,
              builder: (_) => _buildPropertyTab(
                tenantId: tenantId,
              ),
            ),
          ],
        );
      },
    );
  }
}