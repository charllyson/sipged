// lib/_blocs/modules/contracts/budget/budget_cubit.dart

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_widgets/table/magic/magic_table_controller.dart' as bc;

import 'budget_data.dart';
import 'budget_repository.dart';
import 'budget_state.dart';

class BudgetCubit extends Cubit<BudgetState> {
  BudgetCubit({
    required String tenantId,
    BudgetRepository? repository,
  })  : _repo = repository ?? BudgetRepository(tenantId: tenantId),
        super(const BudgetState());

  final BudgetRepository _repo;

  static const int _minLoadingMs = 180;

  /// Carrega o MagicTableController a partir do domínio do orçamento.
  ///
  /// Substitui o antigo BudgetAdapter.loadControllerFromDomain.
  static void loadControllerFromDomain({
    required bc.MagicTableController controller,
    required BudgetData data,
  }) {
    if (data.schema.columns.isEmpty) {
      controller.loadFromSnapshot(
        table: const <List<String>>[<String>[]],
        colTypesAsString: const <String>[],
        widths: const <double>[],
      );
      return;
    }

    controller.loadFromSnapshot(
      table: data.toTableData(),
      colTypesAsString: data.schema.headerTypes,
      widths: data.schema.headerWidths,
    );
  }

  /// Constrói o domínio do orçamento a partir do MagicTableController.
  ///
  /// Substitui o antigo BudgetAdapter.buildDomainFromController.
  static BudgetData buildDomainFromController({
    required bc.MagicTableController controller,
  }) {
    final headers = _cleanHeaders(controller.headers);

    final types = _normalizeTypes(
      controller.colTypesAsString,
      headers.length,
    );

    final widths = _normalizeWidths(
      controller.colWidths,
      headers.length,
    );

    final table = _normalizeTable(
      controller.tableData,
      headers.length,
    );

    if (headers.isEmpty || table.isEmpty) {
      return BudgetData.empty();
    }

    return BudgetData.fromTable(
      headers: headers,
      colTypes: types,
      colWidths: widths,
      rows: table,
      rowsIncludesHeader: _tableIncludesHeader(
        table: table,
        headers: headers,
      ),
    );
  }

  Future<void> ensureFor(String contractId) async {
    final cleanContractId = contractId.trim();
    if (cleanContractId.isEmpty) return;

    final cached = state.byContract[cleanContractId];
    final isLoading = state.loadingFor(cleanContractId);

    if (cached != null) {
      final shouldRefresh =
          cached.entries.isEmpty && cached.schema.columns.isEmpty && !isLoading;

      if (shouldRefresh) {
        await refreshFor(cleanContractId);
      }

      return;
    }

    if (isLoading) return;

    await _loadInternal(cleanContractId);
  }

  Future<void> refreshFor(String contractId) async {
    final cleanContractId = contractId.trim();
    if (cleanContractId.isEmpty) return;

    if (state.loadingFor(cleanContractId)) return;

    await _loadInternal(cleanContractId);
  }

  Future<void> saveDomain({
    required String contractId,
    required BudgetData data,
  }) async {
    final cleanContractId = contractId.trim();
    if (cleanContractId.isEmpty) return;

    final started = DateTime.now();

    _setLoading(
      cleanContractId,
      true,
      status: BudgetStatus.loading,
    );

    try {
      await _repo.save(
        contractId: cleanContractId,
        data: data,
      );

      final saved = await _repo.load(cleanContractId);

      final nextByContract = Map<String, BudgetData>.from(state.byContract)
        ..[cleanContractId] = saved;

      final nextErrors = Map<String, String?>.from(state.errorByContract)
        ..[cleanContractId] = null;

      final nextLoading = Map<String, bool>.from(state.loading)
        ..[cleanContractId] = false;

      await _awaitMinLoading(started);

      emit(
        state.copyWith(
          status: BudgetStatus.success,
          byContract: nextByContract,
          errorByContract: nextErrors,
          loading: nextLoading,
          lastContractId: cleanContractId,
        ),
      );
    } catch (error) {
      await _awaitMinLoading(started);
      _setError(cleanContractId, error.toString());
      rethrow;
    }
  }

  Future<void> saveFromTable({
    required String contractId,
    required List<String> headers,
    required List<String> colTypes,
    required List<double> colWidths,
    required List<List<String>> rows,
    required bool rowsIncludesHeader,
  }) async {
    final cleanContractId = contractId.trim();
    if (cleanContractId.isEmpty) return;

    final started = DateTime.now();

    _setLoading(
      cleanContractId,
      true,
      status: BudgetStatus.loading,
    );

    try {
      await _repo.saveFromTable(
        contractId: cleanContractId,
        headers: headers,
        colTypes: colTypes,
        colWidths: colWidths,
        rows: rows,
        rowsIncludesHeader: rowsIncludesHeader,
      );

      final saved = await _repo.load(cleanContractId);

      final nextByContract = Map<String, BudgetData>.from(state.byContract)
        ..[cleanContractId] = saved;

      final nextErrors = Map<String, String?>.from(state.errorByContract)
        ..[cleanContractId] = null;

      final nextLoading = Map<String, bool>.from(state.loading)
        ..[cleanContractId] = false;

      await _awaitMinLoading(started);

      emit(
        state.copyWith(
          status: BudgetStatus.success,
          byContract: nextByContract,
          errorByContract: nextErrors,
          loading: nextLoading,
          lastContractId: cleanContractId,
        ),
      );
    } catch (error) {
      await _awaitMinLoading(started);
      _setError(cleanContractId, error.toString());
      rethrow;
    }
  }

