import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:siged/screens/commons/listResumed/list_resumed.dart';
import 'package:siged/screens/documents/contract/dashboard/dashboard_contracts_chart_second_section.dart';

import 'package:siged/screens/documents/measurement/dashboard/measurement_resumed_card.dart';

import 'package:siged/_blocs/documents/measurement/report/report_measurement_data.dart';
import 'package:siged/_widgets/background/background_cleaner.dart';
import 'package:siged/_widgets/texts/divider_text.dart';

import '../../../../_widgets/footBar/foot_bar.dart';
import '../../../../_widgets/upBar/up_bar.dart';

import 'dashboard_contracts__type.dart';
import 'dashboard_contracts_charts_section.dart';
import '../../../../_blocs/documents/contracts/contracts/contracts_controller.dart';
import 'dashboard_contracts_list.dart';
import 'dashboard_contracts_map_section.dart';
import '../../../documents/measurement/dashboard/measurement_contract_section.dart';
import '../../../documents/measurement/dashboard/measurement_selector_dates_section.dart';
import 'dashboard_contracts_summary_section.dart';

class DashboardContractPage extends StatefulWidget {
  const DashboardContractPage({super.key});

  @override
  State<DashboardContractPage> createState() => _DashboardContractPageState();
}

class _DashboardContractPageState extends State<DashboardContractPage> {
  List<ReportMeasurementData> filteredMeasurements = [];
  int? selectedPointIndex;
  String? selectedContractSummary;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ContractsController>();

    return Stack(
      children: [
        // Fundo ocupando toda a tela
        const Positioned.fill(child: BackgroundClean()),

        // Slivers para scroll estável no Web
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
                  const SummaryContractSection(),
                  const SizedBox(height: 12),

                  ContractTypeFiltered(controller: controller),
                  const SizedBox(height: 12),

                  ChartsContractSection(controller: controller),
                  const SizedBox(height: 8),
                  DashboardContractsChartSecondSection(controller: controller),
                  const SizedBox(height: 8),
                  DividerText(title: 'Mapa das Regionais'),
                  const SizedBox(height: 8),

                  // ✅ Mapa com constraints finitas (evita w=Infinity)
                  SizedBox(
                    width: double.infinity,
                    height: 360, // ajuste conforme layout
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: MapContractSection(
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

                  // ------- Resumo das Medições -------
                  DividerText(
                    title: 'Resumo das Medições',
                    subtitle: '2018 - ${DateTime.now().year}',
                  ),
                  const SizedBox(height: 8),

                  // ✅ “Linha” toda com scroll horizontal e altura fixa
                  SizedBox(
                    height: 120,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Cards de resumo
                          MeasurementResumedCards([
                            controller.totaisMedicoes,
                            controller.totaisReajustes,
                            controller.totaisRevisoes,
                          ]),

                          const SizedBox(width: 12),

                          // Seletor de datas (sem Expanded/Flexible aqui!)
                          MeasurementSelectorDatesSection(
                            allMeasurements: controller.allMeasurements,
                            initialYear: controller.selectedYear,
                            initialMonth: controller.selectedMonth,
                            onSelectionChanged: (result) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (!mounted) return;
                                setState(() {
                                  controller.selectedYear  = result.selectedYear;
                                  controller.selectedMonth = result.selectedMonth;
                                  filteredMeasurements     = result.filteredItems;
                                  selectedPointIndex       = null;
                                  selectedContractSummary  = null;
                                });
                              });
                            },
                          ),

                          const SizedBox(width: 12),
                        ],
                      ),
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

                  ListContractsSection(
                    currentFiltered: filteredMeasurements,
                    selectedPointIndex: selectedPointIndex,
                    selectedContractSummary: selectedContractSummary,
                  ),
                ],
              ),
            ),

            // Preenche o restante e fixa o rodapé ao fundo
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                children: const [
                  Spacer(),
                  FootBar(),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
