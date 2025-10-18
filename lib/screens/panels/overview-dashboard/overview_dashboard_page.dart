import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:siged/_widgets/list/resume/list_resumed.dart';
import 'package:siged/_widgets/summary/summary_expandable_card.dart';
import 'package:siged/screens/panels/overview-dashboard/overview_dashboard_chart_row_two.dart';
import 'package:siged/screens/process/report/measurement_contract_section.dart';

import 'package:siged/screens/process/report/measurement_resumed_card.dart';

import 'package:siged/_blocs/process/report/report_measurement_data.dart';
import 'package:siged/_widgets/background/background_cleaner.dart';
import 'package:siged/_widgets/texts/divider_text.dart';
import 'package:siged/screens/process/report/measurement_selector_dates_section.dart';

import '../../../../_widgets/footBar/foot_bar.dart';
import '../../../../_widgets/upBar/up_bar.dart';

import 'overview_dashboard_type.dart';
import 'overview_dashboard_charts_row_one.dart';
import '../../../_blocs/process/contracts/contracts_controller.dart';
import 'overview_dashboard_list.dart';
import 'overview_dashboard_map.dart';
import 'overview_dashboard_summary.dart';

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
    final controller = context.watch<ContractsController>();

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

                  OverviewDashboardChartRowOne(controller: controller),
                  const SizedBox(height: 8),
                  OverviewDashboardChartRowTwo(controller: controller),
                  const SizedBox(height: 8),
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
                  if (controller.houveInteracaoComFiltros &&
                      controller.filteredContracts.isNotEmpty)
                    ListResumed(contract: controller.filteredContracts),
                  const SizedBox(height: 8),
                  DividerText(
                    title: 'Resumo das Medições',
                    subtitle: '2018 - ${DateTime.now().year}',
                  ),
                  const SizedBox(height: 8),
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
                            subTitles: ['Medição','Reajuste','Revisão'],
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
                        // Seletor de datas (sem Expanded/Flexible aqui!)
                        MeasurementSelectorDatesSection(
                          allMeasurements: controller.allMeasurements,
                          initialYear: controller.selectedYear,
                          initialMonth: controller.selectedMonth,
                          onSelectionChanged: (result) {
                            if (!mounted) return;
                            setState(() {
                              controller.selectedYear  = result.selectedYear;
                              controller.selectedMonth = result.selectedMonth;
                              filteredMeasurements     = result.filteredItems;
                              selectedPointIndex       = null;
                              selectedContractSummary  = null;
                            });
                          },
                        ),

                        const SizedBox(width: 12),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ------- Gráfico e lista -------
                  MeasurementContractSection(
                    filteredMeasurements: filteredMeasurements,
                    selectedIndex: selectedPointIndex,
                    onPointTap: (index) async {
                      final measurement = filteredMeasurements[index];
                      final contractId  = measurement.contractId;

                      String? resumo;
                      if (contractId != null) {
                        final contrato = await controller.store.getById(contractId);
                        resumo = contrato?.summarySubjectContract ?? 'Contrato não encontrado';
                        if (contrato != null) controller.store.select(contrato);
                      }

                      if (!mounted) return;
                      setState(() {
                        selectedPointIndex      = index;
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
