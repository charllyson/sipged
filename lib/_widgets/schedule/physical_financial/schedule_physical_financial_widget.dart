import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

// Additivos / Modelo + Repo
import 'package:sipged/_blocs/modules/contracts/additives/additives_data.dart';
import 'package:sipged/_blocs/modules/contracts/additives/additives_repository.dart';

import 'package:sipged/_blocs/modules/operation/phys_fin/physics_finance_data.dart';
// ✅ Store dedicado de cronograma
import 'package:sipged/_blocs/modules/operation/phys_fin/physics_finance_store.dart';

// SIGED deps
import 'package:sipged/_widgets/background/background_change.dart';
import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';

// Cubit de cronograma rodoviário
import 'package:sipged/_blocs/modules/operation/operation/road/schedule_road_cubit.dart';
import 'package:sipged/_blocs/modules/operation/operation/road/schedule_road_state.dart';

// Widgets locais/módulos
import 'banner_tip.dart';
import 'busy_overlay.dart';
import 'card_wrapper.dart';
import 'physfin_table.dart';
import '../../../_blocs/modules/operation/phys_fin/physics_finance_controller.dart';
import 'physfin_models.dart';

void _unawaited(Future<void> f) {}

class SchedulePhysicalFinancialWidget extends StatefulWidget {
  final ProcessData contractData;

  /// false => Licitação (só o contratado, azul, editável)
  /// true  => Aditivos (contratado cinza bloqueado + termos editáveis, com possíveis períodos extras)
  final bool chronogramMode;

  const SchedulePhysicalFinancialWidget({
    super.key,
    required this.contractData,
    this.chronogramMode = false,
  });

  @override
  State<SchedulePhysicalFinancialWidget> createState() =>
      _SchedulePhysicalFinancialWidgetState();
}

