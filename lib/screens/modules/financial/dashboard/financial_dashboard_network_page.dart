import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';

// Cubits
import 'package:sipged/_blocs/modules/financial/budget/budget_cubit.dart';
import 'package:sipged/_blocs/modules/financial/empenhos/empenho_cubit.dart';
import 'package:sipged/_blocs/modules/financial/dashboard/financial_dashboard_cubit.dart';
import 'package:sipged/_blocs/modules/financial/dashboard/financial_dashboard_state.dart';

// ✅ DFD cubit (para valorDemanda)
import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_cubit.dart';

// UI
import 'package:sipged/_widgets/menu/footBar/foot_bar.dart';
import 'package:sipged/screens/modules/financial/dashboard/finance_dashboard_page.dart';

class FinancialDashboardNetworkPage extends StatefulWidget {
  final ProcessData? contractData;

  const FinancialDashboardNetworkPage({
    super.key,
    this.contractData,
  });

  @override
  State<FinancialDashboardNetworkPage> createState() =>
      _FinancialDashboardNetworkPageState();
}

class _FinancialDashboardNetworkPageState
    extends State<FinancialDashboardNetworkPage> {
  final NumberFormat _currency =
  NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MultiBlocProvider(
      providers: [
        BlocProvider<EmpenhoCubit>(
          create: (_) => EmpenhoCubit(),
        ),
        BlocProvider<BudgetCubit>(
          create: (_) => BudgetCubit(),
        ),

        // ✅ DashboardCubit (consome repos e consulta DFD/aditivos/apostilas)
        BlocProvider<FinancialDashboardCubit>(
          create: (ctx) {
            final c = FinancialDashboardCubit(
              dfdCubit: ctx.read<DfdCubit>(), // usa o DfdCubit já injetado no app
            );

            final contractId = widget.contractData?.id?.trim() ?? '';
            if (contractId.isNotEmpty) {
              c.loadByContract(contractId);
            } else {
              c.loadAll();
            }
            return c;
          },
        ),
      ],
      child: Scaffold(
        body: BlocBuilder<FinancialDashboardCubit, FinancialDashboardState>(
          builder: (context, st) {
            final cubit = context.read<FinancialDashboardCubit>();

            // loading "duro" só quando não tem nada ainda
            if (st.status == FinancialDashboardStatus.loading &&
                st.budgets.isEmpty &&
                st.empenhos.isEmpty) {
              return const Center(child: CircularProgressIndicator());
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

            return Column(
              children: [
                Expanded(
                  child: FinancialDashboardPage(
                    currency: _currency,
                    theme: theme,
                    budgets: st.budgets,
                    empenhos: st.empenhos,
                    selectedEmpenhoId: st.selectedEmpenhoId,
                    selectedEmpenho: selected,
                    onSelectEmpenho: cubit.selectEmpenho,
                    totalOrcamento: totals.orcamento,
                    totalEmpenhado: totals.empenhado,
                    totalMedido: totals.medido, // 0 por enquanto
                    totalPago: totals.pago, // 0 por enquanto
                    totalSaldo: totals.saldo,
                  ),
                ),
                const FootBar(),
              ],
            );
          },
        ),
      ),
    );
  }
}
