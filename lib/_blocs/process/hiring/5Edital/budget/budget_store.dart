// lib/_blocs/process/budget/budget_store.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:siged/_blocs/process/hiring/5Edital/budget/budget_bloc.dart';
import 'package:siged/_blocs/process/hiring/5Edital/budget/budget_data.dart';

class BudgetStore extends ChangeNotifier {
  BudgetStore({BudgetBloc? bloc}) : _bloc = bloc ?? BudgetBloc();

  final BudgetBloc _bloc;

  final Map<String, BudgetData> _byContract = <String, BudgetData>{};
  final Map<String, bool> _loading = <String, bool>{};

  // ---------- leitura ----------
  BudgetData? dataFor(String contractId) => _byContract[contractId];
  bool loadingFor(String contractId) => _loading[contractId] == true;

  // ---------- carregamento ----------
  Future<void> ensureFor(String contractId) async {
    if (contractId.isEmpty) return;

    final cached = _byContract[contractId];
    if (cached != null) {
      if ((cached.entries.isEmpty || cached.schema.columns.isEmpty) &&
          _loading[contractId] != true) {
        await refreshFor(contractId);
      } else {
      }
      return;
    }

    if (_loading[contractId] == true) {
      return;
    }

    _loading[contractId] = true;
    _notifyAfterBuild();

    const int _minMs = 150;
    final started = DateTime.now();

    try {
      final snap = await _bloc.load(contractId);
      _byContract[contractId] = snap;
    } catch (e) {
      rethrow;
    } finally {
      final elapsed = DateTime.now().difference(started).inMilliseconds;
      if (elapsed < _minMs) {
        await Future.delayed(Duration(milliseconds: _minMs - elapsed));
      }
      _loading[contractId] = false;
      _notifyAfterBuild();
    }
  }

  Future<void> refreshFor(String contractId) async {
    if (contractId.isEmpty) return;

    _loading[contractId] = true;
    _notifyAfterBuild();

    const int _minMs = 150;
    final started = DateTime.now();

    try {
      final snap = await _bloc.load(contractId);
      _byContract[contractId] = snap;
    } catch (e) {
      rethrow;
    } finally {
      final elapsed = DateTime.now().difference(started).inMilliseconds;
      if (elapsed < _minMs) {
        await Future.delayed(Duration(milliseconds: _minMs - elapsed));
      }
      _loading[contractId] = false;
      _notifyAfterBuild();
    }
  }

  void clearFor(String contractId) {
    _byContract.remove(contractId);
    _loading.remove(contractId);
    _notifyAfterBuild();
  }

  // ---------- SALVAR (Domínio) ----------
  Future<void> saveDomain({
    required String contractId,
    required BudgetData data,
  }) async {
    await _bloc.save(contractId: contractId, data: data);
    await refreshFor(contractId);
  }

  // ---------- SHIM LEGADO (UI antiga que passa arrays) ----------
  Future<void> saveBudget({
    required String contractId,
    required List<String> headers,
    required List<String> colTypes,
    required List<double> colWidths,
    required List<List<String>> rows,
    required bool rowsIncludesHeader,
  }) async {
    await _bloc.saveBudgetNested(
      contractId: contractId,
      headers: headers,
      colTypes: colTypes,
      colWidths: colWidths,
      rows: rows,
      rowsIncludesHeader: rowsIncludesHeader,
    );
    await refreshFor(contractId);
  }

  // ---------- notify seguro ----------
  void _notifyAfterBuild() {
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle || phase == SchedulerPhase.postFrameCallbacks) {
      if (hasListeners) notifyListeners();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (hasListeners) notifyListeners();
      });
    }
  }
}
