import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:siged/_blocs/system/user/user_data.dart';
import 'package:siged/_blocs/process/contracts/contract_bloc.dart';
import 'package:siged/_blocs/process/validity/validity_bloc.dart';
import 'package:siged/_blocs/process/contracts/contract_data.dart';

import 'package:siged/_blocs/process/contracts/contract_store.dart';

const bool kExpansionDebug = true;

class ListContractsController extends ChangeNotifier {
  ListContractsController({
    required ContractsStore store,
    required ValidityBloc validityBloc,
    required ContractBloc contractsBloc,
    bool isEditable = true,
  })  : _store = store,
        _validityBloc = validityBloc,
        _contractsBloc = contractsBloc,
        _isEditable = isEditable;

  // ---------- Dependências ----------
  final ContractsStore _store;
  final ValidityBloc _validityBloc;
  final ContractBloc _contractsBloc;

  // ---------- Estado público ----------
  Map<String, List<ContractData>> get cachedByStatus => _cachedContractsByStatus;
  TextEditingController get statusCtrl => _statusCtrl;
  TextEditingController get searchCtrl => _searchCtrl;

  int? get sortColumnIndex => _sortColumnIndex;
  bool get isAscending => _isAscending;
  bool get isEditable => _isEditable;
  bool get initialized => _initialized;
  bool get loading => _loading;
  UserData? get currentUser => _currentUser;

  // ---------- Internos ----------
  final Map<String, List<ContractData>> _cachedContractsByStatus = {};
  final _statusCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  final bool _isEditable;

  Timer? _debounce;
  int? _sortColumnIndex;
  bool _isAscending = true;
  bool _initialized = false;
  bool _loading = false;
  UserData? _currentUser;

  // ---------- Expansão / Persistência ----------
  static const _prefsExpandedKey = 'contracts_expanded_keys';

  final Set<String> _expandedKeys = {};         // sempre normalizadas
  Set<String> _preSearchExpandedSnapshot = {};  // restaura pós-busca

  final Map<String, ExpansionTileController> _tileControllers = {};

  String _norm(String k) => k.trim().toUpperCase();

  /// Snapshot legível pra log/painel
  String debugSnapshot() {
    final cache = _cachedContractsByStatus.map((k, v) => MapEntry(k, v.length));
    return 'expanded=$_expandedKeys | cacheKeys=$cache | search="${_searchCtrl.text.trim()}"';
  }

  Future<void> dumpToConsole() async {
    try {
      await SharedPreferences.getInstance();
      if (kIsWeb) {
      }
    } catch (e) {
    }
  }

  // ---------- API de expansão ----------
  bool isExpanded(String key) => _expandedKeys.contains(_norm(key));

  ExpansionTileController tileControllerFor(String key) {
    final nk = _norm(key);
    final ctrl = _tileControllers.putIfAbsent(nk, () => ExpansionTileController());
    return ctrl;
  }

  void setExpanded(String key, bool open) {
    final nk = _norm(key);
    if (open) {
      _expandedKeys.add(nk);
      tileControllerFor(nk).expand();
    } else {
      _expandedKeys.remove(nk);
      tileControllerFor(nk).collapse();
    }
    notifyListeners();
    _saveExpandedToPrefs();
  }

  void expandAll() {
    for (final k in _allKnownKeys()) {
      _expandedKeys.add(k);
      tileControllerFor(k).expand();
    }
    notifyListeners();
    _saveExpandedToPrefs();
  }

  void collapseAll() {
    for (final k in _allKnownKeys()) {
      _expandedKeys.remove(k);
      tileControllerFor(k).collapse();
    }
    notifyListeners();
    _saveExpandedToPrefs();
  }

  // ---------- Init ----------
  Future<void> initIfNeeded(UserData user) async {
    if (_initialized && _currentUser?.id == user.id) return;
    _initialized = true;
    _currentUser = user;

    await _loadExpandedFromPrefs();

    if (_store.all.isEmpty && !_store.loading) {
      await _store.refresh();
    }

    SchedulerBinding.instance.addPostFrameCallback((_) => _scheduleSyncTilesToState());

    await applyFilters();
  }

