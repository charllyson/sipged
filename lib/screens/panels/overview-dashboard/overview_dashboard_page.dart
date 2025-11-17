import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:siged/_blocs/panels/overview-dashboard/demands_dashboard_controller.dart';
import 'package:siged/_widgets/list/resume/list_resumed.dart';
import 'package:siged/_widgets/summary/summary_expandable_card.dart';
import 'package:siged/screens/panels/overview-dashboard/overview_dashboard_chart_row_two.dart';
import 'package:siged/screens/panels/measurement/measurement_contract_section.dart';

import 'package:siged/_blocs/process/report/report_measurement_data.dart';
import 'package:siged/_widgets/background/background_cleaner.dart';
import 'package:siged/_widgets/texts/divider_text.dart';
import 'package:siged/screens/panels/measurement/measurement_selector_dates_section.dart';
import 'package:siged/_widgets/upBar/up_bar.dart';

import 'overview_dashboard_type.dart';
import 'overview_dashboard_charts_row_one.dart';
import 'overview_dashboard_list.dart';
import 'overview_dashboard_map.dart';
import 'overview_dashboard_summary.dart';

// 🔹 DFD via BLoC para pegar descricaoObjeto
import 'package:siged/_blocs/process/hiring/1Dfd/dfd_bloc.dart';
import 'package:siged/_blocs/process/hiring/1Dfd/dfd_data.dart';

class OverviewDashboardPage extends StatefulWidget {
  const OverviewDashboardPage({super.key});

  @override
  State<OverviewDashboardPage> createState() => _OverviewDashboardPageState();
}

class _OverviewDashboardPageState extends State<OverviewDashboardPage> {
  List<ReportMeasurementData> filteredMeasurements = [];
  int? selectedPointIndex;
  String? selectedContractSummary;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DemandsDashboardController>();

    return Stack(
      children: [
        const Positioned.fill(child: BackgroundClean()),
        CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const UpBar(),
                  const SizedBox(height: 8),
                  DividerText(
                    title: 'Resumo Geral dos Contratos',
                    subtitle: '2018 - ${DateTime.now().year}',
                  ),
                  const SizedBox(height: 8),
                  const OverviewDashboardSummary(),
                  const SizedBox(height: 12),
                  OverviewDashboardTypeFiltered(controller: controller),
                  const SizedBox(height: 12),

                  /// Linha 1 – gráficos principais
                  OverviewDashboardChartRowOne(controller: controller),
                  const SizedBox(height: 8),

                  /// Linha 2 – gráficos secundários
                  OverviewDashboardChartRowTwo(controller: controller),
                  const SizedBox(height: 8),

                  /// Mapa de regionais
                  DividerText(title: 'Mapa das Regionais'),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 360,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: OverviewDashboardMap(
                        geoManager: controller.geoManager,
                        selectedRegionNames: controller.selectedRegions,
                        onRegionTap: controller.onRegionSelected,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  /// Lista resumida de contratos filtrados
                  if (controller.houveInteracaoComFiltros &&
                      controller.filteredContracts.isNotEmpty)
                    ListResumed(contract: controller.filteredContracts),

                  const SizedBox(height: 8),
                  DividerText(
                    title: 'Resumo das Medições',
                    subtitle: '2018 - ${DateTime.now().year}',
                  ),
                  const SizedBox(height: 8),

                  /// Cards de totais + seletor de datas
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedSize(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          child: SummaryExpandableCard(
                            title: 'Totais em medições',
                            subTitles: const ['Medição', 'Reajuste', 'Revisão'],
                            icon: Icons.bar_chart_rounded,
                            colorIcon: const Color(0xFF4C6BFF),
                            valoresIndividuais: [
                              controller.totaisMedicoes,
                              controller.totaisReajustes,
                              controller.totaisRevisoes,
                            ],
                            loading: !controller.initialized,
                            formatAsCurrency: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        MeasurementSelectorDatesSection(
                          allMeasurements: controller.allMeasurements,
                          initialYear: controller.selectedYear,
                          initialMonth: controller.selectedMonth,
                          onSelectionChanged: (result) {
                            if (!mounted) return;
                            setState(() {
                              controller.selectedYear = result.selectedYear;
                              controller.selectedMonth = result.selectedMonth;
                              filteredMeasurements = result.filteredItems;
                              selectedPointIndex = null;
                              selectedContractSummary = null;
                            });
                          },
                        ),
                        const SizedBox(width: 12),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  /// Gráfico + lista de medições
                  MeasurementContractSection(
                    filteredMeasurements: filteredMeasurements,
                    selectedIndex: selectedPointIndex,
                    onPointTap: (index) async {
                      final measurement = filteredMeasurements[index];
                      final contractId = measurement.contractId;

                      String resumo = 'Contrato não encontrado';

                      if (contractId != null && contractId.isNotEmpty) {
                        // 🔹 Busca o DFD para usar descricaoObjeto como resumo
                        final dfdBloc = context.read<DfdBloc>();
                        final DfdData? dfd =
                        await dfdBloc.getDataForContract(contractId);

                        resumo = dfd?.descricaoObjeto ?? 'Contrato não encontrado';

                        // Continua selecionando o contrato no store,
                        // mas sem usar campos legados.
                        final contrato =
                        await controller.store.getById(contractId);
                        if (contrato != null) {
                          controller.store.select(contrato);
                        }
                      }

                      if (!mounted) return;
                      setState(() {
                        selectedPointIndex = index;
                        selectedContractSummary = resumo;
                      });
                    },
                  ),
                  const SizedBox(height: 8),

                  OverviewDashboardList(
                    currentFiltered: filteredMeasurements,
                    selectedPointIndex: selectedPointIndex,
                    selectedContractSummary: selectedContractSummary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
