import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

// ===== SIGED: Models / Stores / Controllers =====
import 'package:siged/_blocs/_process/process_data.dart';
import 'package:siged/_blocs/_process/process_controller.dart';
import 'package:siged/_blocs/panels/overview-dashboard/demands_dashboard_controller.dart';

import 'package:siged/_blocs/process/additives/additive_data.dart';
import 'package:siged/_blocs/process/adjustment/adjustment_measurement_store.dart';
import 'package:siged/_blocs/process/revision/revision_measurement_store.dart';
import 'package:siged/_blocs/process/report/report_measurement_data.dart';

// Road schedule
import 'package:siged/_blocs/sectors/operation/road/schedule_road_bloc.dart';
import 'package:siged/_blocs/sectors/operation/road/schedule_road_state.dart';

// Store de cronograma físico-financeiro
import 'package:siged/_blocs/process/phys_fin/physics_finance_controller.dart';
import 'package:siged/_widgets/schedule/physical_financial/physfin_models.dart';
import 'package:siged/_blocs/process/phys_fin/physics_finance_store.dart';

// Validity (para início da obra)
import 'package:siged/_blocs/process/validity/validity_store.dart';
import 'package:siged/_blocs/process/validity/validity_data.dart';

// ===== Widgets / Seções auxiliares =====
import 'package:siged/_widgets/background/background_cleaner.dart';
import 'package:siged/_widgets/buttons/back_circle_button.dart';
import 'package:siged/_widgets/summary/summary_expandable_card.dart';
import 'package:siged/_widgets/texts/divider_text.dart';
import 'package:siged/_widgets/footBar/foot_bar.dart';
import 'package:siged/_widgets/upBar/up_bar.dart';
import 'package:siged/_widgets/menu/tab/tab_banner.dart';

// Kits
import 'package:siged/_widgets/kit/alert_rules/alert_rules.dart';
import 'package:siged/_widgets/kit/curva_s_chart/curva_s_chart.dart';
import 'package:siged/_widgets/kit/evm_calculator/evm_calculator.dart';
import 'package:siged/_widgets/kit/evm_calculator/evm_summary_card.dart';
import 'package:siged/_widgets/kit/health_score_card/health_score_card.dart';
import 'package:siged/_widgets/kit/rule/cost_per_km_ruler.dart';

// Linha de charts
import 'package:siged/screens/panels/specific-dashboard/specific_dashboard_charts_row_one.dart';

// Seções auxiliares
import 'package:siged/screens/panels/measurement/measurement_selector_dates_section.dart';
import 'package:siged/screens/panels/overview-dashboard/overview_dashboard_list.dart';

// Timeline
import 'package:siged/_widgets/timeline/timeline_class.dart';

// ===== DFD via BLoC (tipo/extensão/descricaoObjeto) =====
import 'package:siged/_blocs/process/hiring/1Dfd/dfd_bloc.dart';
import 'package:siged/_blocs/process/hiring/1Dfd/dfd_data.dart';

class SpecificDashboardPage extends StatefulWidget {
  const SpecificDashboardPage({
    super.key,
    required this.contractData,
  });

  final ProcessData contractData;

  @override
  State<SpecificDashboardPage> createState() => _SpecificDashboardPageState();
}

class _SpecificDashboardPageState extends State<SpecificDashboardPage> {
  List<ReportMeasurementData> filteredMeasurements = [];
  int? selectedPointIndex;
  String? selectedContractSummary;

  // ===== estado da Curva S (PV múltiplo) =====
  bool _loadingPv = false;
  List<CurvaSPvSeries> _pvMulti = const <CurvaSPvSeries>[];
  String _pvSignature = '';

  // ===== TIMELINE: futures memorizados =====
  late Future<List<ValidityData>> _futureValidity;
  late Future<List<ProcessData>> _futureContractList;
  late Future<List<AdditiveData>> _futureAdditiveList;
  bool _timelineInitialized = false;

  // ===== DFD: extensão e tipo de obra (carregados via BLoC) =====
  double? _extKmDfd;
  String? _tipoObraDfd;
  bool _dfdLoaded = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _loadExtentFromDfd(BuildContext context) async {
    final cid = widget.contractData.id ?? '';
    if (cid.isEmpty) return;
    try {
      final dfdBloc = context.read<DfdBloc>();
      final DfdData? dfd = await dfdBloc.getDataForContract(cid);
      if (!mounted) return;
      setState(() {
        _extKmDfd = dfd?.extensaoKm;
        _tipoObraDfd = dfd?.tipoObra;
      });
    } catch (_) {
      // mantém nulo se falhar
    }
  }