  Future<void> deleteFor(String contractId) async {
    final cleanContractId = contractId.trim();
    if (cleanContractId.isEmpty) return;

    final started = DateTime.now();

    _setLoading(
      cleanContractId,
      true,
      status: BudgetStatus.loading,
    );

    try {
      await _repo.delete(cleanContractId);

      final nextByContract = Map<String, BudgetData>.from(state.byContract)
        ..remove(cleanContractId);

      final nextErrors = Map<String, String?>.from(state.errorByContract)
        ..[cleanContractId] = null;

      final nextLoading = Map<String, bool>.from(state.loading)
        ..[cleanContractId] = false;

      await _awaitMinLoading(started);

      emit(
        state.copyWith(
          status: BudgetStatus.success,
          byContract: nextByContract,
          errorByContract: nextErrors,
          loading: nextLoading,
          lastContractId: cleanContractId,
        ),
      );
    } catch (error) {
      await _awaitMinLoading(started);
      _setError(cleanContractId, error.toString());
      rethrow;
    }
  }

  void clearFor(String contractId) {
    final cleanContractId = contractId.trim();
    if (cleanContractId.isEmpty) return;

    final nextByContract = Map<String, BudgetData>.from(state.byContract)
      ..remove(cleanContractId);

    final nextLoading = Map<String, bool>.from(state.loading)
      ..remove(cleanContractId);

    final nextErrors = Map<String, String?>.from(state.errorByContract)
      ..remove(cleanContractId);

    emit(
      state.copyWith(
        byContract: nextByContract,
        loading: nextLoading,
        errorByContract: nextErrors,
      ),
    );
  }

  Future<void> _loadInternal(String contractId) async {
    final started = DateTime.now();

    _setLoading(
      contractId,
      true,
      status: BudgetStatus.loading,
    );

    try {
      final data = await _repo.load(contractId);

      final nextByContract = Map<String, BudgetData>.from(state.byContract)
        ..[contractId] = data;

      final nextErrors = Map<String, String?>.from(state.errorByContract)
        ..[contractId] = null;

      final nextLoading = Map<String, bool>.from(state.loading)
        ..[contractId] = false;

      await _awaitMinLoading(started);

      emit(
        state.copyWith(
          status: BudgetStatus.success,
          byContract: nextByContract,
          errorByContract: nextErrors,
          loading: nextLoading,
          lastContractId: contractId,
        ),
      );
    } catch (error) {
      await _awaitMinLoading(started);
      _setError(contractId, error.toString());
      rethrow;
    }
  }

  void _setLoading(
      String contractId,
      bool isLoading, {
        BudgetStatus? status,
      }) {
    final nextLoading = Map<String, bool>.from(state.loading)
      ..[contractId] = isLoading;

    emit(
      state.copyWith(
        status: status ?? state.status,
        loading: nextLoading,
        lastContractId: contractId,
      ),
    );
  }

  void _setError(String contractId, String message) {
    final nextLoading = Map<String, bool>.from(state.loading)
      ..[contractId] = false;

    final nextErrors = Map<String, String?>.from(state.errorByContract)
      ..[contractId] = message;

    emit(
      state.copyWith(
        status: BudgetStatus.failure,
        loading: nextLoading,
        errorByContract: nextErrors,
        lastContractId: contractId,
      ),
    );
  }

  Future<void> _awaitMinLoading(DateTime started) async {
    final elapsed = DateTime.now().difference(started).inMilliseconds;

    if (elapsed >= _minLoadingMs) return;

    await Future<void>.delayed(
      Duration(milliseconds: _minLoadingMs - elapsed),
    );
  }

  static List<String> _cleanHeaders(List<String> headers) {
    return headers
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  static List<String> _normalizeTypes(
      List<String> types,
      int length,
      ) {
    return List<String>.generate(
      length,
          (index) {
        if (index >= types.length) {
          return BudgetColumnType.auto.name;
        }

        final raw = types[index].trim();

        final exists = BudgetColumnType.values.any(
              (item) => item.name == raw,
        );

        return exists ? raw : BudgetColumnType.auto.name;
      },
      growable: false,
    );
  }

  static List<double> _normalizeWidths(
      List<double> widths,
      int length,
      ) {
    return List<double>.generate(
      length,
          (index) {
        if (index >= widths.length) return 120.0;

        final width = widths[index];

        if (width <= 0) return 120.0;

        return width;
      },
      growable: false,
    );
  }

  static List<List<String>> _normalizeTable(
      List<List<String>> table,
      int headerLength,
      ) {
    if (headerLength <= 0) {
      return const <List<String>>[];
    }

    return table
        .where((row) {
      return row.any((cell) => cell.trim().isNotEmpty);
    })
        .map((row) {
      return _normalizeRow(
        row,
        headerLength,
      );
    })
        .toList(growable: false);
  }

  static List<String> _normalizeRow(
      List<String> row,
      int length,
      ) {
    if (row.length == length) {
      return row.map((item) => item.trim()).toList(growable: false);
    }

    if (row.length > length) {
      return row
          .take(length)
          .map((item) => item.trim())
          .toList(growable: false);
    }

    return <String>[
      ...row.map((item) => item.trim()),
      for (var i = row.length; i < length; i++) '',
    ];
  }

  static bool _tableIncludesHeader({
    required List<List<String>> table,
    required List<String> headers,
  }) {
    if (table.isEmpty || headers.isEmpty) return false;

    final firstRow = table.first;

    if (firstRow.length < headers.length) return false;

    for (var i = 0; i < headers.length; i++) {
      if (firstRow[i].trim() != headers[i].trim()) {
        return false;
      }
    }

    return true;
  }
}