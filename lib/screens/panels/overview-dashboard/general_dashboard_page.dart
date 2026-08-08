// lib/screens/panels/overview-dashboard/general_dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sipged/_utils/formatters/sipged_format_money.dart';
import 'package:sipged/_widgets/texts/divider_text.dart';

import 'package:sipged/_blocs/panels/general_dashboard/general_dashboard_cubit.dart';
import 'package:sipged/_blocs/panels/general_dashboard/general_dashboard_state.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_data.dart';

import 'package:sipged/_blocs/modules/contracts/measurement/report/report_executed_data.dart';

import 'package:sipged/_blocs/system/permission/permission_cubit.dart';

import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_widgets/cards/expandable/expandable_card.dart';
 import 'package:sipged/_widgets/menu/upBar/up_bar.dart';

import 'package:sipged/screens/panels/overview-dashboard/list_resumed.dart';

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
  List<ReportExecutedData> _filteredMeasurements = [];
  int? _selectedPointIndex;
  String? _selectedContractSummary;

  int _lastMeasurementsLength = -1;
  int? _lastSelectedYear;
  int? _lastSelectedMonth;

  List<ReportExecutedData> _applyMeasurementDateFilter({
    required List<ReportExecutedData> allMeasurements,
    required int? selectedYear,
    required int? selectedMonth,
  }) {
    if (selectedYear == null && selectedMonth == null) {
      return List<ReportExecutedData>.from(allMeasurements);
    }

    return allMeasurements.where((item) {
      final date = item.date;

      if (date == null) {
        return false;
      }

      final sameYear = selectedYear == null || date.year == selectedYear;
      final sameMonth = selectedMonth == null || date.month == selectedMonth;

      return sameYear && sameMonth;
    }).toList();
  }

  void _syncMeasurementsFromState(GeneralDashboardState state) {
    final currentLength = state.allMeasurements.length;
    final currentYear = state.selectedYear;
    final currentMonth = state.selectedMonth;

    final shouldSync = currentLength != _lastMeasurementsLength ||
        currentYear != _lastSelectedYear ||
        currentMonth != _lastSelectedMonth;

    if (!shouldSync) {
      return;
    }

    _lastMeasurementsLength = currentLength;
    _lastSelectedYear = currentYear;
    _lastSelectedMonth = currentMonth;

    _filteredMeasurements = _applyMeasurementDateFilter(
      allMeasurements: state.allMeasurements,
      selectedYear: currentYear,
      selectedMonth: currentMonth,
    );

    _selectedPointIndex = null;
    _selectedContractSummary = null;
  }

  String _activeTenantId(BuildContext context) {
    try {
      final activeTenantId =
          context.read<PermissionCubit>().state.activeTenantId;

      return (activeTenantId ?? '').trim();
    } catch (_) {
      return '';
    }
  }

  Widget _buildFilteredContractsSection({
    required BuildContext context,
    required GeneralDashboardCubit cubit,
    required GeneralDashboardState state,
  }) {
    final houveInteracao = cubit.houveInteracaoComFiltros;
    final contratosFiltrados = state.filteredContracts;
    final tenantId = _activeTenantId(context);

    if (!houveInteracao) {
      return const SizedBox.shrink();
    }

    if (tenantId.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Card(
          color: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFB45309),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tenant ativo não encontrado. Não foi possível carregar os detalhes dos contratos filtrados.',
                    style: TextStyle(
                      color: Color(0xFF92400E),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (contratosFiltrados.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Card(
          color: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(
                  Icons.search_off_rounded,
                  color: Color(0xFF64748B),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Nenhum contrato encontrado para os filtros selecionados.',
                    style: TextStyle(
                      color: Color(0xFF334155),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListResumed(
      tenantId: tenantId,
      contract: contratosFiltrados,
    );
  }

  Future<String> _loadContractSummaryForMeasurement({
    required String tenantId,
    required String contractId,
  }) async {
    final cleanTenantId = tenantId.trim();
    final cleanContractId = contractId.trim();

    if (cleanTenantId.isEmpty || cleanContractId.isEmpty) {
      return 'Contrato não encontrado';
    }

    final dfdCubit = DfdCubit(
      tenantId: cleanTenantId,
    );

    try {
      final DfdData? dfd = await dfdCubit.getDataForContract(
        cleanContractId,
      );

      final descricao = (dfd?.descricaoObjeto ?? '').trim();

      if (descricao.isEmpty) {
        return 'Contrato não encontrado';
      }

      return descricao;
    } catch (_) {
      return 'Contrato não encontrado';
    } finally {
      await dfdCubit.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: BackgroundChange(),
        ),
        BlocConsumer<GeneralDashboardCubit, GeneralDashboardState>(
          listenWhen: (previous, current) {
            return previous.allMeasurements.length !=
                current.allMeasurements.length ||
                previous.allAdjustments.length != current.allAdjustments.length ||
                previous.allRevisions.length != current.allRevisions.length ||
                previous.selectedYear != current.selectedYear ||
                previous.selectedMonth != current.selectedMonth ||
                previous.initialized != current.initialized ||
                previous.isLoading != current.isLoading ||
                previous.filteredContracts.length !=
                    current.filteredContracts.length;
          },
          listener: (context, state) {
            setState(() {
              _syncMeasurementsFromState(state);
            });
          },
          builder: (context, state) {
            final cubit = context.read<GeneralDashboardCubit>();

            if (_lastMeasurementsLength == -1) {
              _syncMeasurementsFromState(state);
            }

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

                      GeneralDashboardStatusServicesRegion(
                        cubit: cubit,
                      ),

                      const SizedBox(height: 8),

                      GeneralDashboardCompanyActives(
                        cubit: cubit,
                      ),

                      const SizedBox(height: 8),

                      DividerText(
                        text: 'Mapa das Regionais',
                      ),

                      const SizedBox(height: 8),

                      GeneralDashboardMap(
                        selectedRegionNames:
                        cubit.municipiosSelecionadosParaMapa,
                        strongMunicipios: cubit.municipiosComContratosGeral,
                        onRegionTap: (municipio) {
                          cubit.onMunicipioSelected(municipio);
                        },
                      ),

                      const SizedBox(height: 8),

                      _buildFilteredContractsSection(
                        context: context,
                        cubit: cubit,
                        state: state,
                      ),

                      const SizedBox(height: 8),

                      DividerText(
                        text: 'Resumo das Medições',
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
                                loading: !state.initialized || state.isLoading,
                                formatAsCurrency: true,
                                valueFormatter: SipGedFormatMoney.doubleToText,
                              ),
                            ),

                            const SizedBox(width: 12),

                            MeasurementSelectorDatesSection(
                              allMeasurements: state.allMeasurements,
                              initialYear: state.selectedYear,
                              initialMonth: state.selectedMonth,
                              onSelectionChanged: (result) {
                                if (!mounted) return;

                                cubit.updateSelectedYearMonth(
                                  result.selectedYear,
                                  result.selectedMonth,
                                );

                                setState(() {
                                  _filteredMeasurements =
                                  List<ReportExecutedData>.from(
                                    result.filteredItems,
                                  );

                                  _selectedPointIndex = null;
                                  _selectedContractSummary = null;

                                  _lastSelectedYear = result.selectedYear;
                                  _lastSelectedMonth = result.selectedMonth;
                                  _lastMeasurementsLength =
                                      state.allMeasurements.length;
                                });
                              },
                            ),

                            const SizedBox(width: 12),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      MeasurementContractSection(
                        filteredMeasurements: _filteredMeasurements,
                        selectedIndex: _selectedPointIndex,
                        onPointTap: (index) async {
                          if (index < 0 ||
                              index >= _filteredMeasurements.length) {
                            return;
                          }

                          final measurement = _filteredMeasurements[index];
                          final contractId = measurement.contractId?.trim();
                          final currentTenantId = _activeTenantId(context);

                          String resumo = 'Contrato não encontrado';

                          if (contractId != null &&
                              contractId.isNotEmpty &&
                              currentTenantId.isNotEmpty) {
                            resumo = await _loadContractSummaryForMeasurement(
                              tenantId: currentTenantId,
                              contractId: contractId,
                            );

                            final contrato =
                            await cubit.processCubit.getById(contractId);

                            if (contrato != null) {
                              cubit.processCubit.select(contrato);
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