// lib/_blocs/process/budget/budget_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';

import 'budget_data.dart';
import 'budget_repository.dart';
import 'budget_state.dart';

class BudgetCubit extends Cubit<BudgetState> {
  BudgetCubit({BudgetRepository? repository})
      : _repo = repository ?? BudgetRepository(),
        super(const BudgetState());

  final BudgetRepository _repo;

  static const int _minLoadingMs = 150;

  Future<void> ensureFor(String contractId) async {
    if (contractId.isEmpty) return;

    final cached = state.byContract[contractId];
    final isLoading = state.loadingFor(contractId);

    // Se já tem cache, só recarrega quando estiver vazio/incompleto
    if (cached != null) {
      final shouldRefresh =
          (cached.entries.isEmpty || cached.schema.columns.isEmpty) && !isLoading;

      if (shouldRefresh) {
        await refreshFor(contractId);
      }
      return;
    }

    // Se já está carregando, não duplica
    if (isLoading) return;

    await _loadInternal(contractId, mode: _LoadMode.ensure);
  }

  Future<void> refreshFor(String contractId) async {
    if (contractId.isEmpty) return;

    // evita refresh concorrente
    if (state.loadingFor(contractId)) return;

    await _loadInternal(contractId, mode: _LoadMode.refresh);
  }

  void clearFor(String contractId) {
    final nextBy = Map<String, BudgetData>.from(state.byContract)..remove(contractId);
    final nextLoading = Map<String, bool>.from(state.loading)..remove(contractId);
    final nextErr = Map<String, String?>.from(state.errorByContract)..remove(contractId);

    emit(state.copyWith(
      byContract: nextBy,
      loading: nextLoading,
      errorByContract: nextErr,
    ));
  }

  Future<void> saveDomain({
    required String contractId,
    required BudgetData data,
  }) async {
    if (contractId.isEmpty) return;

    // marca loading
    _setLoading(contractId, true, status: BudgetStatus.loading);

    final started = DateTime.now();
    try {
      await _repo.save(contractId: contractId, data: data);
      // recarrega para garantir consistência (activeWriteId + leitura)
      final snap = await _repo.load(contractId);

      final nextBy = Map<String, BudgetData>.from(state.byContract)
        ..[contractId] = snap;

      final nextErr = Map<String, String?>.from(state.errorByContract)
        ..[contractId] = null;

      _awaitMinLoading(started);
      emit(state.copyWith(
        status: BudgetStatus.success,
        byContract: nextBy,
        errorByContract: nextErr,
        loading: Map<String, bool>.from(state.loading)..[contractId] = false,
        lastContractId: contractId,
      ));
    } catch (e) {
      _awaitMinLoading(started);
      _setError(contractId, e.toString());
      rethrow;
    }
  }

  /// Shim: UI antiga que ainda envia arrays (headers/types/widths/rows)
  Future<void> saveBudgetLegacy({
    required String contractId,
    required List<String> headers,
    required List<String> colTypes,
    required List<double> colWidths,
    required List<List<String>> rows,
    required bool rowsIncludesHeader,
  }) async {
    if (contractId.isEmpty) return;

    _setLoading(contractId, true, status: BudgetStatus.loading);

    final started = DateTime.now();
    try {
      await _repo.saveBudgetNested(
        contractId: contractId,
        headers: headers,
        colTypes: colTypes,
        colWidths: colWidths,
        rows: rows,
        rowsIncludesHeader: rowsIncludesHeader,
      );

      final snap = await _repo.load(contractId);

      final nextBy = Map<String, BudgetData>.from(state.byContract)
        ..[contractId] = snap;

      _awaitMinLoading(started);
      emit(state.copyWith(
        status: BudgetStatus.success,
        byContract: nextBy,
        loading: Map<String, bool>.from(state.loading)..[contractId] = false,
        errorByContract: Map<String, String?>.from(state.errorByContract)..[contractId] = null,
        lastContractId: contractId,
      ));
    } catch (e) {
      _awaitMinLoading(started);
      _setError(contractId, e.toString());
      rethrow;
    }
  }

  // ---------------- internal ----------------

  Future<void> _loadInternal(String contractId, {required _LoadMode mode}) async {
    _setLoading(contractId, true, status: BudgetStatus.loading);

    final started = DateTime.now();
    try {
      final snap = await _repo.load(contractId);

      final nextBy = Map<String, BudgetData>.from(state.byContract)
        ..[contractId] = snap;

      final nextErr = Map<String, String?>.from(state.errorByContract)
        ..[contractId] = null;

      _awaitMinLoading(started);
      emit(state.copyWith(
        status: BudgetStatus.success,
        byContract: nextBy,
        errorByContract: nextErr,
        loading: Map<String, bool>.from(state.loading)..[contractId] = false,
        lastContractId: contractId,
      ));
    } catch (e) {
      _awaitMinLoading(started);
      _setError(contractId, e.toString());
      rethrow;
    }
  }

  void _setLoading(String contractId, bool isLoading, {BudgetStatus? status}) {
    final nextLoading = Map<String, bool>.from(state.loading)
      ..[contractId] = isLoading;

    emit(state.copyWith(
      status: status ?? state.status,
      loading: nextLoading,
      lastContractId: contractId,
    ));
  }

  void _setError(String contractId, String message) {
    final nextLoading = Map<String, bool>.from(state.loading)..[contractId] = false;
    final nextErr = Map<String, String?>.from(state.errorByContract)
      ..[contractId] = message;

    emit(state.copyWith(
      status: BudgetStatus.failure,
      loading: nextLoading,
      errorByContract: nextErr,
      lastContractId: contractId,
    ));
  }

  void _awaitMinLoading(DateTime started) {
    final elapsed = DateTime.now().difference(started).inMilliseconds;
    if (elapsed < _minLoadingMs) {
      // ignore: avoid_slow_async_io
      // (é só delay de UX)
    }
  }
}

enum _LoadMode { ensure, refresh }