  double _totalContratadoMaisAA(
      DemandsDashboardController controller,
      ProcessData k,
      ) {
    final id = k.id ?? '';
    final contratado = (k.initialValueContract ?? 0).toDouble();

    final aditivos = controller.additivesStore.all
        .where((a) => (a.contractId?.toString() ?? '') == id)
        .fold<double>(0.0, (acc, a) => acc + (a.additiveValue ?? 0.0));

    final apostilas = controller.apostillesStore.all
        .where((p) => (p.contractId?.toString() ?? '') == id)
        .fold<double>(0.0, (acc, p) => acc + (p.apostilleValue ?? 0.0));

    return contratado + aditivos + apostilas;
  }

  Map<String, double>? _benchmarksDoServico(
      DemandsDashboardController controller,
      ProcessData c,
      ) {
    // Mantido nulo por enquanto; benchmarks dependem do tipo/serviço
    return null;
  }

  DateTime? _getStartDate(String contractId) {
    try {
      final store = context.read<ValidityStore>();
      store.ensureFor(contractId);
      final list = store.listFor(contractId);
      DateTime? start;
      for (final v in list) {
        final t = (v.ordertype ?? '')
            .toUpperCase()
            .replaceAll('Í', 'I')
            .replaceAll('Á', 'A')
            .replaceAll('Ã', 'A')
            .replaceAll('É', 'E')
            .replaceAll('Ê', 'E')
            .replaceAll('Ç', 'C');
        if (t.contains('INICIO')) {
          start = v.orderdate;
          break;
        }
      }
      return start;
    } catch (_) {
      return null;
    }
  }

  List<int> _sliceDays(int total) {
    if (total <= 0) return const <int>[];
    final out = <int>[];
    int acc = 30;
    while (acc < total) {
      out.add(acc);
      acc += 30;
    }
    if (out.isEmpty || out.last != total) out.add(total);
    return out;
  }

  List<DateTime> _datesFromAdditiveDays({
    required DateTime start,
    required int additiveExecDays,
  }) {
    final slices = _sliceDays(additiveExecDays);
    return [for (final d in slices) start.add(Duration(days: d))];
  }

  List<DateTime> _datesFromBasePvDays({
    required DateTime start,
    required List<int> pvDays,
  }) =>
      [for (final d in pvDays) start.add(Duration(days: d))];

