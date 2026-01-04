import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_blocs/sectors/financial/budget/budget_repository.dart';
import 'package:siged/_blocs/sectors/financial/budget/budget_data.dart';

import 'package:siged/_blocs/sectors/financial/empenhos/empenho_repository.dart';
import 'package:siged/_blocs/sectors/financial/empenhos/empenho_data.dart';

// ✅ DFD (valorDemanda)
import 'package:siged/_blocs/process/hiring/1Dfd/dfd_cubit.dart';
import 'package:siged/_blocs/process/hiring/1Dfd/dfd_data.dart';

// ✅ Aditivos / Apostilas
import 'package:siged/_blocs/process/additives/additives_repository.dart';
import 'package:siged/_blocs/process/additives/additives_data.dart';
import 'package:siged/_blocs/process/apostilles/apostilles_repository.dart';
import 'package:siged/_blocs/process/apostilles/apostilles_data.dart';

import 'financial_dashboard_state.dart';

class FinancialDashboardTotals {
  final double orcamento;
  final double empenhado;
  final double medido;
  final double pago;
  final double saldo;

  const FinancialDashboardTotals({
    required this.orcamento,
    required this.empenhado,
    required this.medido,
    required this.pago,
    required this.saldo,
  });
}

class FinancialDashboardCubit extends Cubit<FinancialDashboardState> {
  final BudgetRepository _budgetRepo;
  final EmpenhoRepository _empenhoRepo;

  // ✅ Injeções novas
  final DfdCubit _dfdCubit;
  final AdditivesRepository _additivesRepo;
  final ApostillesRepository _apostillesRepo;

  FinancialDashboardCubit({
    BudgetRepository? budgetRepository,
    EmpenhoRepository? empenhoRepository,
    DfdCubit? dfdCubit,
    AdditivesRepository? additivesRepository,
    ApostillesRepository? apostillesRepository,
  })  : _budgetRepo = budgetRepository ?? BudgetRepository(),
        _empenhoRepo = empenhoRepository ?? EmpenhoRepository(),
        _dfdCubit = dfdCubit ?? DfdCubit(),
        _additivesRepo = additivesRepository ?? AdditivesRepository(),
        _apostillesRepo = apostillesRepository ?? ApostillesRepository(),
        super(FinancialDashboardState.initial());

  // =========================
  // HELPERS
  // =========================

  void _log(String m) {
    if (kDebugMode) debugPrint('[FinancialDashboardCubit] $m');
  }

  String? _idToString(Object? id) {
    if (id == null) return null;
    try {
      final dynamic dyn = id;
      final hasUid = (() {
        try {
          return (dyn as dynamic).uid is String;
        } catch (_) {
          return false;
        }
      })();
      if (hasUid) return (dyn as dynamic).uid as String;
    } catch (_) {}
    return id.toString();
  }

  /// Tenta extrair contractId do EmpenhoData com tolerância
  String? _contractIdFromEmpenho(EmpenhoData e) {
    try {
      final direct = _idToString((e as dynamic).contractId) ??
          _idToString((e as dynamic).idContract) ??
          _idToString((e as dynamic).contractRef);
      if (direct != null && direct.trim().isNotEmpty) return direct.trim();
    } catch (_) {}
    return null;
  }

  /// Label da demanda do empenho
  String _demandLabelFromEmpenho(EmpenhoData e) {
    final v = e.demandLabel.trim();
    return v.isNotEmpty ? v : 'Sem demanda';
  }

  // =========================
  // LOAD
  // =========================

