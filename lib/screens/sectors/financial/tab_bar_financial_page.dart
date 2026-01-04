// lib/screens/sectors/financial/tab_bar_financial_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:siged/_blocs/_process/process_bloc.dart';
import 'package:siged/_blocs/_process/process_data.dart';

import 'package:siged/_blocs/sectors/financial/budget/budget_cubit.dart';
import 'package:siged/_blocs/sectors/financial/empenhos/empenho_cubit.dart';

// ✅ NOVO: Dashboard cubit/state
import 'package:siged/_blocs/sectors/financial/dashboard/financial_dashboard_cubit.dart';
import 'package:siged/_blocs/sectors/financial/dashboard/financial_dashboard_state.dart';

import 'package:siged/_widgets/menu/tab/tab_changed_widget.dart';

import 'package:siged/screens/sectors/financial/budget/budget_page.dart';
import 'package:siged/screens/sectors/financial/dashboard/finance_dashboard_page.dart';
import 'package:siged/screens/sectors/financial/empenhos/empenho_page.dart';

import 'package:siged/screens/sectors/financial/payments/report/payment_report_page.dart';
import 'package:siged/screens/sectors/financial/payments/adjustment/payment_adjustment_page.dart';
import 'package:siged/screens/sectors/financial/payments/revision/payment_revision_page.dart';

class TabBarFinancialPage extends StatefulWidget {
  final ProcessData? contractData;
  final ProcessBloc? contractsBloc;
  final int initialTabIndex;

  const TabBarFinancialPage({
    super.key,
    this.contractData,
    this.contractsBloc,
    this.initialTabIndex = 0,
  });

  @override
  State<TabBarFinancialPage> createState() => _TabBarFinancialPageState();
}

class _TabBarFinancialPageState extends State<TabBarFinancialPage> {
  final _currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MultiProvider(
      providers: [
        BlocProvider<EmpenhoCubit>(
          create: (_) => EmpenhoCubit(),
        ),
        BlocProvider<BudgetCubit>(
          create: (_) => BudgetCubit(),
        ),

        // ✅ DashboardCubit (consome repos de Budget/Empenho)
        BlocProvider<FinancialDashboardCubit>(
          create: (_) {
            final c = FinancialDashboardCubit();

            // ✅ Carrega por contrato quando existir
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
      child: TabChangedWidget(
        contractData: widget.contractData,
        contractsBloc: widget.contractsBloc,
        initialTabIndex: widget.initialTabIndex,
        tabs: [
          // =======================
          // DASHBOARD (SEM TXS)
          // =======================
          ContractTabDescriptor(
            label: "Dashboard",
            requireSavedContract: false,
            builder: (_) {
              return BlocBuilder<FinancialDashboardCubit, FinancialDashboardState>(
                builder: (context, st) {
                  final cubit = context.read<FinancialDashboardCubit>();
                  final totals = cubit.computeTotals();

                  final selected = cubit.selectedEmpenho;

                  // loading / erro simples (não travar UI)
                  if (st.status == FinancialDashboardStatus.loading &&
                      (st.budgets.isEmpty && st.empenhos.isEmpty)) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (st.status == FinancialDashboardStatus.failure &&
                      (st.budgets.isEmpty && st.empenhos.isEmpty)) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(st.error ?? 'Erro ao carregar dashboard.'),
                      ),
                    );
                  }

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
                    totalMedido: totals.medido, // 0 por enquanto
                    totalPago: totals.pago,     // 0 por enquanto
                    totalSaldo: totals.saldo,
                  );
                },
              );
            },
          ),

          // =======================
          // ORÇAMENTO
          // =======================
          ContractTabDescriptor(
            label: "Orçamento",
            requireSavedContract: false,
            builder: (c) => BudgetPage(contractData: c),
          ),

          // =======================
          // EMPENHOS
          // =======================
          ContractTabDescriptor(
            label: "Empenhos",
            builder: (c) => EmpenhoPage(contractData: c),
          ),

          // =======================
          // BOLETIM / APOSTIL / REVISÕES
          // =======================
          ContractTabDescriptor(
            label: 'Boletim',
            requireSavedContract: false,
            builder: (c) => PaymentReportPage(contractData: c),
          ),
          ContractTabDescriptor(
            label: 'Apostilamentos',
            requireSavedContract: true,
            builder: (c) => PaymentAdjustmentPage(contractData: c!),
          ),
          ContractTabDescriptor(
            label: 'Revisões',
            requireSavedContract: true,
            builder: (c) => PaymentRevisionPage(contractData: c!),
          ),
        ],
      ),
    );
  }
}