  Future<void> _refreshPv({
    required DemandsDashboardController controller,
    required ScheduleRoadState scheduleState,
    required ProcessData contract,
  }) async {
    if (!mounted) return;

    final physStore = context.read<PhysicsFinanceStore>();

    final List<int> pvDays = scheduleState.physfinPeriods.isNotEmpty
        ? List<int>.from(scheduleState.physfinPeriods)
        : const <int>[];

    final pvDaysSig = pvDays.join(',');
    final gridSig = scheduleState.physfinGrid.entries
        .map((e) => '${e.key}:${e.value.join("|")}')
        .join(';');
    final servicesSig = scheduleState.services.map((s) => s.key).join(',');

    final additives = controller.additivesStore.listFor(contract.id ?? '');
    final addsSig = additives
        .map((a) =>
    '${a.id}|${a.additiveOrder}|${a.typeOfAdditive}|${(a.additiveValue ?? 0)}|${a.additiveValidityExecutionDays ?? 0}')
        .join(';');

    final signature = '$pvDaysSig#$gridSig#$servicesSig#$addsSig';
    if (signature == _pvSignature && _pvMulti.isNotEmpty) return;

    setState(() {
      _pvSignature = signature;
      _loadingPv = true;
    });

    final List<CurvaSPvSeries> pvMulti = [];

    final services =
    scheduleState.services.where((s) => s.key != 'geral').toList();
    final List<PhysFinRow> rows = PhysicsFinanceController.buildRows(
      services: services,
      serviceTotals: scheduleState.serviceTotals,
      localGrid: scheduleState.physfinGrid,
      periods: pvDays.length,
    );

    List<double> _normList(List<double> raw, int nCols) {
      if (raw.length == nCols) return raw;
      if (raw.length > nCols) return raw.sublist(0, nCols);
      return [...raw, ...List<double>.filled(nCols - raw.length, 0.0)];
    }

    final cid = contract.id ?? '';
    final startDate = (cid.isNotEmpty) ? _getStartDate(cid) : null;
    final List<DateTime> baseDates =
    (startDate != null && pvDays.isNotEmpty)
        ? _datesFromBasePvDays(start: startDate, pvDays: pvDays)
        : const <DateTime>[];

    // 1) PV contratado
    List<double> contratadoPV;
    if (pvDays.isEmpty || scheduleState.services.isEmpty) {
      contratadoPV = const <double>[];
    } else {
      final totals = scheduleState.serviceTotals;
      final gridBase = scheduleState.physfinGrid;

      final int nCols = pvDays.length;
      final soma = List<double>.filled(nCols, 0.0);

      for (final s in services) {
        final key = s.key;
        final valorServico = (totals[key] ?? 0.0).toDouble();
        final raw = List<double>.from(gridBase[key] ?? const <double>[]);
        final rowPerc = _normList(raw, nCols);
        for (int j = 0; j < nCols; j++) {
          soma[j] += valorServico * (rowPerc[j] / 100.0);
        }
      }
      contratadoPV = soma;
    }

    if (contratadoPV.isNotEmpty) {
      pvMulti.add(
        CurvaSPvSeries(
          id: 'PV_CONTR',
          name: 'Contratado',
          values: contratadoPV,
          dates: baseDates,
          color: AdditiveData.contractedColor,
          showArea: true,
        ),
      );
    }

    // 2) PV por termo
    if (cid.isNotEmpty) {
      final addStore = controller.additivesStore;
      if (addStore.listFor(cid).isEmpty && !addStore.loadingFor(cid)) {
        await addStore.ensureFor(cid);
      }

      for (final a in addStore.listFor(cid)) {
        final ord = a.additiveOrder ?? 0;
        if (ord <= 0) continue;

        final additiveId = a.id ?? '';
        if (additiveId.isEmpty) continue;

        final tipo = (a.typeOfAdditive ?? '').toString().trim();

        final sched = await physStore.getForTerm(
          contractId: cid,
          additiveId: additiveId,
          termOrder: ord,
        );
        if (sched == null) continue;

        final int nCols =
        pvDays.isNotEmpty ? pvDays.length : sched.periods.length;
        if (nCols <= 0) continue;

        final termPV = List<double>.filled(nCols, 0.0);

        for (final r in rows) {
          final itemId = r.item.toString();
          final rawAny = sched.grid[itemId];
          if (rawAny == null) continue;

          final raw =
          rawAny.map<double>((e) => (e as num).toDouble()).toList();
          final perc = _normList(raw, nCols);

          for (int j = 0; j < nCols; j++) {
            termPV[j] += r.valor * (perc[j] / 100.0);
          }
        }

        List<DateTime> termDates = const <DateTime>[];
        if (startDate != null) {
          final extra = a.additiveValidityExecutionDays ?? 0;
          termDates = (extra > 0)
              ? _datesFromAdditiveDays(
            start: startDate,
            additiveExecDays: extra,
          )
              : baseDates;
        }

        pvMulti.add(
          CurvaSPvSeries(
            id: 'PV_TERM_$ord',
            name: '$ordº Termo aditivo'
                '${tipo.isNotEmpty ? ' ($tipo)' : ''}',
            values: termPV,
            dates: termDates,
            color: AdditiveData.colorForOrder(ord),
            showArea: false,
          ),
        );
      }
    }

    if (!mounted) return;
    setState(() {
      _pvMulti = pvMulti;
      _loadingPv = false;
    });
  }

  // ---------- TIMELINE ----------
  Future<List<ValidityData>> _loadValidities(String contractId) async {
    final store = context.read<ValidityStore>();
    await store.ensureFor(contractId);
    return store.listFor(contractId);
  }

  Future<List<AdditiveData>> _loadAdditives(String contractId) async {
    final controller = context.read<ProcessController>();
    final addStore = controller.additivesStore;
    await addStore.ensureFor(contractId);
    return addStore.listFor(contractId);
  }

