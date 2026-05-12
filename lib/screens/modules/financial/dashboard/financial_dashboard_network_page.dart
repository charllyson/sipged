// lib/screens/modules/financial/dashboard/financial_dashboard_network_page.dart
// ajuste o caminho conforme onde esse arquivo está no seu projeto

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';

import 'package:sipged/_blocs/modules/financial/loa/loa_cubit.dart';
import 'package:sipged/_blocs/modules/financial/empenhos/empenho_cubit.dart';
import 'package:sipged/_blocs/modules/financial/dashboard/financial_dashboard_cubit.dart';
import 'package:sipged/_blocs/modules/financial/dashboard/financial_dashboard_state.dart';

import 'package:sipged/_blocs/system/permission/permission_cubit.dart';
import 'package:sipged/_blocs/system/permission/permission_state.dart';

import 'package:sipged/_widgets/loading/loading_tree_dots.dart';
import 'package:sipged/screens/modules/financial/dashboard/finance_dashboard_page.dart';

class FinancialDashboardNetworkPage extends StatefulWidget {
  const FinancialDashboardNetworkPage({
    super.key,
    this.contractData,
  });

  final ContractData? contractData;

  @override
  State<FinancialDashboardNetworkPage> createState() =>
      _FinancialDashboardNetworkPageState();
}

class _FinancialDashboardNetworkPageState
    extends State<FinancialDashboardNetworkPage> {
  final NumberFormat _currency = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );

  String get _contractId => widget.contractData?.id?.trim() ?? '';

  String _resolveRequiredTenantId(PermissionState permissionState) {
    final tenantId = permissionState.activeTenantId?.trim();

    if (tenantId == null || tenantId.isEmpty) {
      throw ArgumentError(
        'tenantId é obrigatório para FinancialDashboardNetworkPage.',
      );
    }

    return tenantId;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<PermissionCubit, PermissionState>(
      buildWhen: (previous, current) {
        return previous.activeTenantId != current.activeTenantId;
      },
      builder: (context, permissionState) {
        final tenantId = _resolveRequiredTenantId(permissionState);
        final contractId = _contractId;

        return MultiBlocProvider(
          key: ValueKey<String>(
            'financial-dashboard-network-$tenantId-$contractId',
          ),
          providers: [
            BlocProvider<EmpenhoCubit>(
              create: (_) {
                return EmpenhoCubit(
                  //tenantId: tenantId,
                );
              },
            ),
            BlocProvider<LOACubit>(
              create: (_) {
                return LOACubit(
                  //tenantId: tenantId,
                );
              },
            ),
            BlocProvider<FinancialDashboardCubit>(
              create: (_) {
                final cubit = FinancialDashboardCubit(
                  tenantId: tenantId,
                );

                if (contractId.isNotEmpty) {
                  cubit.loadByContract(contractId);
                } else {
                  cubit.loadAll();
                }

                return cubit;
              },
            ),
          ],
          child: BlocBuilder<FinancialDashboardCubit, FinancialDashboardState>(
            builder: (context, st) {
              final cubit = context.read<FinancialDashboardCubit>();

              if (st.status == FinancialDashboardStatus.loading &&
                  st.budgets.isEmpty &&
                  st.empenhos.isEmpty) {
                return const Center(
                  child: LoadingTreeDots(size: 110),
                );
              }

              if (st.status == FinancialDashboardStatus.failure &&
                  st.budgets.isEmpty &&
                  st.empenhos.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(st.error ?? 'Erro ao carregar dashboard.'),
                  ),
                );
              }

              final totals = cubit.computeTotals();
              final selected = cubit.selectedEmpenho;

              return FinancialDashboardPage(
                currency: _currency,
                theme: theme,
                budgets: st.budgets,
                empenhos: st.empenhos,
                selectedEmpenhoId: st.selectedEmpenhoId,
                selectedEmpenho: selected,
                onSelectEmpenho: cubit.selectEmpenho,
                totalOrcamento: totals.orcamento,
                totalEmpenhado: totals.empenhado,
                totalMedido: totals.medido,
                totalPago: totals.pago,
                totalSaldo: totals.saldo,
              );
            },
          ),
        );
      },
    );
  }
}