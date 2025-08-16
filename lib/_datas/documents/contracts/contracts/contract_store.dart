// lib/screens/commons/listContracts/contracts_store.dart
import 'package:flutter/foundation.dart';
import 'package:sisged/_blocs/documents/contracts/contracts/contracts_bloc.dart';
import 'package:sisged/_datas/documents/contracts/contracts/contracts_data.dart';
import 'package:sisged/_datas/system/user_data.dart';

class ContractsStore extends ChangeNotifier {
  final ContractsBloc bloc;
  ContractsStore(this.bloc);

  bool _loading = false;
  bool get loading => _loading;

  List<ContractData> _all = const [];
  List<ContractData> get all => _all;

  ContractData? _selected;
  ContractData? get selected => _selected;

  final Map<String, ContractData> _cache = {};
  UserData? _currentUser;
  bool _initialized = false;

  /// Carrega 1x por usuário (idempotente)
  Future<void> warmup(UserData currentUser) async {
    if (_initialized && _currentUser?.id == currentUser.id && _all.isNotEmpty) return;

    _currentUser = currentUser;
    _loading = true; notifyListeners();

    final lista = await bloc.getFilteredContracts(currentUser: currentUser);
    _setAll(lista);

    _loading = false;
    _initialized = true;
    notifyListeners();
  }

  /// Força recarga do Firestore (mantém selected)
  Future<void> refresh() async {
    if (_currentUser == null) return;
    _loading = true; notifyListeners();

    final lista = await bloc.getFilteredContracts(currentUser: _currentUser!);
    _setAll(lista);

    if (_selected != null) _selected = _cache[_selected!.id ?? ''];
    _loading = false;
    notifyListeners();
  }

  void _setAll(List<ContractData> lista) {
    _all = List.unmodifiable(lista);
    _cache
      ..clear()
      ..addEntries(_all.where((c) => c.id != null).map((c) => MapEntry(c.id!, c)));
  }

  /// Seleciona e garante presença na lista/cache
  void select(ContractData c) {
    if (c.id != null) _cache[c.id!] = c;

    final idx = c.id == null ? -1 : _all.indexWhere((e) => e.id == c.id);
    if (idx == -1) {
      _all = List.unmodifiable([..._all, c]);
    } else {
      final tmp = [..._all]; tmp[idx] = c; _all = List.unmodifiable(tmp);
    }
    _selected = c;
    notifyListeners();
  }

  void clearSelection() {
    _selected = null;
    notifyListeners();
  }

  /// Busca por id com cache (útil p/ deep-link)
  Future<ContractData?> getById(String id) async {
    if (_cache.containsKey(id)) return _cache[id];
    final c = await bloc.getContractById(id);
    if (c != null) {
      _cache[id] = c;
      final idx = _all.indexWhere((e) => e.id == id);
      if (idx == -1) {
        _all = List.unmodifiable([..._all, c]);
      } else {
        final tmp = [..._all]; tmp[idx] = c; _all = List.unmodifiable(tmp);
      }
      notifyListeners();
    }
    return c;
  }

  /// Após salvar/editar (sem re-fetch)
  void upsert(ContractData c) {
    if (c.id != null) _cache[c.id!] = c;
    final idx = c.id == null ? -1 : _all.indexWhere((e) => e.id == c.id);
    if (idx == -1) {
      _all = List.unmodifiable([..._all, c]);
    } else {
      final tmp = [..._all]; tmp[idx] = c; _all = List.unmodifiable(tmp);
    }
    if (_selected?.id == c.id) _selected = c;
    notifyListeners();
  }

  /// Após deletar
  void removeById(String id) {
    _cache.remove(id);
    final tmp = [..._all]..removeWhere((e) => e.id == id);
    _all = List.unmodifiable(tmp);
    if (_selected?.id == id) _selected = null;
    notifyListeners();
  }

  /// Filtros em memória p/ dashboards/listas
  List<ContractData> filter({
    String? status,
    String? company,
    String? regionContains,
    String? searchText,
  }) {
    Iterable<ContractData> r = _all;

    if (status != null && status.isNotEmpty) {
      r = r.where((c) => (c.contractStatus ?? '').toUpperCase() == status.toUpperCase());
    }
    if (company != null && company.isNotEmpty) {
      r = r.where((c) => (c.companyLeader ?? '').toUpperCase() == company.toUpperCase());
    }
    if (regionContains != null && regionContains.isNotEmpty) {
      r = r.where((c) => (c.regionOfState ?? '').toUpperCase().contains(regionContains.toUpperCase()));
    }
    if (searchText != null && searchText.isNotEmpty) {
      final s = searchText.toUpperCase();
      r = r.where((c) =>
      (c.summarySubjectContract ?? '').toUpperCase().contains(s) ||
          (c.contractNumber ?? '').toUpperCase().contains(s) ||
          (c.companyLeader ?? '').toUpperCase().contains(s));
    }
    return r.toList(growable: false);
  }
}