  Future<void> loadAll() async {
    emit(state.copyWith(status: FinancialDashboardStatus.loading, clearError: true));
    try {
      final budgets = await _budgetRepo.getAll();
      final empenhos = await _empenhoRepo.getAll();

      final selectedId = (state.selectedEmpenhoId?.trim().isNotEmpty ?? false)
          ? state.selectedEmpenhoId
          : (empenhos.isNotEmpty ? empenhos.first.id : null);

      // ✅ carrega e calcula demanda + aditivos + apostilas (uma vez)
      final computed = await _loadDemandTotalsFromEmpenhos(empenhos);

      emit(state.copyWith(
        status: FinancialDashboardStatus.success,
        budgets: budgets,
        empenhos: empenhos,
        selectedEmpenhoId: selectedId,
        // ✅ novos campos
        allAdditives: computed.allAdditives,
        allApostilles: computed.allApostilles,
        demandTotals: computed.demandTotals,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(status: FinancialDashboardStatus.failure, error: e.toString()));
    }
  }

  Future<void> loadByContract(String contractId) async {
    final cid = contractId.trim();

    emit(state.copyWith(status: FinancialDashboardStatus.loading, clearError: true));
    try {
      final budgets = await _budgetRepo.getAllByContract(contractId: cid);
      final empenhos = await _empenhoRepo.getAllByContract(contractId: cid);

      final selectedId = (state.selectedEmpenhoId?.trim().isNotEmpty ?? false)
          ? state.selectedEmpenhoId
          : (empenhos.isNotEmpty ? empenhos.first.id : null);

      // ✅ no recorte por contrato, ainda calculamos por demanda (se houver mais de uma)
      final computed = await _loadDemandTotalsFromEmpenhos(empenhos);

      emit(state.copyWith(
        status: FinancialDashboardStatus.success,
        budgets: budgets,
        empenhos: empenhos,
        selectedEmpenhoId: selectedId,
        allAdditives: computed.allAdditives,
        allApostilles: computed.allApostilles,
        demandTotals: computed.demandTotals,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(status: FinancialDashboardStatus.failure, error: e.toString()));
    }
  }

  // =========================
  // PIPELINE: demanda + aditivos + apostilas
  // =========================

  /// Retorno interno tipado
  Future<({
  List<AdditivesData> allAdditives,
  List<ApostillesData> allApostilles,
  Map<String, double> demandTotals,
  })> _loadDemandTotalsFromEmpenhos(List<EmpenhoData> empenhos) async {
    // 1) contractIds presentes nos empenhos
    final contractIds = <String>{};
    for (final e in empenhos) {
      final cid = _contractIdFromEmpenho(e);
      if (cid != null && cid.isNotEmpty) contractIds.add(cid);
    }

    if (contractIds.isEmpty) {
      return (
      allAdditives: const <AdditivesData>[],
      allApostilles: const <ApostillesData>[],
      demandTotals: const <String, double>{},
      );
    }

    // 2) DFD.valorDemanda por contrato (paralelo)
    final valueByContract = <String, double>{};
    await Future.wait(contractIds.map((cid) async {
      final DfdData? dfd = await _dfdCubit.getDataForContract(cid);
      valueByContract[cid] = dfd?.valorDemanda ?? 0.0;
    }));

    // 3) Aditivos / Apostilas por contractIds (uma vez cada)
    final allAdditives = await _additivesRepo.getAdditivesByContractIds(contractIds);
    final allApostilles = await _apostillesRepo.getApostillesByContractIds(contractIds);

    final addByContract = <String, double>{};
    for (final ad in allAdditives) {
      final cid = _idToString(ad.contractId);
      if (cid == null || cid.trim().isEmpty) continue;
      addByContract[cid] = (addByContract[cid] ?? 0.0) + (ad.additiveValue ?? 0.0);
    }

    final apostByContract = <String, double>{};
    for (final ap in allApostilles) {
      final cid = _idToString(ap.contractId);
      if (cid == null || cid.trim().isEmpty) continue;
      apostByContract[cid] = (apostByContract[cid] ?? 0.0) + (ap.apostilleValue ?? 0.0);
    }

    // 4) Total do contrato = valorDemanda + aditivos + apostilas
    final totalByContract = <String, double>{};
    for (final cid in contractIds) {
      final base = valueByContract[cid] ?? 0.0;
      final add = addByContract[cid] ?? 0.0;
      final apost = apostByContract[cid] ?? 0.0;
      totalByContract[cid] = base + add + apost;
    }

    // 5) Agrega por DEMANDA (usando os empenhos como fonte de demanda)
    final demandTotals = <String, double>{};
    for (final e in empenhos) {
      final demand = _demandLabelFromEmpenho(e);
      final cid = _contractIdFromEmpenho(e);
      if (cid == null) continue;

      // Para evitar contar o mesmo contrato várias vezes dentro da mesma demanda,
      // podemos usar um set por demanda (dedupe).
      // Se você quiser somar repetido (caso demanda represente "itens" e não contrato),
      // remova essa deduplicação.
      //
      // ✅ vou deduplicar por contrato dentro de cada demanda.
    }

    final seen = <String, Set<String>>{};
    for (final e in empenhos) {
      final demand = _demandLabelFromEmpenho(e);
      final cid = _contractIdFromEmpenho(e);
      if (cid == null) continue;

      final set = seen.putIfAbsent(demand, () => <String>{});
      if (set.contains(cid)) continue;
      set.add(cid);

      demandTotals[demand] = (demandTotals[demand] ?? 0.0) + (totalByContract[cid] ?? 0.0);
    }

    // ordena (opcional) por total desc
    final ordered = demandTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final demandTotalsSorted = {for (final e in ordered) e.key: e.value};

    _log('demandTotals: ${demandTotalsSorted.length} demandas; contracts=${contractIds.length}');

    return (
    allAdditives: allAdditives,
    allApostilles: allApostilles,
    demandTotals: demandTotalsSorted,
    );
  }

  // =========================
  // DRILLDOWN / FILTERS
  // =========================

  void selectEmpenho(String? id) {
    final v = (id ?? '').trim();
    emit(state.copyWith(selectedEmpenhoId: v.isEmpty ? null : v));
  }

  void setStatusDfdLabel(String v) => emit(state.copyWith(statusDfdLabel: v.trim()));
  void setFundingSourceLabel(String v) => emit(state.copyWith(fundingSourceLabel: v.trim()));
  void setExtraLabel(String v) => emit(state.copyWith(extraLabel: v.trim()));

  EmpenhoData? get selectedEmpenho {
    final id = state.selectedEmpenhoId;
    if (id == null || id.trim().isEmpty) return null;
    try {
      return state.empenhos.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  // =========================
  // COMPUTEDS (TOTALS)
  // =========================

  double get totalOrcamento {
    double sum = 0;
    for (final b in state.budgets) {
      sum += b.amount;
    }
    return sum;
  }

  double get totalEmpenhado {
    double sum = 0;
    for (final e in state.empenhos) {
      sum += e.empenhadoTotal;
    }
    return sum;
  }

  FinancialDashboardTotals computeTotals() {
    final orc = totalOrcamento;
    final emp = totalEmpenhado;

    const med = 0.0;
    const pag = 0.0;

    final saldo = max<double>(0.0, orc - emp);

    return FinancialDashboardTotals(
      orcamento: orc,
      empenhado: emp,
      medido: med,
      pago: pag,
      saldo: saldo,
    );
  }

  /// Distribuição do ORÇAMENTO por fonte (para o gráfico/legenda)
  Map<String, double> budgetByFundingSource() {
    final Map<String, double> map = {};
    for (final b in state.budgets) {
      final k = (b.fundingSourceLabel ?? '').trim();
      if (k.isEmpty) continue;
      map[k] = (map[k] ?? 0) + b.amount;
    }

    final entries = map.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return {for (final e in entries) e.key: e.value};
  }

  /// Ordem recomendada das fontes:
  /// 1) orçamento desc; 2) fallback: fontes dos empenhos (alfabético)
  List<String> fundingSourceOrder() {
    final byBudget = budgetByFundingSource();
    if (byBudget.isNotEmpty) return byBudget.keys.toList();

    final set = <String>{};
    for (final e in state.empenhos) {
      final k = e.fundingSourceLabel.trim();
      if (k.isNotEmpty) set.add(k);
    }
    final list = set.toList()..sort();
    return list;
  }

  /// DEMANDA -> (FONTE -> TOTAL EMPENHADO)
  Map<String, Map<String, double>> empenhadoByDemandByFundingSource() {
    final Map<String, Map<String, double>> out = {};

    for (final e in state.empenhos) {
      final demand = e.demandLabel.trim().isNotEmpty ? e.demandLabel.trim() : 'Sem demanda';
      final source = e.fundingSourceLabel.trim().isNotEmpty ? e.fundingSourceLabel.trim() : 'Sem fonte';

      out.putIfAbsent(demand, () => <String, double>{});
      out[demand]![source] = (out[demand]![source] ?? 0) + e.empenhadoTotal;
    }

    final entries = out.entries.toList()
      ..sort((a, b) {
        final at = a.value.values.fold<double>(0, (s, v) => s + v);
        final bt = b.value.values.fold<double>(0, (s, v) => s + v);
        final r = bt.compareTo(at);
        if (r != 0) return r;
        return a.key.toLowerCase().compareTo(b.key.toLowerCase());
      });

    return {for (final e in entries) e.key: e.value};
  }

  /// ✅ Total da DEMANDA (DFD + aditivos + apostilas) já pronto no state
  double demandTotal(String demandLabel) {
    final k = demandLabel.trim();
    if (k.isEmpty) return 0.0;
    return state.demandTotals[k] ?? 0.0;
  }
}