  void _initTimelineFuturesIfNeeded() {
    if (_timelineInitialized) return;
    final cid = widget.contractData.id ?? '';
    if (cid.isEmpty) return;

    _futureValidity = _loadValidities(cid);
    _futureAdditiveList = _loadAdditives(cid);
    _futureContractList =
    Future<List<ProcessData>>.value([widget.contractData]);

    _timelineInitialized = true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _initTimelineFuturesIfNeeded();

    if (!_dfdLoaded) {
      _dfdLoaded = true;
      _loadExtentFromDfd(context);
    }

    final controller = context.read<DemandsDashboardController>();
    final scheduleState = context.read<ScheduleRoadBloc>().state;
    _refreshPv(
      controller: controller,
      scheduleState: scheduleState,
      contract: widget.contractData,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DemandsDashboardController>();
    final adjStore = context.watch<AdjustmentsMeasurementStore>();
    final revStore = context.watch<RevisionsMeasurementStore>();

    final scheduleState = context.watch<ScheduleRoadBloc>().state;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshPv(
        controller: controller,
        scheduleState: scheduleState,
        contract: widget.contractData,
      );
    });

    final String? cid = widget.contractData.id;
    final List<ReportMeasurementData> contractMeasurements =
    (cid == null || cid.isEmpty)
        ? const <ReportMeasurementData>[]
        : controller.allMeasurements
        .where((m) => m.contractId == cid)
        .toList();

    final List<ReportMeasurementData> baseMed =
    filteredMeasurements.isNotEmpty
        ? filteredMeasurements
        : contractMeasurements;

    final double totalMedicoesContrato =
    baseMed.fold<double>(0.0, (acc, m) => acc + (m.value ?? 0.0));

    final double totalReajustesContrato = adjStore.all
        .where((e) => e.contractId == cid)
        .fold<double>(0.0, (acc, e) => acc + (e.value ?? 0.0));

    final double totalRevisoesContrato = revStore.all
        .where((e) => e.contractId == cid)
        .fold<double>(0.0, (acc, e) => acc + (e.value ?? 0.0));

    final bm = _benchmarksDoServico(controller, widget.contractData);
    final double totalContratoAA =
    _totalContratadoMaisAA(controller, widget.contractData);

    final DateTime start = DateTime(DateTime.now().year - 1, 1, 1);
    final DateTime end = DateTime(DateTime.now().year, 12, 31);
    final DateTime asOf = DateTime.now();
    final evm = EvmCalculator.snapshot(
      contract: widget.contractData,
      measurementsOfThisContract: contractMeasurements,
      totalContractValue: totalContratoAA,
      start: start,
      end: end,
      asOf: asOf,
      physicalPercent: 0,
    );

    final pvCurve = EvmCalculator.plannedCumulative(
      totalContractValue: totalContratoAA,
      start: start,
      end: end,
    );

    final acCurve = <int, double>{};
    double accAC = 0.0;
    final ordered = [...contractMeasurements]
      ..sort((a, b) =>
          (a.date ?? DateTime(0)).compareTo(b.date ?? DateTime(0)));
    for (final k in pvCurve.keys) {
      accAC += ordered
          .where((m) =>
      m.date != null &&
          (m.date!.year * 100 + m.date!.month) == k)
          .fold<double>(0.0, (a, m) => a + (m.value ?? 0.0));
      acCurve[k] = accAC;
    }

    final qualityScore = 100.0;
    final riskScore = 80.0;

    final double lengthKm = _extKmDfd ?? 0.0;
    final double custoPorKmAtual =
    lengthKm > 0 ? (totalContratoAA / lengthKm) : 0.0;

    final alerts = AlertRules.evaluate(
      cpi: evm.cpi,
      spi: evm.spi,
      costPerKm: custoPorKmAtual,
      mediaServico: bm?['Média'],
      tetoServico: bm?['Teto'],
      toContractEnd: widget.contractData.initialValidityContract != null
          ? Duration(days: widget.contractData.initialValidityContract!)
          : null,
    );

