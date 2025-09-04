import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:siged/_blocs/documents/contracts/budget/budget_bloc.dart';

class BudgetCache {
  final List<List<String>> tableData;
  final List<String> colTypes;   // ex.: ["text","money",...]
  final List<double> colWidths;

  const BudgetCache({
    required this.tableData,
    required this.colTypes,
    required this.colWidths,
  });

  bool get isEmpty => tableData.isEmpty;
}

class BudgetStore extends ChangeNotifier {
  BudgetStore({BudgetBloc? bloc}) : _bloc = bloc ?? BudgetBloc();

  final BudgetBloc _bloc;

  final Map<String, BudgetCache> _byContract = <String, BudgetCache>{};
  final Map<String, bool> _loading = <String, bool>{};

  // ---------- leitura ----------
  BudgetCache? cacheFor(String contractId) => _byContract[contractId];
  bool loadingFor(String contractId) => _loading[contractId] == true;

  // ---------- carregamento ----------
  Future<void> ensureFor(String contractId) async {
    if (contractId.isEmpty) return;

    // Se já temos cache:
    final cached = _byContract[contractId];
    if (cached != null) {
      if (cached.isEmpty && _loading[contractId] != true) {
        debugPrint('[BudgetStore] ensureFor($contractId): cache vazio, tentando refresh...');
        await refreshFor(contractId);
      } else {
        debugPrint('[BudgetStore] ensureFor($contractId): já em cache. loading=${_loading[contractId]}');
      }
      return;
    }

    // Evita chamadas concorrentes
    if (_loading[contractId] == true) {
      debugPrint('[BudgetStore] ensureFor($contractId): já carregando, saindo.');
      return;
    }

    // >>> Sinaliza loading e NOTIFICA a UI imediatamente <<<
    _loading[contractId] = true;
    _notifyAfterBuild(); // <- ESSENCIAL para o overlay aparecer

    // (opcional) delay mínimo para UX mais suave
    const int _minMs = 150;
    final started = DateTime.now();

    debugPrint('[BudgetStore] ensureFor($contractId): chamando BudgetBloc.loadBudgetNested...');
    try {
      final snap = await _bloc.loadBudgetNested(contractId);
      _byContract[contractId] = BudgetCache(
        tableData: snap.tableData,
        colTypes: snap.colTypes,
        colWidths: snap.colWidths,
      );
      debugPrint('[BudgetStore] ensureFor($contractId): carregado. rows=${snap.tableData.length}');
    } catch (e) {
      debugPrint('[BudgetStore] ensureFor($contractId) ERRO: $e');
      rethrow;
    } finally {
      // aplica delay mínimo (evita "piscar")
      final elapsed = DateTime.now().difference(started).inMilliseconds;
      if (elapsed < _minMs) {
        await Future.delayed(Duration(milliseconds: _minMs - elapsed));
      }
      _loading[contractId] = false;
      _notifyAfterBuild(); // notifica fim do loading
    }
  }

  Future<void> refreshFor(String contractId) async {
    if (contractId.isEmpty) return;

    // Sinaliza loading e notifica ANTES da chamada async (já existia aqui)
    _loading[contractId] = true;
    _notifyAfterBuild();

    // (opcional) delay mínimo para UX
    const int _minMs = 150;
    final started = DateTime.now();

    debugPrint('[BudgetStore] refreshFor($contractId): chamando BudgetBloc.loadBudgetNested...');
    try {
      final snap = await _bloc.loadBudgetNested(contractId);
      _byContract[contractId] = BudgetCache(
        tableData: snap.tableData,
        colTypes: snap.colTypes,
        colWidths: snap.colWidths,
      );
      debugPrint('[BudgetStore] refreshFor($contractId): ok. rows=${snap.tableData.length}');
    } catch (e) {
      debugPrint('[BudgetStore] refreshFor($contractId) ERRO: $e');
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

  Future<void> saveBudget({
    required String contractId,
    required List<String> headers,
    required List<String> colTypes,
    required List<double> colWidths,
    required List<List<String>> rows,
    required bool rowsIncludesHeader,
  }) async {
    debugPrint('[BudgetStore] saveBudget($contractId): salvando...');
    await _bloc.saveBudgetNested(
      contractId: contractId,
      headers: headers,
      colTypes: colTypes,
      colWidths: colWidths,
      rows: rows,
      rowsIncludesHeader: rowsIncludesHeader,
    );
    debugPrint('[BudgetStore] saveBudget($contractId): salvo, atualizando cache...');
    await refreshFor(contractId);
  }

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