class _SchedulePhysicalFinancialWidgetState
    extends State<SchedulePhysicalFinancialWidget> {
  final NumberFormat _brl = NumberFormat.simpleCurrency(locale: 'pt_BR');

  /// Base (Contratado) — por *serviceKey*.
  final Map<String, List<double>> _percentGrid = <String, List<double>>{};

  /// Por termo (1 => 1º termo, …) — **por itemId (string)**.
  final Map<int, Map<String, List<double>>> _gridByTerm = {};

  /// Mapeia ordem do termo -> additiveId (para salvar/buscar no Firestore)
  final Map<int, String> _termAdditiveId = {};

  bool _saving = false;

  /// Controle de carregamento de termos/aditivos
  bool _termsLoaded = false;
  bool _loadingAdds = false;

  // Lista de aditivos ordenados por ordem (1º termo, 2º termo, …)
  List<AdditivesData> _orderedAdds = <AdditivesData>[];

  // Store de cronograma
  PhysicsFinanceStore? _physStore;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // PhysicsFinanceStore (para CRUD de schedules por termo)
    try {
      _physStore = context.read<PhysicsFinanceStore>();
    } catch (_) {
      _physStore = null;
    }
  }

  Future<void> _notifySaved({String? detail}) async {
    setState(() => _saving = true);
    try {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      PhysicsFinanceController.toastSuccess(
        title: 'Planejamento físico-financeiro',
        subtitle: detail?.isNotEmpty == true
            ? detail!
            : 'Distribuição atualizada com sucesso.',
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _notifySavedLite({String? detail}) async {
    PhysicsFinanceController.toastSuccess(
      title: 'Planejamento físico-financeiro',
      subtitle: detail?.isNotEmpty == true ? detail! : 'Distribuição atualizada.',
    );
  }

  // ===== Helpers: períodos extras por prorrogação de prazo (só no modo aditivos)

  int _sumExtraExecutionDays(List<AdditivesData> orderedAdds) {
    int sum = 0;
    for (final a in orderedAdds) {
      final d = a.additiveValidityExecutionDays ?? 0;
      if (d > 0) sum += d;
    }
    return sum;
  }

  List<int> _extendPeriods(List<int> base, int extraDays) {
    if (extraDays <= 0 || base.isEmpty) return base;
    final out = List<int>.from(base);

    final int step =
    base.length >= 2 ? (base.last - base[base.length - 2]).abs() : 30;
    int acc = 0;
    int last = base.last;
    while (acc < extraDays) {
      last += step;
      out.add(last);
      acc += step;
    }
    return out;
  }

  // ===== Helpers por TERMO (sempre por itemId) =====

  Map<String, List<double>> _ensureTermGridByRows(
      int termOrder,
      List<PhysFinRow> rows,
      int periods,
      ) {
    final map =
    _gridByTerm.putIfAbsent(termOrder, () => <String, List<double>>{});
    for (final r in rows) {
      final itemId = r.item.toString();
      map.putIfAbsent(itemId, () => List<double>.filled(periods, 0.0));
      if (map[itemId]!.length != periods) {
        final cur = map[itemId]!;
        if (cur.length > periods) {
          map[itemId] = List<double>.from(cur.take(periods));
        } else {
          map[itemId] = [
            ...cur,
            ...List<double>.filled(periods - cur.length, 0.0)
          ];
        }
      }
    }
    return map;
  }

  List<double> _getPercentsForItem(String itemId, {required int termOrder}) {
    final g = _gridByTerm[termOrder];
    if (g == null) return const <double>[];
    return g[itemId] ?? const <double>[];
  }

  /// Busca todos os schedules (por termo) e guarda em `_gridByTerm` (por itemId).
  Future<void> _warmupAllTerms({
    required int periods,
    required List<AdditivesData> additives,
  }) async {
    final physStore = _physStore;
    final contractId = widget.contractData.id ?? '';
    if (physStore == null || contractId.isEmpty) return;

    _termAdditiveId.clear();
    for (final a in additives) {
      final ord = a.additiveOrder ?? 0;
      if (ord > 0 && (a.id?.isNotEmpty ?? false)) {
        _termAdditiveId[ord] = a.id!;
      }
    }

    for (final entry in _termAdditiveId.entries) {
      final termOrder = entry.key;
      final additiveId = entry.value;

      final sched = await physStore.getForTerm(
        contractId: contractId,
        additiveId: additiveId,
        termOrder: termOrder,
      );

      if (sched != null) {
        final Map<String, List<double>> m = {};
        sched.grid.forEach((k, v) {
          final lst = (v).map((e) => (e as num).toDouble()).toList();
          m[k] = lst.length == periods
              ? lst
              : (lst.length > periods
              ? List<double>.from(lst.take(periods))
              : [
            ...lst,
            ...List<double>.filled(periods - lst.length, 0.0)
          ]);
        });
        _gridByTerm[termOrder] = m;
      } else {
        _gridByTerm.putIfAbsent(termOrder, () => <String, List<double>>{});
      }
    }
  }

  /// Salva o grid do TERMO no Firestore (já está por itemId).
  Future<void> _persistTermGrid({
    required int termOrder,
    required List<int> periods,
  }) async {
    final physStore = _physStore;
    final contractId = widget.contractData.id ?? '';
    if (physStore == null || contractId.isEmpty) return;

    final additiveId = _termAdditiveId[termOrder];
    final grid = _gridByTerm[termOrder];
    if (additiveId == null || grid == null) return;

    await physStore.upsert(
      contractId: contractId,
      additiveId: additiveId,
      schedule: PhysicsFinanceData(
        id: PhysicsFinanceData.docIdForTerm(termOrder),
        contractId: contractId,
        additiveId: additiveId,
        termOrder: termOrder,
        periods: periods,
        grid: grid,
      ),
    );
  }

  /// Carrega aditivos pelo `AdditivesRepository` e aquece os termos.
  Future<void> _bootstrapTerms({
    required int periods,
  }) async {
    if (!widget.chronogramMode) return;

    final contractId = widget.contractData.id ?? '';
    if (contractId.isEmpty) return;
    if (_termsLoaded) return;

    setState(() {
      _loadingAdds = true;
    });

    try {
      final repo = AdditivesRepository();
      final adds = await repo.ensureForContract(contractId);

      final ordered = List<AdditivesData>.from(adds)
        ..sort(
              (a, b) => (a.additiveOrder ?? 0).compareTo(b.additiveOrder ?? 0),
        );

      _orderedAdds = ordered;

      await _warmupAllTerms(
        periods: periods,
        additives: ordered,
      );

      if (mounted) {
        setState(() {
          _termsLoaded = true;
          _loadingAdds = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _orderedAdds = <AdditivesData>[];
          _termsLoaded = true; // evita loop de loading infinito
          _loadingAdds = false;
        });
      }
    }
  }

  String _titleCase(String s) {
    final t = s.trim();
    if (t.isEmpty) return t;
    return t
        .split(RegExp(r'\s+'))
        .map(
          (p) => p.isEmpty ? p : '${p[0].toUpperCase()}${p.substring(1).toLowerCase()}',
    )
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    const double kCardMarginH = 40.0;
    const EdgeInsets kCardPadding =
    EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 10);

    // rótulos e subtítulos dos termos (por ordem) usando lista local de aditivos
    final List<AdditivesData> orderedAdds = _orderedAdds;
    final int termosQt = orderedAdds.length;

    final List<String> termLabels = <String>[
      'Contratado',
      ...List<String>.generate(termosQt, (i) => '${i + 1}º Termo'),
    ];

    final List<String?> termSubLabels = <String?>[
      '',
      ...orderedAdds.map((a) => _titleCase(a.typeOfAdditive ?? '')),
    ];

    return Scaffold(
      body: Stack(
        children: [
          const BackgroundChange(),
          BlocBuilder<ScheduleRoadCubit, ScheduleRoadState>(
            buildWhen: (a, b) =>
            a.services != b.services ||
                a.serviceTotals != b.serviceTotals ||
                a.loadingServices != b.loadingServices ||
                a.physfinGrid != b.physfinGrid ||
                a.physfinPeriods != b.physfinPeriods,
            builder: (context, state) {
              final List<int> baseDays = state.physfinPeriods.isNotEmpty
                  ? List<int>.from(state.physfinPeriods)
                  : PhysicsFinanceController.daysFromContract(
                widget.contractData,
              );

              final int extraDays = widget.chronogramMode
                  ? _sumExtraExecutionDays(orderedAdds)
                  : 0;

              final List<int> dias = widget.chronogramMode
                  ? _extendPeriods(baseDays, extraDays)
                  : baseDays;

              final services =
              state.services.where((s) => s.key != 'geral').toList();

              if (!state.loadingServices && services.isEmpty) {
                return const Center(
                  child: Text(
                    'Nenhum serviço encontrado no orçamento.\n'
                        'Verifique a aba Orçamento (grupos/itens).',
                    textAlign: TextAlign.center,
                  ),
                );
              }

              PhysicsFinanceController.syncLocalGrid(
                stateGrid: state.physfinGrid,
                services: services,
                periods: dias.length,
                localGrid: _percentGrid,
              );

              _unawaited(_bootstrapTerms(periods: dias.length));

              final String contractId = widget.contractData.id ?? '';
              final bool waitingStore = widget.chronogramMode &&
                  (contractId.isEmpty || !_termsLoaded || _loadingAdds);

              if (waitingStore) {
                return const Center(child: CircularProgressIndicator());
              }

              final List<PhysFinRow> dados =
              PhysicsFinanceController.buildRows(
                services: services,
                serviceTotals: state.serviceTotals,
                localGrid: _percentGrid,
                periods: dias.length,
              );

              if (widget.chronogramMode) {
                for (final entry in _termAdditiveId.keys) {
                  _ensureTermGridByRows(entry, dados, dias.length);
                }
              }

              final PhysFinTotals totals = widget.chronogramMode
                  ? PhysicsFinanceController.computeTotalsChrono(
                rows: dados,
                periods: dias.length,
                termOrders: List<int?>.generate(
                  termLabels.length,
                      (i) => i == 0 ? null : i,
                ),
                getPercentFor:
                    (serviceKeyOrItemId, {int? termOrder}) {
                  if (termOrder == null) {
                    return _percentGrid[serviceKeyOrItemId] ??
                        const <double>[];
                  } else {
                    return _getPercentsForItem(
                      serviceKeyOrItemId,
                      termOrder: termOrder,
                    );
                  }
                },
              )
                  : PhysicsFinanceController.computeTotals(
                rows: dados,
                periods: dias.length,
              );

              final PhysFinMeasured measured =
              PhysicsFinanceController.measureWidths(
                context: context,
                rows: dados,
                totalGeral: totals.totalGeral,
              );

              return LayoutBuilder(
                builder: (context, constraints) {
                  const double kExtraCol = 120.0;
                  final double contentViewport =
                      constraints.maxWidth - kCardMarginH;

                  final bool preferFit = !widget.chronogramMode &&
                      constraints.maxWidth >= 1280 &&
                      (dias.isEmpty || dias.last <= 365);

                  final PhysFinWidths widths =
                  PhysicsFinanceController.resolveColumnWidths(
                    context: context,
                    preferFit: preferFit,
                    nCols: dias.length,
                    viewportWidth: contentViewport,
                    paddingsHorizontal: kCardPadding.horizontal,
                    measuredDescWidth: measured.descColWidth,
                    measuredValueWidth: measured.valueColWidth,
                    extraColWidth:
                    widget.chronogramMode ? kExtraCol : null,
                  );

                  final double tableWidth = widths.itemCol +
                      widths.descCol +
                      (widths.extraCol ?? 0.0) +
                      dias.length * widths.percentCol +
                      widths.valueCol;

                  final double contentWidth =
                      tableWidth + kCardPadding.horizontal;

                  final table = PhysFinTable(
                    chronogramMode: widget.chronogramMode,
                    termLabels: termLabels,
                    termSubLabels: termSubLabels,
                    additives: orderedAdds,
                    days: dias,
                    rows: dados,
                    totals: totals,
                    widths: widths,
                    money: _brl,
                    localGrid: _percentGrid,
                    getPercentFor: (key, {int? termOrder}) {
                      if (termOrder == null) {
                        return _percentGrid[key] ?? const <double>[];
                      }
                      return _getPercentsForItem(key, termOrder: termOrder);
                    },
                    onPickPercent: (
                        serviceKey,
                        colIndex,
                        current,
                        alreadyAllocated,
                        serviceTotal,
                        ) async {
                      final picked =
                      await PhysicsFinanceController.pickPercentDialog(
                        context: context,
                        current: current,
                        alreadyAllocatedPercent: alreadyAllocated,
                        serviceTotalReais: serviceTotal,
                      );
                      if (picked == null) return;

                      setState(() {
                        _percentGrid[serviceKey]![colIndex] = picked;
                      });

                      // ⬇️ Novo padrão: chamar método do Cubit
                      await context
                          .read<ScheduleRoadCubit>()
                          .updatePhysFinGrid(
                        periods: dias,
                        grid: _percentGrid,
                      );

                      await _notifySaved(
                        detail: 'Período atualizado: ${colIndex + 1}',
                      );
                    },
                    onPickPercentForTerm: (
                        itemId,
                        colIndex,
                        current,
                        alreadyAllocated,
                        serviceTotal, {
                          required int termOrder,
                        }) async {
                      final picked =
                      await PhysicsFinanceController.pickPercentDialog(
                        context: context,
                        current: current,
                        alreadyAllocatedPercent: alreadyAllocated,
                        serviceTotalReais: serviceTotal,
                      );
                      if (picked == null) return;

                      setState(() {
                        _ensureTermGridByRows(
                            termOrder, dados, dias.length);
                        final grid = _gridByTerm[termOrder]!;
                        final row = grid.putIfAbsent(
                          itemId,
                              () => List<double>.filled(dias.length, 0.0),
                        );
                        row[colIndex] = picked;
                      });

                      await _persistTermGrid(
                        termOrder: termOrder,
                        periods: dias,
                      );

                      await _notifySavedLite(
                        detail:
                        'Período atualizado (Termo $termOrder): ${colIndex + 1}',
                      );
                    },
                    pickBarColors: ({int? termOrder}) {
                      if (!widget.chronogramMode) {
                        return (
                        fill: AdditivesData.contractedColor,
                        track: AdditivesData.trackColor,
                        disabled: false,
                        );
                      }
                      if (termOrder == null) {
                        return (
                        fill: const Color(0xFFBDBDBD),
                        track: AdditivesData.trackColor,
                        disabled: true,
                        );
                      }
                      final c = AdditivesData.colorForOrder(termOrder);
                      return (
                      fill: c,
                      track: AdditivesData.trackColor,
                      disabled: false,
                      );
                    },
                  );

                  final card =
                  PhysFinCardWrapper(padding: kCardPadding, child: table);

                  final tableRegion =
                  (contentWidth > (constraints.maxWidth - kCardMarginH))
                      ? SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: kCardMarginH / 2),
                    child: ConstrainedBox(
                      constraints:
                      BoxConstraints(minWidth: contentWidth),
                      child: card,
                    ),
                  )
                      : Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: kCardMarginH / 2),
                    child: card,
                  );

                  final banner = PhysFinBannerTip(
                    text: widget.chronogramMode
                        ? 'Edite os percentuais nas linhas dos Termos. “Contratado” está desativado.'
                        : 'Clique nas barras para alterar os percentuais de cada período.',
                  );

                  final verticalScroll = SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 18),
                        banner,
                        const SizedBox(height: 6),
                        tableRegion,
                      ],
                    ),
                  );

                  final bool isBusy =
                      (state.loadingServices && services.isEmpty) || _saving;

                  return Stack(
                    children: [
                      verticalScroll,
                      if (isBusy)
                        const PhysFinBusyOverlay(
                          saving: false,
                          textWhenBusy: 'Carregando planejamento...',
                          textWhenSaving: 'Salvando planejamento...',
                        ),
                      if (_saving)
                        const PhysFinBusyOverlay(
                          saving: true,
                          textWhenBusy: 'Carregando planejamento...',
                          textWhenSaving: 'Salvando planejamento...',
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