  // ---------- Filtro/Busca ----------
  Future<void> applyFilters() async {
    if (_currentUser == null) return;

    _setLoading(true);
    try {
      final contratosFiltrados = _store.filter(
        status: _statusCtrl.text.isNotEmpty ? _statusCtrl.text : null,
        searchText: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
      );

      _cachedContractsByStatus
        ..clear();

      for (final c in contratosFiltrados) {
        final status = _norm(c.contractStatus ?? 'SEM STATUS');
        _cachedContractsByStatus.putIfAbsent(status, () => []).add(c);
      }

      _applyLocalSortIfAny();

      final hasSearch = _searchCtrl.text.trim().isNotEmpty;

      if (hasSearch) {
        // snapshot do estado salvo (se ainda não tirou nesta sessão de busca)
        _preSearchExpandedSnapshot = _preSearchExpandedSnapshot.isEmpty
            ? Set<String>.from(_expandedKeys)
            : _preSearchExpandedSnapshot;

        final tempKeys = _cachedContractsByStatus.entries
            .where((e) => e.value.isNotEmpty)
            .map((e) => e.key)
            .toSet();

        _scheduleSyncSpecific(tempKeys);
      } else {
        if (_preSearchExpandedSnapshot.isNotEmpty) {
          _expandedKeys
            ..clear()
            ..addAll(_preSearchExpandedSnapshot);
          _preSearchExpandedSnapshot = {};
          _saveExpandedToPrefs();
        }

        // poda SUAVE: só remove se a chave EXISTE no agrupamento atual e está vazia
        _expandedKeys.removeWhere(
              (k) => _cachedContractsByStatus.containsKey(k) && (_cachedContractsByStatus[k]?.isEmpty ?? true),
        );

        _scheduleSyncTilesToState();
      }

      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refresh() async {
    _setLoading(true);
    try {
      await _store.refresh();
      await applyFilters();
    } finally {
      _setLoading(false);
    }
  }

  // ---------- Busca com debounce ----------
  void onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (_searchCtrl.text != value) _searchCtrl.text = value;
      await applyFilters();
    });
  }

  // ---------- Ordenação ----------
  void handleSort(int columnIndex) {
    if (_sortColumnIndex == columnIndex) {
      _isAscending = !_isAscending;
    } else {
      _sortColumnIndex = columnIndex;
      _isAscending = true;
    }
    _applyLocalSortIfAny();
    notifyListeners();
  }

  void _applyLocalSortIfAny() {
    if (_sortColumnIndex == null) return;

    final byName = _sortColumnIndex == 0;
    if (!byName) return;

    int cmp(ContractData a, ContractData b) {
      final an = (a.summarySubjectContract ?? '').toUpperCase();
      final bn = (b.summarySubjectContract ?? '').toUpperCase();
      return an.compareTo(bn);
    }

    for (final entry in _cachedContractsByStatus.entries) {
      entry.value.sort((a, b) => _isAscending ? cmp(a, b) : cmp(b, a));
    }
  }

  // ---------- Sincronização visual ----------
  Set<String> _allKnownKeys() {
    return {..._cachedContractsByStatus.keys, ..._expandedKeys};
  }

  void _scheduleSyncTilesToState() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final keys = _allKnownKeys();
      for (final k in keys) {
        final ctrl = tileControllerFor(k);
        if (_expandedKeys.contains(k)) {
          ctrl.expand();
        } else {
          ctrl.collapse();
        }
      }
    });
  }

  void _scheduleSyncSpecific(Set<String> expandedTemp) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final keys = _allKnownKeys();
      for (final k in keys) {
        final ctrl = tileControllerFor(k);
        if (expandedTemp.contains(k)) {
          ctrl.expand();
        } else {
          ctrl.collapse();
        }
      }
    });
  }

  // ---------- Persistência ----------
  Future<void> _saveExpandedToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _expandedKeys.map(_norm).toList();
      await prefs.setStringList(_prefsExpandedKey, list);
    } catch (e) {
    }
  }

  Future<void> _loadExpandedFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = (prefs.getStringList(_prefsExpandedKey) ?? const <String>[])
          .map(_norm)
          .toSet();
      _expandedKeys
        ..clear()
        ..addAll(saved);
    } catch (e) {
    }
  }

  // ---------- Getters utilitários ----------
  ValidityBloc get validityBloc => _validityBloc;
  ContractBloc get contractsBloc => _contractsBloc;
  ContractsStore get store => _store;

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  @override
  void dispose() {
    _statusCtrl.dispose();
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ---------- Helpers de Provider ----------
  static ListContractsController of(BuildContext context, {bool listen = true}) =>
      Provider.of<ListContractsController>(context, listen: listen);

  static ListContractsController create(BuildContext context) {
    return ListContractsController(
      store: context.read<ContractsStore>(),
      validityBloc: context.read<ValidityBloc>(),
      contractsBloc: context.read<ContractBloc>(),
      isEditable: true,
    );
  }
}
