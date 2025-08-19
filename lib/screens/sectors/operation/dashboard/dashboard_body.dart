import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sisged/screens/sectors/operation/dashboard/charts_contract_section.dart';
import 'package:sisged/screens/sectors/operation/dashboard/resumed_measurement_card.dart';
import 'package:sisged/screens/sectors/operation/dashboard/summary_contract_section.dart';
import '../../../../_datas/documents/measurement/reports/report_measurement_data.dart';
import '../../../../_widgets/background/background_cleaner.dart';
import '../../../../_widgets/contractList/contract_list.dart';
import '../../../../_widgets/texts/divider_text.dart';
import '../../../commons/footBar/foot_bar.dart';
import '../../../commons/upBar/up_bar.dart';
import 'contract_type_filtered.dart';
import 'dashboard_controller.dart';
import 'list_contracts_section.dart';
import 'map_card_section.dart';
import 'measurement_contract_section.dart';
import 'measurement_selector_dates_section.dart';

class DashboardBody extends StatefulWidget {
  const DashboardBody({super.key});

  @override
  State<DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends State<DashboardBody> {
  List<ReportMeasurementData> filteredMeasurements = [];
  int? selectedPointIndex;
  String? selectedContractSummary;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DashboardController>();

    return Stack(
      children: [
        const BackgroundClean(),
        LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
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
                      DividerText(title: 'Mapa das Regionais'),
                      const SizedBox(height: 8),
                      MapContractSection(
                        geoManager: controller.geoManager,
                        selectedRegionNames: controller.selectedRegions,
                        onRegionTap: controller.onRegionSelected,
                      ),
                      const SizedBox(height: 8),
                      if (controller.houveInteracaoComFiltros && controller.filteredContracts.isNotEmpty)
                        ContractList(
                          contract: controller.filteredContracts,
                        ),
                      const SizedBox(height: 8),
                      DividerText(
                        title: 'Resumo das Medições',
                        subtitle: '2018 - ${DateTime.now().year}',
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ResumedMeasurementCards([
                            controller.totaisMedicoes,
                            controller.totaisReajustes,
                            controller.totaisRevisoes
                          ]),
                          MeasurementSelectorDatesSection(
                            allMeasurements: controller.allMeasurements,
                            initialYear: controller.selectedYear,
                            initialMonth: controller.selectedMonth,
                            onSelectionChanged: (result) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                setState(() {
                                  controller.selectedYear = result.selectedYear;
                                  controller.selectedMonth = result.selectedMonth;
                                  filteredMeasurements = result.filteredItems;
                                  selectedPointIndex = null;
                                  selectedContractSummary = null;
                                });
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      MeasurementContractSection(
                        filteredMeasurements: filteredMeasurements,
                        selectedIndex: selectedPointIndex,
                        onPointTap: (index) async {
                          final measurement = filteredMeasurements[index];
                          final contractId = measurement.contractId;

                          String? resumo;

                          if (contractId != null) {
                            final contrato = await controller.store.getById(contractId); // ⭐ usa o store (com cache)
                            resumo = contrato?.summarySubjectContract ?? 'Contrato não encontrado';

                            // (opcional) deixa o contrato selecionado globalmente p/ outras telas
                            if (contrato != null) {
                              controller.store.select(contrato);
                            }
                          }

                          setState(() {
                            selectedPointIndex = index;
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
                      const SizedBox(height: 12),
                      const Spacer(),
                      const FootBar(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
