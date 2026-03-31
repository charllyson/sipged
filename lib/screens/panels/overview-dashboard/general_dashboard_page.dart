import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/panels/general_dashboard/general_dashboard_cubit.dart';
import 'package:sipged/_blocs/panels/general_dashboard/general_dashboard_state.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_data.dart';

import 'package:sipged/_blocs/modules/contracts/measurement/report/report_measurement_data.dart';

import 'package:sipged/_widgets/background/background_change.dart';
import 'package:sipged/_widgets/list/resume/list_resumed.dart';
import 'package:sipged/_widgets/cards/expandable/expandable_card.dart';
import 'package:sipged/_widgets/texts/divider_text.dart';
import 'package:sipged/_widgets/menu/upBar/up_bar.dart';

import 'package:sipged/screens/panels/overview-dashboard/measurement_contract_section.dart';
import 'package:sipged/screens/panels/overview-dashboard/measurement_selector_dates_section.dart';

import 'general_dashboard_type.dart';
import 'general_dashboard_status_services_region.dart';
import 'general_dashboard_company_actives.dart';
import 'general_dashboard_list.dart';
import 'general_dashboard_map.dart';
import 'general_dashboard_summary.dart';

class GeneralDashboardPage extends StatefulWidget {
  const GeneralDashboardPage({super.key});

  @override
  State<GeneralDashboardPage> createState() => _GeneralDashboardPageState();
}

class _GeneralDashboardPageState extends State<GeneralDashboardPage> {
  /// Lista de medições filtradas pelo seletor de ano/mês.
  List<ReportMeasurementData> _filteredMeasurements = [];

  /// Índice do ponto selecionado no gráfico de medições.
  int? _selectedPointIndex;

  /// Resumo do contrato selecionado (texto exibido na tabela/resumo).
  String? _selectedContractSummary;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: BackgroundChange()),
        BlocBuilder<GeneralDashboardCubit, GeneralDashboardState>(
          builder: (context, state) {
            final cubit = context.read<GeneralDashboardCubit>();

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const UpBar(),
                      const SizedBox(height: 8),
                      DividerText(
                        text: 'Resumo Geral dos Contratos',
                        subtitle: '2018 - ${DateTime.now().year}',
                      ),
                      const SizedBox(height: 8),
                      const GeneralDashboardSummary(),
                      const SizedBox(height: 12),

                      const GeneralDashboardTypeFiltered(),
                      const SizedBox(height: 12),

                      /// 🔹 Primeira linha de gráficos (por tipo/status/etc.)
                      GeneralDashboardStatusServicesRegion(cubit: cubit),
                      const SizedBox(height: 8),

                      /// 🔹 Segunda linha de gráficos (por região/empresa/etc.)
                      GeneralDashboardCompanyActives(cubit: cubit),
                      const SizedBox(height: 8),

                      DividerText(text: 'Mapa das Regionais'),
                      const SizedBox(height: 8),

                      /// 🔹 Mapa das regionais:
                      /// - selectedRegionNames: municípios filtrados (destaque forte)
                      /// - strongMunicipios: todos municípios que têm contratos (opacidade "forte")
                      /// - onRegionTap: filtra por município no Cubit
                      GeneralDashboardMap(
                        selectedRegionNames:
                        cubit.municipiosSelecionadosParaMapa,
                        strongMunicipios: cubit.municipiosComContratosGeral,
                        onRegionTap: (municipio) =>
                            cubit.onMunicipioSelected(municipio),
                      ),

                      const SizedBox(height: 8),

                      if (cubit.houveInteracaoComFiltros &&
                          state.filteredContracts.isNotEmpty)
                        ListResumed(contract: state.filteredContracts),

                      const SizedBox(height: 8),
                      DividerText(
                        text: 'Resumo das Medições',
                        subtitle: '2018 - ${DateTime.now().year}',
                      ),
                      const SizedBox(height: 8),

                      // ------------------------------------------------------------------
                      // Linha de resumo + seletor de datas
                      // ------------------------------------------------------------------
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
                              child: ExpandableCard(
                                title: 'Totais em medições',
                                subTitles: const [
                                  'Medição',
                                  'Reajuste',
                                  'Revisão',
                                ],
                                icon: Icons.bar_chart_rounded,
                                colorIcon: const Color(0xFF4C6BFF),
                                valoresIndividuais: [
                                  cubit.totaisMedicoes ?? 0,
                                  cubit.totaisReajustes ?? 0,
                                  cubit.totaisRevisoes ?? 0,
                                ],
                                loading: !state.initialized,
                                formatAsCurrency: true,
                              ),
                            ),
                            const SizedBox(width: 12),
                            MeasurementSelectorDatesSection(
                              allMeasurements: state.allMeasurements,
                              initialYear: state.selectedYear,
                              initialMonth: state.selectedMonth,
                              onSelectionChanged: (result) {
                                if (!mounted) return;

                                // Atualiza o filtro global (ano/mês) no Cubit
                                cubit.updateSelectedYearMonth(
                                  result.selectedYear,
                                  result.selectedMonth,
                                );

                                // Mantém o controle local das medições filtradas
                                setState(() {
                                  _filteredMeasurements = result.filteredItems;
                                  _selectedPointIndex = null;
                                  _selectedContractSummary = null;
                                });
                              },
                            ),
                            const SizedBox(width: 12),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // ------------------------------------------------------------------
                      // Gráfico de medições + seleção de contrato
                      // ------------------------------------------------------------------
                      MeasurementContractSection(
                        filteredMeasurements: _filteredMeasurements,
                        selectedIndex: _selectedPointIndex,
                        onPointTap: (index) async {
                          final measurement = _filteredMeasurements[index];
                          final contractId = measurement.contractId;

                          String resumo = 'Contrato não encontrado';

                          if (contractId != null && contractId.isNotEmpty) {
                            // Busca descrição do DFD (objeto do contrato)
                            final dfdCubit = context.read<DfdCubit>();
                            final DfdData? dfd = await dfdCubit
                                .getDataForContract(contractId);

                            resumo = dfd?.descricaoObjeto ??
                                'Contrato não encontrado';

                            // Mantém interação com o "store" de contratos, se existir
                            final contrato = await cubit.store.getById(
                              contractId,
                            );
                            if (contrato != null) {
                              cubit.store.select(contrato);
                            }
                          }

                          if (!mounted) return;
                          setState(() {
                            _selectedPointIndex = index;
                            _selectedContractSummary = resumo;
                          });
                        },
                      ),
                      const SizedBox(height: 8),

                      // ------------------------------------------------------------------
                      // Lista de resumo da medição selecionada
                      // ------------------------------------------------------------------
                      /// 🔹 Usa todos os ajustes e revisões já carregados no DemandsDashboardCubit,
                      /// sem depender mais de *Store* separado para reajustes/revisões.
                      GeneralDashboardList(
                        currentFiltered: _filteredMeasurements,
                        selectedPointIndex: _selectedPointIndex,
                        selectedContractSummary: _selectedContractSummary,
                        allAdjustments: state.allAdjustments,
                        allRevisions: state.allRevisions,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