    return Stack(
      children: [
        const Positioned.fill(child: BackgroundClean()),
        CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const UpBar(
                    leading: Padding(
                      padding: EdgeInsets.only(left: 12.0),
                      child: BackCircleButton(),
                    ),
                  ),
                  TabBanner(contract: widget.contractData,),

                  // TIMELINE
                  const SizedBox(height: 8),
                  const DividerText(title: 'Linha do tempo do contrato'),
                  const SizedBox(height: 8),
                  Center(
                    child: TimelineClass(
                      futureValidity: _futureValidity,
                      futureContractList: _futureContractList,
                      futureAdditiveList: _futureAdditiveList,
                    ),
                  ),

                  // Acompanhamento físico
                  const SizedBox(height: 12),
                  const DividerText(title: 'Acompanhamento físico'),
                  const SizedBox(height: 8),
                  SpecificDashboardChartRowOne(
                    controller: controller,
                    contract: widget.contractData,
                  ),

                  // Métricas
                  const SizedBox(height: 8),
                  const DividerText(title: 'Métricas'),
                  const SizedBox(height: 8),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(width: 12),
                        CostPerKmRuler(
                          totalValueBRL: totalContratoAA,
                          lengthKm: lengthKm,
                          title: 'Custo por km',
                          serviceName: _tipoObraDfd,
                          benchmarks: bm,
                        ),
                        const SizedBox(width: 12),
                        HealthScoreCard(
                          cpi: evm.cpi,
                          spi: evm.spi,
                          quality: qualityScore,
                          riskScore: riskScore,
                        ),
                        const SizedBox(width: 12),
                        EvmSummaryCard(evm: evm),
                        const SizedBox(width: 12),
                        if (alerts.isNotEmpty)
                          SizedBox(
                            width: 360,
                            child: Card(
                              color: Colors.white,
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: SizedBox(
                                height: 165,
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Alertas',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      ...alerts.map(
                                            (a) => Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 6),
                                          child: Row(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              Icon(
                                                a.severity == 'crit'
                                                    ? Icons.error_rounded
                                                    : a.severity == 'warn'
                                                    ? Icons
                                                    .warning_rounded
                                                    : Icons.info_rounded,
                                                size: 18,
                                                color: a.severity == 'crit'
                                                    ? Colors.red
                                                    : a.severity == 'warn'
                                                    ? Colors.orange
                                                    : Colors.blueGrey,
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                                  children: [
                                                    Text(a.title),
                                                    if (a.description
                                                        .isNotEmpty)
                                                      Text(
                                                        a.description,
                                                        style:
                                                        const TextStyle(
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Previsto x Realizado
                  const SizedBox(height: 8),
                  const DividerText(title: 'Previsto x Realizado'),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(width: 12),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          child: SummaryExpandableCard(
                            title: 'Totais em medições',
                            icon: Icons.bar_chart_rounded,
                            colorIcon: const Color(0xFF4C6BFF),
                            subTitles: const [
                              'Medição',
                              'Reajuste',
                              'Revisão',
                            ],
                            valoresIndividuais: [
                              totalMedicoesContrato,
                              totalReajustesContrato,
                              totalRevisoesContrato,
                            ],
                            loading: !controller.initialized,
                            formatAsCurrency: true,
                          ),
                        ),
                        MeasurementSelectorDatesSection(
                          allMeasurements: contractMeasurements,
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Curva S
                  Stack(
                    children: [
                      CurvaSChart(
                        contractId: cid!,
                        pvMultiSeries: _pvMulti,
                        filteredMeasurements: filteredMeasurements,
                        selectedIndex: selectedPointIndex,
                        onPointTap: (index) async {
                          final measurement = filteredMeasurements[index];
                          final contractId = measurement.contractId;

                          String resumo = 'Contrato não encontrado';

                          if (contractId != null &&
                              contractId.isNotEmpty) {
                            // 🔹 Usa DFD para pegar descricaoObjeto como resumo
                            final dfdBloc = context.read<DfdBloc>();
                            final DfdData? dfd =
                            await dfdBloc.getDataForContract(contractId);

                            resumo = dfd?.descricaoObjeto ??
                                'Contrato não encontrado';

                            // Seleciona o contrato no store para manter o fluxo
                            final contrato = await controller.store.getById(contractId);
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
                      if (_loadingPv)
                        const Positioned.fill(
                          child: IgnorePointer(
                            ignoring: true,
                            child: Center(
                              child: SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
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
            SliverFillRemaining(
              hasScrollBody: false,
              child: const Column(
                children: [
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
